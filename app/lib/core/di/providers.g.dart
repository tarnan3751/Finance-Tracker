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
/// (`bootstrap` opens it at startup) and closed with the container ([databaseClosing]).
/// The demo flavor has none, and reading it there is a [StateError].

@ProviderFor(database)
final databaseProvider = DatabaseProvider._();

/// The local database of the dev and prod flavors, opened lazily on its first query
/// (`bootstrap` opens it at startup) and closed with the container ([databaseClosing]).
/// The demo flavor has none, and reading it there is a [StateError].

final class DatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// The local database of the dev and prod flavors, opened lazily on its first query
  /// (`bootstrap` opens it at startup) and closed with the container ([databaseClosing]).
  /// The demo flavor has none, and reading it there is a [StateError].
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

String _$databaseHash() => r'fc8520e04f7c246856214b4b4eab9246f4fe5370';

/// The state behind the in-memory and demo repositories: empty by default; the demo
/// flavor's holds the system categories and the selected persona's demo seed.

@ProviderFor(inMemoryStore)
final inMemoryStoreProvider = InMemoryStoreProvider._();

/// The state behind the in-memory and demo repositories: empty by default; the demo
/// flavor's holds the system categories and the selected persona's demo seed.

final class InMemoryStoreProvider
    extends $FunctionalProvider<InMemoryStore, InMemoryStore, InMemoryStore>
    with $Provider<InMemoryStore> {
  /// The state behind the in-memory and demo repositories: empty by default; the demo
  /// flavor's holds the system categories and the selected persona's demo seed.
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

/// The sync store [changeRecorder] records into, for what reads its records outside a
/// write (the rules on arrival): [inMemorySyncStore] by default, the Drift store in dev and
/// prod, none in the demo flavor, which never records.

@ProviderFor(recordingSyncStore)
final recordingSyncStoreProvider = RecordingSyncStoreProvider._();

/// The sync store [changeRecorder] records into, for what reads its records outside a
/// write (the rules on arrival): [inMemorySyncStore] by default, the Drift store in dev and
/// prod, none in the demo flavor, which never records.

final class RecordingSyncStoreProvider
    extends $FunctionalProvider<SyncStore?, SyncStore?, SyncStore?>
    with $Provider<SyncStore?> {
  /// The sync store [changeRecorder] records into, for what reads its records outside a
  /// write (the rules on arrival): [inMemorySyncStore] by default, the Drift store in dev and
  /// prod, none in the demo flavor, which never records.
  RecordingSyncStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordingSyncStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordingSyncStoreHash();

  @$internal
  @override
  $ProviderElement<SyncStore?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncStore? create(Ref ref) {
    return recordingSyncStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncStore? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncStore?>(value),
    );
  }
}

String _$recordingSyncStoreHash() =>
    r'8804be0683e16b62a4d26c0d47919e6260092d7c';

/// The server's id for this device while someone is signed in, else null: the node the
/// device's sync clock adopts.

@ProviderFor(syncDeviceId)
final syncDeviceIdProvider = SyncDeviceIdProvider._();

/// The server's id for this device while someone is signed in, else null: the node the
/// device's sync clock adopts.

final class SyncDeviceIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// The server's id for this device while someone is signed in, else null: the node the
  /// device's sync clock adopts.
  SyncDeviceIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncDeviceIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncDeviceIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return syncDeviceId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$syncDeviceIdHash() => r'f4397e0b56d6422f251e0d511f53d3cf27e6600d';

/// The relay the device syncs through while someone is signed in, else null: the API's
/// sync endpoints, as this device.

@ProviderFor(syncRelay)
final syncRelayProvider = SyncRelayProvider._();

/// The relay the device syncs through while someone is signed in, else null: the API's
/// sync endpoints, as this device.

final class SyncRelayProvider
    extends $FunctionalProvider<SyncRelay?, SyncRelay?, SyncRelay?>
    with $Provider<SyncRelay?> {
  /// The relay the device syncs through while someone is signed in, else null: the API's
  /// sync endpoints, as this device.
  SyncRelayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncRelayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncRelayHash();

  @$internal
  @override
  $ProviderElement<SyncRelay?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncRelay? create(Ref ref) {
    return syncRelay(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncRelay? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncRelay?>(value),
    );
  }
}

