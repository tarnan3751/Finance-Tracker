// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's restart: `bootstrap` supplies it; anywhere else (the tests) it is
/// unavailable unless overridden.

@ProviderFor(appRestart)
final appRestartProvider = AppRestartProvider._();

/// The app's restart: `bootstrap` supplies it; anywhere else (the tests) it is
/// unavailable unless overridden.

final class AppRestartProvider
    extends $FunctionalProvider<AppRestart, AppRestart, AppRestart>
    with $Provider<AppRestart> {
  /// The app's restart: `bootstrap` supplies it; anywhere else (the tests) it is
  /// unavailable unless overridden.
  AppRestartProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRestartProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRestartHash();

  @$internal
  @override
  $ProviderElement<AppRestart> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppRestart create(Ref ref) {
    return appRestart(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppRestart value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppRestart>(value),
    );
  }
}

String _$appRestartHash() => r'a1b1b572ab3799609ea1cd8d5fc354e486898800';

/// The backup environment.

@ProviderFor(backupEnvironment)
final backupEnvironmentProvider = BackupEnvironmentProvider._();

/// The backup environment.

final class BackupEnvironmentProvider
    extends
        $FunctionalProvider<
          BackupEnvironment,
          BackupEnvironment,
          BackupEnvironment
        >
    with $Provider<BackupEnvironment> {
  /// The backup environment.
  BackupEnvironmentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupEnvironmentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupEnvironmentHash();

  @$internal
  @override
  $ProviderElement<BackupEnvironment> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BackupEnvironment create(Ref ref) {
    return backupEnvironment(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupEnvironment value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupEnvironment>(value),
    );
  }
}

String _$backupEnvironmentHash() => r'8700faabbe63320755e43ef3d9817fcd938e93a7';

/// The backup service over the dev and prod database (the demo flavor has none).

@ProviderFor(backupService)
final backupServiceProvider = BackupServiceProvider._();

/// The backup service over the dev and prod database (the demo flavor has none).

final class BackupServiceProvider
    extends $FunctionalProvider<BackupService, BackupService, BackupService>
    with $Provider<BackupService> {
  /// The backup service over the dev and prod database (the demo flavor has none).
  BackupServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupServiceHash();

  @$internal
  @override
  $ProviderElement<BackupService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BackupService create(Ref ref) {
    return backupService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupService>(value),
    );
  }
}

String _$backupServiceHash() => r'bea81dfed50ea8c65863b26db5ea71618df49c34';

/// Whether the restore offer is pending: in dev and prod (the data that syncs), when
/// someone is signed in, the local database holds nothing (`hasLocalData`), and the
/// offer has not been answered on this install (`restore_offer_answered` in
/// `app_meta`). While it is pending the router shows the offer at `/restore` and sync
/// runs no session; [answer] ("Start fresh") records the answer and lets both go on.

@ProviderFor(RestoreOffer)
final restoreOfferProvider = RestoreOfferProvider._();

/// Whether the restore offer is pending: in dev and prod (the data that syncs), when
/// someone is signed in, the local database holds nothing (`hasLocalData`), and the
/// offer has not been answered on this install (`restore_offer_answered` in
/// `app_meta`). While it is pending the router shows the offer at `/restore` and sync
/// runs no session; [answer] ("Start fresh") records the answer and lets both go on.
final class RestoreOfferProvider
    extends $AsyncNotifierProvider<RestoreOffer, bool> {
  /// Whether the restore offer is pending: in dev and prod (the data that syncs), when
  /// someone is signed in, the local database holds nothing (`hasLocalData`), and the
  /// offer has not been answered on this install (`restore_offer_answered` in
  /// `app_meta`). While it is pending the router shows the offer at `/restore` and sync
  /// runs no session; [answer] ("Start fresh") records the answer and lets both go on.
  RestoreOfferProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restoreOfferProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restoreOfferHash();

  @$internal
  @override
  RestoreOffer create() => RestoreOffer();
}

String _$restoreOfferHash() => r'02373b0775c1ec98eadf2938ff58aba7e11390ee';

/// Whether the restore offer is pending: in dev and prod (the data that syncs), when
/// someone is signed in, the local database holds nothing (`hasLocalData`), and the
/// offer has not been answered on this install (`restore_offer_answered` in
/// `app_meta`). While it is pending the router shows the offer at `/restore` and sync
/// runs no session; [answer] ("Start fresh") records the answer and lets both go on.

abstract class _$RestoreOffer extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
