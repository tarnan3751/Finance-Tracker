/// How an imported file's bytes become text (`docs/reference/import.md`, **Reading the
/// file**). Pure Dart.
///
/// The first bytes are sniffed for a byte order mark: `EF BB BF` is UTF-8, `FF FE` UTF-16
/// little-endian and `FE FF` UTF-16 big-endian, each read without its mark. A file with
/// no mark is read as strict UTF-8; when that fails, as Windows-1252, the 8-bit encoding
/// banks' "Latin-1" exports nearly always are (Latin-1 with printable characters, `€`
/// among them, at 0x80 to 0x9F), and the review says accented characters may be wrong.
/// `dart:convert` has no UTF-16 or Windows-1252 decoder, so both are here.
library;

import 'dart:convert';

/// The text encoding a file is read in.
enum ImportEncoding {
  /// UTF-8 with no byte order mark.
  utf8,

  /// UTF-8 after its byte order mark.
  utf8Bom,

  /// UTF-16 little-endian after its byte order mark.
  utf16le,

  /// UTF-16 big-endian after its byte order mark.
  utf16be,

  /// Windows-1252, the fallback when strict UTF-8 fails.
  windows1252;

  /// How many bytes its byte order mark takes.
  int get markLength => switch (this) {
    utf8Bom => 3,
    utf16le || utf16be => 2,
    utf8 || windows1252 => 0,
  };

  /// The decoder of the bytes after the mark: strict for UTF-8, so a file in another
  /// encoding fails with a [FormatException].
  Converter<List<int>, String> get decoder => switch (this) {
    utf8 || utf8Bom => const Utf8Decoder(),
    utf16le => const Utf16Decoder(littleEndian: true),
    utf16be => const Utf16Decoder(littleEndian: false),
    windows1252 => const Windows1252Decoder(),
  };
}

/// The encoding [head], a file's first bytes, announces with a byte order mark, else
/// [ImportEncoding.utf8].
ImportEncoding sniffEncoding(List<int> head) {
  bool startsWith(List<int> mark) {
    if (head.length < mark.length) return false;
    for (int i = 0; i < mark.length; i++) {
      if (head[i] != mark[i]) return false;
    }
    return true;
  }

  if (startsWith(const [0xEF, 0xBB, 0xBF])) return ImportEncoding.utf8Bom;
  if (startsWith(const [0xFF, 0xFE])) return ImportEncoding.utf16le;
  if (startsWith(const [0xFE, 0xFF])) return ImportEncoding.utf16be;
  return ImportEncoding.utf8;
}

/// UTF-16 in either byte order, by chunks: a byte left over at the end of a chunk is
/// carried to the next, and one left at the end of the input is U+FFFD. Code units pass
/// as they are, surrogate pairs included (a Dart string is UTF-16).
final class Utf16Decoder extends Converter<List<int>, String> {
  /// The decoder of [littleEndian] or big-endian bytes.
  const Utf16Decoder({required this.littleEndian});

  /// Whether the low byte of each code unit comes first.
  final bool littleEndian;

  @override
  String convert(List<int> input) {
    final StringBuffer out = StringBuffer();
    final _Utf16Sink sink = _Utf16Sink(_BufferSink(out), littleEndian)
      ..add(input)
      ..close();
    assert(sink._pending == null);
    return out.toString();
  }

  @override
  Sink<List<int>> startChunkedConversion(Sink<String> sink) =>
      _Utf16Sink(sink, littleEndian);
}

final class _Utf16Sink implements Sink<List<int>> {
  _Utf16Sink(this._out, this._littleEndian);

  final Sink<String> _out;
  final bool _littleEndian;
  int? _pending;

  @override
  void add(List<int> chunk) {
    final List<int> units = [];
    int i = 0;
    final int? pending = _pending;
    if (pending != null && chunk.isNotEmpty) {
      units.add(_unit(pending, chunk[0]));
      i = 1;
      _pending = null;
    }
    for (; i + 1 < chunk.length; i += 2) {
      units.add(_unit(chunk[i], chunk[i + 1]));
    }
    if (i < chunk.length) _pending = chunk[i];
    if (units.isNotEmpty) _out.add(String.fromCharCodes(units));
  }

  int _unit(int first, int second) =>
      _littleEndian ? first | (second << 8) : (first << 8) | second;

  @override
  void close() {
    if (_pending != null) {
      _out.add('�');
      _pending = null;
    }
    _out.close();
  }
}

final class _BufferSink implements Sink<String> {
  _BufferSink(this._buffer);

  final StringBuffer _buffer;

  @override
  void add(String data) => _buffer.write(data);

  @override
  void close() {}
}

/// Windows-1252: Latin-1, except 0x80 to 0x9F, which are printable characters (the five
/// bytes Windows-1252 leaves undefined stay their Latin-1 control characters).
final class Windows1252Decoder extends Converter<List<int>, String> {
  /// The decoder.
  const Windows1252Decoder();

  @override
  String convert(List<int> input) =>
      String.fromCharCodes([for (final int b in input) _char(b)]);

  @override
  Sink<List<int>> startChunkedConversion(Sink<String> sink) =>
      _Windows1252Sink(sink, this);

  static int _char(int byte) =>
      byte >= 0x80 && byte <= 0x9F ? _high[byte - 0x80] : byte & 0xFF;

  // 0x80 to 0x9F; 0x81, 0x8D, 0x8F, 0x90 and 0x9D are undefined and kept.
  static const List<int> _high = [
    0x20AC, 0x0081, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, //
    0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x008D, 0x017D, 0x008F, //
    0x0090, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014, //
    0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x009D, 0x017E, 0x0178, //
  ];
}

final class _Windows1252Sink implements Sink<List<int>> {
  _Windows1252Sink(this._out, this._decoder);

  final Sink<String> _out;
  final Windows1252Decoder _decoder;

  @override
  void add(List<int> chunk) => _out.add(_decoder.convert(chunk));

  @override
  void close() => _out.close();
}
