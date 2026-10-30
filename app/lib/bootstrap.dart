/// Startup shared by the three entry points: [bootstrap] checks the configuration and
/// sets up logging, time zones and the locale once, then [startApp] opens the local data
/// (dev and prod), reads the stored session and the lock's settings (locking the app and
/// securing its window before the first frame when they say so), starts sync and the
/// budget alerts, and runs the app on a new Riverpod container; after the first frame,
/// the bill reminders are planned (a tapped one opens its bill), and dev and prod sweep
/// the receipt files no transaction references. [startApp] can run again in the same
/// process, on a new container: a restore (`features/backup/`) stops the app, replaces
/// its database on a plain screen showing its progress, and starts it again through the
/// app restart [startApp] supplies (`appRestartProvider`); the local wipe
/// (`core/db/local_wipe.dart`, `wipeLocalDataProvider`) stops it the same way, wipes,
/// confirms on a plain screen and starts it again on the fresh install; a wipe cut short
/// is finished the same way before [startApp] opens anything local.
library;

import 'dart:async';

import 'package:finance_tracker/app.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/legacy_import/import_summary.dart';
import 'package:finance_tracker/core/db/legacy_import/legacy_importer.dart';
import 'package:finance_tracker/core/db/local_wipe.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/logging/app_log.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler_provider.dart';
import 'package:finance_tracker/core/router/app_router.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/time/time_zone_setup.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/auth/presentation/erasing_app.dart';
import 'package:finance_tracker/features/backup/application/backup_providers.dart';
import 'package:finance_tracker/features/backup/application/backup_service.dart';
import 'package:finance_tracker/features/backup/presentation/backup_messages.dart';
import 'package:finance_tracker/features/backup/presentation/restore_flow.dart';
import 'package:finance_tracker/features/backup/presentation/restoring_app.dart';
import 'package:finance_tracker/features/bills/application/reminder_planner.dart';
import 'package:finance_tracker/features/budgets/application/budgets_providers.dart';
import 'package:finance_tracker/features/lock/application/lock_controller.dart';
import 'package:finance_tracker/features/net_worth/application/snapshot_writer.dart';
import 'package:finance_tracker/features/recurring/application/detector_runner.dart';
import 'package:finance_tracker/features/reports/application/weekly_summary_providers.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Logger _log = Logger('app');

// The running app's container and its reminder taps, which a restart stops.
ProviderContainer? _running;
StreamSubscription<String>? _reminderTaps;

/// Starts the app for [config] ([startApp]) after the process's one-time setup. Throws a
/// [StateError] before anything runs when the prod flavor is given a server URL that is
/// not HTTPS.
Future<void> bootstrap(AppConfig config) async {
  final Uri? serverBaseUrl = config.serverBaseUrl;
  if (config.flavor == Flavor.prod &&
      serverBaseUrl != null &&
      serverBaseUrl.scheme != 'https') {
    throw StateError(
      'The prod flavor needs an https server URL, got $serverBaseUrl',
    );
  }
  WidgetsFlutterBinding.ensureInitialized();
  setUpLogging(config.flavor);
  forwardUncaughtErrors();
  await setUpTimeZones();
  // intl's default locale is en_US until set; Money.format and Money.parse use it. Its
  // date symbols are loaded for every locale, since a device's need not be English.
  Intl.defaultLocale = deviceLocale();
  await initializeDateFormatting();
  await startApp(config);
}

