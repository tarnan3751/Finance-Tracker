/// The [ImageSource] of the dev and prod flavors: the system camera and photo picker
/// through `image_picker`, at most 1600 pixels wide at JPEG quality 85. The picked file
/// (in the app's cache) is read and deleted, and its metadata stripped before the bytes
/// leave here: a JPEG's APP segments (`jpeg_metadata.dart`), a PNG's ancillary chunks
/// (`png_metadata.dart`; the plugin re-encodes an image with transparency as a PNG and
/// copies the EXIF into it). Anything else (a WebP, a HEIC, an original the plugin could
/// not decode and passed through) is refused, since its metadata cannot be stripped here.
/// Nothing about the photo is logged but the picker's error code.
library;

import 'dart:io';

import 'package:finance_tracker/core/platform/image_source.dart';
import 'package:finance_tracker/core/platform/jpeg_metadata.dart';
import 'package:finance_tracker/core/platform/png_metadata.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:logging/logging.dart';

final Logger _log = Logger('image_source');

/// Photos through `image_picker`.
final class ImagePickerSource implements ImageSource {
  /// A source over [imagePicker] (a new `ImagePicker` by default).
  ImagePickerSource([picker.ImagePicker? imagePicker])
    : _picker = imagePicker ?? picker.ImagePicker();

  final picker.ImagePicker _picker;

  /// The widest a stored photo is, in pixels.
  static const double maxWidth = 1600;

  /// The JPEG quality a photo is stored at.
  static const int imageQuality = 85;

  @override
  Future<PickedImage?> pickFromCamera() => _pick(picker.ImageSource.camera);

  @override
  Future<PickedImage?> pickFromGallery() => _pick(picker.ImageSource.gallery);

  Future<PickedImage?> _pick(picker.ImageSource source) async {
    final picker.XFile? file;
    try {
      file = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        imageQuality: imageQuality,
      );
    } on PlatformException catch (e) {
      if (e.code == 'no_available_camera') throw const NoCameraException();
      _log.warning('the image picker failed: ${e.code}');
      throw const ImagePickFailedException();
    }
    if (file == null) return null;
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } on FileSystemException {
      throw const ImagePickFailedException();
    } finally {
      // The picker's copy in the cache is not kept.
      try {
        await File(file.path).delete();
      } on FileSystemException {
        // Already gone.
      }
    }
    try {
      if (isJpeg(bytes)) return PickedImage(stripJpegMetadata(bytes));
      if (isPng(bytes)) return PickedImage(stripPngMetadata(bytes));
    } on FormatException {
      throw const ImagePickFailedException();
    }
    throw const ImagePickFailedException();
  }
}
