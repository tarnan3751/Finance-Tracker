// Decimal: the contract's form read and written exactly, compared by value, equal across
// scales, and its JSON the string.
import 'dart:convert';

import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  test('reads and writes the contract form, keeping the scale', () {
    for (final String s in [
      '0',
      '7',
      '41.50',
      '10.4234',
      '-0.0001',
      '-1234567890123456789012.000000001',
      '0.10',
    ]) {
      expect(Decimal.parse(s).toString(), s, reason: s);
    }
    expect(Decimal.parse('41.50').scale, 2);
    expect(Decimal.parse('41.50').unscaled, BigInt.from(4150));
    expect(Decimal.parse('-41.50').unscaled, BigInt.from(-4150));
  });

  test('zero has no sign', () {
    expect(Decimal.parse('-0').toString(), '0');
    expect(Decimal.parse('-0.00').toString(), '0.00');
    expect(Decimal.parse('-0.00').isNegative, isFalse);
    expect(Decimal.parse('-0.01').isNegative, isTrue);
  });

  test('anything outside the contract form is a FormatException', () {
    for (final String bad in [
      '',
      '-',
      '1.',
      '.5',
      '01',
      '+1',
      '1e3',
      '1.2.3',
      ' 1',
      '1,5',
      '--1',
      'NaN',
    ]) {
      expect(() => Decimal.parse(bad), throwsFormatException, reason: bad);
    }
  });

  test('the constructor takes the signed digits and a scale', () {
    expect(Decimal(BigInt.from(12345), 3).toString(), '12.345');
    expect(Decimal(BigInt.from(-5), 3).toString(), '-0.005');
    expect(Decimal(BigInt.from(450), 0).toString(), '450');
    expect(() => Decimal(BigInt.one, -1), throwsArgumentError);
  });

  test('compares by value across scales and signs', () {
    Decimal d(String s) => Decimal.parse(s);
    expect(d('1.5').compareTo(d('1.50')), 0);
    expect(d('1.5').compareTo(d('1.499')), greaterThan(0));
    expect(d('-1.5').compareTo(d('-1.49')), lessThan(0));
    expect(d('-0.001').compareTo(d('0')), lessThan(0));
    expect(d('-0').compareTo(d('0.000')), 0);
    final List<Decimal> sorted = [
      d('10'),
      d('-2.5'),
      d('0.01'),
      d('9.999'),
      d('-2.49'),
    ]..sort();
    expect(
      [for (final Decimal x in sorted) '$x'],
      ['-2.5', '-2.49', '0.01', '9.999', '10'],
    );
  });

  test('equal values are equal and hash alike, whatever the scale', () {
    Decimal d(String s) => Decimal.parse(s);
    expect(d('1.5'), d('1.500'));
    expect(d('1.5').hashCode, d('1.500').hashCode);
    expect(d('-0'), d('0.00'));
    expect(d('-0').hashCode, d('0.00').hashCode);
    expect(d('100').hashCode, d('100.0').hashCode);
    expect(d('1.5'), isNot(d('1.05')));
    expect({d('2.50'), d('2.5'), d('2.500')}, hasLength(1));
  });

  test('the JSON form is the contract string', () {
    final Decimal price = Decimal.parse('41.50');
    expect(jsonEncode({'price': price}), '{"price":"41.50"}');
    expect(Decimal.fromJson('41.50'), price);
    expect(Decimal.fromJson('41.50').toString(), '41.50');
  });
}