/// Runs the app for [config] on a new container over [overrides] (the flavor's,
/// [overridesFor], unless a test supplies its own), after [bootstrap]'s one-time setup.
/// When the local data cannot be opened, for whatever reason, logs the failure's type
/// and shows [DatabaseErrorApp] instead of the app.
Future<void> startApp(AppConfig config, {List<Override>? overrides}) async {
  final List<Override> base = overrides ?? overridesFor(config);
  final Override restart = appRestartProvider.overrideWithValue(
    (work) => _restart(config, overrides, work),
  );
  late final ProviderContainer container;
  final Override wipe = wipeLocalDataProvider.overrideWithValue(
    (reason) =>
        _wipe(config, overrides, container.read(localWipeProvider), reason),
  );
  container = ProviderContainer(overrides: [...base, restart, wipe]);
  // A wipe cut short (the process killed part way) is finished before anything local
  // opens, so the app never starts on what is left of it.
  final LocalWipe localWipe = container.read(localWipeProvider);
  final WipeReason? pending = await _pendingWipe(localWipe);
  if (pending != null) {
    container.dispose();
    await _wipe(config, overrides, localWipe, pending, resumed: true);
    return;
  }
  if (config.flavor != Flavor.demo) {
    try {
      await openLocalData(container, locale: Intl.getCurrentLocale());
    } catch (e) {
      // Any failure here (a lost or wrong key, a damaged file, a schema this build cannot
      // migrate) would otherwise crash every launch. Only the type is logged. The
      // container is left open: closing a database whose open failed rethrows the
      // failure, and the process now only shows the error screen.
      _log.severe('the local database did not open: ${e.runtimeType}');
      runApp(
        ProviderScope(
          overrides: [...base, restart, wipe],
          child: DatabaseErrorApp(failure: databaseFailureOf(e)),
        ),
      );
      return;
    }
  }
  _running = container;
  // The stored session, read before the first frame so the router never shows the
  // sign-in screen to a signed-in user; GET /me confirms it in the background.
  await container.read(sessionControllerProvider.notifier).restored();
  // The lock's settings, read before the first frame: a locked app never shows its content,
  // and a secure window is secure before anything is drawn in it.
  await container.read(lockControllerProvider.notifier).restored();
  // Sync starts with the app: it runs a session when someone is signed in (never in demo).
  container.read(syncControllerProvider);
  // The budget alerts are evaluated whenever the statuses change, in every flavor.
  container.listen(budgetAlertWatcherProvider, (_, _) {});
  // The detected recurring streams follow the transactions, in every flavor.
  container.listen(detectorRunnerProvider, (_, _) {});
  // The weekly summary's notice is raised once a week, in every flavor.
  container.listen(weeklySummaryNoticeProvider, (_, _) {});
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FinanceTrackerApp(),
    ),
  );
  // The bill reminders are planned from the first frame on, in every flavor, and again
  // whenever their inputs, a sync or the device's zone change (reminder_planner.dart);
  // a tapped reminder opens its bill.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    container.listen(reminderWatcherProvider, (_, _) {});
    // Today's balance snapshots, from the first frame on and after every pull and sync
    // session, in every flavor (snapshot_writer.dart).
    container.listen(snapshotWriterRunnerProvider, (_, _) {});
    _reminderTaps = container
        .read(reminderSchedulerProvider)
        .openedBillIds
        .listen(
          (id) => unawaited(
            container
                .read(goRouterProvider)
                .push<void>(EditBillRoute(id).location),
          ),
        );
  });
  if (config.flavor != Flavor.demo) {
    // Once per launch, off the first frame: the photos attached before receipt hashes
    // existed get theirs (`TransactionActions.fillReceiptHashes`), then a delete that
    // became final while the app was not watching (`TransactionActions.sweepReceipts`)
    // leaves its photo behind.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(
        fillReceiptHashes(container).then((_) => sweepReceipts(container)),
      ),
    );
  }
}

// The app restart a restore runs under: the restoring screen, the running app stopped,
// [work] with its progress shown, then the app started again on [config] and
// [overrides]; a failure of [work] is shown, by type in the log, until the user goes on.
Future<void> _restart(
  AppConfig config,
  List<Override>? overrides,
  Future<void> Function(ProgressReport report) work,
) async {
  final ValueNotifier<RestoringState> state = ValueNotifier(
    const RestoringState(),
  );
  runApp(ProviderScope(child: RestoringApp(state: state)));
  await WidgetsBinding.instance.endOfFrame;
  await stopApp();
  final ProgressThrottle throttle = ProgressThrottle();
  try {
    await work((progress) {
      if (throttle.admit(progress)) {
        state.value = RestoringState(progress: progress);
      }
    });
  } on Object catch (e) {
    _log.severe('the restore failed: ${e.runtimeType}');
    final Completer<void> resume = Completer<void>();
    state.value = RestoringState(failure: e, onContinue: completeOnce(resume));
    await resume.future;
  }
  await startApp(config, overrides: overrides);
}