String _$syncRelayHash() => r'9f573de51dd7394acac0b90535f9d7da2c38ffc7';

/// Whether this build's local data syncs: the Drift data of dev and prod, through
/// [overridesFor]. The in-memory data of the tests and the demo flavor never does.

@ProviderFor(localDataSyncs)
final localDataSyncsProvider = LocalDataSyncsProvider._();

/// Whether this build's local data syncs: the Drift data of dev and prod, through
/// [overridesFor]. The in-memory data of the tests and the demo flavor never does.

final class LocalDataSyncsProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether this build's local data syncs: the Drift data of dev and prod, through
  /// [overridesFor]. The in-memory data of the tests and the demo flavor never does.
  LocalDataSyncsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localDataSyncsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localDataSyncsHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return localDataSyncs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$localDataSyncsHash() => r'30083c89dc671e1b5868b20511a00537f8757e0a';

/// How long after the last local change a sync session starts.

@ProviderFor(syncDebounce)
final syncDebounceProvider = SyncDebounceProvider._();

/// How long after the last local change a sync session starts.

final class SyncDebounceProvider
    extends $FunctionalProvider<Duration, Duration, Duration>
    with $Provider<Duration> {
  /// How long after the last local change a sync session starts.
  SyncDebounceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncDebounceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncDebounceHash();

  @$internal
  @override
  $ProviderElement<Duration> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Duration create(Ref ref) {
    return syncDebounce(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Duration value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Duration>(value),
    );
  }
}

String _$syncDebounceHash() => r'c2ba3054ead3d6775d154f2cb91eea025f9e1bc4';

/// How long after the [failures]th failed session in a row the next one runs: 15 s,
/// doubling, at most five minutes.

@ProviderFor(syncBackoff)
final syncBackoffProvider = SyncBackoffProvider._();

/// How long after the [failures]th failed session in a row the next one runs: 15 s,
/// doubling, at most five minutes.

final class SyncBackoffProvider
    extends
        $FunctionalProvider<
          Duration Function(int failures),
          Duration Function(int failures),
          Duration Function(int failures)
        >
    with $Provider<Duration Function(int failures)> {
  /// How long after the [failures]th failed session in a row the next one runs: 15 s,
  /// doubling, at most five minutes.
  SyncBackoffProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncBackoffProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncBackoffHash();

  @$internal
  @override
  $ProviderElement<Duration Function(int failures)> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Duration Function(int failures) create(Ref ref) {
    return syncBackoff(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Duration Function(int failures) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Duration Function(int failures)>(
        value,
      ),
    );
  }
}

String _$syncBackoffHash() => r'b4df0a1c8f61be454feb6f74ad5d9ad354faeceb';

/// The persona the demo flavor shows: [initialDemoPersona] at start, then what Settings →
/// Demo data selects.

@ProviderFor(DemoPersona)
final demoPersonaProvider = DemoPersonaProvider._();

/// The persona the demo flavor shows: [initialDemoPersona] at start, then what Settings →
/// Demo data selects.
final class DemoPersonaProvider
    extends $NotifierProvider<DemoPersona, PersonaId> {
  /// The persona the demo flavor shows: [initialDemoPersona] at start, then what Settings →
  /// Demo data selects.
  DemoPersonaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'demoPersonaProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$demoPersonaHash();

  @$internal
  @override
  DemoPersona create() => DemoPersona();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PersonaId value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PersonaId>(value),
    );
  }
}

String _$demoPersonaHash() => r'6646595be34595249fceb3ae52383d10e5f57c03';

/// The persona the demo flavor shows: [initialDemoPersona] at start, then what Settings →
/// Demo data selects.

