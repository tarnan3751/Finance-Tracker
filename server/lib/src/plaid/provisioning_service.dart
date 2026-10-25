/// Persona provisioning into Plaid Sandbox as a job (`docs/reference/server.md`,
/// **Provisioning**; `docs/reference/persona.md`, **Sandbox custom users**, **Injection
/// batches**, **Dates in Sandbox**).
///
/// A job generates the persona's Sandbox outputs with `persona_engine` at the engine's
/// fixed as-of date (the committed goldens' date), so a provisioned persona equals the
/// `days730` fixtures, and shifts every date of every Item by one amount computed once at
/// the start: Plaid's today (UTC−12) minus that as-of date. For each institution it
/// creates a custom user, exchanges it and stores the Item for the caller exactly as an
/// exchange through Link does, runs the first sync (retrying `not_ready`) and maps the
/// engine's accounts to the Item's by name and mask. It then injects the older history,
/// ten per call, newest first, one round across the Items at a time, at least 35 s apart
/// per Item, and syncs each Item once more. A Plaid rate limit is retried after its
/// `Retry-After` (60 s by default) at most three times, and a Plaid 5xx 15 s apart at most
/// three times; the first other failure, a 4xx included, ends the job `failed` with the
/// step and Plaid's code, never a token. A transaction whose shifted date falls outside
/// Plaid's window at the moment of its call is left out and counted in `skipped`: the
/// window is checked at every call against the shift computed once, and a 730-day persona
/// ends one day inside Plaid's 730, so this happens to a job that outlasts the day after
/// it started.
///
/// Jobs live in memory: a restart forgets them, and the Items they linked stay. One job
/// per user runs at a time. Every record the job causes is stored from Plaid's own
/// answers with the client's provenance; the server fabricates none (`PLAN.md` §7.1).
library;

import 'dart:async';

import 'package:finance_tracker_server/src/db/database.dart';
import 'package:finance_tracker_server/src/http/problem.dart';
import 'package:finance_tracker_server/src/http/wire.dart';
import 'package:finance_tracker_server/src/ids.dart';
import 'package:finance_tracker_server/src/logging.dart';
import 'package:finance_tracker_server/src/plaid/item_service.dart';
import 'package:finance_tracker_server/src/plaid/plaid_client.dart';
import 'package:finance_tracker_server/src/plaid/sandbox_service.dart';
import 'package:logging/logging.dart';
import 'package:persona_engine/persona_engine.dart';
import 'package:shared_models/shared_models.dart';

/// The as-of date the job generates at: the persona engine's default, the date of its
/// committed goldens (`tools/persona_engine/bin/persona_engine.dart`, `defaultAsOf`).
final LocalDate provisioningAsOf = LocalDate(2026, 10, 24);

/// The least time between two `/sandbox/transactions/create` calls on one Item: Plaid
/// documents 2 per minute per Item (`PLAN.md` §4).
const injectionInterval = Duration(seconds: injectionIntervalSeconds);

/// The wait between first-sync attempts while Plaid answers `NOT_READY`.
const notReadyRetry = Duration(seconds: 5);

/// How many times the first sync is tried before the job gives up.
const notReadyAttempts = 24;

/// The wait after a rate limit that names none.
const rateLimitWait = Duration(seconds: 60);

/// How many times a rate-limited call is retried.
const rateLimitRetries = 3;

/// The wait before retrying a call Plaid failed on its side (a 5xx).
const serverErrorWait = Duration(seconds: 15);

/// How many times a call Plaid failed on its side is retried.
const serverErrorRetries = 3;

final _http5xx = RegExp(r'^HTTP_5[0-9]{2}$');

/// Whether [e] is Plaid failing on its side: `API_ERROR` with
/// `INTERNAL_SERVER_ERROR`, `HTTP_5xx`, `TIMEOUT` or `NETWORK_ERROR`.
bool isPlaidServerError(PlaidException e) =>
    e.errorType == 'API_ERROR' &&
    (e.errorCode == 'INTERNAL_SERVER_ERROR' ||
        e.errorCode == 'TIMEOUT' ||
        e.errorCode == 'NETWORK_ERROR' ||
        _http5xx.hasMatch(e.errorCode));

/// A job's state (the contract's `ProvisionJobStatus`).
enum ProvisionStatus { queued, running, completed, failed }

final class _Job {
  _Job(
    this.id,
    this.userId,
    this.persona,
    this.seed,
    this.days,
    this.createdAt,
  );

  final String id;
  final String userId;
  final PersonaId persona;
  final int seed;
  final int days;
  final DateTime createdAt;
  ProvisionStatus status = ProvisionStatus.queued;
  DateTime? finishedAt;
  String? error;
  int itemsTotal = 0;
  int itemsLinked = 0;
  int batchesTotal = 0;
  int batchesSent = 0;
  int skipped = 0;
  final List<String> itemIds = [];
  final Completer<void> finished = Completer();

