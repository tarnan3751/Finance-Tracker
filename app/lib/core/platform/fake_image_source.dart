/// The [ImageSource] of the demo flavor and the tests: no camera and no photo picker.
/// The demo's gives the bundled synthetic receipt (`assets/demo/receipt.jpg`, an asset of
/// the demo flavor only) from both; a test gives what it likes and counts the picks.
library;

import 'package:finance_tracker/core/platform/image_source.dart';
import 'package:flutter/services.dart';

/// The demo flavor's receipt photo: a synthetic "DEMO RECEIPT", not a real purchase.
const String demoReceiptAsset = 'assets/demo/receipt.jpg';

/// Photos without a camera or a picker.
final class FakeImageSource implements ImageSource {
  /// A source whose every pick completes with [next]: a photo, null (the user took or
  /// chose none), or an [ImagePickException].
  FakeImageSource(this.next);

  /// The demo flavor's: the bundled receipt from the camera and the gallery alike.
  factory FakeImageSource.demo() => FakeImageSource(() async {
    final ByteData data = await rootBundle.load(demoReceiptAsset);
    return PickedImage(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  });

  /// What the next pick completes with.
  Future<PickedImage?> Function() next;

  /// How many times the camera was asked.
  int cameraPicks = 0;

  /// How many times the gallery was asked.
  int galleryPicks = 0;

  @override
  Future<PickedImage?> pickFromCamera() {
    cameraPicks++;
    return next();
  }

  @override
  Future<PickedImage?> pickFromGallery() {
    galleryPicks++;
    return next();
  }
}
