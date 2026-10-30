/// Startup shared by the three entry points: [bootstrap] checks the configuration and
/// sets up logging, time zones and the locale once, then [startApp] opens the local data
/// (dev and prod), reads the stored session, starts sync and the budget alerts, and runs
/// the app on a new Riverpod container; after the first frame, the bill reminders are
/// planned (a tapped one opens its bill), and dev and prod sweep the receipt files no
/// transaction references. [startApp] can run again in the same process, on a new
/// container.
library;

import 'dart:async';

import 'package:finance_tracker/app.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/legacy_import/import_summary.dart';
import 'package:finance_tracker/core/db/legacy_import/legacy_importer.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/logging/app_log.dart';
import 'package:finance_tracker/core/platform/reminder_scheduler_provider.dart';
import 'package:finance_tracker/core/router/app_router.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/sync/sync_controller.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/time/time_zone_setup.dart';
import 'package:finance_tracker/features/auth/application/session_controller.dart';
import 'package:finance_tracker/features/bills/application/reminder_planner.dart';
import 'package:finance_tracker/features/budgets/application/budgets_providers.dart';
import 'package:finance_tracker/features/net_worth/application/snapshot_writer.dart';
import 'package:finance_tracker/features/recurring/application/detector_runner.dart';
import 'package:finance_tracker/features/reports/application/weekly_summary_providers.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Logger _log = Logger('app');

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
  // intl's default locale is en_US until set; Money.format and Money.parse use it.
  Intl.defaultLocale = deviceLocale();
  await startApp(config);
}

/// Runs the app for [config] on a new container over [overrides] (the flavor's,
/// [overridesFor], unless a test supplies its own), after [bootstrap]'s one-time setup.
/// When the local data cannot be opened, for whatever reason, logs the failure's type
/// and shows [DatabaseErrorApp] instead of the app.
Future<void> startApp(AppConfig config, {List<Override>? overrides}) async {
  final ProviderContainer container = ProviderContainer(
    overrides: overrides ?? overridesFor(config),
  );
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
        ProviderScope(child: DatabaseErrorApp(failure: databaseFailureOf(e))),
      );
      return;
    }
  }
  // The stored session, read before the first frame so the router never shows the
  // sign-in screen to a signed-in user; GET /me confirms it in the background.
  await container.read(sessionControllerProvider.notifier).restored();
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
    container
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
    // Once per launch, off the first frame: a delete that became final while the app
    // was not watching (`TransactionActions.sweepReceipts`) leaves its photo behind.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(sweepReceipts(container)),
    );
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
/// held records of every type this build knows are released, the install date is recorded
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
/// loop, saying why when the cause is the key or encryption. Phase 7's restore flow
/// replaces it for a lost key.
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
