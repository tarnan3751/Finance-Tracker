/// The app-wide providers: the flavor's configuration, the clock, the repositories, and the
/// overrides `bootstrap` installs for a flavor.
///
/// Feature providers live in their feature's `application/` folder; what is here is what
/// every feature may depend on. With no override, the repositories are the in-memory ones
/// over one shared [InMemoryStore] (what tests get), recording into an in-memory sync
/// store; [overridesFor] gives dev and prod the Drift repositories over the encrypted
/// database, recording into the Drift sync store, and the demo flavor the demo ones,
/// which record nothing.
library;

import 'dart:async';

import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/config/app_config.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/database_key_store.dart';
import 'package:finance_tracker/core/db/demo_seed.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/db/legacy_import/import_summary.dart';
import 'package:finance_tracker/core/db/open_database.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/sync/device_clock.dart';
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
import 'package:sync_engine/sync_engine.dart';

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

/// The sync store the in-memory repositories record into (tests read its outbox).
@Riverpod(keepAlive: true)
InMemorySyncStore inMemorySyncStore(Ref ref) => InMemorySyncStore();

/// The sync store over the local database of the dev and prod flavors.
@Riverpod(keepAlive: true)
DriftSyncStore driftSyncStore(Ref ref) =>
    DriftSyncStore(ref.watch(databaseProvider), ref.watch(clockProvider));

/// The device's sync clock and node, over [driftSyncStore]: one instance for every
/// local edit and every sync session.
@Riverpod(keepAlive: true)
DeviceClock deviceClock(Ref ref) =>
    DeviceClock(ref.watch(driftSyncStoreProvider));

/// Where the repositories record user-authored writes for sync: by default into
/// [inMemorySyncStore] on a fixed node; [overridesFor] gives dev and prod the Drift store
/// and the device clock, and the demo flavor no recording.
@Riverpod(keepAlive: true)
ChangeRecorder changeRecorder(Ref ref) {
  final Clock clock = ref.watch(clockProvider);
  final HlcClock hlc = HlcClock('local-memory');
  return EngineChangeRecorder(
    ref.watch(inMemorySyncStoreProvider),
    () async => hlc,
    () => clock.nowUtc().millisecondsSinceEpoch,
  );
}

/// The server's id for this device while someone is signed in, else null: the node the
/// device's sync clock adopts. Null until the session is wired to it.
@Riverpod(keepAlive: true)
String? syncDeviceId(Ref ref) => null;

/// The relay the device syncs through while someone is signed in, else null. Null until
/// the API layer is wired to it.
@Riverpod(keepAlive: true)
SyncRelay? syncRelay(Ref ref) => null;

/// How long after the last local change a sync session starts.
@Riverpod(keepAlive: true)
Duration syncDebounce(Ref ref) => const Duration(seconds: 3);

/// The accounts.
@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) => InMemoryAccountRepository(
  ref.watch(inMemoryStoreProvider),
  recorder: ref.watch(changeRecorderProvider),
);

/// The transactions.
@Riverpod(keepAlive: true)
TransactionRepository transactionRepository(Ref ref) =>
    InMemoryTransactionRepository(
      ref.watch(inMemoryStoreProvider),
      recorder: ref.watch(changeRecorderProvider),
    );

/// The categories.
@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(Ref ref) => InMemoryCategoryRepository(
  ref.watch(inMemoryStoreProvider),
  recorder: ref.watch(changeRecorderProvider),
);

/// Where the app preferences are kept.
@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  final InMemorySettingsRepository repository = InMemorySettingsRepository(
    recorder: ref.watch(changeRecorderProvider),
  );
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
  ...apiOverridesFor(config),
];

/// dev and prod: the Drift repositories over the encrypted database, recording into the
/// Drift sync store with the device clock.
final List<Override> _driftOverrides = [
  changeRecorderProvider.overrideWith((ref) {
    final Clock clock = ref.watch(clockProvider);
    return EngineChangeRecorder(
      ref.watch(driftSyncStoreProvider),
      ref.watch(deviceClockProvider).current,
      () => clock.nowUtc().millisecondsSinceEpoch,
    );
  }),
  accountRepositoryProvider.overrideWith(
    (ref) => DriftAccountRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
      recorder: ref.watch(changeRecorderProvider),
    ),
  ),
  transactionRepositoryProvider.overrideWith(
    (ref) => DriftTransactionRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
      recorder: ref.watch(changeRecorderProvider),
    ),
  ),
  categoryRepositoryProvider.overrideWith(
    (ref) => DriftCategoryRepository(
      ref.watch(databaseProvider),
      ref.watch(clockProvider),
      recorder: ref.watch(changeRecorderProvider),
    ),
  ),
  settingsRepositoryProvider.overrideWith(
    (ref) => DriftSettingsRepository(
      ref.watch(databaseProvider),
      recorder: ref.watch(changeRecorderProvider),
    ),
  ),
];

/// The demo flavor: everything in memory, from the demo seed dated to the clock's today.
final List<Override> _demoOverrides = [
  databaseProvider.overrideWith(
    (ref) => throw StateError('The demo flavor has no database'),
  ),
  changeRecorderProvider.overrideWithValue(const NoChangeRecorder()),
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
