/// The app-wide providers: the flavor's configuration, the clock, the repositories, and the
/// overrides `bootstrap` installs for a flavor.
///
/// Feature providers live in their feature's `application/` folder; what is here is what
/// every feature may depend on. With no override, the repositories are the in-memory ones
/// over one shared [InMemoryStore] (what tests get); [overridesFor] gives dev and prod the
/// Drift repositories over the encrypted database, and the demo flavor the demo ones.
library;

import 'dart:async';

import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/db/legacy_import/import_summary.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/accounts/data/demo_account_repository.dart';
import 'package:finance_tracker/features/accounts/data/drift_account_repository.dart';
import 'package:finance_tracker/features/accounts/data/in_memory_account_repository.dart';
import 'package:finance_tracker/features/accounts/domain/account_repository.dart';
import 'package:finance_tracker/features/categories/data/demo_category_repository.dart';
import 'package:finance_tracker/features/categories/data/drift_category_repository.dart';
import 'package:finance_tracker/features/categories/data/in_memory_category_repository.dart';
import 'package:finance_tracker/features/categories/domain/category_repository.dart';
import 'package:finance_tracker/features/settings/data/demo_settings_repository.dart';
import 'package:finance_tracker/features/settings/data/drift_settings_repository.dart';
import 'package:finance_tracker/features/settings/data/in_memory_settings_repository.dart';
import 'package:finance_tracker/features/settings/domain/settings_repository.dart';
import 'package:finance_tracker/features/transactions/data/demo_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/data/drift_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/data/in_memory_transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The running flavor's configuration. There is no default: `bootstrap` (or a test)
/// overrides it through [overridesFor].
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) => throw UnimplementedError(
  'appConfigProvider is supplied by bootstrap through overridesFor(config)',
);

/// The clock every "now" and "today" comes from.
@Riverpod(keepAlive: true)
Clock clock(Ref ref) => const SystemClock();

/// Where the database key is kept: the Keystore-backed secure storage.
@Riverpod(keepAlive: true)
DatabaseKeyStore databaseKeyStore(Ref ref) => SecureDatabaseKeyStore();

/// The local database of the dev and prod flavors, opened lazily on its first query
/// (`bootstrap` opens it at startup) and closed with the container. The demo flavor has
/// none, and reading it there is a [StateError].
@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  final AppDatabase database = openAppDatabase(
    ref.watch(appConfigProvider),
    ref.watch(databaseKeyStoreProvider),
  );
  // Closing a database that failed to open rethrows the open failure, which bootstrap
  // has already handled; any other close error still surfaces.
  ref.onDispose(
    () => unawaited(
      database.close().catchError((Object _) {}, test: isDatabaseOpenFailure),
    ),
  );
  return database;
}

/// The state behind the in-memory and demo repositories: empty by default; the demo
/// flavor's holds the system categories and the demo seed.
@Riverpod(keepAlive: true)
InMemoryStore inMemoryStore(Ref ref) {
  final InMemoryStore store = InMemoryStore(ref.watch(clockProvider));
  ref.onDispose(store.close);
  return store;
}

/// The accounts.
@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) =>
    InMemoryAccountRepository(ref.watch(inMemoryStoreProvider));

/// The transactions.
@Riverpod(keepAlive: true)
TransactionRepository transactionRepository(Ref ref) =>
    InMemoryTransactionRepository(ref.watch(inMemoryStoreProvider));

/// The categories.
@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(Ref ref) =>
    InMemoryCategoryRepository(ref.watch(inMemoryStoreProvider));

/// Where the app preferences are kept.
@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  final InMemorySettingsRepository repository = InMemorySettingsRepository();
  ref.onDispose(repository.close);
  return repository;
}

/// What the legacy importer did at this launch (`bootstrap`), or null when it did nothing;
/// Phase 1d shows it once.
@Riverpod(keepAlive: true)
class LegacyImportResult extends _$LegacyImportResult {
  @override
  ImportSummary? build() => null;

  /// Records the importer's [summary].
  void record(ImportSummary? summary) => state = summary;
}

/// The provider overrides that make up the app for [config].
List<Override> overridesFor(AppConfig config) => [
  appConfigProvider.overrideWithValue(config),
  ...switch (config.flavor) {
    Flavor.dev || Flavor.prod => _driftOverrides,
    Flavor.demo => _demoOverrides,
  },
];

/// dev and prod: the Drift repositories over the encrypted database.
final List<Override> _driftOverrides = [
  accountRepositoryProvider.overrideWith(
    (ref) => DriftAccountRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
    ),
  ),
  transactionRepositoryProvider.overrideWith(
    (ref) => DriftTransactionRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
    ),
  ),
  categoryRepositoryProvider.overrideWith(
    (ref) => DriftCategoryRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
    ),
  ),
  settingsRepositoryProvider.overrideWith(
    (ref) => DriftSettingsRepository(ref.watch(databaseProvider)),
  ),
];

/// The demo flavor: everything in memory, from the demo seed dated to the clock's today.
final List<Override> _demoOverrides = [
  databaseProvider.overrideWith(
    (ref) => throw StateError('The demo flavor has no database'),
  ),
  inMemoryStoreProvider.overrideWith((ref) {
    final Clock clock = ref.watch(clockProvider);
    final InMemoryStore store = InMemoryStore(clock)..seedSystemCategories();
    loadDemoSeed(store, buildDemoSeed(clock.today()));
    ref.onDispose(store.close);
    return store;
  }),
  accountRepositoryProvider.overrideWith(
    (ref) => DemoAccountRepository(ref.watch(inMemoryStoreProvider)),
  ),
  transactionRepositoryProvider.overrideWith(
    (ref) => DemoTransactionRepository(ref.watch(inMemoryStoreProvider)),
  ),
  categoryRepositoryProvider.overrideWith(
    (ref) => DemoCategoryRepository(ref.watch(inMemoryStoreProvider)),
  ),
  settingsRepositoryProvider.overrideWith((ref) {
    final DemoSettingsRepository repository = DemoSettingsRepository();
    ref.onDispose(repository.close);
    return repository;
  }),
];
