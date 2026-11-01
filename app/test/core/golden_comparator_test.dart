// The CI goldens' tolerance (helpers/golden_comparator.dart) on four real pairs from Linux
// CI runs against the macOS goldens (test/fixtures/golden_noise/; the fourth holds a
// segment switcher's gradient fade, which Linux rounds a level apart over a whole block):
// each passes, as does a golden against itself; a 3×3 ink square painted on a golden
// fails, as do 1 % of its pixels flipped and an image one pixel narrower, each writing the
// failures/ images and naming the numbers; a block a channel's four levels apart differs,
// three levels apart does not.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/golden_comparator.dart';

const String _fixtures = 'test/fixtures/golden_noise';

const List<String> _pairs = [
  'shell_accounts_medium_light',
  'bills_list_dark',
  'forecast_chart_light',
  'shell_insights_dark_phone',
];

Uint8List _read(String name) => File('$_fixtures/$name.png').readAsBytesSync();

/// A comparator whose golden is [master], in a directory of its own (failures/ goes
/// there).
TolerantGoldenComparator _comparatorFor(Uint8List master) {
  final Directory dir = Directory.systemTemp.createTempSync('golden_noise');
  addTearDown(() => dir.deleteSync(recursive: true));
  File('${dir.path}/golden.png').writeAsBytesSync(master);
  return TolerantGoldenComparator(Uri.file('${dir.path}/_test.dart'));
}

/// [png] decoded, changed by [edit] on its RGBA pixels, and encoded again.
Future<Uint8List> _edited(
  Uint8List png,
  void Function(Uint8List rgba, int width, int height) edit,
) async {
  final ui.Codec codec = await ui.instantiateImageCodec(png);
  final ui.Image image = (await codec.getNextFrame()).image;
  final int width = image.width;
  final int height = image.height;
  final Uint8List rgba = Uint8List.fromList(
    (await image.toByteData())!.buffer.asUint8List(),
  );
  image.dispose();
  edit(rgba, width, height);
  return _encode(rgba, width, height);
}

Future<Uint8List> _encode(Uint8List rgba, int width, int height) async {
  final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
    rgba,
  );
  final ui.Codec codec = await ui.ImageDescriptor.raw(
    buffer,
    width: width,
    height: height,
    pixelFormat: ui.PixelFormat.rgba8888,
  ).instantiateCodec();
  final ui.Image image = (await codec.getNextFrame()).image;
  final ByteData png = (await image.toByteData(
    format: ui.ImageByteFormat.png,
  ))!;
  image.dispose();
  return png.buffer.asUint8List();
}