  bool get active =>
      status == ProvisionStatus.queued || status == ProvisionStatus.running;

  Map<String, Object?> toJson() => {
    'id': id,
    'persona': persona.slug,
    'seed': seed,
    'status': status.name,
    'created_at': instantJson(createdAt.millisecondsSinceEpoch),
    'finished_at': finishedAt == null
        ? null
        : instantJson(finishedAt!.millisecondsSinceEpoch),
    'progress': {
      'items_total': itemsTotal,
      'items_linked': itemsLinked,
      'batches_total': batchesTotal,
      'batches_sent': batchesSent,
      'skipped': skipped,
    },
    'error': error,
    'item_ids': [...itemIds],
  };
}

/// A failure that ends a job, with the text the job records.
final class _JobFailure implements Exception {
  const _JobFailure(this.text);

  final String text;
}

/// One linked Item during a job: its injection batches and when it was last called.
final class _Linked {
  _Linked(this.itemId, this.accessToken, this.batches);

  final String itemId;
  final String accessToken;
  final List<List<SandboxTransaction>> batches;
  DateTime? lastCall;
}

/// The jobs.
final class ProvisioningService {
  /// The service.
  ProvisioningService({
    required this.db,
    required this.items,
    required this.sandbox,
    required this.plaid,
    required this.now,
    Future<void> Function(Duration)? delay,
  }) : delay = delay ?? Future<void>.delayed;

  /// The database.
  final AppDatabase db;

  /// The Item store: exchange and sync, exactly as the Plaid routes use them.
  final ItemService items;

  /// The Sandbox rules ([SandboxService.checkAvailable]).
  final SandboxService sandbox;

  /// The Plaid client.
  final PlaidClient plaid;

  /// The server's clock.
  final DateTime Function() now;

  /// Waits: the pacing, the `NOT_READY` retries and the rate-limit backoff.
  final Future<void> Function(Duration) delay;

  final Map<String, _Job> _jobs = {};
  final Logger _log = Logger('provisioning');

  /// Starts a job for [userId] on [deviceId]; the contract's `ProvisionJob`, queued.
  /// [baseUrl] is the request's, for the Items' logo URLs. 409 `conflict` while another
  /// job of the user is queued or running.
  Map<String, Object?> start(
    String userId,
    String deviceId, {
    required PersonaId persona,
    required int seed,
    required int days,
    required Uri baseUrl,
  }) {
    sandbox.checkAvailable();
    if (_jobs.values.any((j) => j.userId == userId && j.active)) {
      throw const ProblemException(
        409,
        ProblemCode.conflict,
        detail: 'A provisioning job of this user is already running',
      );
    }
    final job = _Job(newId(), userId, persona, seed, days, now().toUtc());
    _jobs[job.id] = job;
    _log.info(
      LogEvent('provision_started', {
        'job_id': job.id,
        'user_id': userId,
        'persona': persona.slug,
        'seed': seed,
        'days': days,
      }),
    );
    final queued = job.toJson();
    unawaited(Future(() => _run(job, deviceId, baseUrl)));
    return queued;
  }

  /// The user's job [jobId]; 404 for another user's or an unknown one.
  Map<String, Object?> get(String userId, String jobId) {
    sandbox.checkAvailable();
    final job = _jobs[jobId];
    if (job == null || job.userId != userId) {
      throw const ProblemException.notFound('No provisioning job with that id');
    }
    return job.toJson();
  }

  /// Completes when the job [jobId] has finished, either way.
  Future<void> finished(String jobId) => _jobs[jobId]!.finished.future;

  Future<void> _run(_Job job, String deviceId, Uri baseUrl) async {
    job.status = ProvisionStatus.running;
    try {
      await _provision(job, deviceId, baseUrl);
      job.status = ProvisionStatus.completed;
      _log.info(
        LogEvent('provision_completed', {
          'job_id': job.id,
          'items': job.itemsLinked,
          'batches': job.batchesSent,
          'skipped': job.skipped,
        }),
      );
    } on _JobFailure catch (e) {
      _fail(job, e.text);
    } on Object catch (e) {
      // Not a Plaid or problem failure: logged by type only, never its text.
      _fail(job, 'internal: ${e.runtimeType}');
    } finally {
      job.finishedAt = now().toUtc();
      job.finished.complete();
    }
  }

  void _fail(_Job job, String text) {
    job
      ..status = ProvisionStatus.failed
      ..error = text;
    _log.warning(
      LogEvent('provision_failed', {'job_id': job.id, 'error': text}),
    );
  }

