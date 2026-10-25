/// Persona provisioning into Plaid Sandbox as a job (`docs/reference/server.md`,
/// **Provisioning**; `docs/reference/persona.md`, **Sandbox custom users**, **Dates in
/// Sandbox**).
///
/// A job generates the persona's Sandbox outputs with `persona_engine` at the engine's
/// fixed as-of date (the committed goldens' date), so a provisioned persona equals the
/// `days730` fixtures, and shifts every date of every Item by one amount computed once at
/// the start: Plaid's today (UTC−12) minus that as-of date. For each institution it
/// creates a custom user, exchanges it and stores the Item for the caller exactly as an
/// exchange through Link does, and runs the first sync (retrying `not_ready`) and, a few
/// seconds after it completes, a second one: Sandbox reports a large custom user's
/// historical update complete while the rest of its rows is still arriving, and delivers
/// them on a later sync (`PLAN.md` §4), so the job's Item is whole when it reports it
/// linked. The custom
/// user is the Item's whole history: Plaid serves an injected row only when it is dated
/// its today (`PLAN.md` §4), so the job injects nothing, and the history the engine left
/// out of the configuration (the manifest's `transactions_left_out`) never reaches
/// Sandbox. A Plaid rate limit is retried after its `Retry-After` (60 s by default) at
/// most three times, and a Plaid 5xx 15 s apart at most three times; the first other
/// failure, a 4xx included, ends the job `failed` with the step and Plaid's code, never a
/// token. A transaction whose shifted date falls outside Plaid's window when its Item is
/// linked (the UTC date minus 729 to Plaid's today, `inPlaidWindow`) is left out of the
/// configuration and counted in `skipped`. A 730-day persona's oldest day is therefore
/// skipped, when its Item carries it, by a job that links before 12:00 UTC, when the UTC
/// date is a day past Plaid's today, or after a UTC midnight it outlasted.
///
/// Jobs live in memory: a restart forgets them, and the Items they linked stay. One job
/// per user runs at a time. Every record the job causes is stored from Plaid's own
/// answers with the client's provenance; the server fabricates none (`PLAN.md` §7.1).
library;

import 'dart:async';

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

/// The wait between first-sync attempts while Plaid answers `NOT_READY`.
const notReadyRetry = Duration(seconds: 5);

/// How many times the first sync is tried before the job gives up.
const notReadyAttempts = 24;

/// The wait between the first completed sync and the second, which stores the history
/// Sandbox delivers late.
const lateHistoryWait = Duration(seconds: 5);

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
      // The job injects no batches; the contract keeps the counters.
      'batches_total': 0,
      'batches_sent': 0,
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

/// The jobs.
final class ProvisioningService {
  /// The service.
  ProvisioningService({
    required this.items,
    required this.sandbox,
    required this.plaid,
    required this.now,
    Future<void> Function(Duration)? delay,
  }) : delay = delay ?? Future<void>.delayed;

  /// The Item store: exchange and sync, exactly as the Plaid routes use them.
  final ItemService items;

  /// The Sandbox rules ([SandboxService.checkAvailable]).
  final SandboxService sandbox;

  /// The Plaid client.
  final PlaidClient plaid;

  /// The server's clock.
  final DateTime Function() now;

  /// Waits: the `NOT_READY` retries and the retry backoffs.
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
    job.itemsTotal = users.length;
    for (final user in users) {
      await _link(job, user, shift, deviceId, baseUrl);
    }
  }

  /// Creates, exchanges and syncs one custom user.
  Future<void> _link(
    _Job job,
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
    await delay(lateHistoryWait);
    await _step(
      'second sync ${institution.key}',
      () => items.sync(job.userId, itemId),
    );
    job.itemsLinked++;
    _log.info(
      LogEvent('provision_item_linked', {'job_id': job.id, 'item_id': itemId}),
    );
  }

  /// [config] without the transactions whose dates fall outside Plaid's window now,
  /// each counted in [job]'s `skipped`.
  Map<String, Object?> _withinWindow(_Job job, Map<String, Object?> config) {
    final at = now();
    final accounts = <Object?>[];
    for (final raw in config['override_accounts']! as List<Object?>) {
      final account = raw! as Map<String, Object?>;
      final kept = <Object?>[];
      for (final raw in account['transactions']! as List<Object?>) {
        final t = raw! as Map<String, Object?>;
        if (inPlaidWindow(LocalDate.parse(t['date_posted']! as String), at) &&
            inPlaidWindow(
              LocalDate.parse(t['date_transacted']! as String),
              at,
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