abstract class _$DemoPersona extends $Notifier<PersonaId> {
  PersonaId build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PersonaId, PersonaId>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PersonaId, PersonaId>,
              PersonaId,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The demo seed of the selected persona as of the clock's today: what the demo flavor's
/// store is loaded from (and the in-app fake server's dataset).

@ProviderFor(demoSeed)
final demoSeedProvider = DemoSeedProvider._();

/// The demo seed of the selected persona as of the clock's today: what the demo flavor's
/// store is loaded from (and the in-app fake server's dataset).

final class DemoSeedProvider
    extends $FunctionalProvider<DemoSeed, DemoSeed, DemoSeed>
    with $Provider<DemoSeed> {
  /// The demo seed of the selected persona as of the clock's today: what the demo flavor's
  /// store is loaded from (and the in-app fake server's dataset).
  DemoSeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'demoSeedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$demoSeedHash();

  @$internal
  @override
  $ProviderElement<DemoSeed> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DemoSeed create(Ref ref) {
    return demoSeed(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DemoSeed value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DemoSeed>(value),
    );
  }
}

String _$demoSeedHash() => r'3295e6dab3813bf96facbd7d3fc31f45741d0279';

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

/// The user's Plaid Items.

@ProviderFor(itemRepository)
final itemRepositoryProvider = ItemRepositoryProvider._();

/// The user's Plaid Items.

final class ItemRepositoryProvider
    extends $FunctionalProvider<ItemRepository, ItemRepository, ItemRepository>
    with $Provider<ItemRepository> {
  /// The user's Plaid Items.
  ItemRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'itemRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$itemRepositoryHash();

  @$internal
  @override
  $ProviderElement<ItemRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ItemRepository create(Ref ref) {
    return itemRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ItemRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ItemRepository>(value),
    );
  }
}

String _$itemRepositoryHash() => r'4e06709b476bab90530a481baf2c582826909613';

/// The rules.

@ProviderFor(ruleRepository)
final ruleRepositoryProvider = RuleRepositoryProvider._();

/// The rules.

final class RuleRepositoryProvider
    extends $FunctionalProvider<RuleRepository, RuleRepository, RuleRepository>
    with $Provider<RuleRepository> {
  /// The rules.
  RuleRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ruleRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ruleRepositoryHash();

  @$internal
  @override
  $ProviderElement<RuleRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RuleRepository create(Ref ref) {
    return ruleRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RuleRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RuleRepository>(value),
    );
  }
}

String _$ruleRepositoryHash() => r'e61eb88d426fccdfd23056fa18a0df7098bab5c9';

/// The budgets.

@ProviderFor(budgetRepository)
final budgetRepositoryProvider = BudgetRepositoryProvider._();

/// The budgets.

final class BudgetRepositoryProvider
    extends
        $FunctionalProvider<
          BudgetRepository,
          BudgetRepository,
          BudgetRepository
        >
    with $Provider<BudgetRepository> {
  /// The budgets.
  BudgetRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetRepositoryHash();

  @$internal
  @override
  $ProviderElement<BudgetRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BudgetRepository create(Ref ref) {
    return budgetRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BudgetRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BudgetRepository>(value),
    );
  }
}

String _$budgetRepositoryHash() => r'f78e75f5318ada075b16c6955547b9a30e3f9697';

/// The recurring streams and the user's overrides of them.

@ProviderFor(recurringStreamRepository)
final recurringStreamRepositoryProvider = RecurringStreamRepositoryProvider._();

/// The recurring streams and the user's overrides of them.

final class RecurringStreamRepositoryProvider
    extends
        $FunctionalProvider<
          RecurringStreamRepository,
          RecurringStreamRepository,
          RecurringStreamRepository
        >
    with $Provider<RecurringStreamRepository> {
  /// The recurring streams and the user's overrides of them.
  RecurringStreamRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurringStreamRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recurringStreamRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecurringStreamRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecurringStreamRepository create(Ref ref) {
    return recurringStreamRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecurringStreamRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecurringStreamRepository>(value),
    );
  }
}

String _$recurringStreamRepositoryHash() =>
    r'd0ff435257b759faaf4bc56f2e59b93308fd4afb';

/// The liabilities of the linked accounts.

@ProviderFor(liabilityRepository)
final liabilityRepositoryProvider = LiabilityRepositoryProvider._();

/// The liabilities of the linked accounts.

final class LiabilityRepositoryProvider
    extends
        $FunctionalProvider<
          LiabilityRepository,
          LiabilityRepository,
          LiabilityRepository
        >
    with $Provider<LiabilityRepository> {
  /// The liabilities of the linked accounts.
  LiabilityRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liabilityRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liabilityRepositoryHash();

  @$internal
  @override
  $ProviderElement<LiabilityRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LiabilityRepository create(Ref ref) {
    return liabilityRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LiabilityRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LiabilityRepository>(value),
    );
  }
}

String _$liabilityRepositoryHash() =>
    r'd8781db8290d2dabe868a06e7d6ebc612a119c3c';

/// The holdings of the linked investment accounts and their securities.