  Future<void> _provision(_Job job, String deviceId, Uri baseUrl) async {
    final household = generateHousehold(
      personaFor(job.persona),
      seed: job.seed,
      asOf: provisioningAsOf,
      days: job.days,
    );
    final users = sandboxUsers(household);
    final shift = provisioningAsOf.daysUntil(plaidToday(now()));
    job
      ..itemsTotal = users.length
      ..batchesTotal = users.fold(0, (n, u) => n + batchCount(u));

    final linked = <_Linked>[];
    for (final user in users) {
      linked.add(await _link(job, household, user, shift, deviceId, baseUrl));
    }

    final rounds = linked.fold(
      0,
      (n, l) => l.batches.length > n ? l.batches.length : n,
    );
    for (var round = 0; round < rounds; round++) {
      for (final item in linked) {
        if (round >= item.batches.length) continue;
        await _inject(job, item, item.batches[round]);
        job.batchesSent++;
      }
    }

    for (final item in linked) {
      await _step('final sync', () => items.sync(job.userId, item.itemId));
    }
  }

  /// Creates, exchanges and first-syncs one custom user; its batches mapped to the
  /// Item's Plaid account ids.
  Future<_Linked> _link(
    _Job job,
    GeneratedHousehold household,
    SandboxUser user,
    int shift,
    String deviceId,
    Uri baseUrl,
  ) async {
    final institution = user.split.institution;
    final config = _withinWindow(
      job,
      shiftSandboxUserDates(user.config, shift),
    );
    final accounts = [
      for (final a in config['override_accounts']! as List<Object?>)
        a! as Map<String, Object?>,
    ];
    final products = [
      'transactions',
      if (accounts.any((a) => a.containsKey('liability'))) 'liabilities',
      if (accounts.any((a) => a['type'] == 'investment')) 'investments',
    ];
    // Creating the custom user and exchanging it are retried together: an exchange that
    // fails after Plaid made the Item (a rate limit on `/item/get`) removes that Item, so
    // a retry needs a fresh public token.
    final item = await _step('link ${institution.key}', () async {
      final publicToken = await plaid.sandboxPublicTokenCreate(
        institutionId: institution.plaidId,
        products: products,
        overrideUsername: 'user_custom',
        overridePassword: writeJson(config, pretty: false),
        daysRequested: plaidWindowDays,
      );
      return items.exchange(
        job.userId,
        deviceId,
        publicToken,
        baseUrl: baseUrl,
      );
    });
    final itemId = item['id']! as String;
    job.itemIds.add(itemId);

    for (var attempt = 1; ; attempt++) {
      final run = await _step(
        'first sync ${institution.key}',
        () => items.sync(job.userId, itemId),
      );
      if (run['status'] == 'completed') break;
      if (attempt >= notReadyAttempts) {
        throw _JobFailure('first sync ${institution.key}: NOT_READY');
      }
      await delay(notReadyRetry);
    }

    final rows = await db.read(
      (tx) => tx.select(
        'SELECT name, mask, plaid_account_id FROM accounts WHERE item_id = ?',
        [itemId],
      ),
    );
    // Accounts are matched by name and mask, so two that share both cannot be told
    // apart, on the Item or in the persona.
    final plaidIds = <String, String>{};
    for (final r in rows) {
      final key = '${r['name']}|${r['mask']}';
      if (plaidIds.containsKey(key)) {
        throw _JobFailure(
          'map ${institution.key}: two accounts on the Item share the name '
          '${r['name']} and mask ${r['mask']}',
        );
      }
      plaidIds[key] = r['plaid_account_id']! as String;
    }
    final persona = household.persona;
    final accountOf = <String, String>{};
    final seen = <String, String>{};
    for (final spec in persona.accounts) {
      if (spec.institution != institution.key) continue;
      final previous = seen['${spec.name}|${spec.mask}'];
      if (previous != null) {
        throw _JobFailure(
          'map ${institution.key}: accounts $previous and ${spec.key} share '
          'name and mask',
        );
      }
      seen['${spec.name}|${spec.mask}'] = spec.key;
      final plaidId = plaidIds['${spec.name}|${spec.mask}'];
      if (plaidId == null) {
        throw _JobFailure(
          'map ${institution.key}: no account ${spec.key} on the Item',
        );
      }
      accountOf[accountIdFor(persona.id, spec.key)] = plaidId;
    }
    final injected = user.split.injected;
    final batches = <List<SandboxTransaction>>[
      for (var i = 0; i < injected.length; i += injectionBatchSize)
        [
          for (final t in injected.skip(i).take(injectionBatchSize))
            (
              dateTransacted: t.authorizedDate!.addDays(shift),
              datePosted: t.date.addDays(shift),
              amount: -t.amount,
              description: t.name,
              accountId: accountOf[t.accountId],
            ),
        ],
    ];
    final opened = await items.loadActive(job.userId, itemId);
    job.itemsLinked++;
    _log.info(
      LogEvent('provision_item_linked', {
        'job_id': job.id,
        'item_id': itemId,
        'batches': batches.length,
      }),
    );
    return _Linked(itemId, opened.accessToken, batches);
  }