void main() {
  for (final String name in _pairs) {
    testWidgets('$name from Linux passes against its macOS golden', (
      tester,
    ) async {
      final bool? passed = await tester.runAsync(
        () =>
            _comparatorFor(_read('${name}_master'))
                .compare(_read('${name}_test'), Uri.parse('golden.png')),
      );
      expect(passed, isTrue);
      // It is noise, not identity: the plain comparison fails.
      final GoldenNoise? noise = await tester.runAsync<GoldenNoise?>(
        () => noiseBetween(_read('${name}_test'), _read('${name}_master')),
      );
      expect(noise!.differing, greaterThan(0));
      expect(isNoise(noise), isTrue);
    });
  }

  testWidgets('a golden against itself passes', (tester) async {
    final Uint8List master = _read('bills_list_dark_master');
    final bool? passed = await tester.runAsync(
      () => _comparatorFor(master).compare(master, Uri.parse('golden.png')),
    );
    expect(passed, isTrue);
  });

  Future<String> failure(
    WidgetTester tester,
    Uint8List master,
    Uint8List test,
  ) async {
    final TolerantGoldenComparator comparator = _comparatorFor(master);
    Object? error;
    await tester.runAsync(() async {
      try {
        await comparator.compare(test, Uri.parse('golden.png'));
      } on FlutterError catch (e) {
        error = e;
      }
    });
    expect(error, isA<FlutterError>());
    expect(
      Directory.fromUri(comparator.basedir.resolve('failures/')).listSync(),
      isNotEmpty,
    );
    return error.toString();
  }

  testWidgets('a 3×3 ink square fails, named as a solid block', (tester) async {
    final Uint8List master = _read('shell_accounts_medium_light_master');
    final Uint8List? square = await tester.runAsync(
      () => _edited(master, (rgba, width, height) {
        for (int y = 400; y < 403; y++) {
          for (int x = 400; x < 403; x++) {
            final int o = (y * width + x) * 4;
            // Ink, or paper where the golden is ink already.
            final int v = rgba[o] == 0x1F ? 0xF7 : 0x1F;
            rgba
              ..[o] = v
              ..[o + 1] = v
              ..[o + 2] = v
              ..[o + 3] = 0xFF;
          }
        }
      }),
    );
    final String message = await failure(tester, master, square!);
    expect(
      message,
      contains('9 of 589541 pixels differ by more than 3 levels'),
    );
    expect(message, contains('the 3×3 block at (400, 400) differs entirely'));
  });

  testWidgets('1 % of the pixels flipped fails, named as too many', (
    tester,
  ) async {
    final Uint8List master = _read('forecast_chart_light_master');
    final Uint8List? flipped = await tester.runAsync(
      () => _edited(master, (rgba, width, height) {
        for (int i = 0; i < width * height; i += 100) {
          rgba[i * 4] = 255 - rgba[i * 4];
        }
      }),
    );
    final String message = await failure(tester, master, flipped!);
    expect(message, contains('(1.000 %; at most 0.5 % passes)'));
    expect(message, contains('no 3×3 block differs entirely'));
  });

  testWidgets('an image one pixel narrower fails', (tester) async {
    final Uint8List master = _read('bills_list_dark_master');
    final Uint8List? narrower = await tester.runAsync(() async {
      final ui.Codec codec = await ui.instantiateImageCodec(master);
      final ui.Image image = (await codec.getNextFrame()).image;
      final int width = image.width - 1;
      final int height = image.height;
      final Uint8List rgba = (await image.toByteData())!.buffer.asUint8List();
      final Uint8List cropped = Uint8List(width * height * 4);
      for (int y = 0; y < height; y++) {
        cropped.setRange(
          y * width * 4,
          (y + 1) * width * 4,
          rgba,
          y * image.width * 4,
        );
      }
      image.dispose();
      return _encode(cropped, width, height);
    });
    final String message = await failure(tester, master, narrower!);
    expect(message, contains('size'));
  });

  test('a solid block is found wherever it is, and thin lines are not one', () {
    const int w = 8;
    const int h = 8;
    final Uint8List a = Uint8List(w * h * 4);
    Uint8List b(Iterable<(int, int)> changed, {int level = 255}) {
      final Uint8List out = Uint8List.fromList(a);
      for (final (int x, int y) in changed) {
        out[(y * w + x) * 4] = level;
      }
      return out;
    }

    // A two-pixel-wide line down the whole image: noise by shape.
    final GoldenNoise line = measureNoise(
      a,
      b([
        for (int y = 0; y < h; y++) ...[(3, y), (4, y)],
      ]),
      w,
      h,
    );
    expect(line.solidAt, isNull);
    // A 3×3 block in the last corner.
    final GoldenNoise block = measureNoise(
      a,
      b([
        for (int y = 5; y < 8; y++)
          for (int x = 5; x < 8; x++) (x, y),
      ]),
      w,
      h,
    );
    expect(block.solidAt, (x: 5, y: 5));
    // The same block a channel's three levels apart is rounding, four is a difference.
    final List<(int, int)> whole = [
      for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++) (x, y),
    ];
    final GoldenNoise rounding = measureNoise(a, b(whole, level: 3), w, h);
    expect(rounding.differing, 0);
    expect(rounding.solidAt, isNull);
    final GoldenNoise step = measureNoise(a, b(whole, level: 4), w, h);
    expect(step.differing, w * h);
    expect(step.solidAt, (x: 0, y: 0));
  });
}
