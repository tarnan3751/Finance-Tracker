/// Camera metadata out of a JPEG before it is stored (`docs/reference/app-core.md`,
/// **The image source**): every APP1 to APP15 segment (EXIF with its GPS, device and
/// timestamps, XMP, ICC profiles, maker notes) is dropped, and the EXIF orientation alone
/// is written back as a minimal APP1, so a portrait still displays upright. Pure Dart, a
/// segment walker over the bytes; the image data itself is copied untouched.
library;

import 'dart:typed_data';

/// [bytes] without its APP1 to APP15 segments, with the EXIF orientation (when one was
/// there and is not the default 1) rewritten as a minimal APP1 after the SOI and any
/// APP0 (JFIF). Throws a [FormatException] for bytes that are not a JPEG ([isJpeg]) and
/// for a JPEG whose segments are cut short or malformed before the start of scan.
Uint8List stripJpegMetadata(Uint8List bytes) {
  if (!isJpeg(bytes)) throw const FormatException('JPEG: no SOI marker');
  final List<Uint8List> kept = [];
  // Where the orientation segment goes: after the leading APP0 segments.
  int? insertAt;
  int? orientation;
  int i = 2;
  while (true) {
    if (i >= bytes.length || bytes[i] != 0xFF) {
      throw const FormatException('JPEG: expected a marker');
    }
    // A marker may be preceded by fill bytes (0xFF).
    int m = i + 1;
    while (m < bytes.length && bytes[m] == 0xFF) {
      m++;
    }
    if (m >= bytes.length) throw const FormatException('JPEG: cut short');
    final int marker = bytes[m];
    if (marker == 0xDA || marker == 0xD9) {
      // The start of scan (or an early end of image): the rest is image data.
      insertAt ??= kept.length;
      kept.add(Uint8List.sublistView(bytes, i));
      break;
    }
    if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
      // A marker with no length.
      insertAt ??= kept.length;
      kept.add(Uint8List.sublistView(bytes, i, m + 1));
      i = m + 1;
      continue;
    }
    if (m + 2 >= bytes.length) throw const FormatException('JPEG: cut short');
    final int length = bytes[m + 1] << 8 | bytes[m + 2];
    final int end = m + 1 + length;
    if (length < 2 || end > bytes.length) {
      throw const FormatException('JPEG: a segment runs past the end');
    }
    if (marker >= 0xE1 && marker <= 0xEF) {
      if (marker == 0xE1) orientation ??= _exifOrientation(bytes, m + 3, end);
    } else {
      if (marker != 0xE0) insertAt ??= kept.length;
      kept.add(Uint8List.sublistView(bytes, i, end));
    }
    i = end;
  }
  final BytesBuilder out = BytesBuilder(copy: false)
    ..add(Uint8List.sublistView(bytes, 0, 2));
  for (int k = 0; k < kept.length; k++) {
    if (k == insertAt && orientation != null && orientation != 1) {
      out.add(orientationSegment(orientation));
    }
    out.add(kept[k]);
  }
  return out.takeBytes();
}

/// The minimal APP1 holding EXIF [orientation] (1 to 8) alone: the `Exif\0\0` header, a
/// big-endian TIFF header and an IFD0 with the one tag 0x0112.
Uint8List orientationSegment(int orientation) {
  if (orientation < 1 || orientation > 8) {
    throw ArgumentError.value(orientation, 'orientation', 'must be 1 to 8');
  }
  return Uint8List.fromList([
    0xFF, 0xE1, 0x00, 0x22, // APP1, 34 bytes long with the length
    0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // Exif\0\0
    0x4D, 0x4D, 0x00, 0x2A, 0x00, 0x00, 0x00, 0x08, // MM, 42, IFD0 at 8
    0x00, 0x01, // one entry
    0x01,
    0x12,
    0x00,
    0x03,
    0x00,
    0x00,
    0x00,
    0x01, // orientation, SHORT, count 1
    0x00, orientation, 0x00, 0x00, // its value
    0x00, 0x00, 0x00, 0x00, // no next IFD
  ]);
}

/// Whether [bytes] start with a JPEG's SOI marker.
bool isJpeg(Uint8List bytes) =>
    bytes.length >= 4 && bytes[0] == 0xFF && bytes[1] == 0xD8;

// The orientation in the EXIF payload of an APP1 at [start] (just past its length) to
// [end], or null when it is not EXIF, names none, or is malformed.
int? _exifOrientation(Uint8List bytes, int start, int end) {
  const List<int> header = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00];
  final int tiff = start + header.length;
  if (tiff + 8 > end) return null;
  for (int k = 0; k < header.length; k++) {
    if (bytes[start + k] != header[k]) return null;
  }
  final Endian endian;
  if (bytes[tiff] == 0x49 && bytes[tiff + 1] == 0x49) {
    endian = Endian.little;
  } else if (bytes[tiff] == 0x4D && bytes[tiff + 1] == 0x4D) {
    endian = Endian.big;
  } else {
    return null;
  }
  final ByteData data = ByteData.sublistView(bytes, tiff, end);
  if (data.getUint16(2, endian) != 42) return null;
  final int ifd = data.getUint32(4, endian);
  if (ifd + 2 > data.lengthInBytes) return null;
  final int count = data.getUint16(ifd, endian);
  for (int k = 0; k < count; k++) {
    final int entry = ifd + 2 + 12 * k;
    if (entry + 12 > data.lengthInBytes) return null;
    if (data.getUint16(entry, endian) != 0x0112) continue;
    // A SHORT, count 1: the value sits in the first two bytes of the value field.
    if (data.getUint16(entry + 2, endian) != 3) return null;
    if (data.getUint32(entry + 4, endian) < 1) return null;
    final int value = data.getUint16(entry + 8, endian);
    return value >= 1 && value <= 8 ? value : null;
  }
  return null;
}