// The local wipe: the erasing screen, the running app stopped (none when it finishes a
// pending wipe at startup, [resumed]), [wipe] run until it succeeds (each failure shown,
// by type in the log, until the user tries again; a repeated one, the second in a row
// or any of a resumed wipe, also points at Android's storage settings), the confirmation
// for [reason], then, on Done, the app started again on [config] and [overrides], on the
// fresh install.
Future<void> _wipe(
  AppConfig config,
  List<Override>? overrides,
  LocalWipe wipe,
  WipeReason reason, {
  bool resumed = false,
}) async {
  final ValueNotifier<ErasingState> state = ValueNotifier(const Erasing());
  runApp(
    ProviderScope(
      child: ErasingApp(state: state, reason: reason),
    ),
  );
  await WidgetsBinding.instance.endOfFrame;
  await stopApp();
  int failures = 0;
  while (true) {
    try {
      await wipe.wipe(reason);
      break;
    } on Object catch (e) {
      _log.severe('the local wipe failed: ${e.runtimeType}');
      failures++;
      final Completer<void> retry = Completer<void>();
      state.value = EraseFailed(
        () => _completeOnce(retry),
        repeated: resumed || failures > 1,
      );
      await retry.future;
      state.value = const Erasing();
    }
  }
  final Completer<void> done = Completer<void>();
  state.value = Erased(() => _completeOnce(done));
  await done.future;
  await startApp(config, overrides: overrides);
}

// A second tap lands before the state moves on: only the first counts.
void _completeOnce(Completer<void> completer) {
  if (!completer.isCompleted) completer.complete();
}

// The reason of a wipe cut short, or null; a record that cannot be read is logged by
// type and taken as none, so a broken preference store cannot keep the app from starting.
Future<WipeReason?> _pendingWipe(LocalWipe wipe) async {
  try {
    return await wipe.pending();
  } on Object catch (e) {
    _log.warning('the pending wipe could not be read: ${e.runtimeType}');
    return null;
  }
}

/// Stops the running app: its reminder taps, its container (sync, the watchers), and its
/// database, closed before this completes. Nothing happens when no app runs.
@visibleForTesting
Future<void> stopApp() async {
  final ProviderContainer? container = _running;
  _running = null;
  await _reminderTaps?.cancel();
  _reminderTaps = null;
  if (container == null) return;
  final AppDatabase? database =
      container.read(appConfigProvider).flavor == Flavor.demo
      ? null
      : container.read(databaseProvider);
  container.dispose();
  // The close the container started (one close only: two at once race in Drift),
  // awaited so the files can go.
  if (database != null) await databaseClosing[database];
}

/// Gives the receipt photos on this device that have no hash theirs, recorded, so they
/// upload and sync (`TransactionActions.fillReceiptHashes`). A failure is logged by type
/// only; the next launch tries again.
Future<void> fillReceiptHashes(ProviderContainer container) async {
  try {
    final int filled = await container
        .read(transactionActionsProvider)
        .fillReceiptHashes();
    if (filled > 0) _log.info('hashed $filled receipt photos');
  } on Object catch (e) {
    _log.warning('hashing the receipt photos failed: ${e.runtimeType}');
  }
}

/// Deletes the receipt files no live transaction in [container] references. A failure
/// is logged by type only; the next launch sweeps again.
Future<void> sweepReceipts(ProviderContainer container) async {
  try {
    final int deleted = await container
        .read(transactionActionsProvider)
        .sweepReceipts();
    if (deleted > 0) _log.info('swept $deleted receipt files');
  } on Object catch (e) {
    _log.warning('the receipt sweep failed: ${e.runtimeType}');
  }
}

/// The device's locale as an intl locale intl has data for (en_US when it has none).
String deviceLocale() => Intl.verifiedLocale(
  Intl.canonicalizedLocale(
    WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag(),
  ),
  NumberFormat.localeExists,
  onFailure: (_) => 'en_US',
)!;

