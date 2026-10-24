// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The running flavor's configuration. There is no default: `bootstrap` (or a test)
/// overrides it through [overridesFor].

@ProviderFor(appConfig)
final appConfigProvider = AppConfigProvider._();

/// The running flavor's configuration. There is no default: `bootstrap` (or a test)
/// overrides it through [overridesFor].

final class AppConfigProvider
    extends $FunctionalProvider<AppConfig, AppConfig, AppConfig>
    with $Provider<AppConfig> {
  /// The running flavor's configuration. There is no default: `bootstrap` (or a test)
  /// overrides it through [overridesFor].
  AppConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appConfigHash();

  @$internal
  @override
  $ProviderElement<AppConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppConfig create(Ref ref) {
    return appConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppConfig>(value),
    );
  }
}

String _$appConfigHash() => r'f6e2db0dd982be39b829e68a29abacfe8aaa0b48';

/// The clock every "now" and "today" comes from.

@ProviderFor(clock)
final clockProvider = ClockProvider._();

/// The clock every "now" and "today" comes from.

final class ClockProvider extends $FunctionalProvider<Clock, Clock, Clock>
    with $Provider<Clock> {
  /// The clock every "now" and "today" comes from.
  ClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockHash();

  @$internal
  @override
  $ProviderElement<Clock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Clock create(Ref ref) {
    return clock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Clock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Clock>(value),
    );
  }
}

String _$clockHash() => r'55214d6539f7396a3ae1aa23b06eea79fdac0ebe';

/// Where the database key is kept: the Keystore-backed secure storage.

@ProviderFor(databaseKeyStore)
final databaseKeyStoreProvider = DatabaseKeyStoreProvider._();

/// Where the database key is kept: the Keystore-backed secure storage.

final class DatabaseKeyStoreProvider
    extends
        $FunctionalProvider<
          DatabaseKeyStore,
          DatabaseKeyStore,
          DatabaseKeyStore
        >
    with $Provider<DatabaseKeyStore> {
  /// Where the database key is kept: the Keystore-backed secure storage.
  DatabaseKeyStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseKeyStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseKeyStoreHash();

  @$internal
  @override
  $ProviderElement<DatabaseKeyStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DatabaseKeyStore create(Ref ref) {
    return databaseKeyStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DatabaseKeyStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DatabaseKeyStore>(value),
    );
  }
}

String _$databaseKeyStoreHash() => r'6730b51f8d1f9e9580c0cb1074cf2a0271840203';

/// The local database of the dev and prod flavors, opened lazily on its first query
/// (`bootstrap` opens it at startup) and closed with the container. The demo flavor has
/// none, and reading it there is a [StateError].

@ProviderFor(database)
final databaseProvider = DatabaseProvider._();

/// The local database of the dev and prod flavors, opened lazily on its first query
/// (`bootstrap` opens it at startup) and closed with the container. The demo flavor has
/// none, and reading it there is a [StateError].

final class DatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// The local database of the dev and prod flavors, opened lazily on its first query
  /// (`bootstrap` opens it at startup) and closed with the container. The demo flavor has
  /// none, and reading it there is a [StateError].
  DatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return database(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$databaseHash() => r'56a4e6e4b2bac9c19896f3c9420d5aec318ac5bf';

/// The state behind the in-memory and demo repositories: empty by default; the demo
/// flavor's holds the system categories and the demo seed.

@ProviderFor(inMemoryStore)
final inMemoryStoreProvider = InMemoryStoreProvider._();

/// The state behind the in-memory and demo repositories: empty by default; the demo
/// flavor's holds the system categories and the demo seed.

final class InMemoryStoreProvider
    extends $FunctionalProvider<InMemoryStore, InMemoryStore, InMemoryStore>
    with $Provider<InMemoryStore> {
  /// The state behind the in-memory and demo repositories: empty by default; the demo
  /// flavor's holds the system categories and the demo seed.
  InMemoryStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inMemoryStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inMemoryStoreHash();

  @$internal
  @override
  $ProviderElement<InMemoryStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  InMemoryStore create(Ref ref) {
    return inMemoryStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InMemoryStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InMemoryStore>(value),
    );
  }
}

