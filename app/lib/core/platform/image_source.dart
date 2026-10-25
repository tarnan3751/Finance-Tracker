/// The platform boundary for receipt photos (`docs/reference/app-core.md`, **The image
/// source**): the app asks an [ImageSource] for a photo from the camera or the gallery and
/// gets back its bytes, with no camera metadata but the orientation. `image_picker` is
/// behind it in dev and prod; a fake stands in for the demo flavor and the tests, where the
/// system camera and photo picker cannot be driven. Pure Dart, no Flutter import.
library;

import 'dart:typed_data';

/// Takes or chooses a photo.
abstract interface class ImageSource {
  /// A photo taken with the camera, or null when the user took none. Throws
  /// [NoCameraException] when the device has no camera app, [ImagePickFailedException]
  /// when the photo cannot be used.
  Future<PickedImage?> pickFromCamera();

  /// A photo chosen from the gallery, or null when the user chose none. Throws
  /// [ImagePickFailedException] when the photo cannot be used.
  Future<PickedImage?> pickFromGallery();
}

/// A photo as the app keeps it.
final class PickedImage {
  /// A photo of [bytes].
  const PickedImage(this.bytes);

  /// The encoded image, metadata stripped: a JPEG (a PNG when it has transparency), at
  /// most 1600 pixels wide.
  final Uint8List bytes;

  @override
  String toString() => 'PickedImage(${bytes.length} bytes)';
}

/// Why no photo came back, other than the user's choice.
sealed class ImagePickException implements Exception {
  const ImagePickException();
}

/// The device has no camera app to take a photo with.
final class NoCameraException extends ImagePickException {
  /// The exception.
  const NoCameraException();

  @override
  String toString() => 'NoCameraException';
}

/// The photo cannot be used: the picker failed, what it returned is malformed, or it is
/// neither a JPEG nor a PNG, so its metadata cannot be stripped.
final class ImagePickFailedException extends ImagePickException {
  /// The exception.
  const ImagePickFailedException();

  @override
  String toString() => 'ImagePickFailedException';
}
