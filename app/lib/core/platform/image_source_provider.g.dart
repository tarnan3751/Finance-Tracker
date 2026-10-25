// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_source_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The image source.

@ProviderFor(imageSource)
final imageSourceProvider = ImageSourceProvider._();

/// The image source.

final class ImageSourceProvider
    extends $FunctionalProvider<ImageSource, ImageSource, ImageSource>
    with $Provider<ImageSource> {
  /// The image source.
  ImageSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageSourceHash();

  @$internal
  @override
  $ProviderElement<ImageSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImageSource create(Ref ref) {
    return imageSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImageSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImageSource>(value),
    );
  }
}

String _$imageSourceHash() => r'b241e49d8c925ca3608e01d24f58b70830f4e4e4';
