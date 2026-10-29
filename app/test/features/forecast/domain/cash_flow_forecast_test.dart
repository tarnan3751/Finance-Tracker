// Worked examples of the cash-flow forecast (cash_flow_forecast.dart), as of Saturday
// 24 October 2026: a salary and a rent crossing a month end, a biweekly payroll with a
// band, an ended stream, bills with and without an amount, a negative crossing, the
// overdue rule, the horizon's last day, a refund among a stream's members, a stream with
// no members, and the lowest point's tie.
import 'package:finance_tracker/features/forecast/domain/cash_flow_forecast.dart';
import 'package:finance_tracker/features/forecast/domain/forecast_plan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import 'forecast_fixtures.dart';

LocalDate day(int offset) => today.addDays(offset);

ForecastPoint pointOn(ForecastSeries s, LocalDate date) =>
    s.points.singleWhere((p) => p.date == date);

ForecastStream projected(
  RecurringStream s, [
  List<Transaction> members = const [],
]) => ForecastStream(stream: s, name: s.merchantName, members: members);

void main() {
  test('a salary and a rent on the 1st cross the month end', () {
    final ForecastSeries s = projectCashFlow(
      plan(
        start: 100000,
        allowance: 1000,
        streams: [
          projected(
            stream('salary', cents: 300000, next: LocalDate(2026, 11, 1)),
          ),
          projected(
            stream('rent', cents: -150000, next: LocalDate(2026, 11, 1)),
          ),
        ],
      ),
      30,
    );
    expect(s.points, hasLength(31));
    expect(s.points.first.date, today);
    expect(s.points.first.balance, usd(100000));
    final ForecastPoint oct31 = pointOn(s, LocalDate(2026, 10, 31));
    expect(oct31.balance, usd(100000 - 7 * 1000));
    expect(oct31.events, isEmpty);
    final ForecastPoint nov1 = pointOn(s, LocalDate(2026, 11, 1));
    expect(nov1.balance, usd(100000 + 300000 - 150000 - 8 * 1000));
    expect(nov1.events.map((e) => e.id), ['rent', 'salary']);
    expect(nov1.lower, nov1.balance);
    expect(nov1.upper, nov1.balance);
    expect(s.points.last.balance, usd(250000 - 30 * 1000));
    expect(s.lowestPoint.date, LocalDate(2026, 10, 31));
    expect(s.firstNegativeDate, isNull);
  });

  test('a biweekly payroll widens the band with each occurrence', () {
    final List<Transaction> members = [
      txn('p1', 200000, LocalDate(2026, 9, 18)),
      txn('p2', 210000, LocalDate(2026, 10, 2)),
      txn('p3', 190000, LocalDate(2026, 10, 16)),
    ];
    final ForecastSeries s = projectCashFlow(
      plan(
        start: 0,
        streams: [
          projected(
            stream(
              'pay',
              cadence: RecurringCadence.biweekly,
              cents: 200000,
              next: LocalDate(2026, 10, 30),
              last: LocalDate(2026, 10, 16),
            ),
            members,
          ),
        ],
      ),
      30,
    );
    final ForecastPoint first = pointOn(s, LocalDate(2026, 10, 30));
    expect(first.balance, usd(200000));
    expect(first.lower, usd(190000));
    expect(first.upper, usd(210000));
    expect(first.events.single.amount, usd(200000));
    final ForecastPoint second = pointOn(s, LocalDate(2026, 11, 13));
    expect(second.balance, usd(400000));
    expect(second.lower, usd(380000));
    expect(second.upper, usd(420000));
    expect(pointOn(s, LocalDate(2026, 11, 12)).lower, usd(190000));
  });

  test('an ended stream contributes nothing', () {
    final ForecastSeries s = projectCashFlow(
      plan(
        streams: [
          projected(
            stream(
              'gym',
              next: LocalDate(2026, 11, 1),
              status: RecurringStatus.ended,
            ),
          ),
        ],
      ),
      30,
    );
    expect(s.points.every((p) => p.balance == usd(100000)), isTrue);
    expect(s.points.expand((p) => p.events), isEmpty);
  });

  test('bills count on their dates; one with no amount is listed only', () {
    final ForecastSeries s = projectCashFlow(
      plan(
        bills: [
          ForecastBill(
            id: 'water',
            name: 'Water',
            amount: usd(-4500),
            dates: [LocalDate(2026, 11, 5), LocalDate(2026, 12, 5)],
          ),
          ForecastBill(
            id: 'dentist',
            name: null,
            amount: null,
            dates: [LocalDate(2026, 11, 5)],
          ),
        ],
      ),
      90,
    );
    final ForecastPoint nov5 = pointOn(s, LocalDate(2026, 11, 5));
    expect(nov5.balance, usd(100000 - 4500));
    expect(nov5.lower, nov5.balance);
    expect(nov5.events.map((e) => (e.id, e.kind, e.name, e.amount)), [
      ('dentist', ForecastEventKind.bill, null, null),
      ('water', ForecastEventKind.bill, 'Water', usd(-4500)),
    ]);
    expect(pointOn(s, LocalDate(2026, 12, 5)).balance, usd(100000 - 9000));
  });

  test('the first negative date and the lowest point', () {
    final ForecastSeries s = projectCashFlow(
      plan(
        start: 5000,
        allowance: 1000,
        streams: [
          projected(
            stream('salary', cents: 40000, next: LocalDate(2026, 11, 1)),
          ),
        ],
      ),
      30,
    );
    expect(s.firstNegativeDate, LocalDate(2026, 10, 30));
    expect(pointOn(s, LocalDate(2026, 10, 30)).balance, usd(-1000));
    expect(s.lowestPoint.date, LocalDate(2026, 10, 31));
    expect(s.lowestPoint.balance, usd(-2000));
  });

  test('a start balance already negative is the first negative date', () {
    final ForecastSeries s = projectCashFlow(plan(start: -100), 30);
    expect(s.firstNegativeDate, today);
    expect(s.lowestPoint.date, today);
  });

  test('a tie for the lowest point takes the earliest day', () {
    final ForecastSeries s = projectCashFlow(
      plan(
        start: 1000,
        bills: [
          ForecastBill(id: 'a', name: 'A', amount: usd(-500), dates: [day(2)]),
          ForecastBill(id: 'b', name: 'B', amount: usd(500), dates: [day(3)]),
          ForecastBill(id: 'c', name: 'C', amount: usd(-500), dates: [day(4)]),
        ],
      ),
      30,
    );
    expect(s.lowestPoint.date, day(2));
    expect(s.lowestPoint.balance, usd(500));
  });

  group('overdue', () {
    test('a stream due 3 days ago with nothing posted lands tomorrow', () {
      final ForecastSeries s = projectCashFlow(
        plan(
          streams: [
            projected(stream('rent', cents: -50000, next: day(-3)), [
              txn('old', -50000, day(-34)),
            ]),
          ],
        ),
        30,
      );
      final ForecastPoint tomorrow = s.points[1];
      expect(tomorrow.balance, usd(50000));
      expect(tomorrow.events.single.due, day(-3));
      expect(pointOn(s, day(-3).addMonths(1)).events.single.id, 'rent');
    });

    test('one due today with nothing posted lands tomorrow', () {
      final ForecastSeries s = projectCashFlow(
        plan(streams: [projected(stream('rent', cents: -50000, next: today))]),
        30,
      );
      expect(s.points.first.balance, usd(100000));
      expect(s.points[1].balance, usd(50000));
    });

    test('one 4 days overdue is dropped and the series goes on', () {
      final ForecastSeries s = projectCashFlow(
        plan(
          streams: [
            projected(
              stream(
                'w',
                cadence: RecurringCadence.weekly,
                cents: -1000,
                next: day(-4),
              ),
            ),
          ],
        ),
        30,
      );
      expect(s.points[1].events, isEmpty);
      expect(pointOn(s, day(3)).events.single.due, day(3));
      expect(pointOn(s, day(3)).balance, usd(99000));
    });

    test('a member posted on or after 3 days before it means it arrived', () {
      ForecastSeries withMember(LocalDate posted, {bool pending = false}) =>
          projectCashFlow(
            plan(
              streams: [
                projected(stream('rent', cents: -50000, next: day(-1)), [
                  txn('paid', -50000, posted, pending: pending),
                ]),
              ],
            ),
            30,
          );
      expect(withMember(day(-4)).points[1].events, isEmpty);
      expect(withMember(day(-4), pending: true).points[1].events, isEmpty);
      expect(withMember(day(-5)).points[1].events.single.id, 'rent');
    });

    test('an occurrence after today is never skipped', () {
      final ForecastSeries s = projectCashFlow(
        plan(
          streams: [
            projected(stream('rent', cents: -50000, next: day(2)), [
              txn('early', -50000, day(0)),
            ]),
          ],
        ),
        30,
      );
      expect(pointOn(s, day(2)).events.single.id, 'rent');
    });

    test('bills: 3 days overdue lands tomorrow, 4 is dropped', () {
      final ForecastSeries s = projectCashFlow(
        plan(
          bills: [
            ForecastBill(
              id: 'a',
              name: 'A',
              amount: usd(-100),
              dates: [day(-3)],
            ),
            ForecastBill(
              id: 'b',
              name: 'B',
              amount: usd(-200),
              dates: [day(-4)],
            ),
          ],
        ),
        30,
      );
      expect(s.points[1].events.map((e) => e.id), ['a']);
      expect(s.points[1].balance, usd(99900));
    });
  });

  test('an occurrence on the horizon counts, the day after does not', () {
    final ForecastSeries s = projectCashFlow(
      plan(
        bills: [
          ForecastBill(
            id: 'a',
            name: 'A',
            amount: usd(-100),
            dates: [day(30), day(31)],
          ),
        ],
      ),
      30,
    );
    expect(s.points.last.date, day(30));
    expect(s.points.last.balance, usd(99900));
  });

  test(
    'a refund among the members widens the band below a positive median',
    () {
      final ForecastSeries s = projectCashFlow(
        plan(
          start: 0,
          streams: [
            projected(stream('gig', cents: 1000, next: day(1)), [
              txn('g1', 1000, day(-60)),
              txn('g2', -950, day(-40)),
              txn('g3', 1000, day(-20)),
            ]),
          ],
        ),
        30,
      );
      final ForecastPoint p = s.points[1];
      expect(p.balance, usd(1000));
      expect(p.lower, usd(-950));
      expect(p.upper, usd(1000));
    },
  );

  test('a stream with no members uses its average with no band', () {
    final ForecastSeries s = projectCashFlow(
      plan(streams: [projected(stream('netflix', cents: -1549, next: day(5)))]),
      30,
    );
    final ForecastPoint p = pointOn(s, day(5));
    expect(p.balance, usd(100000 - 1549));
    expect(p.lower, p.balance);
    expect(p.upper, p.balance);
  });

  test('two streams on one date both land', () {
    final ForecastSeries s = projectCashFlow(
      plan(
        streams: [
          projected(stream('b', cents: -100, next: day(3))),
          projected(stream('a', cents: -200, next: day(3))),
        ],
      ),
      30,
    );
    expect(pointOn(s, day(3)).events.map((e) => e.id), ['a', 'b']);
    expect(pointOn(s, day(3)).balance, usd(99700));
  });

  test('the 30-day series is the first 31 points of the 90-day one', () {
    final ForecastPlan p = plan(
      allowance: 700,
      streams: [projected(stream('rent', cents: -50000, next: day(8)))],
    );
    final ForecastSeries short = projectCashFlow(p, 30);
    final ForecastSeries long = projectCashFlow(p, 90);
    expect(short.points, long.points.sublist(0, 31));
    expect(long.points, hasLength(91));
    expect(long.horizonDays, 90);
  });
}
