import 'package:finance_tracker_server/src/plaid/plaid_json.dart';
import 'package:finance_tracker_server/src/plaid/plaid_money.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  test('numbers come back as an int or their text, never a double', () {
    final json =
        decodePlaidJson(
              '{"a": 12.50, "b": -3, "c": 0.1, "d": 1e3, "e": 9223372036854775808,'
              ' "f": [1, 2.0, {"g": -0.25}]}',
            )!
            as Map<String, Object?>;
    expect(json['a'], '12.50');
    expect(json['b'], -3);
    expect(json['c'], '0.1');
    expect(json['d'], '1e3');
    expect(json['e'], '9223372036854775808');
    expect(json['f'], [
      1,
      '2.0',
      {'g': '-0.25'},
    ]);
    expect(plaidMoney(json['a']!, 'USD'), Money(1250, 'USD'));
  });

  test('everything else decodes as jsonDecode would', () {
    expect(
      decodePlaidJson(
        r' {"s": "a\"b\\u00e9\n", "t": true, "f": false, "n": null,'
        r' "e": {}, "l": []} ',
      ),
      {
        's': 'a"b\\u00e9\n',
        't': true,
        'f': false,
        'n': null,
        'e': <String, Object?>{},
        'l': <Object?>[],
      },
    );
    expect(decodePlaidJson('"\\u00e9"'), 'é');
  });

  test('malformed text is a FormatException', () {
    for (final text in [
      '',
      '{',
      '{"a" 1}',
      '[1,]',
      '01',
      '1.',
      '"open',
      '{"a": 1} x',
      'nul',
      '+1',
    ]) {
      expect(() => decodePlaidJson(text), throwsFormatException, reason: text);
    }
  });
}
