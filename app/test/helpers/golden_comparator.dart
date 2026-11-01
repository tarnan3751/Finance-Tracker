// The golden comparator of every test file (`test/flutter_test_config.dart` installs it):
// Flutter's LocalFileComparator, which passes byte-identical images, with a tolerance for
// the anti-aliasing noise between the machine that generates the CI goldens (macOS) and
// the one that checks them (Linux in CI). An image of the golden's exact size passes when
//   (a) at most 0.5 % of its pixels differ, and
//   (b) no 3×3 window of pixels differs entirely,
// a pixel differing when any channel does. Anti-aliasing is thin (single pixels and
// one-pixel lines at the ends of the obscured text blocks and along the 1.5 px ink lines);
// a real change of colour or position is solid. A failure writes the same failures/ images
// as the base class and names both numbers (`docs/reference/testing-tools.md`, Goldens).
// --update-goldens is the base class's.
//
// alchemist's own `diffThreshold` replaces the comparator only when it is exactly a
// LocalFileComparator, and throws otherwise: no golden test here sets one.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// What differs between two images of one size.
typedef GoldenNoise = ({
  int width,
  int height,
  int differing,
  ({int x, int y})? solidAt,
});

/// The largest fraction of pixels that may differ.
const double maxNoiseFraction = 0.005;

/// Whether [noise] is anti-aliasing noise: few pixels, none in a solid 3×3 block.
bool isNoise(GoldenNoise noise) =>
    noise.differing <= noise.width * noise.height * maxNoiseFraction &&
    noise.solidAt == null;

/// [noise] in words, for a failure message.
String describeNoise(GoldenNoise noise) {
  final int total = noise.width * noise.height;
  final String percent = (noise.differing * 100 / total).toStringAsFixed(3);
  final String solid = switch (noise.solidAt) {
    null => 'no 3×3 block differs entirely',
    (:final int x, :final int y) =>
      'the 3×3 block at ($x, $y) differs entirely',
  };
  return '${noise.differing} of $total pixels differ ($percent %; at most '
      '${(maxNoiseFraction * 100).toStringAsFixed(1)} % passes), and $solid.';
}

/// The noise between two RGBA buffers of [width] × [height].
GoldenNoise measureNoise(Uint8List a, Uint8List b, int width, int height) {
  final Uint8List differs = Uint8List(width * height);
  int differing = 0;
  for (int i = 0; i < width * height; i++) {
    final int o = i * 4;
    if (a[o] != b[o] ||
        a[o + 1] != b[o + 1] ||
        a[o + 2] != b[o + 2] ||
        a[o + 3] != b[o + 3]) {
      differs[i] = 1;
      differing++;
    }
  }
  ({int x, int y})? solidAt;
  // Every solid window contains its top-left pixel, so only differing pixels anchor one.
  search:
  for (int y = 0; y + 2 < height; y++) {
    for (int x = 0; x + 2 < width; x++) {
      if (differs[y * width + x] == 0) continue;
      bool solid = true;
      for (int dy = 0; dy < 3 && solid; dy++) {
        for (int dx = 0; dx < 3 && solid; dx++) {
          solid = differs[(y + dy) * width + x + dx] == 1;
        }
      }
      if (solid) {
        solidAt = (x: x, y: y);
        break search;
      }
    }
  }
  return (width: width, height: height, differing: differing, solidAt: solidAt);
}

/// The noise between two PNGs, or null when their sizes differ. Runs in real async.
Future<GoldenNoise?> noiseBetween(Uint8List test, Uint8List master) async {
  Future<ui.Image> decode(Uint8List bytes) async {
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  final ui.Image a = await decode(test);
  final ui.Image b = await decode(master);
  try {
    if (a.width != b.width || a.height != b.height) return null;
    final ByteData pa = (await a.toByteData())!;
    final ByteData pb = (await b.toByteData())!;
    return measureNoise(
      pa.buffer.asUint8List(),
      pb.buffer.asUint8List(),
      a.width,
      a.height,
    );
  } finally {
    a.dispose();
    b.dispose();
  }
}

/// A LocalFileComparator that passes anti-aliasing noise ([isNoise]).
class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(super.testUri);

  /// One comparing against the goldens of [existing]'s directory.
  factory TolerantGoldenComparator.from(LocalFileComparator existing) =>
      TolerantGoldenComparator(existing.basedir.resolve('_tolerant.dart'));

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final Uint8List goldenBytes = Uint8List.fromList(
      await getGoldenBytes(golden),
    );
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      goldenBytes,
    );
    if (result.passed) {
      result.dispose();
      return true;
    }
    final GoldenNoise? noise = await noiseBetween(imageBytes, goldenBytes);
    if (noise != null && isNoise(noise)) {
      result.dispose();
      return true;
    }
    final String error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(switch (noise) {
      null => error,
      final GoldenNoise noise => '$error\n${describeNoise(noise)}',
    });
  }
}
