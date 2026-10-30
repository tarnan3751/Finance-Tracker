// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_work_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The background work.

@ProviderFor(backgroundWork)
final backgroundWorkProvider = BackgroundWorkProvider._();

/// The background work.

final class BackgroundWorkProvider
    extends $FunctionalProvider<BackgroundWork, BackgroundWork, BackgroundWork>
    with $Provider<BackgroundWork> {
  /// The background work.
  BackgroundWorkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundWorkProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundWorkHash();

  @$internal
  @override
  $ProviderElement<BackgroundWork> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BackgroundWork create(Ref ref) {
    return backgroundWork(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackgroundWork value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackgroundWork>(value),
    );
  }
}

String _$backgroundWorkHash() => r'b67dfbb2b194df7f43939de6269971a8ae741057';