String _$inMemoryStoreHash() => r'3eec0edbaefb6e758cd7a7b12574470341f1dfe1';

/// The sync store the in-memory repositories record into (tests read its outbox).

@ProviderFor(inMemorySyncStore)
final inMemorySyncStoreProvider = InMemorySyncStoreProvider._();

/// The sync store the in-memory repositories record into (tests read its outbox).

final class InMemorySyncStoreProvider
    extends
        $FunctionalProvider<
          InMemorySyncStore,
          InMemorySyncStore,
          InMemorySyncStore
        >
    with $Provider<InMemorySyncStore> {
  /// The sync store the in-memory repositories record into (tests read its outbox).
  InMemorySyncStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inMemorySyncStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inMemorySyncStoreHash();

  @$internal
  @override
  $ProviderElement<InMemorySyncStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InMemorySyncStore create(Ref ref) {
    return inMemorySyncStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InMemorySyncStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InMemorySyncStore>(value),
    );
  }
}

String _$inMemorySyncStoreHash() => r'1b39734cbcb143ff067a5742ecdaeb93186ea354';

/// The sync store over the local database of the dev and prod flavors.

@ProviderFor(driftSyncStore)
final driftSyncStoreProvider = DriftSyncStoreProvider._();

/// The sync store over the local database of the dev and prod flavors.

final class DriftSyncStoreProvider
    extends $FunctionalProvider<DriftSyncStore, DriftSyncStore, DriftSyncStore>
    with $Provider<DriftSyncStore> {
  /// The sync store over the local database of the dev and prod flavors.
  DriftSyncStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'driftSyncStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$driftSyncStoreHash();

  @$internal
  @override
  $ProviderElement<DriftSyncStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DriftSyncStore create(Ref ref) {
    return driftSyncStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DriftSyncStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DriftSyncStore>(value),
    );
  }
}

String _$driftSyncStoreHash() => r'7f6b030bf5b3eafe4fd8dfcebc65299de8fa4acc';

/// The device's sync clock and node, over [driftSyncStore]: one instance for every
/// local edit and every sync session.

@ProviderFor(deviceClock)
final deviceClockProvider = DeviceClockProvider._();

/// The device's sync clock and node, over [driftSyncStore]: one instance for every
/// local edit and every sync session.

final class DeviceClockProvider
    extends $FunctionalProvider<DeviceClock, DeviceClock, DeviceClock>
    with $Provider<DeviceClock> {
  /// The device's sync clock and node, over [driftSyncStore]: one instance for every
  /// local edit and every sync session.
  DeviceClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceClockHash();

  @$internal
  @override
  $ProviderElement<DeviceClock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeviceClock create(Ref ref) {
    return deviceClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceClock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceClock>(value),
    );
  }
}

String _$deviceClockHash() => r'b5657fd7141a93eed72a85a8598bd8e034e030bd';

/// Where the repositories record user-authored writes for sync: by default into
/// [inMemorySyncStore] on a fixed node; [overridesFor] gives dev and prod the Drift store
/// and the device clock, and the demo flavor no recording.

@ProviderFor(changeRecorder)
final changeRecorderProvider = ChangeRecorderProvider._();

/// Where the repositories record user-authored writes for sync: by default into
/// [inMemorySyncStore] on a fixed node; [overridesFor] gives dev and prod the Drift store
/// and the device clock, and the demo flavor no recording.

