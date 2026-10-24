// Cross-checks the ISO 4217 table in `currency.dart` against intl's
// `currencyFractionDigits` (CLDR display digits). The ISO table is authoritative; the
// codes where CLDR deliberately shows fewer digits are listed below, and the test fails on
// any other disagreement, or when a listed code stops disagreeing, so the list stays true.
import 'package:intl/number_symbols_data.dart';
import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

/// Known codes where CLDR's display digits differ from ISO 4217's minor unit. CLDR shows
/// 0 digits for all of them; ISO gives 2 (3 for IQD).
const cldrDivergent = {
  'AFN', 'ALL', 'COP', 'HUF', 'IDR', 'IQD', 'IRR', 'KPW', 'LAK', //
  'LBP', 'MGA', 'MMK', 'PKR', 'RSD', 'SOS', 'SYP', 'YER',
};

void main() {
  test('the table covers List One', () {
    expect(Currency.minorUnitDigits.length, 165);
    expect(Currency.minorUnitDigits.values.toSet(), {0, 2, 3, 4});
    expect(Currency.minorUnitDigits['CLF'], 4);
    expect(Currency.minorUnitDigits['UYW'], 4);
    expect(Currency.minorUnitDigits['BHD'], 3);
    expect(Currency.minorUnitDigits['JPY'], 0);
    expect(Currency.minorUnitDigits['USN'], 2, reason: 'funds codes included');
    for (final code in Currency.minorUnitDigits.keys) {
      expect(Money.isValidCurrencyCode(code), isTrue, reason: code);
    }
  });

  test('intl disagrees only on the expected codes', () {
    final disagreements = <String>{};
    final notInTable = <String>[];
    currencyFractionDigits.forEach((code, digits) {
      if (code == 'DEFAULT') return;
      final iso = Currency.minorUnitDigits[code];
      if (iso == null) {
        notInTable.add(code);
      } else if (iso != digits) {
        disagreements.add(code);
        print('$code: ISO $iso, intl $digits');
      }
    });
    print('intl codes not in the ISO table (withdrawn or N.A.): $notInTable');
    expect(disagreements, cldrDivergent);
  });
}