  /// [config] without the transactions whose dates fall outside Plaid's window today,
  /// each counted in [job]'s `skipped`.
  Map<String, Object?> _withinWindow(_Job job, Map<String, Object?> config) {
    final today = plaidToday(now());
    final accounts = <Object?>[];
    for (final raw in config['override_accounts']! as List<Object?>) {
      final account = raw! as Map<String, Object?>;
      final kept = <Object?>[];
      for (final raw in account['transactions']! as List<Object?>) {
        final t = raw! as Map<String, Object?>;
        if (inPlaidWindow(
              LocalDate.parse(t['date_posted']! as String),
              today,
            ) &&
            inPlaidWindow(
              LocalDate.parse(t['date_transacted']! as String),
              today,
            )) {
          kept.add(t);
        } else {
          job.skipped++;
        }
      }
      accounts.add({...account, 'transactions': kept});
    }
    return {...config, 'override_accounts': accounts};
  }

  /// Sends one batch to [item], paced and with what is still inside Plaid's window.
  Future<void> _inject(
    _Job job,
    _Linked item,
    List<SandboxTransaction> batch,
  ) async {
    final last = item.lastCall;
    if (last != null) {
      final wait = last.add(injectionInterval).difference(now());
      if (wait > Duration.zero) await delay(wait);
    }
    final today = plaidToday(now());
    final inside = [
      for (final t in batch)
        if (inPlaidWindow(t.dateTransacted, today) &&
            inPlaidWindow(t.datePosted, today))
          t,
    ];
    job.skipped += batch.length - inside.length;
    if (inside.isEmpty) return;
    await _step(
      'inject',
      () => plaid.sandboxTransactionsCreate(item.accessToken, inside),
    );
    item.lastCall = now();
  }

  /// Runs [call], retrying a rate limit after its wait at most [rateLimitRetries] times
  /// and a Plaid 5xx ([isPlaidServerError]) [serverErrorWait] apart at most
  /// [serverErrorRetries] times; any other failure, a 4xx included, ends the job with
  /// [step] and the code. A 5xx counts whether it arrives raw (a Sandbox call) or as the
  /// cause of a 502 `plaid_error` from [ItemService] (the exchange and the syncs).
  Future<T> _step<T>(String step, Future<T> Function() call) async {
    var serverErrors = 0;
    for (var retry = 0; ; retry++) {
      try {
        return await call();
      } on PlaidException catch (e) {
        if (isPlaidServerError(e)) {
          if (serverErrors >= serverErrorRetries) {
            throw _JobFailure('$step: ${e.errorCode}');
          }
          retry--;
          await _serverError(step, e, ++serverErrors);
          continue;
        }
        if (!e.isRateLimit) throw _JobFailure('$step: ${e.errorCode}');
        if (retry >= rateLimitRetries) {
          throw _JobFailure('$step: ${e.errorCode}');
        }
        await _rateLimited(step, rateLimitWait);
      } on ProblemException catch (e) {
        final cause = e.cause;
        if (e.status == 502 &&
            cause is PlaidException &&
            isPlaidServerError(cause)) {
          if (serverErrors >= serverErrorRetries) {
            throw _JobFailure('$step: ${cause.errorCode}');
          }
          retry--;
          await _serverError(step, cause, ++serverErrors);
          continue;
        }
        if (e.status != 429) {
          throw _JobFailure(
            '$step: ${e.code.wire}${e.detail == null ? '' : ' (${e.detail})'}',
          );
        }
        if (retry >= rateLimitRetries) throw _JobFailure('$step: rate_limited');
        final seconds = int.tryParse(e.headers['retry-after'] ?? '');
        await _rateLimited(
          step,
          seconds == null ? rateLimitWait : Duration(seconds: seconds),
        );
      }
    }
  }

  Future<void> _serverError(String step, PlaidException e, int attempt) {
    _log.info(
      LogEvent('provision_plaid_server_error', {
        'step': step,
        'code': e.errorCode,
        'attempt': attempt,
      }),
    );
    return delay(serverErrorWait);
  }

  Future<void> _rateLimited(String step, Duration wait) {
    _log.info(
      LogEvent('provision_rate_limited', {
        'step': step,
        'wait_seconds': wait.inSeconds,
      }),
    );
    return delay(wait);
  }
}
