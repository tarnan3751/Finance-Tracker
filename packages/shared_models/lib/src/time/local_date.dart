/// Calendar dates without a time or a zone (`PLAN.md` §6.8).
///
/// A transaction has a date, not a timestamp. `LocalDate` is that date: year, month and day
/// in the proleptic Gregorian calendar, years 1 to 9999, with arithmetic on a day count so
/// no time zone or daylight-saving shift can move it. This package knows nothing about
/// zones: "today" is computed by the app's `timezone`-based clock and handed in through
/// [LocalDate.fromDateTime]. Budget periods are half-open [LocalDateRange]s.
library;

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

/// A calendar date: [year], [month] (1-12) and [day] (1-31).
@immutable
final class LocalDate implements Comparable<LocalDate> {
  /// The date [year]-[month]-[day]; an impossible date is an [ArgumentError].
  LocalDate(this.year, this.month, this.day) {
    if (year < 1 || year > 9999) {
      throw ArgumentError.value(year, 'year', 'must be 1 to 9999');
    }
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'must be 1 to 12');
    }
    if (day < 1 || day > daysInMonth(year, month)) {
      throw ArgumentError.value(day, 'day', 'not a day of $year-$month');
    }
  }

  /// Parses `yyyy-MM-dd`, exactly; anything else, or an impossible date, is a
  /// [FormatException].
  factory LocalDate.parse(String iso) {
    final match = _isoPattern.firstMatch(iso);
    if (match == null) throw FormatException('Not an ISO date', iso);
    try {
      return LocalDate(
        int.parse(match[1]!),
        int.parse(match[2]!),
        int.parse(match[3]!),
      );
    } on ArgumentError catch (e) {
      throw FormatException('Not a valid date: ${e.message}', iso);
    }
  }

  /// The date fields of [dateTime] as they are, in whatever zone it carries. The caller
  /// chooses the zone (the app passes a `timezone`-local time).
  factory LocalDate.fromDateTime(DateTime dateTime) =>
      LocalDate(dateTime.year, dateTime.month, dateTime.day);

  /// Reads the ISO string form (for json_serializable).
  factory LocalDate.fromJson(String json) => LocalDate.parse(json);

  factory LocalDate._fromEpochDay(int epochDay) {
    final (y, m, d) = _civilFromDays(epochDay);
    return LocalDate(y, m, d);
  }

  /// The year, 1 to 9999.
  final int year;

  /// The month, 1 to 12.
  final int month;

  /// The day of the month, 1 to 31.
  final int day;

  static final RegExp _isoPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// Whether [year] is a Gregorian leap year.
  static bool isLeap(int year) =>
      year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

  /// The number of days in [month] of [year].
  static int daysInMonth(int year, int month) => switch (month) {
    2 => isLeap(year) ? 29 : 28,
    4 || 6 || 9 || 11 => 30,
    _ => 31,
  };

  /// Whether this date's year is a leap year.
  bool get isLeapYear => isLeap(year);

  /// The ISO weekday: 1 is Monday, 7 is Sunday (as `DateTime.weekday`).
  int get weekday => (_epochDay + 3) % 7 + 1; // 1970-01-01 was a Thursday

  /// The first day of this date's month.
  LocalDate get firstOfMonth => LocalDate(year, month, 1);

  /// The last day of this date's month.
  LocalDate get lastOfMonth => LocalDate(year, month, daysInMonth(year, month));

  /// The date [days] later (earlier when negative).
  LocalDate addDays(int days) => LocalDate._fromEpochDay(_epochDay + days);

  /// The date [months] later (earlier when negative), clamped to the last day of the
  /// target month: January 31 plus one month is February 28 or 29.
  LocalDate addMonths(int months) {
    final index = year * 12 + (month - 1) + months;
    final y = index ~/ 12;
    final m = index % 12 + 1;
    if (index < 12) {
      throw ArgumentError.value(months, 'months', 'goes before year 1');
    }
    final d = day > daysInMonth(y, m) ? daysInMonth(y, m) : day;
    return LocalDate(y, m, d);
  }

  /// The number of days from this date to [other]; negative when [other] is earlier.
  int daysUntil(LocalDate other) => other._epochDay - _epochDay;

  /// Whether this date is before [other].
  bool isBefore(LocalDate other) => compareTo(other) < 0;

  /// Whether this date is after [other].
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  /// Midnight of this date in the device's local zone, for widgets that need a
  /// `DateTime`. Never use it for date arithmetic.
  DateTime toDateTime() => DateTime(year, month, day);

  /// `yyyy-MM-dd`.
  String toIso() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  /// The ISO string form (for json_serializable).
  String toJson() => toIso();

  int get _epochDay => _daysFromCivil(year, month, day);

  @override
  int compareTo(LocalDate other) => _epochDay.compareTo(other._epochDay);

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}

