// The canonical JSON writer and its raw decimals.
import 'dart:convert';

import 'package:persona_engine/persona_engine.dart';
import 'package:test/test.dart';

void main() {
  test('pretty output: two-space indent, insertion order, final newline', () {
    final text = writeJson({
      'b': 1,
      'a': [true, null, 'x\n"y"'],
      'e': <String, Object?>{},
      'l': <Object?>[],
    });
    expect(
      text,
      '{\n'
      '  "b": 1,\n'
      '  "a": [\n'
      '    true,\n'
      '    null,\n'
      '    "x\\n\\"y\\""\n'
      '  ],\n'
      '  "e": {},\n'
      '  "l": []\n'
      '}\n',
    );
    expect(jsonDecode(text), isA<Map<String, Object?>>());
  });

  test('compact output has no whitespace', () {
    expect(
      writeJson({
        'a': [1, JsonDecimal('-12.50')],
      }, pretty: false),
      '{"a":[1,-12.50]}',
    );
  });

  test('a decimal is written as its text and must be a plain JSON decimal', () {
    expect(writeJson(JsonDecimal('1234.56'), pretty: false), '1234.56');
    for (final bad in ['1e5', '01', '.5', '1.', '+1', 'NaN', '']) {
      expect(() => JsonDecimal(bad), throwsFormatException, reason: bad);
    }
  });

  test('a double is refused', () {
    expect(() => writeJson({'x': 1.5}), throwsArgumentError);
  });

  test('scaledDecimal', () {
    expect(scaledDecimal(625, 2).text, '6.25');
    expect(scaledDecimal(5, 2).text, '0.05');
    expect(scaledDecimal(-5, 3).text, '-0.005');
    expect(scaledDecimal(12345, 3).text, '12.345');
    expect(scaledDecimal(7, 0).text, '7');
  });
}