final class ChangeRecorderProvider
    extends $FunctionalProvider<ChangeRecorder, ChangeRecorder, ChangeRecorder>
    with $Provider<ChangeRecorder> {
  /// Where the repositories record user-authored writes for sync: by default into
  /// [inMemorySyncStore] on a fixed node; [overridesFor] gives dev and prod the Drift store
  /// and the device clock, and the demo flavor no recording.
  ChangeRecorderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'changeRecorderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$changeRecorderHash();

  @$internal
  @override
  $ProviderElement<ChangeRecorder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChangeRecorder create(Ref ref) {
    return changeRecorder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChangeRecorder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChangeRecorder>(value),
    );
  }
}

String _$changeRecorderHash() => r'12d25ee7e97c97cffb45f8dff0debccf12ae5c12';

/// The accounts.

@ProviderFor(accountRepository)
final accountRepositoryProvider = AccountRepositoryProvider._();

/// The accounts.

final class AccountRepositoryProvider
    extends
        $FunctionalProvider<
          AccountRepository,
          AccountRepository,
          AccountRepository
        >
    with $Provider<AccountRepository> {
  /// The accounts.
  AccountRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountRepositoryHash();

  @$internal
  @override
  $ProviderElement<AccountRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccountRepository create(Ref ref) {
    return accountRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountRepository>(value),
    );
  }
}

String _$accountRepositoryHash() => r'2357629cfb29e8e8e503c6cfe9f9697c594663ff';

/// The transactions.

@ProviderFor(transactionRepository)
final transactionRepositoryProvider = TransactionRepositoryProvider._();

/// The transactions.

final class TransactionRepositoryProvider
    extends
        $FunctionalProvider<
          TransactionRepository,
          TransactionRepository,
          TransactionRepository
        >
    with $Provider<TransactionRepository> {
  /// The transactions.
  TransactionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionRepositoryHash();

  @$internal
  @override
  $ProviderElement<TransactionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TransactionRepository create(Ref ref) {
    return transactionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionRepository>(value),
    );
  }
}

String _$transactionRepositoryHash() =>
    r'386f58ca703d12e5483e3591c708326d7172bb44';

/// The categories.

@ProviderFor(categoryRepository)
final categoryRepositoryProvider = CategoryRepositoryProvider._();

/// The categories.

final class CategoryRepositoryProvider
    extends
        $FunctionalProvider<
          CategoryRepository,
          CategoryRepository,
          CategoryRepository
        >
    with $Provider<CategoryRepository> {
  /// The categories.
  CategoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<CategoryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CategoryRepository create(Ref ref) {
    return categoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryRepository>(value),
    );
  }
}

String _$categoryRepositoryHash() =>
    r'560f8096426c9864d0d1c462c9a9c2b4c5940c37';

/// Where the app preferences are kept.

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

/// Where the app preferences are kept.

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  /// Where the app preferences are kept.
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'ae819a2df2ba8cfe68dd3f654206240eb52bf4f7';

/// What the legacy importer did at this launch (`bootstrap`), or null when it did nothing;
/// Phase 1d shows it once.

@ProviderFor(LegacyImportResult)
final legacyImportResultProvider = LegacyImportResultProvider._();

/// What the legacy importer did at this launch (`bootstrap`), or null when it did nothing;
/// Phase 1d shows it once.
final class LegacyImportResultProvider
    extends $NotifierProvider<LegacyImportResult, ImportSummary?> {
  /// What the legacy importer did at this launch (`bootstrap`), or null when it did nothing;
  /// Phase 1d shows it once.
  LegacyImportResultProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'legacyImportResultProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$legacyImportResultHash();

  @$internal
  @override
  LegacyImportResult create() => LegacyImportResult();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportSummary? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportSummary?>(value),
    );
  }
}

String _$legacyImportResultHash() =>
    r'f382269369b051ea53ee7ea3d698f5fe95241207';

/// What the legacy importer did at this launch (`bootstrap`), or null when it did nothing;
/// Phase 1d shows it once.

abstract class _$LegacyImportResult extends $Notifier<ImportSummary?> {
  ImportSummary? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ImportSummary?, ImportSummary?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ImportSummary?, ImportSummary?>,
              ImportSummary?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
