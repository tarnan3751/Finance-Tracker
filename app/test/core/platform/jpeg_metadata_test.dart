// Camera metadata out of a JPEG: every APP1 to APP15 segment goes (EXIF with GPS, device
// and timestamps, XMP, ICC), the orientation alone comes back as a minimal APP1 after the
// JFIF segment, the image data is untouched and still decodes; a JPEG with no EXIF passes
// through unchanged; a JPEG cut short, or bytes that are not a JPEG, are a
// FormatException.
//
// Fixtures (test/fixtures/receipts/, drawn for these tests): exif_gps_orientation6.jpg,
// 32x16 with a big-endian EXIF (orientation 6, make "FixtureCam", model, date and a GPS
// position) and an XMP APP1; plain.jpg, 16x16 with JFIF only; tiny.png, a PNG.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:finance_tracker/core/platform/jpeg_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _fixture(String name) =>
    File('test/fixtures/receipts/$name').readAsBytesSync();

/// The markers of [jpeg]'s segments before the start of scan, in order.
List<int> _markers(Uint8List jpeg) {
  final List<int> markers = [];
  int i = 2;
  while (jpeg[i + 1] != 0xDA) {
    markers.add(jpeg[i + 1]);
    i += 2 + (jpeg[i + 2] << 8 | jpeg[i + 3]);
  }
  return markers;
}

/// Whether [haystack] holds the bytes of [needle].
bool _contains(Uint8List haystack, List<int> needle) {
  outer:
  for (int i = 0; i + needle.length <= haystack.length; i++) {
    for (int k = 0; k < needle.length; k++) {
      if (haystack[i + k] != needle[k]) continue outer;
    }
    return true;
  }
  return false;
}

/// The image data: everything from the start of scan on.
Uint8List _scan(Uint8List jpeg) {
  int i = 2;
  while (jpeg[i + 1] != 0xDA) {
    i += 2 + (jpeg[i + 2] << 8 | jpeg[i + 3]);
  }
  return Uint8List.sublistView(jpeg, i);
}

/// [jpeg] with [segment] inserted right after its SOI.
Uint8List _withSegment(Uint8List jpeg, List<int> segment) =>
    Uint8List.fromList([...jpeg.sublist(0, 2), ...segment, ...jpeg.sublist(2)]);

/// A little-endian EXIF APP1 with a make and orientation [orientation].
List<int> _littleEndianExif(int orientation) {
  final List<int> make = [...ascii.encode('LittleCam'), 0];
  final List<int> tiff = [
    0x49, 0x49, 0x2A, 0x00, 0x08, 0x00, 0x00, 0x00, // II, 42, IFD0 at 8
    0x02, 0x00, // two entries
    0x0F, 0x01, 0x02, 0x00, make.length, 0x00, 0x00, 0x00, 0x26, 0x00, 0x00,
    0x00, // make, ASCII, at 38
    0x12, 0x01, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00, orientation, 0x00, 0x00,
    0x00, // orientation
    0x00, 0x00, 0x00, 0x00, // no next IFD
    ...make,
  ];
  final List<int> payload = [...ascii.encode('Exif'), 0, 0, ...tiff];
  final int length = payload.length + 2;
  return [0xFF, 0xE1, length >> 8, length & 0xFF, ...payload];
}

void main() {
  test('a JPEG with GPS and orientation 6 keeps orientation 6 alone', () {
    final Uint8List input = _fixture('exif_gps_orientation6.jpg');
    // The fixture is what it says.
    expect(_markers(input).where((m) => m == 0xE1), hasLength(2));
    expect(_contains(input, ascii.encode('FixtureCam')), isTrue);

    final Uint8List output = stripJpegMetadata(input);

    expect(output.sublist(0, 2), [0xFF, 0xD8]);
    // JFIF first, then the one APP1, then the tables.
    final List<int> markers = _markers(output);
    expect(markers.first, 0xE0);
    expect(markers[1], 0xE1);
    expect(markers.where((m) => m >= 0xE1 && m <= 0xEF), [0xE1]);
    expect(_contains(output, orientationSegment(6)), isTrue);
    for (final String gone in [
      'FixtureCam',
      'Fixture Model',
      '2026:10:24',
      'adobe:ns:meta',
    ]) {
      expect(_contains(output, ascii.encode(gone)), isFalse, reason: gone);
    }
    // The GPS IFD pointer tag (0x8825) is gone with the EXIF it was in.
    expect(_contains(output, [0x88, 0x25]), isFalse);
    expect(_scan(output), _scan(input));
  });

  testWidgets('the stripped JPEG still decodes at its size', (tester) async {
    final Uint8List output = stripJpegMetadata(
      _fixture('exif_gps_orientation6.jpg'),
    );
    final ui.Image? image = await tester.runAsync(() async {
      final ui.Codec codec = await ui.instantiateImageCodec(output);
      return (await codec.getNextFrame()).image;
    });
    // Orientation 6 is a quarter turn: the decoder applies it, so 32x16 reads as 16x32.
    expect([image!.width, image.height], [16, 32]);
  });

  test('a little-endian EXIF keeps its orientation too', () {
    final Uint8List input = _withSegment(
      _fixture('plain.jpg'),
      _littleEndianExif(3),
    );
    final Uint8List output = stripJpegMetadata(input);

    expect(_contains(output, ascii.encode('LittleCam')), isFalse);
    expect(_contains(output, orientationSegment(3)), isTrue);
  });

  test('orientation 1, the default, is not written back', () {
    final Uint8List plain = _fixture('plain.jpg');
    final Uint8List output = stripJpegMetadata(
      _withSegment(plain, _littleEndianExif(1)),
    );

    expect(output, plain);
  });

  test('every APP segment from APP2 to APP15 goes, APP0 stays', () {
    final Uint8List plain = _fixture('plain.jpg');
    Uint8List input = plain;
    for (int marker = 0xE2; marker <= 0xEF; marker++) {
      input = _withSegment(input, [0xFF, marker, 0x00, 0x05, 0x41, 0x42, 0x43]);
    }
    expect(stripJpegMetadata(input), plain);
  });

  test('a JPEG with no EXIF is unchanged', () {
    final Uint8List plain = _fixture('plain.jpg');
    expect(stripJpegMetadata(plain), plain);
  });

  test('bytes that are not a JPEG are a FormatException', () {
    expect(
      () => stripJpegMetadata(_fixture('tiny.png')),
      throwsFormatException,
    );
  });

  test('a JPEG cut short is a FormatException', () {
    final Uint8List input = _fixture('exif_gps_orientation6.jpg');
    expect(
      () => stripJpegMetadata(Uint8List.sublistView(input, 0, 40)),
      throwsFormatException,
    );
  });

  test('an orientation outside 1 to 8 has no segment', () {
    expect(() => orientationSegment(9), throwsArgumentError);
  });
}
