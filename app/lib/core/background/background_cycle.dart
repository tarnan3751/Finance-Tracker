/// One background sync cycle (`docs/reference/background.md`, **The cycle**): what the
/// WorkManager task runs in its own engine (`background_dispatcher.dart`), and what the
/// integration test runs in its own isolate over the fakes.
///
/// 1. The demo flavor has nothing to sync: done.
/// 2. The `ft.background` lock is taken first (`background_ports.dart`): a live cycle
///    holding it already is done. Then the app's isolate is asked: busy (a restore or a
///    wipe) is done; a sync it ran is its outcome; either way the lock goes. With no app
///    answering, the cycle runs itself under the lock, which an app starting meanwhile
///    waits for.
/// 3. Guards, before anything is opened: a pending wipe (`wipe_pending_v1`), no stored
///    session, or no database file or no key is done. The cycle never creates a key or
///    a database.
/// 4. A probe connection reads the schema version, the full-text definition and the
///    full-text objects: a schema the app has not migrated to yet (or past), a
///    definition that is absent or another, or a missing object is done, so the cycle
///    never runs a schema step or builds the full-text index; those are the app's.
/// 5. The database opens (WAL, the busy timeout: `open_database.dart`); a pending restore
///    offer holds the cycle (recorded as [BackgroundResult.held]), since a restore must
///    land before the server's copy does.
/// 6. The sync controller's start session runs (push, pull, then the Plaid pull), the
///    reminders are planned again, and [backgroundCycleHooksProvider]'s steps run.
/// 7. The outcome is recorded in `app_meta` (`background_last_run`); a session the server
///    ended (the API cleared it on a 401) is recorded too (`session_ended_in_background`),
///    for the sign-in screen to say, and told in the tray (`sync_problems`).
///
/// Steps 3 to 7 run under [backgroundCycleDeadline]: past it the cycle records
/// [BackgroundResult.timedOut] if it can and returns. On every path the container is
/// disposed and the database closed before the cycle returns: Drift's own isolate is not
/// tied to the engine, so a connection left open could keep its lock after the engine
/// is gone, and closing it rolls back whatever it left open. The lock is released when
/// the cycle has stopped. The result is true (done) except after a network failure,
/// false, which WorkManager retries on its backoff. Nothing is logged but types and
/// outcomes.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/api/token_store.dart';
import 'package:finance_tracker/core/background/background_hooks.dart';
import 'package:finance_tracker/core/background/background_ports.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/full_text_search.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/platform/in_app_notifications.dart';
import 'package:finance_tracker/core/platform/notifier.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/sync/sync_status.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/backup/application/backup_providers.dart';
import 'package:finance_tracker/features/bills/application/bills_providers.dart';
import 'package:finance_tracker/features/bills/application/reminder_planner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:logging/logging.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:timezone/timezone.dart' as tz;

final Logger _log = Logger('background');

/// How long a cycle may run.
const Duration backgroundCycleDeadline = Duration(seconds: 30);

/// How a cycle went, as `background_last_run` records it.
enum BackgroundResult {
  /// A session and the Plaid pull ran.
  synced,

  /// No network: retried.
  offline,

  /// The server failed, or something else did; the next period tries again.
  failed,

  /// The server had ended the session.
  sessionEnded,

  /// Nothing to do: a guard (signed out, no database, a wipe or a migration the app
  /// has not run).
  skipped,

  /// Held until the restore offer is answered: a restore must land before the
  /// server's copy does.
  held,

  /// The deadline passed.
  timedOut,
}

/// The last background run as `background_last_run` holds it.
final class BackgroundRun {
  const BackgroundRun({
    required this.at,
    required this.result,
    required this.delegated,
  });

  /// The run kept as [json] (`toJson`), or null when there is none or it is unreadable.
  static BackgroundRun? parse(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final Object? value = jsonDecode(json);
      if (value case {
        'at': final String at,
        'result': final String result,
        'delegated': final bool delegated,
      }) {
        final BackgroundResult? r = BackgroundResult.values.asNameMap()[result];
        if (r == null) return null;
        return BackgroundRun(
          at: const UtcInstantConverter().fromJson(at),
          result: r,
          delegated: delegated,
        );
      }
    } on FormatException {
      // Unreadable: none.
    }
    return null;
  }

  /// When it ended, UTC.
  final DateTime at;

  /// How it went.
  final BackgroundResult result;

  /// Whether the app's isolate ran it.
  final bool delegated;

  /// The JSON kept.
  String toJson() => jsonEncode({
    'at': const UtcInstantConverter().toJson(at),
    'result': result.name,
    'delegated': delegated,
  });
}

