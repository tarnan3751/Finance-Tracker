/// How domain values are stored in the local database (`docs/reference/data.md`).
///
/// - A `LocalDate` is TEXT `yyyy-MM-dd` ([LocalDateColumnConverter]).
/// - An audit instant is INTEGER epoch milliseconds UTC ([UtcMillisColumnConverter]).
/// - A `Uri` is its TEXT form ([UriColumnConverter]).
/// - An enum is TEXT by name, through Drift's `textEnum`; every enum stored in schema 1 has
///   one-word values, so the Dart name is also its JSON name.
/// - A `Money` is never one column: it is a `<name>_minor` INTEGER beside the row's shared
///   `currency` TEXT, put together on read by [moneyOrNull] and taken apart on write by
///   [minorUnitsIn], which refuses an amount in another currency than the row's.
///
/// Pure Dart, no Flutter import: the schema dump runs this file in the Dart VM.
library;

import 'package:drift/drift.dart';
import 'package:shared_models/shared_models.dart';

/// `LocalDate` ↔ TEXT `yyyy-MM-dd`.
final class LocalDateColumnConverter extends TypeConverter<LocalDate, String> {
  /// The converter.
  const LocalDateColumnConverter();

  @override
  LocalDate fromSql(String fromDb) => LocalDate.parse(fromDb);

  @override
  String toSql(LocalDate value) => value.toIso();
}

/// A UTC `DateTime` with millisecond precision ↔ INTEGER epoch milliseconds.
///
/// Writing a non-UTC value or one with a microsecond part is an [ArgumentError], as for
/// `UtcInstantConverter`: audit instants are UTC milliseconds by contract (`PLAN.md` §12).
final class UtcMillisColumnConverter extends TypeConverter<DateTime, int> {
  /// The converter.
  const UtcMillisColumnConverter();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);

  @override
  int toSql(DateTime value) {
    if (!value.isUtc) {
      throw ArgumentError.value(value, 'value', 'audit instants must be UTC');
    }
    if (value.microsecond != 0) {
      throw ArgumentError.value(
        value,
        'value',
        'audit instants have millisecond precision',
      );
    }
    return value.millisecondsSinceEpoch;
  }
}

/// `Uri` ↔ TEXT.
final class UriColumnConverter extends TypeConverter<Uri, String> {
  /// The converter.
  const UriColumnConverter();

  @override
  Uri fromSql(String fromDb) => Uri.parse(fromDb);

  @override
  String toSql(Uri value) => value.toString();
}

/// The `Money` of [minorUnits] in the row's [currency], or null when the column is null.
Money? moneyOrNull(int? minorUnits, String currency) =>
    minorUnits == null ? null : Money(minorUnits, currency);

/// The minor units of [money] for a row whose currency is [currency]; null for null.
/// Throws [CurrencyMismatchException] when [money] is in another currency.
int? minorUnitsIn(Money? money, String currency) {
  if (money == null) return null;
  if (money.currencyCode != currency) {
    throw CurrencyMismatchException(currency, money.currencyCode);
  }
  return money.minorUnits;
}
