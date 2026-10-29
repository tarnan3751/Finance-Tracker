// The cash-flow forecast over many seeded plans. Deterministic by default: seeds start
// at 1000; set FORECAST_PROPERTY_SEED to start elsewhere
// (`FORECAST_PROPERTY_SEED=5000 flutter test test/features/forecast/domain/forecast_property_test.dart`).
// A failure names the seed, so it reproduces exactly.
//
// Each plan has a random today in 2024 to 2030 (month ends and 29 February among them),
// a start balance either side of zero, an allowance, up to six streams of every cadence,
// status and source with up to six members (refunds and other directions among them),
// next and last dates either side of today or missing, and up to four bills with and
// without amounts. Properties: the result does not depend on the inputs' order; there
// are horizon + 1 consecutive points from today; the band contains the balance and each
// side only widens; the balance is the start plus the day's events less the allowance;
// the 30-day series is the 90-day one's prefix; the lowest point and the first negative
// date agree with the points.
import 'dart:io';
import 'dart:math';

import 'package:finance_tracker/features/forecast/domain/cash_flow_forecast.dart';
import 'package:finance_tracker/features/forecast/domain/forecast_plan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import 'forecast_fixtures.dart';

const int defaultSeed = 1000;
const int cases = 200;

final int base =
    int.tryParse(Platform.environment['FORECAST_PROPERTY_SEED'] ?? '') ??
    defaultSeed;

final List<LocalDate> boundaryDays = [
  LocalDate(2024, 2, 29),
  LocalDate(2028, 2, 29),
  LocalDate(2026, 1, 31),
  LocalDate(2026, 4, 30),
  LocalDate(2027, 2, 28),
  LocalDate(2026, 12, 31),
];

LocalDate randomToday(Random r) => r.nextInt(4) == 0
    ? boundaryDays[r.nextInt(boundaryDays.length)]
    : LocalDate(2024, 1, 1).addDays(r.nextInt(7 * 365));

T pick<T>(Random r, List<T> values) => values[r.nextInt(values.length)];

ForecastPlan randomPlan(Random r) {
  final LocalDate on = randomToday(r);
  int txn = 0;
  final List<ForecastStream> streams = [
    for (final int i in List.generate(r.nextInt(7), (i) => i))
      () {
        final int sign = r.nextInt(3) == 0 ? 1 : -1;
        final int size = 100 + r.nextInt(300000);
        final List<Transaction> members = [
          for (final int _ in List.filled(r.nextInt(7), 0))
            Transaction(
              id: 'm${txn++}',
              accountId: 'checking',
              amount: usd(
                (r.nextInt(8) == 0 ? -sign : sign) *
                    (size + r.nextInt(size ~/ 4 + 1) - size ~/ 8),
              ),
              date: on.addDays(-r.nextInt(120)),
              pending: r.nextBool(),
              name: 'member',
              source: DataSource.manual,
              createdAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
              syncVersion: 0,
            ),
        ];
        final RecurringStream s = stream(
          's$i',
          cadence: pick(r, RecurringCadence.values),
          cents: sign * size,
          next: r.nextInt(6) == 0 ? null : on.addDays(r.nextInt(130) - 20),
          last: r.nextInt(4) == 0 ? null : on.addDays(-r.nextInt(60)),
          status: r.nextInt(6) == 0
              ? RecurringStatus.ended
              : RecurringStatus.active,
          source: pick(r, RecurringSource.values),
          members: [for (final Transaction t in members) t.id],
        );
        return ForecastStream(stream: s, name: 'Stream $i', members: members);
      }(),
  ];
  final List<ForecastBill> bills = [
    for (final int i in List.generate(r.nextInt(5), (i) => i))
      ForecastBill(
        id: 'b$i',
        name: r.nextBool() ? 'Bill $i' : null,
        amount: r.nextInt(4) == 0 ? null : usd(-(1 + r.nextInt(200000))),
        dates: {
          for (final int _ in List.filled(r.nextInt(5), 0))
            on.addDays(r.nextInt(110) - 10),
        }.toList(),
      ),
  ];
  return ForecastPlan(
    today: on,
    start: usd(r.nextInt(2000000) - 500000),
    allowance: usd(r.nextInt(20000)),
    streams: streams,
    bills: bills,
  );
}

