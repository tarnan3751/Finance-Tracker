/// The one JSON writer every output goes through, so the bytes are a function of the
/// value alone: maps in their insertion order (the code builds them in a fixed order),
/// two-space indentation, `\n` line ends and a final newline.
///
/// Plaid's Sandbox takes amounts as JSON numbers. `dart:convert` can only write a number
/// from a `num`, which would route money through a `double`; [JsonDecimal] carries the
/// number's text instead (from `Money.toDecimalString()`), and the writer emits it as is.
library;

import 'dart:convert';

import 'package:meta/meta.dart';

final RegExp _jsonNumber = RegExp(r'^-?(0|[1-9][0-9]*)(\.[0-9]+)?$');

/// A JSON number written from its decimal text.
@immutable
final class JsonDecimal {
  /// A number; [text] must be a plain JSON decimal such as `-12.50`.
  JsonDecimal(this.text) {
    if (!_jsonNumber.hasMatch(text)) {
      throw FormatException('Not a JSON decimal', text);
    }
  }

  /// The number's text.
  final String text;
}

/// [value] as JSON: `Map<String, Object?>`, `List<Object?>`, `String`, `int`, `bool`,
/// `null` and [JsonDecimal]. Anything else, a `double` included, is an [ArgumentError].
/// [pretty] indents by two spaces and ends with a newline; otherwise the output is compact.
String writeJson(Object? value, {bool pretty = true}) {
  final out = StringBuffer();
  _write(out, value, pretty ? '' : null);
  if (pretty) out.write('\n');
  return out.toString();
}

void _write(StringBuffer out, Object? value, String? indent) {
  switch (value) {
    case null:
      out.write('null');
    case final bool b:
      out.write(b ? 'true' : 'false');
    case final int i:
      out.write(i.toString());
    case final String s:
      out.write(jsonEncode(s));
    case final JsonDecimal d:
      out.write(d.text);
    case final Map<String, Object?> m:
      if (m.isEmpty) {
        out.write('{}');
        return;
      }
      final inner = indent == null ? null : '$indent  ';
      out.write('{');
      var first = true;
      for (final entry in m.entries) {
        if (!first) out.write(',');
        first = false;
        if (inner != null) out.write('\n$inner');
        out.write(jsonEncode(entry.key));
        out.write(inner == null ? ':' : ': ');
        _write(out, entry.value, inner);
      }
      if (indent != null) out.write('\n$indent');
      out.write('}');
    case final List<Object?> l:
      if (l.isEmpty) {
        out.write('[]');
        return;
      }
      final inner = indent == null ? null : '$indent  ';
      out.write('[');
      for (var i = 0; i < l.length; i++) {
        if (i > 0) out.write(',');
        if (inner != null) out.write('\n$inner');
        _write(out, l[i], inner);
      }
      if (indent != null) out.write('\n$indent');
      out.write(']');
    default:
      throw ArgumentError.value(value, 'value', 'not writable as JSON');
  }
}

/// [value] scaled down by [scale] decimal digits as a [JsonDecimal]: basis points at
/// scale 2 are a percentage (`625` is `6.25`), thousandths of a share at scale 3 a
/// quantity.
JsonDecimal scaledDecimal(int value, int scale) {
  final negative = value < 0;
  final digits = (negative ? -value : value).toString().padLeft(scale + 1, '0');
  final whole = digits.substring(0, digits.length - scale);
  final fraction = digits.substring(digits.length - scale);
  final text = scale == 0 ? whole : '$whole.$fraction';
  return JsonDecimal(negative ? '-$text' : text);
}
