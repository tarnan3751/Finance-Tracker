// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_view.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How a receipt photo's bytes become an image: decoded from memory. Image decoding and
/// resizing are platform code whose pixels differ between machines, so the goldens
/// override this with an image the test draws itself.

@ProviderFor(receiptImage)
final receiptImageProvider = ReceiptImageProvider._();

/// How a receipt photo's bytes become an image: decoded from memory. Image decoding and
/// resizing are platform code whose pixels differ between machines, so the goldens
/// override this with an image the test draws itself.

final class ReceiptImageProvider
    extends
        $FunctionalProvider<
          ImageProvider<Object> Function(Uint8List bytes),
          ImageProvider<Object> Function(Uint8List bytes),
          ImageProvider<Object> Function(Uint8List bytes)
        >
    with $Provider<ImageProvider<Object> Function(Uint8List bytes)> {
  /// How a receipt photo's bytes become an image: decoded from memory. Image decoding and
  /// resizing are platform code whose pixels differ between machines, so the goldens
  /// override this with an image the test draws itself.
  ReceiptImageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptImageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptImageHash();

  @$internal
  @override
  $ProviderElement<ImageProvider<Object> Function(Uint8List bytes)>
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ImageProvider<Object> Function(Uint8List bytes) create(Ref ref) {
    return receiptImage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    ImageProvider<Object> Function(Uint8List bytes) value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<ImageProvider<Object> Function(Uint8List bytes)>(
            value,
          ),
    );
  }
}

String _$receiptImageHash() => r'c5631e8280b8bbd24c85d785bd9eb62cff9b7543';
