// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'launch_intent_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The launch links.

@ProviderFor(launchIntent)
final launchIntentProvider = LaunchIntentProvider._();

/// The launch links.

final class LaunchIntentProvider
    extends $FunctionalProvider<LaunchIntent, LaunchIntent, LaunchIntent>
    with $Provider<LaunchIntent> {
  /// The launch links.
  LaunchIntentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'launchIntentProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$launchIntentHash();

  @$internal
  @override
  $ProviderElement<LaunchIntent> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LaunchIntent create(Ref ref) {
    return launchIntent(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LaunchIntent value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LaunchIntent>(value),
    );
  }
}

String _$launchIntentHash() => r'5b0ec9b862a168451ee872c5892ff185f929472c';
