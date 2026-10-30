// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lock_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app lock and its settings.

@ProviderFor(LockController)
final lockControllerProvider = LockControllerProvider._();

/// The app lock and its settings.
final class LockControllerProvider
    extends $NotifierProvider<LockController, AppLockState> {
  /// The app lock and its settings.
  LockControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lockControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lockControllerHash();

  @$internal
  @override
  LockController create() => LockController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLockState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLockState>(value),
    );
  }
}

String _$lockControllerHash() => r'afe61632f0864ced46c441075a2ea184f83a5a29';

/// The app lock and its settings.

abstract class _$LockController extends $Notifier<AppLockState> {
  AppLockState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppLockState, AppLockState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppLockState, AppLockState>,
              AppLockState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
