// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'developer_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The developer menu's state and operations.

@ProviderFor(DeveloperController)
final developerControllerProvider = DeveloperControllerProvider._();

/// The developer menu's state and operations.
final class DeveloperControllerProvider
    extends $NotifierProvider<DeveloperController, DeveloperState> {
  /// The developer menu's state and operations.
  DeveloperControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'developerControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$developerControllerHash();

  @$internal
  @override
  DeveloperController create() => DeveloperController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeveloperState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeveloperState>(value),
    );
  }
}

String _$developerControllerHash() =>
    r'424340aa64cd87446894802995e6e68957f57921';

/// The developer menu's state and operations.

abstract class _$DeveloperController extends $Notifier<DeveloperState> {
  DeveloperState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DeveloperState, DeveloperState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DeveloperState, DeveloperState>,
              DeveloperState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
