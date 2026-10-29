/// The cash-flow forecast (`docs/reference/forecast.md`; `PLAN.md` §12 "The forecast",
/// "5d plan rulings"): the projected balance of the chosen accounts for each day from
/// today to the horizon, with a confidence band. Pure Dart, integer `Money` only, one
/// currency per series, deterministic: the inputs are taken in id order, so their order
/// never changes the result.
///
/// - **Balance**: `balance(d) = start + Σ stream occurrences in (today, d] + Σ bill
///   occurrences in (today, d] − allowance × days from today to d`; today's point is the
///   start balance.
/// - **Streams**: each date of a stream's series (`stream_schedule.dart`) is an
///   occurrence of the median of its members' band (`StreamBand`), signed; a stream with
///   no live members uses its `averageAmount`, with no band.
/// - **Band**: `lower(d) = balance(d) − Σ (median − min)` and `upper(d) = balance(d) +
///   Σ (max − median)` over the stream occurrences up to d, so the band contains the
///   balance and only widens; bills and the allowance add no width.
/// - **Overdue**: an occurrence dated from [overdueDays] days ago to today lands on
///   tomorrow, unless (for a stream) a member is dated on or after [overdueDays] days
///   before it, which means it arrived (pending or posted) and is skipped; anything
///   older is dropped, and the series goes on from its next date. Nothing after today is
///   ever skipped.
/// - **Lowest point**: the smallest balance, the earliest on a tie; the **first negative
///   date** the first day whose balance is below zero.
library;

import 'package:finance_tracker/features/forecast/domain/forecast_plan.dart';
import 'package:finance_tracker/features/forecast/domain/stream_schedule.dart';
import 'package:finance_tracker/features/recurring/domain/recurring_detector.dart';
import 'package:shared_models/shared_models.dart';

/// The horizons the screen offers, in days.
const List<int> forecastHorizons = [30, 90];

/// How many days past its date an occurrence not yet arrived still lands on tomorrow.
const int overdueDays = 3;

/// What an event is: a stream's occurrence or a bill's.
enum ForecastEventKind { stream, bill }

/// One occurrence on a day of the forecast.
final class ForecastEvent {
  /// The occurrence of [id] due [due].
  const ForecastEvent({
    required this.kind,
    required this.id,
    required this.name,
    required this.amount,
    required this.due,
  });

  /// A stream's or a bill's.
  final ForecastEventKind kind;

  /// The stream's or the bill's id.
  final String id;

  /// The name the app shows; null for a bill with none (the screen says "Bill").
  final String? name;

  /// What it moves, signed; null for a bill with no expected amount.
  final Money? amount;

  /// The date it was expected on: before the point's date when it was overdue.
  final LocalDate due;

  @override
  bool operator ==(Object other) =>
      other is ForecastEvent &&
      other.kind == kind &&
      other.id == id &&
      other.name == name &&
      other.amount == amount &&
      other.due == due;

  @override
  int get hashCode => Object.hash(kind, id, name, amount, due);

  @override
  String toString() => 'ForecastEvent($kind $id $amount due $due)';
}

/// The forecast on one day.
final class ForecastPoint {
  /// The point on [date].
  const ForecastPoint({
    required this.date,
    required this.balance,
    required this.lower,
    required this.upper,
    this.events = const [],
  });

  /// The day.
  final LocalDate date;

  /// The projected balance at the end of the day.
  final Money balance;

  /// The band's low edge, at most [balance].
  final Money lower;

  /// The band's high edge, at least [balance].
  final Money upper;

  /// The occurrences landing on the day, streams then bills, each by id.
  final List<ForecastEvent> events;

  @override
  bool operator ==(Object other) =>
      other is ForecastPoint &&
      other.date == date &&
      other.balance == balance &&
      other.lower == lower &&
      other.upper == upper &&
      _listEquals(other.events, events);

  @override
  int get hashCode =>
      Object.hash(date, balance, lower, upper, Object.hashAll(events));

  @override
  String toString() => 'ForecastPoint($date $balance [$lower, $upper])';
}