@ProviderFor(holdingRepository)
final holdingRepositoryProvider = HoldingRepositoryProvider._();

/// The holdings of the linked investment accounts and their securities.

final class HoldingRepositoryProvider
    extends
        $FunctionalProvider<
          HoldingRepository,
          HoldingRepository,
          HoldingRepository
        >
    with $Provider<HoldingRepository> {
  /// The holdings of the linked investment accounts and their securities.
  HoldingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'holdingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$holdingRepositoryHash();

  @$internal
  @override
  $ProviderElement<HoldingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HoldingRepository create(Ref ref) {
    return holdingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HoldingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HoldingRepository>(value),
    );
  }
}

String _$holdingRepositoryHash() => r'e854830ece44b4d0bf962c756b24b6ccaaf5d234';

/// The investment transactions of the linked investment accounts.

@ProviderFor(investmentTransactionRepository)
final investmentTransactionRepositoryProvider =
    InvestmentTransactionRepositoryProvider._();

/// The investment transactions of the linked investment accounts.

final class InvestmentTransactionRepositoryProvider
    extends
        $FunctionalProvider<
          InvestmentTransactionRepository,
          InvestmentTransactionRepository,
          InvestmentTransactionRepository
        >
    with $Provider<InvestmentTransactionRepository> {
  /// The investment transactions of the linked investment accounts.
  InvestmentTransactionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'investmentTransactionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$investmentTransactionRepositoryHash();

  @$internal
  @override
  $ProviderElement<InvestmentTransactionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InvestmentTransactionRepository create(Ref ref) {
    return investmentTransactionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InvestmentTransactionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InvestmentTransactionRepository>(
        value,
      ),
    );
  }
}

String _$investmentTransactionRepositoryHash() =>
    r'6e2a8f664e865ec27065430794ec7a1fca5c1e42';

/// The balance snapshots this device has observed: in memory by default, empty at launch
/// in the demo flavor, `balance_snapshots` in dev and prod.

@ProviderFor(balanceSnapshotRepository)
final balanceSnapshotRepositoryProvider = BalanceSnapshotRepositoryProvider._();

/// The balance snapshots this device has observed: in memory by default, empty at launch
/// in the demo flavor, `balance_snapshots` in dev and prod.

final class BalanceSnapshotRepositoryProvider
    extends
        $FunctionalProvider<
          BalanceSnapshotRepository,
          BalanceSnapshotRepository,
          BalanceSnapshotRepository
        >
    with $Provider<BalanceSnapshotRepository> {
  /// The balance snapshots this device has observed: in memory by default, empty at launch
  /// in the demo flavor, `balance_snapshots` in dev and prod.
  BalanceSnapshotRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'balanceSnapshotRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$balanceSnapshotRepositoryHash();

  @$internal
  @override
  $ProviderElement<BalanceSnapshotRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BalanceSnapshotRepository create(Ref ref) {
    return balanceSnapshotRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BalanceSnapshotRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BalanceSnapshotRepository>(value),
    );
  }
}

String _$balanceSnapshotRepositoryHash() =>
    r'2ca10704610e618988d06750a94bc67d99ec2676';

/// Which budget alerts this device has raised: in memory by default and in the demo
/// flavor, `budget_alerts` in dev and prod.

@ProviderFor(budgetAlertStore)
final budgetAlertStoreProvider = BudgetAlertStoreProvider._();

/// Which budget alerts this device has raised: in memory by default and in the demo
/// flavor, `budget_alerts` in dev and prod.

final class BudgetAlertStoreProvider
    extends
        $FunctionalProvider<
          BudgetAlertStore,
          BudgetAlertStore,
          BudgetAlertStore
        >
    with $Provider<BudgetAlertStore> {
  /// Which budget alerts this device has raised: in memory by default and in the demo
  /// flavor, `budget_alerts` in dev and prod.
  BudgetAlertStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetAlertStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetAlertStoreHash();

  @$internal
  @override
  $ProviderElement<BudgetAlertStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BudgetAlertStore create(Ref ref) {
    return budgetAlertStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BudgetAlertStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BudgetAlertStore>(value),
    );
  }
}

String _$budgetAlertStoreHash() => r'6750109fbb393e2b675f6fb7f1ca2aa3d7e92ff9';

/// Facts about this install (`app_meta`): in memory by default and in the demo flavor,
/// the database's in dev and prod.

