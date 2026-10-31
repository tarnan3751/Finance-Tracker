// The import's decoding: the byte order marks are sniffed, UTF-16 is read in both orders
// with a code unit split across chunks, and Windows-1252 reads 0x80 to 0x9F as their
// printable characters.
import 'dart:convert';

import 'package:finance_tracker/features/import/domain/text_decoding.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sniffs the byte order marks', () {
    expect(sniffEncoding([0xEF, 0xBB, 0xBF, 0x41]), ImportEncoding.utf8Bom);
    expect(sniffEncoding([0xFF, 0xFE, 0x41, 0]), ImportEncoding.utf16le);
    expect(sniffEncoding([0xFE, 0xFF, 0, 0x41]), ImportEncoding.utf16be);
    expect(sniffEncoding([0x41, 0x42]), ImportEncoding.utf8);
    expect(sniffEncoding([0xEF]), ImportEncoding.utf8);
    expect(sniffEncoding(const []), ImportEncoding.utf8);
  });

  test('UTF-16 in both orders, a code unit split across chunks', () async {
    const String text = 'Café, 12€ 😀';
    final List<int> units = text.codeUnits;
    final List<int> le = [
      for (final u in units) ...[u & 0xFF, u >> 8],
    ];
    final List<int> be = [
      for (final u in units) ...[u >> 8, u & 0xFF],
    ];
    expect(const Utf16Decoder(littleEndian: true).convert(le), text);
    expect(const Utf16Decoder(littleEndian: false).convert(be), text);
    final String chunked = await Stream.fromIterable([
      le.sublist(0, 3),
      le.sublist(3, 4),
      le.sublist(4, 11),
      le.sublist(11),
    ]).transform(const Utf16Decoder(littleEndian: true)).join();
    expect(chunked, text);
    expect(
      const Utf16Decoder(littleEndian: true).convert([0x41, 0, 0x42]),
      'A�',
    );
  });

  test('Windows-1252 reads the euro and the curly quotes', () {
    expect(
      const Windows1252Decoder().convert([0x80, 0x93, 0x94, 0xE9, 0x41, 0x81]),
      '€“”éA\u0081',
    );
  });

  test('the UTF-8 decoders are strict', () {
    expect(
      () => ImportEncoding.utf8.decoder.convert([0x43, 0xE9, 0x43]),
      throwsFormatException,
    );
    expect(ImportEncoding.utf8Bom.decoder.convert(utf8.encode('é')), 'é');
  });
}