/// A forecast: one point per day from today to [horizonDays] days ahead.
final class ForecastSeries {
  /// The series of [points].
  ForecastSeries(this.points, this.horizonDays)
    : lowestPoint = points.reduce((a, b) => b.balance < a.balance ? b : a),
      firstNegativeDate = points
          .where((p) => p.balance.isNegative)
          .firstOrNull
          ?.date;

  /// The points, today first; `horizonDays + 1` of them.
  final List<ForecastPoint> points;

  /// How many days ahead the series runs.
  final int horizonDays;

  /// The point with the smallest balance, the earliest on a tie.
  final ForecastPoint lowestPoint;

  /// The first day whose balance is below zero, or null.
  final LocalDate? firstNegativeDate;

  /// The series' currency.
  String get currencyCode => points.first.balance.currencyCode;
}

/// The forecast of [plan] for [horizonDays] days.
ForecastSeries projectCashFlow(ForecastPlan plan, int horizonDays) {
  final LocalDate today = plan.today;
  final LocalDate end = today.addDays(horizonDays);
  final String currency = plan.currencyCode;
  final Money zero = Money.zero(currency);
  // By days after today: the occurrences landing then.
  final Map<int, List<_Occurrence>> byDay = {};
  void land(LocalDate due, _Occurrence occurrence) {
    final int day = due.isAfter(today) ? today.daysUntil(due) : 1;
    byDay.putIfAbsent(day, () => []).add(occurrence);
  }

  final LocalDate overdueFrom = today.addDays(-overdueDays);
  for (final ForecastStream s in [
    ...plan.streams,
  ]..sort((a, b) => a.stream.id.compareTo(b.stream.id))) {
    final StreamBand band =
        StreamBand.of(s.members) ??
        StreamBand(
          median: s.stream.averageAmount,
          min: s.stream.averageAmount,
          max: s.stream.averageAmount,
        );
    LocalDate? newest;
    for (final Transaction t in s.members) {
      if (newest == null || t.date.isAfter(newest)) newest = t.date;
    }
    for (final LocalDate due in streamDates(s.stream, overdueFrom, end)) {
      // An overdue occurrence with a member near or after it has arrived.
      if (!due.isAfter(today) &&
          newest != null &&
          !newest.isBefore(due.addDays(-overdueDays))) {
        continue;
      }
      land(
        due,
        _Occurrence(
          ForecastEvent(
            kind: ForecastEventKind.stream,
            id: s.stream.id,
            name: s.name,
            amount: band.median,
            due: due,
          ),
          amount: band.median,
          below: band.median - band.min,
          above: band.max - band.median,
        ),
      );
    }
  }
  for (final ForecastBill b in [
    ...plan.bills,
  ]..sort((a, b) => a.id.compareTo(b.id))) {
    for (final LocalDate due in [...b.dates]..sort()) {
      if (due.isBefore(overdueFrom) || due.isAfter(end)) continue;
      land(
        due,
        _Occurrence(
          ForecastEvent(
            kind: ForecastEventKind.bill,
            id: b.id,
            name: b.name,
            amount: b.amount,
            due: due,
          ),
          amount: b.amount ?? zero,
          below: zero,
          above: zero,
        ),
      );
    }
  }

  Money balance = plan.start;
  Money below = zero;
  Money above = zero;
  final List<ForecastPoint> points = [
    ForecastPoint(
      date: today,
      balance: balance,
      lower: balance,
      upper: balance,
    ),
  ];
  for (int day = 1; day <= horizonDays; day++) {
    final List<_Occurrence> landing = byDay[day] ?? const [];
    for (final _Occurrence o in landing) {
      balance += o.amount;
      below += o.below;
      above += o.above;
    }
    balance -= plan.allowance;
    points.add(
      ForecastPoint(
        date: today.addDays(day),
        balance: balance,
        lower: balance - below,
        upper: balance + above,
        events: List.unmodifiable([
          for (final _Occurrence o in landing) o.event,
        ]),
      ),
    );
  }
  return ForecastSeries(List.unmodifiable(points), horizonDays);
}

final class _Occurrence {
  const _Occurrence(
    this.event, {
    required this.amount,
    required this.below,
    required this.above,
  });

  final ForecastEvent event;
  final Money amount;
  final Money below;
  final Money above;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