@ProviderFor(appMetaStore)
final appMetaStoreProvider = AppMetaStoreProvider._();

/// Facts about this install (`app_meta`): in memory by default and in the demo flavor,
/// the database's in dev and prod.

final class AppMetaStoreProvider
    extends $FunctionalProvider<AppMetaStore, AppMetaStore, AppMetaStore>
    with $Provider<AppMetaStore> {
  /// Facts about this install (`app_meta`): in memory by default and in the demo flavor,
  /// the database's in dev and prod.
  AppMetaStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appMetaStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appMetaStoreHash();

  @$internal
  @override
  $ProviderElement<AppMetaStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppMetaStore create(Ref ref) {
    return appMetaStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppMetaStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppMetaStore>(value),
    );
  }
}

String _$appMetaStoreHash() => r'2f9b9904345e82a25ff5f6ef051da553d75a0f5c';

/// The bills.

@ProviderFor(billRepository)
final billRepositoryProvider = BillRepositoryProvider._();

/// The bills.

final class BillRepositoryProvider
    extends $FunctionalProvider<BillRepository, BillRepository, BillRepository>
    with $Provider<BillRepository> {
  /// The bills.
  BillRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billRepositoryHash();

  @$internal
  @override
  $ProviderElement<BillRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BillRepository create(Ref ref) {
    return billRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BillRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BillRepository>(value),
    );
  }
}

String _$billRepositoryHash() => r'3717e3c97ab9a89c47ef9f5f2194a9d4f214c51d';

/// Which bill notifications this device has raised: in memory by default and in the
/// demo flavor, `bill_alerts` in dev and prod.

@ProviderFor(billAlertStore)
final billAlertStoreProvider = BillAlertStoreProvider._();

/// Which bill notifications this device has raised: in memory by default and in the
/// demo flavor, `bill_alerts` in dev and prod.

final class BillAlertStoreProvider
    extends $FunctionalProvider<BillAlertStore, BillAlertStore, BillAlertStore>
    with $Provider<BillAlertStore> {
  /// Which bill notifications this device has raised: in memory by default and in the
  /// demo flavor, `bill_alerts` in dev and prod.
  BillAlertStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billAlertStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billAlertStoreHash();

  @$internal
  @override
  $ProviderElement<BillAlertStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BillAlertStore create(Ref ref) {
    return billAlertStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BillAlertStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BillAlertStore>(value),
    );
  }
}

String _$billAlertStoreHash() => r'150465590c05fac350f8dfe6fbb8e01512a7aadf';

/// The savings goals and their contributions.

@ProviderFor(goalRepository)
final goalRepositoryProvider = GoalRepositoryProvider._();

/// The savings goals and their contributions.

final class GoalRepositoryProvider
    extends $FunctionalProvider<GoalRepository, GoalRepository, GoalRepository>
    with $Provider<GoalRepository> {
  /// The savings goals and their contributions.
  GoalRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalRepositoryHash();

  @$internal
  @override
  $ProviderElement<GoalRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoalRepository create(Ref ref) {
    return goalRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalRepository>(value),
    );
  }
}

String _$goalRepositoryHash() => r'd912513e2d496597d3ea180847b48d8686862c42';

/// The transaction list's saved filters, on this device only.

@ProviderFor(savedFilterRepository)
final savedFilterRepositoryProvider = SavedFilterRepositoryProvider._();

/// The transaction list's saved filters, on this device only.

final class SavedFilterRepositoryProvider
    extends
        $FunctionalProvider<
          SavedFilterRepository,
          SavedFilterRepository,
          SavedFilterRepository
        >
    with $Provider<SavedFilterRepository> {
  /// The transaction list's saved filters, on this device only.
  SavedFilterRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedFilterRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedFilterRepositoryHash();

  @$internal
  @override
  $ProviderElement<SavedFilterRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SavedFilterRepository create(Ref ref) {
    return savedFilterRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SavedFilterRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SavedFilterRepository>(value),
    );
  }
}

String _$savedFilterRepositoryHash() =>
    r'8f010995331cdbd6aef46af795105462c3649d1b';

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

/// Where the receipt photos are kept: in memory by default (the tests, the demo flavor),
/// files in the app's support directory in dev and prod.

@ProviderFor(receiptStore)
final receiptStoreProvider = ReceiptStoreProvider._();

