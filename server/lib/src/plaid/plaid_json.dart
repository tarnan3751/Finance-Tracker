/// A JSON decoder that never builds a `double` (`docs/reference/server.md`, **Money from
/// Plaid**).
///
/// Plaid writes amounts as JSON numbers, and `jsonDecode` turns `12.50` into a `double`,
/// which `plaidMoney` refuses. [decodePlaidJson] reads a number as an `int` when it is an
/// integer that fits, and otherwise as its decimal text exactly as written (`"12.50"`,
/// `"1e3"`), which `plaidMoney` and `plaidDecimal` then check. Everything else decodes as
/// `jsonDecode` would: `Map<String, Object?>`, `List<Object?>`, `String`, `bool`, `null`.
/// The fake client reads the custom-user configurations through it; the real client
/// (lane 3b) reads Plaid's responses through it.
library;

import 'dart:convert';

/// [text] as JSON, numbers as an `int` or their text; a [FormatException] for anything
/// that is not one JSON value.
Object? decodePlaidJson(String text) {
  final reader = _Reader(text);
  reader.space();
  final value = reader.value();
  reader.space();
  if (!reader.atEnd) reader.fail('trailing text');
  return value;
}

final _number = RegExp(r'-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?');
final _integer = RegExp(r'^-?(0|[1-9][0-9]*)$');

final class _Reader {
  _Reader(this.text);

  final String text;
  var at = 0;

  bool get atEnd => at >= text.length;

  Never fail(String what) => throw FormatException('Bad JSON: $what', text, at);

  void space() {
    while (!atEnd && ' \t\n\r'.contains(text[at])) {
      at++;
    }
  }

  void expect(String token) {
    if (!text.startsWith(token, at)) fail('expected $token');
    at += token.length;
  }

  Object? value() {
    if (atEnd) fail('unexpected end');
    switch (text[at]) {
      case '{':
        return object();
      case '[':
        return array();
      case '"':
        return string();
      case 't':
        expect('true');
        return true;
      case 'f':
        expect('false');
        return false;
      case 'n':
        expect('null');
        return null;
      default:
        return number();
    }
  }

  Map<String, Object?> object() {
    expect('{');
    final map = <String, Object?>{};
    space();
    if (text.startsWith('}', at)) {
      at++;
      return map;
    }
    while (true) {
      space();
      final key = string();
      space();
      expect(':');
      space();
      map[key] = value();
      space();
      if (text.startsWith(',', at)) {
        at++;
        continue;
      }
      expect('}');
      return map;
    }
  }

  List<Object?> array() {
    expect('[');
    final list = <Object?>[];
    space();
    if (text.startsWith(']', at)) {
      at++;
      return list;
    }
    while (true) {
      space();
      list.add(value());
      space();
      if (text.startsWith(',', at)) {
        at++;
        continue;
      }
      expect(']');
      return list;
    }
  }

  String string() {
    if (atEnd || text[at] != '"') fail('expected a string');
    var end = at + 1;
    while (end < text.length && text[end] != '"') {
      end += text[end] == r'\' ? 2 : 1;
    }
    if (end >= text.length) fail('unterminated string');
    final token = text.substring(at, end + 1);
    at = end + 1;
    return jsonDecode(token) as String;
  }

  Object number() {
    final match = _number.matchAsPrefix(text, at);
    if (match == null) fail('unexpected character');
    at = match.end;
    final token = match[0]!;
    if (_integer.hasMatch(token)) return int.tryParse(token) ?? token;
    return token;
  }
}