ForecastPlan shuffled(ForecastPlan p, Random r) => ForecastPlan(
  today: p.today,
  start: p.start,
  allowance: p.allowance,
  streams: [
    for (final ForecastStream s in p.streams)
      ForecastStream(
        stream: s.stream,
        name: s.name,
        members: [...s.members]..shuffle(r),
      ),
  ]..shuffle(r),
  bills: [
    for (final ForecastBill b in p.bills)
      ForecastBill(
        id: b.id,
        name: b.name,
        amount: b.amount,
        dates: [...b.dates]..shuffle(r),
      ),
  ]..shuffle(r),
);

void forEachCase(void Function(int seed, ForecastPlan plan, Random r) body) {
  for (int seed = base; seed < base + cases; seed++) {
    final Random r = Random(seed);
    body(seed, randomPlan(r), r);
  }
}

void main() {
  test('the inputs\' order never changes the result', () {
    forEachCase((seed, p, r) {
      for (final int h in forecastHorizons) {
        expect(
          projectCashFlow(shuffled(p, r), h).points,
          projectCashFlow(p, h).points,
          reason: 'seed $seed, horizon $h',
        );
      }
    });
  });

  test('horizon + 1 consecutive points from today', () {
    forEachCase((seed, p, _) {
      for (final int h in forecastHorizons) {
        final ForecastSeries s = projectCashFlow(p, h);
        expect(s.points, hasLength(h + 1), reason: 'seed $seed');
        for (int i = 0; i <= h; i++) {
          expect(s.points[i].date, p.today.addDays(i), reason: 'seed $seed');
        }
        expect(s.points.first.balance, p.start, reason: 'seed $seed');
        expect(s.currencyCode, 'USD');
      }
    });
  });

  test('the band contains the balance and each side only widens', () {
    forEachCase((seed, p, _) {
      final ForecastSeries s = projectCashFlow(p, 90);
      Money below = usd(0);
      Money above = usd(0);
      for (final ForecastPoint point in s.points) {
        final Money b = point.balance - point.lower;
        final Money a = point.upper - point.balance;
        expect(
          b >= below && a >= above,
          isTrue,
          reason: 'seed $seed ${point.date}',
        );
        below = b;
        above = a;
      }
    });
  });

  test('the balance is the start plus the events less the allowance', () {
    forEachCase((seed, p, _) {
      final ForecastSeries s = projectCashFlow(p, 90);
      Money running = p.start;
      for (int i = 1; i < s.points.length; i++) {
        final ForecastPoint point = s.points[i];
        for (final ForecastEvent e in point.events) {
          running += e.amount ?? usd(0);
          expect(e.due.isAfter(p.today.addDays(-overdueDays - 1)), isTrue);
          expect(
            e.due == point.date || (i == 1 && !e.due.isAfter(p.today)),
            isTrue,
            reason:
                'seed $seed: an event lands on its date, or tomorrow when overdue',
          );
        }
        running -= p.allowance;
        expect(point.balance, running, reason: 'seed $seed ${point.date}');
      }
    });
  });

  test('the 30-day series is the 90-day one\'s first 31 points', () {
    forEachCase((seed, p, _) {
      expect(
        projectCashFlow(p, 30).points,
        projectCashFlow(p, 90).points.sublist(0, 31),
        reason: 'seed $seed',
      );
    });
  });

  test(
    'the lowest point and the first negative date agree with the points',
    () {
      forEachCase((seed, p, _) {
        for (final int h in forecastHorizons) {
          final ForecastSeries s = projectCashFlow(p, h);
          final Money lowest = s.points
              .map((pt) => pt.balance)
              .reduce(Money.min);
          expect(s.lowestPoint.balance, lowest, reason: 'seed $seed');
          expect(
            s.lowestPoint.date,
            s.points.firstWhere((pt) => pt.balance == lowest).date,
            reason: 'seed $seed',
          );
          expect(
            s.firstNegativeDate,
            s.points.where((pt) => pt.balance.isNegative).firstOrNull?.date,
            reason: 'seed $seed',
          );
        }
      });
    },
  );
}
