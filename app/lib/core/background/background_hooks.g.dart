// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_hooks.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The steps, in order.

@ProviderFor(backgroundCycleHooks)
final backgroundCycleHooksProvider = BackgroundCycleHooksProvider._();

/// The steps, in order.

final class BackgroundCycleHooksProvider
    extends
        $FunctionalProvider<
          List<BackgroundCycleHook>,
          List<BackgroundCycleHook>,
          List<BackgroundCycleHook>
        >
    with $Provider<List<BackgroundCycleHook>> {
  /// The steps, in order.
  BackgroundCycleHooksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundCycleHooksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundCycleHooksHash();

  @$internal
  @override
  $ProviderElement<List<BackgroundCycleHook>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<BackgroundCycleHook> create(Ref ref) {
    return backgroundCycleHooks(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<BackgroundCycleHook> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<BackgroundCycleHook>>(value),
    );
  }
}

String _$backgroundCycleHooksHash() =>
    r'0e545d43fc77f15d13c0187b5afc08970d942880';
