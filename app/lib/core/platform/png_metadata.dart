/// Metadata out of a PNG before it is stored (`docs/reference/app-core.md`, **The image
/// source**): `image_picker` re-encodes a photo with transparency as a PNG and copies the
/// original's EXIF (its GPS position, device and timestamps) into it. Every ancillary
/// chunk is dropped (eXIf, tEXt, iTXt, zTXt, tIME and the rest) except the ones that
/// say how to show the image: gAMA, cHRM, sRGB, iCCP, pHYs and tRNS. The critical chunks
/// are kept as they are; nothing after IEND is. Pure Dart, a chunk walker that checks
/// every chunk's length and CRC. A PNG has no orientation to keep: the plugin applied it
/// when it re-encoded.
library;

import 'dart:typed_data';

/// The eight bytes every PNG starts with.
const List<int> pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

/// The ancillary chunks a stored PNG keeps: how to show the image, nothing about where,
/// when or with what it was taken.
const Set<String> keptAncillaryChunks = {
  'gAMA',
  'cHRM',
  'sRGB',
  'iCCP',
  'pHYs',
  'tRNS',
};

/// Whether [bytes] start with the PNG signature.
bool isPng(Uint8List bytes) {
  if (bytes.length < pngSignature.length) return false;
  for (int i = 0; i < pngSignature.length; i++) {
    if (bytes[i] != pngSignature[i]) return false;
  }
  return true;
}

/// [bytes], a PNG, with its critical chunks and [keptAncillaryChunks] only, up to and
/// including IEND. Throws a [FormatException] when [bytes] is not a PNG, a chunk runs
/// past the end or fails its CRC, or there is no IHDR first or no IEND.
Uint8List stripPngMetadata(Uint8List bytes) {
  if (!isPng(bytes)) throw const FormatException('PNG: no signature');
  final ByteData data = ByteData.sublistView(bytes);
  final BytesBuilder out = BytesBuilder(copy: false)
    ..add(Uint8List.sublistView(bytes, 0, pngSignature.length));
  int i = pngSignature.length;
  bool first = true;
  while (true) {
    if (i + 12 > bytes.length) throw const FormatException('PNG: cut short');
    final int length = data.getUint32(i);
    final int end = i + 12 + length;
    if (length > 0x7FFFFFFF || end > bytes.length) {
      throw const FormatException('PNG: a chunk runs past the end');
    }
    final Uint8List typeAndData = Uint8List.sublistView(
      bytes,
      i + 4,
      i + 8 + length,
    );
    if (crc32(typeAndData) != data.getUint32(i + 8 + length)) {
      throw const FormatException('PNG: a chunk fails its CRC');
    }
    final String type = String.fromCharCodes(bytes, i + 4, i + 8);
    if (first && type != 'IHDR') throw const FormatException('PNG: no IHDR');
    first = false;
    // Bit 5 of the first byte: lower case is ancillary, upper case critical.
    final bool ancillary = bytes[i + 4] & 0x20 != 0;
    if (!ancillary || keptAncillaryChunks.contains(type)) {
      out.add(Uint8List.sublistView(bytes, i, end));
    }
    if (type == 'IEND') return out.takeBytes();
    i = end;
  }
}

final Uint32List _crcTable = () {
  final Uint32List table = Uint32List(256);
  for (int n = 0; n < 256; n++) {
    int c = n;
    for (int k = 0; k < 8; k++) {
      c = c & 1 != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    table[n] = c;
  }
  return table;
}();

/// The CRC-32 of [bytes] as PNG computes it (ISO 3309, as in zlib).
int crc32(List<int> bytes) {
  int c = 0xFFFFFFFF;
  for (final int b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}
