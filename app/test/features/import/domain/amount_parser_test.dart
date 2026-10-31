// The import's amounts: both separators, signs in every place a bank writes them,
// currency symbols and spaces, thousands, exactness with no double, half-even rounding of
// digits past the currency's, and what is refused.
import 'package:finance_tracker/features/import/domain/amount_parser.dart';
import 'package:flutter_test/flutter_test.dart';

int _point(String s, [int scale = 2]) =>
    parseMinorUnits(s, separator: DecimalSeparator.point, scale: scale);

int _comma(String s, [int scale = 2]) =>
    parseMinorUnits(s, separator: DecimalSeparator.comma, scale: scale);

Matcher _refused(AmountProblem p) => throwsA(
  isA<AmountFormatException>().having((e) => e.problem, 'problem', p),
);

void main() {
  test('both separators, with thousands', () {
    expect(_point('1,234.56'), 123456);
    expect(_comma('1.234,56'), 123456);
    expect(_point('1234'), 123400);
    expect(_comma('1234'), 123400);
    expect(_point('.5'), 50);
    expect(_point("1'234.50"), 123450);
    expect(_comma('1 234,56'), 123456);
    expect(_comma('1 234,56'), 123456);
    expect(_comma('1 234,56'), 123456);
  });

  test('signs: minus in front or behind, parentheses, plus, U+2212', () {
    expect(_point('-12.00'), -1200);
    expect(_point('12.00-'), -1200);
    expect(_point('(12.00)'), -1200);
    expect(_point('+12.00'), 1200);
    expect(_point('−12.00'), -1200);
    expect(_point(r'-$1,200.00'), -120000);
    expect(_point(r'$-1,200.00'), -120000);
    expect(_point(r'($1,200.00)'), -120000);
  });

  test('currency symbols and spaces are stripped', () {
    expect(_point(r'$ 4.75'), 475);
    expect(_comma('4,75 €'), 475);
    expect(_point('£3.20'), 320);
    expect(_point('¥1,000', 0), 1000);
  });

  test('the wrong separator is refused, never misread', () {
    expect(() => _point('12,50'), _refused(AmountProblem.notANumber));
    expect(() => _comma('-82.17'), _refused(AmountProblem.notANumber));
    expect(() => _point('1,2,3.4'), _refused(AmountProblem.notANumber));
    expect(() => _point(',5'), _refused(AmountProblem.notANumber));
    expect(() => _point('1234,567.00'), _refused(AmountProblem.notANumber));
    expect(() => _point('1,234,56'), _refused(AmountProblem.notANumber));
    expect(_point('1,234,567.89'), 123456789);
    expect(_comma('-1.234,56'), -123456);
  });

  test('one currency word at either end', () {
    expect(_point('USD 12.34'), 1234);
    expect(_point('12.34 usd'), 1234);
    expect(_comma('12,50 kr'), 1250);
    expect(_comma('kr 12,50'), 1250);
    expect(_comma('EUR -1.234,56'), -123456);
  });

  test('exact: tenths and hundredths stay what they say', () {
    expect(_point('0.1') + _point('0.2'), _point('0.3'));
    expect(_point('0.1'), 10);
    expect(_point('0.2'), 20);
    expect(_point('0.30'), 30);
    expect(_point('92233720368547758.07'), 9223372036854775807);
  });

  test('past the currency digits: half-even', () {
    expect(_point('1.005'), 100);
    expect(_point('1.015'), 102);
    expect(_point('1.0051'), 101);
    expect(_point('1.0049'), 100);
    expect(_point('-1.005'), -100);
    expect(_point('-1.015'), -102);
    expect(_point('2.5', 0), 2);
    expect(_point('3.5', 0), 4);
    expect(_point('1.2345', 3), 1234);
    expect(_point('1.2355', 3), 1236);
  });

  test('refused', () {
    expect(() => _point(''), _refused(AmountProblem.empty));
    expect(() => _point(r' $ '), _refused(AmountProblem.empty));
    expect(() => _point('-'), _refused(AmountProblem.notANumber));
    expect(() => _point('12.00 CR'), _refused(AmountProblem.notANumber));
    expect(() => _point('12.00 DR'), _refused(AmountProblem.notANumber));
    expect(() => _point('12.00 DBT'), _refused(AmountProblem.notANumber));
    expect(() => _point('CRD 12.00'), _refused(AmountProblem.notANumber));
    expect(() => _point('12.00 deb'), _refused(AmountProblem.notANumber));
    expect(() => _point('USD EUR 12.00'), _refused(AmountProblem.notANumber));
    expect(() => _point('abc'), _refused(AmountProblem.notANumber));
    expect(() => _point('1.2.3'), _refused(AmountProblem.notANumber));
    expect(() => _point('1.23,4'), _refused(AmountProblem.notANumber));
    expect(() => _point('(-12.00)'), _refused(AmountProblem.notANumber));
    expect(() => _point('-12.00-'), _refused(AmountProblem.notANumber));
    expect(() => _point('1e5'), _refused(AmountProblem.notANumber));
    expect(
      () => _point('92233720368547758.08'),
      _refused(AmountProblem.tooLarge),
    );
  });

  test('detectDecimalSeparator', () {
    expect(
      detectDecimalSeparator(['-82.17', '1850.00']),
      DecimalSeparator.point,
    );
    expect(
      detectDecimalSeparator(['-82,17', '2.450,00']),
      DecimalSeparator.comma,
    );
    expect(detectDecimalSeparator(['1,234,567']), DecimalSeparator.point);
    expect(detectDecimalSeparator(['1.234.567']), DecimalSeparator.comma);
    expect(detectDecimalSeparator(['1,234', '12']), isNull);
    expect(detectDecimalSeparator(['1,234', '4.50']), DecimalSeparator.point);
    expect(detectDecimalSeparator(const []), isNull);
    expect(detectDecimalSeparator(['1.5', '1,5']), isNull);
  });
}