/// Opens the dev and prod flavors' database in [container] and prepares it: the open
/// sequence runs (and throws its exceptions) here rather than under the first screen, the
/// held records of every type this build knows are released, the sync conflicts thirty
/// days old are swept, the install date is recorded
/// on the first launch, the system categories are seeded, and the original app's data is
/// imported once (in the currency of [locale]), its summary left in
/// `legacyImportResultProvider`. A failed release or import is logged, not thrown.
Future<void> openLocalData(
  ProviderContainer container, {
  required String locale,
  Future<SharedPreferences> Function() preferences =
      SharedPreferences.getInstance,
}) async {
  final AppDatabase database = container.read(databaseProvider);
  await database.verifyOpen();
  try {
    await releaseKnownHeldRecords(container.read(driftSyncStoreProvider));
  } on Object catch (e) {
    // A held record that cannot be read or written must not keep the app from starting:
    // its type's records stay held, and the next launch tries again.
    _log.warning('releasing the held records failed: ${e.runtimeType}');
  }
  try {
    await container.read(driftSyncStoreProvider).sweepConflicts();
  } on Object catch (e) {
    // Old conflicts linger until the next launch; they never keep the app from starting.
    _log.warning('sweeping the sync conflicts failed: ${e.runtimeType}');
  }
  final DriftAppMetaStore meta = DriftAppMetaStore(database);
  if (await meta.read(AppMetaKeys.installDate) == null) {
    await meta.write(
      AppMetaKeys.installDate,
      container.read(clockProvider).today().toIso(),
    );
  }
  await container.read(categoryRepositoryProvider).ensureSeeded();
  ImportSummary? imported;
  try {
    imported = await LegacyImporter(
      preferences: await preferences(),
      accounts: container.read(accountRepositoryProvider),
      transactions: container.read(transactionRepositoryProvider),
      meta: meta,
      clock: container.read(clockProvider),
      locale: locale,
    ).runIfNeeded();
  } on Exception catch (e) {
    // A failed import must not keep the app from starting; not having recorded
    // legacy_import_done, it runs again at the next launch.
    _log.severe('the legacy import failed: ${e.runtimeType}');
  }
  container.read(legacyImportResultProvider.notifier).record(imported);
}

/// Why the local data did not open, as [DatabaseErrorApp] explains it.
enum DatabaseFailure { encryptionUnavailable, keyMismatch, keyLost, other }

/// The [DatabaseFailure] that [error] is: one of the three open failures of
/// `database_exceptions.dart`, or [DatabaseFailure.other].
DatabaseFailure databaseFailureOf(Object error) => switch (error) {
  EncryptionUnavailableException() => DatabaseFailure.encryptionUnavailable,
  DatabaseKeyMismatchException() => DatabaseFailure.keyMismatch,
  DatabaseKeyLostException() => DatabaseFailure.keyLost,
  _ => DatabaseFailure.other,
};

/// What the app shows when its local data cannot be opened: a plain screen, not a crash
/// loop, saying why when the cause is the key or encryption; for a lost key, with
/// "Restore from a backup" beside the message (`features/backup/`).
class DatabaseErrorApp extends StatelessWidget {
  const DatabaseErrorApp({required this.failure, super.key});

  /// Why the data did not open.
  final DatabaseFailure failure;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: _DatabaseErrorScreen(failure),
  );
}

class _DatabaseErrorScreen extends StatelessWidget {
  const _DatabaseErrorScreen(this.failure);

  final DatabaseFailure failure;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.databaseErrorTitle,
                  style: text.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  switch (failure) {
                    DatabaseFailure.encryptionUnavailable =>
                      l10n.databaseErrorNoEncryption,
                    DatabaseFailure.keyMismatch =>
                      l10n.databaseErrorKeyMismatch,
                    DatabaseFailure.keyLost => l10n.databaseErrorKeyLost,
                    DatabaseFailure.other => l10n.databaseErrorBody,
                  },
                  style: text.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (failure == DatabaseFailure.keyLost) ...[
                  const SizedBox(height: 24),
                  const RestoreFlow(entry: RestoreEntry.keyLost),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