/// The half-open range of dates [start] (included) to [end] (excluded).
@immutable
final class LocalDateRange {
  /// The dates from [start] up to but not including [end]; [end] before [start] is an
  /// [ArgumentError], and [end] equal to [start] is the empty range.
  LocalDateRange(this.start, this.end) {
    if (end.isBefore(start)) {
      throw ArgumentError.value(end, 'end', 'is before start $start');
    }
  }

  /// The first date in the range.
  final LocalDate start;

  /// The first date after the range.
  final LocalDate end;

  /// The number of dates in the range.
  int get length => start.daysUntil(end);

  /// Whether the range has no dates.
  bool get isEmpty => length == 0;

  /// The dates in the range, in order.
  Iterable<LocalDate> get days sync* {
    for (var i = 0; i < length; i++) {
      yield start.addDays(i);
    }
  }

  /// Whether [date] is in the range.
  bool contains(LocalDate date) => !date.isBefore(start) && date.isBefore(end);

  /// Whether this range and [other] share at least one date.
  bool overlaps(LocalDateRange other) =>
      start.isBefore(other.end) && other.start.isBefore(end);

  @override
  bool operator ==(Object other) =>
      other is LocalDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '[$start, $end)';
}

/// Converts [LocalDate] to and from its ISO string, for annotated model fields.
final class LocalDateConverter implements JsonConverter<LocalDate, String> {
  /// The converter.
  const LocalDateConverter();

  @override
  LocalDate fromJson(String json) => LocalDate.parse(json);

  @override
  String toJson(LocalDate object) => object.toIso();
}

// Days since 1970-01-01 from a civil date and back, after Howard Hinnant's
// "chrono-compatible low-level date algorithms". Exact for every proleptic Gregorian date.
int _daysFromCivil(int year, int month, int day) {
  final y = month <= 2 ? year - 1 : year;
  final era = (y >= 0 ? y : y - 399) ~/ 400;
  final yearOfEra = y - era * 400;
  final dayOfYear =
      (153 * (month > 2 ? month - 3 : month + 9) + 2) ~/ 5 + day - 1;
  final dayOfEra =
      yearOfEra * 365 + yearOfEra ~/ 4 - yearOfEra ~/ 100 + dayOfYear;
  return era * 146097 + dayOfEra - 719468;
}

(int, int, int) _civilFromDays(int epochDay) {
  final z = epochDay + 719468;
  final era = (z >= 0 ? z : z - 146096) ~/ 146097;
  final dayOfEra = z - era * 146097;
  final yearOfEra =
      (dayOfEra - dayOfEra ~/ 1460 + dayOfEra ~/ 36524 - dayOfEra ~/ 146096) ~/
      365;
  final dayOfYear =
      dayOfEra - (365 * yearOfEra + yearOfEra ~/ 4 - yearOfEra ~/ 100);
  final mp = (5 * dayOfYear + 2) ~/ 153;
  final day = dayOfYear - (153 * mp + 2) ~/ 5 + 1;
  final month = mp < 10 ? mp + 3 : mp - 9;
  final year = yearOfEra + era * 400 + (month <= 2 ? 1 : 0);
  return (year, month, day);
}
