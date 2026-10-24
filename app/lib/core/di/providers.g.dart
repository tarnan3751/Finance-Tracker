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

String _$accountRepositoryHash() => r'89c853b025f1130c7c4c5c729d3a91cc85e88d41';

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
    r'ceaac0f82d3d115a6973c43f700b375503c196ce';

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
    r'a4f8dd69674e0727d3a6005247bee23c2b2e70f3';

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
    r'f241523d07f20c13474f2de1f202b75004d236a5';
