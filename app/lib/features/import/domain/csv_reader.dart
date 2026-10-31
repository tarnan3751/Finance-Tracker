/// A CSV file read into rows of text (`docs/reference/import.md`, **Reading the file**).
/// Pure Dart.
///
/// The bytes are decoded as [sniffEncoding] says (strict UTF-8 falling back to
/// Windows-1252), then parsed as a stream by the `csv` package, one row per event, every
/// field kept as text, never typed; blank lines are skipped. The delimiter is the one
/// given, else [detectDelimiter]'s.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:finance_tracker/features/import/domain/text_decoding.dart';

/// The delimiters an import reads, in the order a tie is broken.
const List<String> csvDelimiters = [',', ';', '\t', '|'];

/// How many decoded characters [detectDelimiter] looks at.
const int delimiterSampleLength = 64 * 1024;

/// A file read into rows.
final class CsvTable {
  /// The rows of a file.
  const CsvTable({
    required this.rows,
    required this.delimiter,
    required this.encoding,
  });

  /// The rows, each a list of fields as text; blank lines are not rows.
  final List<List<String>> rows;

  /// The delimiter the rows were split on.
  final String delimiter;

  /// The encoding the file was read in.
  final ImportEncoding encoding;

  /// Whether the text was read in the 8-bit fallback, so accented characters may be
  /// wrong.
  bool get lossy => encoding == ImportEncoding.windows1252;
}

/// Reads [bytes] as CSV, split on [delimiter] or the one detected, feeding the parser
/// [chunkBytes] at a time.
Future<CsvTable> readCsv(
  Uint8List bytes, {
  String? delimiter,
  int chunkBytes = 64 * 1024,
}) async {
  final ImportEncoding sniffed = sniffEncoding(bytes);
  try {
    return await _read(bytes, sniffed, delimiter, chunkBytes);
  } on FormatException {
    if (sniffed != ImportEncoding.utf8) rethrow;
    return _read(bytes, ImportEncoding.windows1252, delimiter, chunkBytes);
  }
}

Future<CsvTable> _read(
  Uint8List bytes,
  ImportEncoding encoding,
  String? delimiter,
  int chunkBytes,
) async {
  final Uint8List body = Uint8List.sublistView(bytes, encoding.markLength);
  final String chosen = delimiter ?? detectDelimiter(_sample(body, encoding));
  final Stream<List<int>> chunks = Stream.fromIterable([
    for (int at = 0; at < body.length; at += chunkBytes)
      Uint8List.sublistView(
        body,
        at,
        at + chunkBytes > body.length ? body.length : at + chunkBytes,
      ),
  ]);
  final List<List<String>> rows = [
    await for (final List<dynamic> row
        in chunks
            .transform(encoding.decoder)
            .transform(CsvDecoder(fieldDelimiter: chosen)))
      [for (final Object? field in row) field.toString()],
  ];
  return CsvTable(rows: rows, delimiter: chosen, encoding: encoding);
}

// The first characters of [body], decoded leniently: a sample may end inside a character.
String _sample(Uint8List body, ImportEncoding encoding) {
  final int end = body.length < delimiterSampleLength * 2
      ? body.length
      : delimiterSampleLength * 2;
  final Uint8List head = Uint8List.sublistView(body, 0, end);
  final String text = switch (encoding) {
    ImportEncoding.utf8 || ImportEncoding.utf8Bom => const Utf8Decoder(
      allowMalformed: true,
    ).convert(head),
    _ => encoding.decoder.convert(head),
  };
  return text.length > delimiterSampleLength
      ? text.substring(0, delimiterSampleLength)
      : text;
}

/// The delimiter of [sample], the start of a file's text: the one of [csvDelimiters]
/// that splits the longest run of consecutive records into the same number of fields, at
/// least three, quotes respected (so a preamble or a comma in a quoted description does
/// not decide it); the longer run wins, then the more fields, then the earlier delimiter.
/// A comma when none splits a record into three.
String detectDelimiter(String sample) {
  String best = csvDelimiters.first;
  (int, int) bestScore = (0, 0);
  for (final String delimiter in csvDelimiters) {
    final (int, int) score = _score(_fieldCounts(sample, delimiter));
    if (score.$1 > bestScore.$1 ||
        (score.$1 == bestScore.$1 && score.$2 > bestScore.$2)) {
      best = delimiter;
      bestScore = score;
    }
  }
  return best;
}

// The longest run of equal counts of at least 3, and that count.
(int, int) _score(List<int> counts) {
  (int, int) best = (0, 0);
  int run = 0;
  for (int i = 0; i < counts.length; i++) {
    run = i > 0 && counts[i] == counts[i - 1] ? run + 1 : 1;
    if (counts[i] >= 3 &&
        (run > best.$1 || (run == best.$1 && counts[i] > best.$2))) {
      best = (run, counts[i]);
    }
  }
  return best;
}

// The number of fields of each non-blank record of [text] split on [delimiter].
List<int> _fieldCounts(String text, String delimiter) {
  final int d = delimiter.codeUnitAt(0);
  const int quote = 0x22, cr = 0x0D, lf = 0x0A;
  final List<int> counts = [];
  bool quoted = false;
  bool blank = true;
  int fields = 1;
  for (int i = 0; i < text.length; i++) {
    final int c = text.codeUnitAt(i);
    if (c == quote) {
      quoted = !quoted;
      blank = false;
    } else if (!quoted && (c == cr || c == lf)) {
      if (!blank) counts.add(fields);
      blank = true;
      fields = 1;
    } else if (!quoted && c == d) {
      fields++;
      blank = false;
    } else {
      blank = false;
    }
  }
  if (!blank) counts.add(fields);
  return counts;
}
