// The column converters: dates as ISO text, audit instants as UTC milliseconds (strictly),
// and Money taken apart and put together against the row's currency.
import 'package:finance_tracker/core/db/converters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

void main() {
  test('a LocalDate is its ISO text', () {
    const LocalDateColumnConverter converter = LocalDateColumnConverter();
    expect(converter.toSql(LocalDate(987, 3, 9)), '0987-03-09');
    expect(converter.fromSql('2026-10-24'), LocalDate(2026, 10, 24));
  });

  test(
    'an instant is UTC epoch milliseconds and refuses local or sub-ms values',
    () {
      const UtcMillisColumnConverter converter = UtcMillisColumnConverter();
      final DateTime instant = DateTime.utc(2026, 10, 24, 15, 4, 5, 123);
      expect(converter.toSql(instant), instant.millisecondsSinceEpoch);
      final DateTime back = converter.fromSql(instant.millisecondsSinceEpoch);
      expect(back, instant);
      expect(back.isUtc, isTrue);
      expect(() => converter.toSql(instant.toLocal()), throwsArgumentError);
      expect(
        () => converter.toSql(DateTime.utc(2026, 10, 24, 15, 4, 5, 123, 4)),
        throwsArgumentError,
      );
    },
  );

  test('a Uri is its text', () {
    const UriColumnConverter converter = UriColumnConverter();
    final Uri uri = Uri.parse('https://example.com/logo.png');
    expect(converter.fromSql(converter.toSql(uri)), uri);
  });

  test('Money is minor units in the row currency', () {
    expect(moneyOrNull(null, 'USD'), isNull);
    expect(moneyOrNull(-1234, 'JPY'), Money(-1234, 'JPY'));
    expect(minorUnitsIn(null, 'USD'), isNull);
    expect(minorUnitsIn(Money(-1234, 'USD'), 'USD'), -1234);
    expect(
      () => minorUnitsIn(Money(5, 'EUR'), 'USD'),
      throwsA(isA<CurrencyMismatchException>()),
    );
  });
}