/// Where the receipt photos are kept: in memory by default (the tests, the demo flavor),
/// files in the app's support directory in dev and prod.

final class ReceiptStoreProvider
    extends $FunctionalProvider<ReceiptStore, ReceiptStore, ReceiptStore>
    with $Provider<ReceiptStore> {
  /// Where the receipt photos are kept: in memory by default (the tests, the demo flavor),
  /// files in the app's support directory in dev and prod.
  ReceiptStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptStoreHash();

  @$internal
  @override
  $ProviderElement<ReceiptStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReceiptStore create(Ref ref) {
    return receiptStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptStore>(value),
    );
  }
}

String _$receiptStoreHash() => r'7c0a4f57f4a5fd258e6ef9009f695f9622a3b0f2';

/// The local wipe (`local_wipe.dart`): the stores only by default (the tests, the demo
/// flavor), the database files too in dev and prod.

@ProviderFor(localWipe)
final localWipeProvider = LocalWipeProvider._();

/// The local wipe (`local_wipe.dart`): the stores only by default (the tests, the demo
/// flavor), the database files too in dev and prod.

final class LocalWipeProvider
    extends $FunctionalProvider<LocalWipe, LocalWipe, LocalWipe>
    with $Provider<LocalWipe> {
  /// The local wipe (`local_wipe.dart`): the stores only by default (the tests, the demo
  /// flavor), the database files too in dev and prod.
  LocalWipeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localWipeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localWipeHash();

  @$internal
  @override
  $ProviderElement<LocalWipe> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocalWipe create(Ref ref) {
    return localWipe(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalWipe value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalWipe>(value),
    );
  }
}

String _$localWipeHash() => r'036e070ea46d410094a539cba8af7b747def5620';

/// Stops the app, wipes its local data, confirms and starts it again: `bootstrap`
/// supplies it; anywhere else (the tests) it is unavailable unless overridden.

@ProviderFor(wipeLocalData)
final wipeLocalDataProvider = WipeLocalDataProvider._();

/// Stops the app, wipes its local data, confirms and starts it again: `bootstrap`
/// supplies it; anywhere else (the tests) it is unavailable unless overridden.

final class WipeLocalDataProvider
    extends $FunctionalProvider<WipeLocalData, WipeLocalData, WipeLocalData>
    with $Provider<WipeLocalData> {
  /// Stops the app, wipes its local data, confirms and starts it again: `bootstrap`
  /// supplies it; anywhere else (the tests) it is unavailable unless overridden.
  WipeLocalDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wipeLocalDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wipeLocalDataHash();

  @$internal
  @override
  $ProviderElement<WipeLocalData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WipeLocalData create(Ref ref) {
    return wipeLocalData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WipeLocalData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WipeLocalData>(value),
    );
  }
}

String _$wipeLocalDataHash() => r'ac0f7379aedf0b5e086823928036195af0f5678a';

/// Where the Plaid pull keeps its cursors: in memory by default (beside the in-memory
/// store, so a new store starts it afresh), `sync_meta` in dev and prod.

@ProviderFor(plaidPullStore)
final plaidPullStoreProvider = PlaidPullStoreProvider._();

/// Where the Plaid pull keeps its cursors: in memory by default (beside the in-memory
/// store, so a new store starts it afresh), `sync_meta` in dev and prod.

final class PlaidPullStoreProvider
    extends $FunctionalProvider<PlaidPullStore, PlaidPullStore, PlaidPullStore>
    with $Provider<PlaidPullStore> {
  /// Where the Plaid pull keeps its cursors: in memory by default (beside the in-memory
  /// store, so a new store starts it afresh), `sync_meta` in dev and prod.
  PlaidPullStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plaidPullStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plaidPullStoreHash();

  @$internal
  @override
  $ProviderElement<PlaidPullStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlaidPullStore create(Ref ref) {
    return plaidPullStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaidPullStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaidPullStore>(value),
    );
  }
}

String _$plaidPullStoreHash() => r'd709e2b573f3075367004dffce0fe76d43590c0a';

/// The duplicate pairs the user dismissed, kept on the device and never synced: in memory
/// by default and in the demo (beside the in-memory store, so a new store starts it
/// afresh), `dismissed_pairs` in dev and prod.

@ProviderFor(dismissedPairStore)
final dismissedPairStoreProvider = DismissedPairStoreProvider._();

