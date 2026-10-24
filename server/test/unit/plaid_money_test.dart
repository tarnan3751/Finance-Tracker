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

  test('with a mode, extra digits round as text (half-even here)', () {
    for (final (text, minor) in <(String, int)>[
      ('10.021521', 1002),
      ('342.099285', 34210),
      ('19.569999999999997', 1957),
      ('12.650000000000002', 1265),
      ('6.0424743', 604),
      ('0.125', 12),
      ('0.135', 14),
      ('-0.125', -12),
      ('-0.135', -14),
      ('0.1250001', 13),
      ('-0.004', 0),
      ('12.34', 1234),
      ('92233720368547758.0749', 9223372036854775807),
    ]) {
      expect(
        plaidMoney(text, 'USD', rounding: RoundingMode.halfEven),
        Money(minor, 'USD'),
        reason: text,
      );
    }
    expect(
      plaidMoney('1.5', 'JPY', rounding: RoundingMode.halfEven),
      Money(2, 'JPY'),
    );
    expect(
      plaidMoney('2.5', 'JPY', rounding: RoundingMode.halfEven),
      Money(2, 'JPY'),
    );
    expect(
      () => plaidMoney(
        '92233720368547758.075',
        'USD',
        rounding: RoundingMode.halfEven,
      ),
      throwsFormatException,
    );
    expect(
      () => plaidMoney(1.5, 'USD', rounding: RoundingMode.halfEven),
      throwsArgumentError,
    );
  });

  test('every mode decides a dropped remainder', () {
    Money round(String text, RoundingMode mode) =>
        plaidMoney(text, 'USD', rounding: mode);
    expect(round('1.005', RoundingMode.halfUp), Money(101, 'USD'));
    expect(round('1.005', RoundingMode.halfDown), Money(100, 'USD'));
    expect(round('1.001', RoundingMode.up), Money(101, 'USD'));
    expect(round('1.009', RoundingMode.down), Money(100, 'USD'));
    expect(round('-1.001', RoundingMode.ceiling), Money(-100, 'USD'));
    expect(round('-1.001', RoundingMode.floor), Money(-101, 'USD'));
    expect(round('1.001', RoundingMode.ceiling), Money(101, 'USD'));
  });

  test('with a mode, exponent forms are expanded exactly', () {
    expect(expandPlaidExponent('1e-07'), '0.0000001');
    expect(expandPlaidExponent('1.5e-07'), '0.00000015');
    expect(expandPlaidExponent('-2.5E+3'), '-2500');
    expect(expandPlaidExponent('1.2345e2'), '123.45');
    expect(expandPlaidExponent('12.5'), '12.5');
    expect(
      plaidMoney('1e-07', 'USD', rounding: RoundingMode.halfEven),
      Money(0, 'USD'),
    );
    expect(
      plaidMoney('1.2345e2', 'USD', rounding: RoundingMode.halfEven),
      Money(12345, 'USD'),
    );
    expect(plaidDecimal('1.5e-3', exponents: true), '0.0015');
    expect(() => plaidDecimal('1.5e-3'), throwsFormatException);
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
