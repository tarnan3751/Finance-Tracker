// Metadata out of a PNG: the ancillary chunks go (eXIf with a GPS position, tEXt, iTXt,
// zTXt, tIME) except the ones that say how to show the image (pHYs here); the critical
// chunks stay byte for byte and the image still decodes; a chunk with a bad CRC, one
// that runs past the end, a missing IEND or bytes that are not a PNG are a
// FormatException.
//
// Fixture (test/fixtures/receipts/metadata.png, drawn for these tests): 24x12 RGBA with
// tEXt, iTXt, zTXt, tIME, pHYs and an eXIf carrying make "FixtureCam", a date and a GPS
// position.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:finance_tracker/core/platform/png_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _fixture(String name) =>
    File('test/fixtures/receipts/$name').readAsBytesSync();

/// The chunk types of [png], in order.
List<String> _chunks(Uint8List png) {
  final ByteData data = ByteData.sublistView(png);
  final List<String> types = [];
  int i = 8;
  while (i < png.length) {
    types.add(String.fromCharCodes(png, i + 4, i + 8));
    i += 12 + data.getUint32(i);
  }
  return types;
}

bool _contains(Uint8List haystack, String needle) =>
    latin1.decode(haystack).contains(needle);

void main() {
  test('the metadata chunks go, the image and display chunks stay', () {
    final Uint8List input = _fixture('metadata.png');
    expect(_chunks(input), [
      'IHDR',
      'tEXt',
      'iTXt',
      'zTXt',
      'tIME',
      'pHYs',
      'eXIf',
      'IDAT',
      'IEND',
    ]);

    final Uint8List output = stripPngMetadata(input);

    expect(_chunks(output), ['IHDR', 'pHYs', 'IDAT', 'IEND']);
    for (final String gone in [
      'FixtureCam',
      '2026:10:24',
      'FixtureComment',
      'FixtureItxt',
    ]) {
      expect(_contains(output, gone), isFalse, reason: gone);
    }
  });

  testWidgets('the stripped PNG still decodes at its size', (tester) async {
    final Uint8List output = stripPngMetadata(_fixture('metadata.png'));
    final ui.Image? image = await tester.runAsync(() async {
      final ui.Codec codec = await ui.instantiateImageCodec(output);
      return (await codec.getNextFrame()).image;
    });
    expect([image!.width, image.height], [24, 12]);
  });

  test('a PNG with no metadata is unchanged', () {
    final Uint8List png = _fixture('tiny.png');
    expect(stripPngMetadata(png), png);
  });

  test('a chunk with a bad CRC is a FormatException', () {
    final Uint8List input = Uint8List.fromList(_fixture('metadata.png'));
    // The last byte of IHDR's data.
    input[8 + 8 + 12] ^= 0xFF;
    expect(() => stripPngMetadata(input), throwsFormatException);
  });

  test('a PNG cut short is a FormatException', () {
    final Uint8List input = _fixture('metadata.png');
    expect(
      () => stripPngMetadata(Uint8List.sublistView(input, 0, input.length - 6)),
      throwsFormatException,
    );
  });

  test('bytes that are not a PNG are a FormatException', () {
    expect(
      () => stripPngMetadata(_fixture('plain.jpg')),
      throwsFormatException,
    );
  });

  test('the CRC is zlib\'s', () {
    expect(crc32(ascii.encode('IEND')), 0xAE426082);
    expect(crc32(ascii.encode('123456789')), 0xCBF43926);
  });
}