/// The duplicate pairs the user dismissed, kept on the device and never synced: in memory
/// by default and in the demo (beside the in-memory store, so a new store starts it
/// afresh), `dismissed_pairs` in dev and prod.

final class DismissedPairStoreProvider
    extends
        $FunctionalProvider<
          DismissedPairStore,
          DismissedPairStore,
          DismissedPairStore
        >
    with $Provider<DismissedPairStore> {
  /// The duplicate pairs the user dismissed, kept on the device and never synced: in memory
  /// by default and in the demo (beside the in-memory store, so a new store starts it
  /// afresh), `dismissed_pairs` in dev and prod.
  DismissedPairStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dismissedPairStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dismissedPairStoreHash();

  @$internal
  @override
  $ProviderElement<DismissedPairStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DismissedPairStore create(Ref ref) {
    return dismissedPairStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DismissedPairStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DismissedPairStore>(value),
    );
  }
}

String _$dismissedPairStoreHash() =>
    r'7ed3e2b5233371d8c439614aa131195ffe2bf0f1';

/// This device's sync conflicts, kept on the device and never synced: in memory by
/// default and in the demo (which never syncs, so it stays empty), `conflicts` in dev
/// and prod.

@ProviderFor(conflictStore)
final conflictStoreProvider = ConflictStoreProvider._();

/// This device's sync conflicts, kept on the device and never synced: in memory by
/// default and in the demo (which never syncs, so it stays empty), `conflicts` in dev
/// and prod.

final class ConflictStoreProvider
    extends $FunctionalProvider<ConflictStore, ConflictStore, ConflictStore>
    with $Provider<ConflictStore> {
  /// This device's sync conflicts, kept on the device and never synced: in memory by
  /// default and in the demo (which never syncs, so it stays empty), `conflicts` in dev
  /// and prod.
  ConflictStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conflictStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conflictStoreHash();

  @$internal
  @override
  $ProviderElement<ConflictStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ConflictStore create(Ref ref) {
    return conflictStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConflictStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConflictStore>(value),
    );
  }
}

String _$conflictStoreHash() => r'2e59c2000b66fe769e917f43b612272184817b7f';

/// What the Plaid pull does with the transactions it inserts: the rules
/// (`docs/reference/rules.md`, **On arrival**).

@ProviderFor(arrivalProcessor)
final arrivalProcessorProvider = ArrivalProcessorProvider._();

/// What the Plaid pull does with the transactions it inserts: the rules
/// (`docs/reference/rules.md`, **On arrival**).

final class ArrivalProcessorProvider
    extends
        $FunctionalProvider<
          ArrivalProcessor,
          ArrivalProcessor,
          ArrivalProcessor
        >
    with $Provider<ArrivalProcessor> {
  /// What the Plaid pull does with the transactions it inserts: the rules
  /// (`docs/reference/rules.md`, **On arrival**).
  ArrivalProcessorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'arrivalProcessorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$arrivalProcessorHash();

  @$internal
  @override
  $ProviderElement<ArrivalProcessor> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ArrivalProcessor create(Ref ref) {
    return arrivalProcessor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArrivalProcessor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArrivalProcessor>(value),
    );
  }
}

String _$arrivalProcessorHash() => r'a9a8e9407aed945fad87b12815679d217b41c150';

/// The Plaid pull over the API into the repositories (`core/plaid/plaid_pull.dart`):
/// run after each sync session and after each Item action.

@ProviderFor(plaidPull)
final plaidPullProvider = PlaidPullProvider._();

/// The Plaid pull over the API into the repositories (`core/plaid/plaid_pull.dart`):
/// run after each sync session and after each Item action.

final class PlaidPullProvider
    extends $FunctionalProvider<PlaidPull, PlaidPull, PlaidPull>
    with $Provider<PlaidPull> {
  /// The Plaid pull over the API into the repositories (`core/plaid/plaid_pull.dart`):
  /// run after each sync session and after each Item action.
  PlaidPullProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plaidPullProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plaidPullHash();

  @$internal
  @override
  $ProviderElement<PlaidPull> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlaidPull create(Ref ref) {
    return plaidPull(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaidPull value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaidPull>(value),
    );
  }
}

String _$plaidPullHash() => r'05e9d50a6f26cd1b6144b5da3d6fc6b7724fbe30';

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
