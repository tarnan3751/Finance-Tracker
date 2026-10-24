import 'package:finance_tracker_server/src/plaid/plaid_money.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  test('decimal text and ints become minor units at the currency scale', () {
    for (final (value, currency, minor) in <(Object, String, int)>[
      ('12.34', 'USD', 1234),
      ('-12.5', 'USD', -1250),
      ('0', 'USD', 0),
      ('0.01', 'USD', 1),
      ('1450', 'USD', 145000),
      (1450, 'USD', 145000),
      (-3, 'USD', -300),
      ('12.340000', 'USD', 1234),
      ('1500', 'JPY', 1500),
      ('1.234', 'KWD', 1234),
      ('92233720368547758.07', 'USD', 9223372036854775807),
    ]) {
      expect(
        plaidMoney(value, currency),
        Money(minor, currency),
        reason: '$value',
      );
    }
  });

  test('never a double, never a round', () {
    expect(() => plaidMoney(12.34, 'USD'), throwsArgumentError);
    expect(() => plaidMoney('12.345', 'USD'), throwsFormatException);
    expect(() => plaidMoney('1.5', 'JPY'), throwsFormatException);
  });

  test('rejects text that is not a plain decimal', () {
    for (final text in [
      '',
      '1e3',
      '+1',
      '01',
      '1.',
      '.5',
      '1,000',
      ' 1',
      'NaN',
      '92233720368547758.08',
    ]) {
      expect(
        () => plaidMoney(text, 'USD'),
        throwsFormatException,
        reason: text,
      );
    }
  });

  test('optionalPlaidMoney and plaidDecimal', () {
    expect(optionalPlaidMoney(null, 'USD'), isNull);
    expect(plaidDecimal('10.4234'), '10.4234');
    expect(plaidDecimal(3), '3');
    expect(() => plaidDecimal(1.5), throwsFormatException);
  });

  test("plaidColor reads Plaid's #rrggbb as opaque ARGB", () {
    expect(plaidColor('#0075a3'), 0xFF0075A3);
    expect(plaidColor('#FFFFFF'), 0xFFFFFFFF);
    expect(plaidColor('#000000'), 0xFF000000);
    for (final text in ['0075a3', '#075a3', '#0075a3ff', '#00g5a3', '']) {
      expect(() => plaidColor(text), throwsFormatException, reason: text);
    }
  });
}
