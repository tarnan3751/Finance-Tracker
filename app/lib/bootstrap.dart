/// Startup shared by the three entry points: checks the configuration, sets up logging,
/// time zones and the locale, opens the local data (dev and prod), then runs the app on
/// its Riverpod container.
library;

import 'package:finance_tracker/app.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/app_meta_store.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/logging/app_log.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/time/time_zone_setup.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

final Logger _log = Logger('app');

/// Starts the app for [config]. Throws a [StateError] before anything runs when the prod
/// flavor is given a server URL that is not HTTPS. When the local data cannot be opened,
/// for whatever reason, logs the failure's type and shows [DatabaseErrorApp] instead of
/// the app.
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

  final ProviderContainer container = ProviderContainer(
    overrides: overridesFor(config),
  );
  if (config.flavor != Flavor.demo) {
    try {
      await openLocalData(container);
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
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FinanceTrackerApp(),
    ),
  );
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
/// install date is recorded on the first launch, and the system categories are seeded.
Future<void> openLocalData(ProviderContainer container) async {
  final AppDatabase database = container.read(databaseProvider);
  await database.verifyOpen();
  final DriftAppMetaStore meta = DriftAppMetaStore(database);
  if (await meta.read(AppMetaKeys.installDate) == null) {
    await meta.write(
      AppMetaKeys.installDate,
      container.read(clockProvider).today().toIso(),
    );
  }
  await container.read(categoryRepositoryProvider).ensureSeeded();
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