/// Records [run] in [meta]; a failure is logged by type.
Future<void> recordBackgroundRun(AppMetaStore meta, BackgroundRun run) async {
  try {
    await meta.write(AppMetaKeys.backgroundLastRun, run.toJson());
  } on Object catch (e) {
    _log.warning('the background run was not recorded: ${e.runtimeType}');
  }
}

/// The result a status gives: offline, the server's or another failure, or synced.
BackgroundResult resultOf(SyncStatus status) => switch (status.failure) {
  SyncFailure.offline => BackgroundResult.offline,
  SyncFailure.server || SyncFailure.other => BackgroundResult.failed,
  null => BackgroundResult.synced,
};

/// What a cycle runs on.
final class BackgroundEnvironment {
  const BackgroundEnvironment({
    required this.config,
    required this.overrides,
    required this.databaseFile,
    required this.wipePending,
    this.registry = const IsolateNameRegistry(),
    this.deadline = backgroundCycleDeadline,
  });

  /// The flavor.
  final AppConfig config;

  /// The container's overrides: the flavor's (`overridesFor`), or the test's.
  final List<Override> overrides;

  /// Where the database file is.
  final Future<File> Function() databaseFile;

  /// Whether a local wipe started and did not finish.
  final Future<bool> Function() wipePending;

  /// The process's port names.
  final PortRegistry registry;

  /// How long steps 3 to 7 may take.
  final Duration deadline;
}

/// Runs one cycle on [env]; true when done, false to be retried.
Future<bool> runBackgroundCycle(BackgroundEnvironment env) async {
  if (env.config.flavor == Flavor.demo) {
    _log.info('background: demo, nothing to sync');
    return true;
  }
  // The lock first, then the app: each side registers before it looks at the other's.
  final BackgroundCyclePort? lock = await acquireBackgroundCycle(
    registry: env.registry,
  );
  if (lock == null) {
    _log.info('background: another cycle runs');
    return true;
  }
  final AppAnswer answer;
  try {
    answer = await askApp(registry: env.registry);
  } on Object {
    lock.release();
    rethrow;
  }
  switch (answer) {
    case AppBusy():
      lock.release();
      _log.info('background: the app is restoring or erasing');
      return true;
    case AppSynced(:final DelegatedResult? result):
      lock.release();
      _log.info('background: the app synced (${result?.name ?? 'no answer'})');
      return result != DelegatedResult.retry;
    case NoApp():
      break;
  }
  final _Cycle cycle = _Cycle(env);
  // The lock goes when the cycle has stopped, not when the deadline returns.
  final Future<bool> running = cycle.run().whenComplete(lock.release);
  try {
    return await running.timeout(
      env.deadline,
      onTimeout: () async {
        _log.warning('background: the cycle passed its deadline');
        await cycle
            .record(BackgroundResult.timedOut)
            .timeout(const Duration(seconds: 2), onTimeout: () {});
        return true;
      },
    );
  } on Object catch (e) {
    _log.warning('background: the cycle failed: ${e.runtimeType}');
    return true;
  } finally {
    // Closed here on every path, the deadline's included: the database's own isolate
    // is not tied to this engine, so a connection left open could hold its lock after
    // the engine is gone. Closing ends the connection and rolls back what it left open.
    await cycle.close().timeout(
      closeTimeout,
      onTimeout: () => _log.warning('background: the database did not close'),
    );
  }
}

/// How long the cycle waits for its database to close.
const Duration closeTimeout = Duration(seconds: 10);

final class _Cycle {
  _Cycle(this.env);

  final BackgroundEnvironment env;
  ProviderContainer? _container;
  AppDatabase? _database;

