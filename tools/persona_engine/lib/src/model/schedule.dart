/// When a recurring event happens: the cadences a persona's income, bills, subscriptions,
/// loans and transfers are written in.
library;

import 'package:meta/meta.dart';
import 'package:shared_models/shared_models.dart';

/// What happens to an occurrence that falls on a weekend.
enum BusinessDayRule {
  /// It stays on the weekend (card charges, subscriptions).
  none,

  /// It moves to the Friday before (payroll).
  rollBack,

  /// It moves to the Monday after (bills paid by ACH).
  rollForward,
}

/// A month and day of the year, for [Yearly] schedules.
@immutable
final class MonthDay {
  /// A month (1 to 12) and a day (1 to 31, clamped to the month's length).
  const MonthDay(this.month, this.day);

  /// The month, 1 to 12.
  final int month;

  /// The day, 1 to 31; a day past the month's end means its last day.
  final int day;

  /// `MM-DD`.
  String toIso() =>
      '${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

/// A cadence. [isNominal] says whether a date is a scheduled date before the weekend rule;
/// [occurrences] applies the rule and keeps the dates inside a window.
@immutable
sealed class Schedule {
  const Schedule(this.businessDay);

  /// The weekend rule.
  final BusinessDayRule businessDay;

  /// Whether [date] is a scheduled date, before [businessDay] moves it.
  bool isNominal(LocalDate date);

  /// The cadence as the domain names it; [RecurringCadence.unknown] where it has no name.
  RecurringCadence get cadence;

  /// How far [businessDay] can move an occurrence from its nominal date.
  int get toleranceDays => businessDay == BusinessDayRule.none ? 0 : 2;

  /// [date] moved by the weekend rule.
  LocalDate adjust(LocalDate date) {
    final weekday = date.weekday; // 6 is Saturday, 7 Sunday
    if (weekday < 6) return date;
    return switch (businessDay) {
      BusinessDayRule.none => date,
      BusinessDayRule.rollBack => date.addDays(weekday == 6 ? -1 : -2),
      BusinessDayRule.rollForward => date.addDays(weekday == 6 ? 2 : 1),
    };
  }

  /// The adjusted occurrence dates that fall in `[first, last]`, in order. Nominal dates
  /// just outside the window are considered too, since the rule can move them in.
  List<LocalDate> occurrences(LocalDate first, LocalDate last) {
    final result = <LocalDate>[];
    for (
      var d = first.addDays(-toleranceDays);
      !d.isAfter(last.addDays(toleranceDays));
      d = d.addDays(1)
    ) {
      if (!isNominal(d)) continue;
      final a = adjust(d);
      if (!a.isBefore(first) && !a.isAfter(last)) result.add(a);
    }
    return result;
  }

  /// The JSON form, for the recurring expectations in the demo seed.
  Map<String, Object?> toJson();

  String get _ruleName => switch (businessDay) {
    BusinessDayRule.none => 'none',
    BusinessDayRule.rollBack => 'roll_back',
    BusinessDayRule.rollForward => 'roll_forward',
  };
}

/// Every week on [weekday] (1 is Monday, 7 Sunday).
final class Weekly extends Schedule {
  /// A weekly schedule.
  const Weekly(
    this.weekday, {
    BusinessDayRule businessDay = BusinessDayRule.none,
  }) : super(businessDay);

  /// The weekday, 1 (Monday) to 7 (Sunday).
  final int weekday;

  @override
  bool isNominal(LocalDate date) => date.weekday == weekday;

  @override
  RecurringCadence get cadence => RecurringCadence.weekly;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'weekly',
    'weekday': weekday,
    'business_day': _ruleName,
  };
}

/// Every fourteen days counted from [anchor].
final class Biweekly extends Schedule {
  /// A biweekly schedule.
  const Biweekly(
    this.anchor, {
    BusinessDayRule businessDay = BusinessDayRule.none,
  }) : super(businessDay);

  /// One scheduled date; every date a multiple of fourteen days away is another.
  final LocalDate anchor;

  @override
  bool isNominal(LocalDate date) => anchor.daysUntil(date) % 14 == 0;

  @override
  RecurringCadence get cadence => RecurringCadence.biweekly;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'biweekly',
    'anchor': anchor.toIso(),
    'business_day': _ruleName,
  };
}

/// Twice a month, on [firstDay] and [secondDay] (each clamped to the month's length).
final class SemiMonthly extends Schedule {
  /// A semi-monthly schedule.
  const SemiMonthly(
    this.firstDay,
    this.secondDay, {
    BusinessDayRule businessDay = BusinessDayRule.none,
  }) : super(businessDay);

  /// The first day of the month it occurs on.
  final int firstDay;

  /// The second day; 31 means the month's last day.
  final int secondDay;

  @override
  bool isNominal(LocalDate date) =>
      _onDay(date, firstDay) || _onDay(date, secondDay);

  @override
  RecurringCadence get cadence => RecurringCadence.semiMonthly;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'semi_monthly',
    'days': [firstDay, secondDay],
    'business_day': _ruleName,
  };
}

/// Every month on [day] (clamped to the month's length).
final class Monthly extends Schedule {
  /// A monthly schedule.
  const Monthly(this.day, {BusinessDayRule businessDay = BusinessDayRule.none})
    : super(businessDay);

  /// The day of the month; 31 means the month's last day.
  final int day;

  @override
  bool isNominal(LocalDate date) => _onDay(date, day);

  @override
  RecurringCadence get cadence => RecurringCadence.monthly;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'monthly',
    'day': day,
    'business_day': _ruleName,
  };
}

/// On fixed dates every year: once ([RecurringCadence.annually]), or several times, such as
/// the four estimated-tax dates or two semester starts ([RecurringCadence.unknown]).
final class Yearly extends Schedule {
  /// A yearly schedule.
  const Yearly(this.dates, {BusinessDayRule businessDay = BusinessDayRule.none})
    : super(businessDay);

  /// The dates in each year.
  final List<MonthDay> dates;

  @override
  bool isNominal(LocalDate date) =>
      dates.any((md) => date.month == md.month && _onDay(date, md.day));

  @override
  RecurringCadence get cadence =>
      dates.length == 1 ? RecurringCadence.annually : RecurringCadence.unknown;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'yearly',
    'dates': [for (final md in dates) md.toIso()],
    'business_day': _ruleName,
  };
}

bool _onDay(LocalDate date, int day) {
  final last = LocalDate.daysInMonth(date.year, date.month);
  return date.day == (day < last ? day : last);
}
