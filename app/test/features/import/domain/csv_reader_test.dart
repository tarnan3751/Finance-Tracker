// Reading a file into rows: every fixture's encoding and delimiter, the Windows-1252
// fallback, CRLF and quoted fields, tiny chunks reading as one, and the header found past
// Bank of America's preamble and with Chase's trailing commas.
import 'dart:convert';
import 'dart:typed_data';

import 'package:finance_tracker/features/import/domain/csv_reader.dart';
import 'package:finance_tracker/features/import/domain/header_detection.dart';
import 'package:finance_tracker/features/import/domain/text_decoding.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

void main() {
  test('Chase: comma, UTF-8, a quoted comma, the header at row 0', () async {
    final CsvTable t = await readCsv(importFixture('chase_checking.csv'));
    expect(t.delimiter, ',');
    expect(t.encoding, ImportEncoding.utf8);
    expect(t.lossy, isFalse);
    expect(t.rows, hasLength(7));
    expect(t.rows[0].first, 'Details');
    expect(t.rows[1][2], 'NORTHWIND GROCERS #4411, SPRINGFIELD');
    expect(t.rows[1], hasLength(8));
    expect(findHeaderRow(t.rows), 0);
  });

  test('Bank of America: the header past the summary preamble', () async {
    final CsvTable t = await readCsv(importFixture('bofa_preamble.csv'));
    expect(t.delimiter, ',');
    final int header = findHeaderRow(t.rows)!;
    expect(t.rows[header], ['Date', 'Description', 'Amount', 'Running Bal.']);
    expect(t.rows[header + 2][2], '-35.99');
  });

  test('a European export: semicolons with decimal commas', () async {
    final CsvTable t = await readCsv(importFixture('european.csv'));
    expect(t.delimiter, ';');
    expect(t.rows[3][2], 'Contoso Café');
    expect(t.rows[3][4], 'Kaffee, groß');
    expect(t.rows[2][5], '2.450,00');
  });

  test('Monzo: comma, the header at row 0', () async {
    final CsvTable t = await readCsv(importFixture('monzo.csv'));
    expect(t.delimiter, ',');
    expect(findHeaderRow(t.rows), 0);
    expect(t.rows[1][10], '-3.20');
  });

  test('UTF-16 with its mark, and Windows-1252 by the fallback', () async {
    final CsvTable utf16 = await readCsv(importFixture('utf16le.csv'));
    expect(utf16.encoding, ImportEncoding.utf16le);
    expect(utf16.rows[1][1], 'Café Crème');
    expect(utf16.rows[3][1], 'Prix fixe 12€');
    final CsvTable latin = await readCsv(importFixture('latin1.csv'));
    expect(latin.encoding, ImportEncoding.windows1252);
    expect(latin.lossy, isTrue);
    expect(latin.rows[2][1], 'Müller Bäckerei');
    expect(latin.rows[3][1], 'Prix fixe 12€');
  });

  test('a UTF-8 mark is skipped; CRLF and blank lines; tiny chunks', () async {
    final Uint8List bytes = Uint8List.fromList([
      0xEF,
      0xBB,
      0xBF,
      ...utf8.encode('a,b,c\r\n1,"two\r\nlines",3\r\n\r\n"x ""y""",é,\r\n'),
    ]);
    final CsvTable whole = await readCsv(bytes);
    expect(whole.encoding, ImportEncoding.utf8Bom);
    expect(whole.rows, [
      ['a', 'b', 'c'],
      ['1', 'two\r\nlines', '3'],
      ['x "y"', 'é', ''],
    ]);
    for (final int size in [1, 2, 3, 7]) {
      expect((await readCsv(bytes, chunkBytes: size)).rows, whole.rows);
    }
  });

  test('a delimiter given is used', () async {
    final CsvTable t = await readCsv(
      Uint8List.fromList(utf8.encode('a;b,c;d\n1;2,3;4\n')),
      delimiter: ',',
    );
    expect(t.rows.first, ['a;b', 'c;d']);
  });

  test('detectDelimiter: the longest consistent run of three fields', () {
    expect(detectDelimiter('a|b|c\n1|2|3\n'), '|');
    expect(detectDelimiter('a\tb\tc\n1\t2,5\t3\n'), '\t');
    // A preamble of commas does not outvote the table.
    expect(
      detectDelimiter('Title, with, commas, here\n\nd;e;f\n1;2,5;3\n4;5,5;6\n'),
      ';',
    );
    expect(detectDelimiter('"a;b",c,d\n"1;2",3,4\n'), ',');
    expect(detectDelimiter('nothing here'), ',');
  });

  test('findHeaderRow: none without a table', () {
    expect(findHeaderRow(const []), isNull);
    expect(
      findHeaderRow(const [
        ['a', 'b', 'c'],
      ]),
      isNull,
    );
    expect(
      findHeaderRow(const [
        ['a', 'b', 'c'],
        ['1', '2'],
      ]),
      isNull,
    );
    expect(
      findHeaderRow(const [
        ['a', 'b', 'c'],
        ['1', '2', '3', 'x'],
      ]),
      isNull,
    );
  });
}