  Future<bool> run() async {
    if (await env.wipePending()) return _skip('a wipe is pending');
    final ProviderContainer container = _container = ProviderContainer(
      overrides: env.overrides,
    );
    final TokenStore tokens = container.read(tokenStoreProvider);
    if (await tokens.read() == null) return _skip('signed out');
    final File file = await env.databaseFile();
    final String? key = await container.read(databaseKeyStoreProvider).read();
    if (!file.existsSync() || key == null) return _skip('no database');
    if (!_schemaCurrent(file, key)) return _skip('the app has not migrated');

    final AppDatabase database = container.read(databaseProvider);
    _database = database;
    await database.verifyOpen();
    // As at the app's start: the stored session read, so the controller sees who is
    // signed in; the providers listened to, so none is paused.
    await container.read(sessionControllerProvider.notifier).restored();
    final ProviderSubscription<AsyncValue<bool>> offer = container.listen(
      restoreOfferProvider,
      (_, _) {},
    );
    final bool pending = await container.read(restoreOfferProvider.future);
    offer.close();
    if (pending) {
      _log.info('background: held by the restore offer');
      await record(BackgroundResult.held);
      return true;
    }

    final ProviderSubscription<SyncStatus> status$ = container.listen(
      syncControllerProvider,
      (_, _) {},
    );
    await container.read(syncControllerProvider.notifier).firstSession();
    final SyncStatus status = status$.read();
    status$.close();
    BackgroundResult result = resultOf(status);
    if (await tokens.read() == null) {
      result = BackgroundResult.sessionEnded;
      final DateTime now = container.read(clockProvider).nowUtc();
      await container
          .read(appMetaStoreProvider)
          .write(
            AppMetaKeys.sessionEndedInBackground,
            const UtcInstantConverter().toJson(now),
          );
      await container
          .read(appNotifierProvider)
          .notify(
            SyncProblemNotification(
              problem: SyncProblem.signedOut,
              raisedAt: now,
            ),
          );
    }
    await _planReminders(container);
    for (final BackgroundCycleHook hook in container.read(
      backgroundCycleHooksProvider,
    )) {
      try {
        await hook(container);
      } on Object catch (e) {
        _log.warning('background: a step failed: ${e.runtimeType}');
      }
    }
    await record(result);
    _log.info('background: ${result.name}');
    return result != BackgroundResult.offline;
  }

  Future<bool> _skip(String why) async {
    _log.info('background: skipped, $why');
    return true;
  }

  // Whether the database is at the schema and full-text definition this build opens
  // without changing them.
  bool _schemaCurrent(File file, String hexKey) {
    final Database probe = sqlite3.open(file.path);
    try {
      databaseSetup(hexKey: hexKey, requireEncryption: true)(probe);
      final int version =
          probe.select('PRAGMA user_version').first.values.first! as int;
      if (version != AppDatabase.currentSchemaVersion) return false;
      // The full-text index as this build defines it, with every object in place: an
      // open would otherwise rebuild it, which is the app's to do.
      final ResultSet fts = probe.select(
        'SELECT value FROM app_meta WHERE key = ?',
        [ftsDefinitionKey],
      );
      if (fts.isEmpty || fts.first['value'] != '$ftsDefinitionVersion') {
        return false;
      }
      final List<String> objects = [
        ftsSourceView,
        ftsKeysTable,
        ftsTable,
        ...ftsTriggers,
      ];
      final ResultSet present = probe.select(
        'SELECT name FROM sqlite_master WHERE name IN '
        '(${List.filled(objects.length, '?').join(', ')})',
        objects,
      );
      return present.length == objects.length;
    } finally {
      probe.close();
    }
  }

  Future<void> _planReminders(ProviderContainer container) async {
    try {
      final ProviderSubscription<Future<ReminderInputs>> inputs = container
          .listen(reminderInputsProvider.future, (_, _) {});
      final ReminderInputs value = await inputs.read();
      inputs.close();
      final Clock clock = container.read(clockProvider);
      tz.Location location = clock.location;
      try {
        location = tz.getLocation(await container.read(deviceZoneProvider)());
      } on Object catch (e) {
        _log.warning('background: planning in the app zone: ${e.runtimeType}');
      }
      await container
          .read(reminderPlannerProvider)
          .plan(value, clock.nowUtc(), location);
    } on Object catch (e) {
      _log.warning('background: reminders not planned: ${e.runtimeType}');
    }
  }

  Future<void> record(BackgroundResult result) async {
    final ProviderContainer? container = _container;
    if (container == null || _database == null) return;
    await recordBackgroundRun(
      container.read(appMetaStoreProvider),
      BackgroundRun(
        at: container.read(clockProvider).nowUtc(),
        result: result,
        delegated: false,
      ),
    );
  }

  Future<void> close() async {
    final ProviderContainer? container = _container;
    if (container == null) return;
    _container = null;
    final AppDatabase? database = _database;
    container.dispose();
    if (database != null) await databaseClosing[database];
  }
}
