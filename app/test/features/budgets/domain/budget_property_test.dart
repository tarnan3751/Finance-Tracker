// Budget periods and math over many seeded cases (the persona engine's style,
// tools/persona_engine/test/property_test.dart). Deterministic by default: seeds start at
// 1000; set BUDGET_PROPERTY_SEED to start elsewhere
// (`BUDGET_PROPERTY_SEED=5000 flutter test test/features/budgets/domain/budget_property_test.dart`).
// A failure names the seed and the inputs (start day, dates, zone, instant), so it
// reproduces exactly.
//
// Generators: every start day 1 to 28 against boundary dates (every month end of 2023 to
// 2029, the leap days 2024-02-29 and 2028-02-29, 2100-02-28, year ends and starts) and
// random dates in 2020 to 2031; random budgets; random transactions over a category tree
// three levels deep, with splits, refunds, pending rows, other currencies, deleted rows
// and rows the exclusion matches; FixedClocks in four zones at their real DST
// transitions of 2024 to 2028 and at local midnight of period start days.
import 'dart:io';
import 'dart:math';

import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:finance_tracker/features/budgets/domain/budget_period.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const int defaultSeed = 1000;
const int casesPerProperty = 200;

final int base =
    int.tryParse(Platform.environment['BUDGET_PROPERTY_SEED'] ?? '') ??
    defaultSeed;

const List<String> zones = [
  'America/New_York',
  'Europe/Berlin',
  'Asia/Kolkata',
  'Pacific/Auckland',
];

/// Month ends of 2023 to 2029, the leap days, a non-leap century's February end, and the
/// first days of the years around them.
final List<LocalDate> boundaryDates = [
  for (int y = 2023; y <= 2029; y++)
    for (int m = 1; m <= 12; m++) ...[
      LocalDate(y, m, 1),
      LocalDate(y, m, 1).lastOfMonth,
    ],
  LocalDate(2024, 2, 29),
  LocalDate(2028, 2, 29),
  LocalDate(2100, 2, 28),
  LocalDate(2100, 3, 1),
];

LocalDate randomDate(Random r) => LocalDate(
  2020,
  1,
  1,
).addDays(r.nextInt(LocalDate(2020, 1, 1).daysUntil(LocalDate(2031, 12, 31))));

// food > groceries > coffee; rides apart; plaid codes for the effective category.
const List<Category> categories = [
  Category(id: 'food', name: 'Food', isSystem: false, icon: 'i', color: 0),
  Category(
    id: 'groceries',
    name: 'Groceries',
    parentId: 'food',
    isSystem: false,
    icon: 'i',
    color: 0,
    plaidCategory: 'FOOD_AND_DRINK_GROCERIES',
  ),
  Category(
    id: 'coffee',
    name: 'Coffee',
    parentId: 'groceries',
    isSystem: false,
    icon: 'i',
    color: 0,
  ),
  Category(
    id: 'rides',
    name: 'Rides',
    isSystem: false,
    icon: 'i',
    color: 0,
    plaidCategory: 'TRANSPORTATION',
  ),
];
final CategoryLookup lookup = categoryLookup(categories);
const List<String?> categoryChoices = [
  'food',
  'groceries',
  'coffee',
  'rides',
  'missing',
  null,
];

bool excludedRow(Transaction t) => t.tags.contains('hidden');

Budget randomBudget(Random r, {LocalDate? startDate}) => Budget(
  id: 'b',
  categoryId: const ['food', 'groceries', 'rides'][r.nextInt(3)],
  period: BudgetPeriodKind.monthly,
  periodStartDay: 1 + r.nextInt(28),
  amount: Money(r.nextInt(100000), 'USD'),
  rollover: r.nextBool(),
  startDate: startDate ?? randomDate(r),
);

/// [count] random transactions dated in [from, to): USD with a few EUR, user and Plaid
/// categories, 0 to 3 splits that sum to the amount, refunds, pending, a few deleted and
/// a few the exclusion matches.
List<Transaction> randomTransactions(
  Random r,
  LocalDate from,
  LocalDate to,
  int count, {
  bool onlyCounted = false,
}) {
  final int span = from.daysUntil(to);
  return [
    for (int i = 0; i < count; i++)
      () {
        final int minor = r.nextInt(5) == 0
            ? r.nextInt(20000)
            : -r.nextInt(50000);
        final String currency = !onlyCounted && r.nextInt(8) == 0
            ? 'EUR'
            : 'USD';
        final int parts = r.nextInt(6) == 0 ? 1 + r.nextInt(3) : 0;
        final List<Money> shares = parts == 0
            ? const []
            : Money(minor, currency).split(parts);
        return Transaction(
          id: 't$i',
          accountId: 'a1',
          amount: Money(minor, currency),
          date: from.addDays(r.nextInt(span)),
          pending: r.nextInt(4) == 0,
          name: 'n',
          userCategoryId: categoryChoices[r.nextInt(categoryChoices.length)],
          plaidDetailedCategory: r.nextBool()
              ? 'FOOD_AND_DRINK_GROCERIES'
              : null,
          plaidPrimaryCategory: r.nextBool() ? 'TRANSPORTATION' : null,
          splits: [
            for (final Money share in shares)
              TransactionSplit(
                categoryId: categoryChoices[r.nextInt(4)]!,
                amount: share,
              ),
          ],
          tags: !onlyCounted && r.nextInt(8) == 0 ? const ['hidden'] : const [],
          source: DataSource.manual,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          deletedAt: !onlyCounted && r.nextInt(10) == 0
              ? DateTime.utc(2026, 1, 2)
              : null,
          syncVersion: 0,
        );
      }(),
  ];
}

/// The instants around each DST transition of [location] in 2024 to 2028.
List<DateTime> transitionInstants(tz.Location location) {
  final int from = DateTime.utc(2024).millisecondsSinceEpoch;
  final int to = DateTime.utc(2029).millisecondsSinceEpoch;
  const List<Duration> offsets = [
    Duration.zero,
    Duration(milliseconds: 1),
    Duration(milliseconds: -1),
    Duration(hours: 1),
    Duration(hours: -1),
    Duration(hours: 23),
    Duration(hours: -23),
  ];
  return [
    for (final int at in location.transitionAt)
      if (at >= from && at < to)
        for (final Duration o in offsets)
          DateTime.fromMillisecondsSinceEpoch(at, isUtc: true).add(o),
  ];
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('periods', () {
    void checkPeriod(LocalDate day, int s, String reason) {
      final LocalDateRange p = periodContaining(day, s);
      expect(p.contains(day), isTrue, reason: reason);
      expect(p.start.day, s, reason: reason);
      expect(p.length, inInclusiveRange(28, 31), reason: reason);
      expect(periodContaining(p.end, s).start, p.end, reason: reason);
      expect(
        periodContaining(p.start.addDays(-1), s).end,
        p.start,
        reason: reason,
      );
      expect(periodContaining(p.start, s), p, reason: reason);
      expect(periodContaining(p.end.addDays(-1), s), p, reason: reason);
    }

    test('every start day against the boundary dates: the period contains the '
        'date, tiles with its neighbours and is 28 to 31 days', () {
      for (int s = 1; s <= 28; s++) {
        for (final LocalDate day in boundaryDates) {
          checkPeriod(day, s, 'start day $s, date $day');
        }
      }
    });

    test('random dates, seeds $base to ${base + casesPerProperty - 1}', () {
      for (int seed = base; seed < base + casesPerProperty; seed++) {
        final Random r = Random(seed);
        final LocalDate day = randomDate(r);
        final int s = 1 + r.nextInt(28);
        checkPeriod(day, s, 'seed $seed, start day $s, date $day');
      }
    });

    test('periodsFrom starts with the start date\'s period and runs '
        'consecutively to the one containing the day', () {
      for (int seed = base; seed < base + casesPerProperty; seed++) {
        final Random r = Random(seed);
        final LocalDate start = randomDate(r);
        final LocalDate through = start.addDays(r.nextInt(900) - 60);
        final int s = 1 + r.nextInt(28);
        final String reason =
            'seed $seed, start $start, through $through, '
            'start day $s';
        final List<LocalDateRange> ps = periodsFrom(start, s, through: through);
        final LocalDateRange first = periodContaining(start, s);
        if (through.isBefore(first.start)) {
          expect(ps, isEmpty, reason: reason);
          continue;
        }
        expect(ps.first, first, reason: reason);
        expect(ps.last.contains(through), isTrue, reason: reason);
        for (int i = 1; i < ps.length; i++) {
          expect(ps[i].start, ps[i - 1].end, reason: reason);
        }
      }
    });

    for (final String zone in zones) {
      test('$zone: around every DST transition of 2024 to 2028 the clock\'s '
          'today is in its period, and a transaction dated today counts', () {
        final tz.Location location = tz.getLocation(zone);
        final List<DateTime> instants = transitionInstants(location);
        if (zone != 'Asia/Kolkata') expect(instants, isNotEmpty);
        for (final (int i, DateTime utc) in instants.indexed) {
          final int s = 1 + i % 28;
          final FixedClock clock = FixedClock(utc, location);
          final LocalDate today = clock.today();
          final String reason = '$zone at $utc, start day $s';
          expect(
            today,
            LocalDate.fromDateTime(tz.TZDateTime.from(utc, location)),
            reason: reason,
          );
          final Budget b = Budget(
            id: 'b',
            categoryId: 'food',
            period: BudgetPeriodKind.monthly,
            periodStartDay: s,
            amount: Money(10000, 'USD'),
            rollover: false,
            startDate: LocalDate(2024, 1, 1),
          );
          final Transaction t = randomTransactions(
            Random(i),
            today,
            today.addDays(1),
            1,
            onlyCounted: true,
          ).single.copyWith(userCategoryId: 'groceries', splits: const []);
          final BudgetStatus status = budgetStatus(b, today, [t], lookup);
          expect(status.period.contains(today), isTrue, reason: reason);
          expect(status.spent, -t.amount, reason: reason);
          expect(
            status.elapsedDays,
            status.period.start.daysUntil(today) + 1,
            reason: reason,
          );
        }
      });

      test(
        '$zone: a period begins exactly at local midnight of its start day',
        () {
          final tz.Location location = tz.getLocation(zone);
          final Random r = Random(base);
          for (int y = 2024; y <= 2028; y++) {
            for (int m = 1; m <= 12; m++) {
              for (final int s in [1, 15, 28, 1 + r.nextInt(28)]) {
                final tz.TZDateTime midnight = tz.TZDateTime(location, y, m, s);
                final LocalDate startDay = LocalDate(y, m, s);
                final String reason = '$zone, $startDay, start day $s';
                final LocalDate at = FixedClock(midnight, location).today();
                expect(at, startDay, reason: reason);
                expect(periodContaining(at, s).start, startDay, reason: reason);
                final LocalDate before = FixedClock(
                  midnight.subtract(const Duration(milliseconds: 1)),
                  location,
                ).today();
                expect(before, startDay.addDays(-1), reason: reason);
                expect(
                  periodContaining(before, s).end,
                  startDay,
                  reason: reason,
                );
              }
            }
          }
        },
      );
    }
  });

  group('status', () {
    // A random budget, today, and transactions from before its first period to after
    // the current one.
    ({Budget budget, LocalDate today, List<Transaction> transactions}) scenario(
      Random r,
    ) {
      final LocalDate today = randomDate(r);
      final Budget budget = randomBudget(
        r,
        startDate: today.addDays(-r.nextInt(450) + 20),
      );
      final List<Transaction> transactions = randomTransactions(
        r,
        budget.startDate.addDays(-60),
        today.addDays(60),
        r.nextInt(150),
      );
      return (budget: budget, today: today, transactions: transactions);
    }

    String describe(int seed, Budget b, LocalDate today) =>
        'seed $seed, today $today, start day ${b.periodStartDay}, '
        'start ${b.startDate}, rollover ${b.rollover}, amount ${b.amount}, '
        'category ${b.categoryId}';

    test('spent, carry, available and remaining equal their closed forms', () {
      for (int seed = base; seed < base + casesPerProperty; seed++) {
        final (:budget, :today, :transactions) = scenario(Random(seed));
        final String reason = describe(seed, budget, today);
        final BudgetStatus s = budgetStatus(
          budget,
          today,
          transactions,
          lookup,
          excluded: excludedRow,
        );
        Money spent(LocalDateRange p) =>
            spentIn(p, budget, transactions, lookup, excluded: excludedRow);
        final LocalDateRange current = periodContaining(
          today,
          budget.periodStartDay,
        );
        expect(s.period, current, reason: reason);
        expect(s.spent, spent(current), reason: reason);
        final List<LocalDateRange> earlier = [
          for (final LocalDateRange p in periodsFrom(
            budget.startDate,
            budget.periodStartDay,
            through: today,
          ))
            if (p.start.isBefore(current.start)) p,
        ];
        final Money expectedCarry = budget.rollover
            ? budget.amount * earlier.length -
                  Money.sum(
                    earlier.map(spent),
                    currencyCode: budget.amount.currencyCode,
                  )
            : Money.zero('USD');
        expect(s.carried, expectedCarry, reason: reason);
        expect(s.available, budget.amount + s.carried, reason: reason);
        expect(s.remaining, s.available - s.spent, reason: reason);
        expect(s.progress.numerator, s.spent.minorUnits, reason: reason);
        expect(s.progress.denominator, s.available.minorUnits, reason: reason);
      }
    });

    test('the projection rounds spent × length ÷ elapsed to the nearest unit, '
        'and equals spent on the period\'s last day', () {
      for (int seed = base; seed < base + casesPerProperty; seed++) {
        final (:budget, :today, :transactions) = scenario(Random(seed));
        final String reason = describe(seed, budget, today);
        final BudgetStatus s = budgetStatus(
          budget,
          today,
          transactions,
          lookup,
        );
        final int k = s.elapsedDays;
        expect(k, inInclusiveRange(1, s.period.length), reason: reason);
        final int exact = s.spent.minorUnits * s.period.length;
        expect(
          (s.projected.minorUnits * k - exact).abs() * 2,
          lessThanOrEqualTo(k),
          reason: reason,
        );
        expect(s.projectedOverspend, s.projected > s.available, reason: reason);

        final LocalDate last = s.period.end.addDays(-1);
        final BudgetStatus end = budgetStatus(
          budget,
          last,
          transactions,
          lookup,
        );
        expect(end.elapsedDays, end.period.length, reason: reason);
        expect(end.projected, end.spent, reason: reason);
      }
    });

    test('thresholds are monotone in spent, and match their fractions', () {
      for (int seed = base; seed < base + casesPerProperty; seed++) {
        final Random r = Random(seed);
        final (:budget, :today, :transactions) = scenario(r);
        final String reason = describe(seed, budget, today);
        final BudgetStatus before = budgetStatus(
          budget,
          today,
          transactions,
          lookup,
        );
        final Transaction more =
            randomTransactions(
              r,
              before.period.start,
              today.addDays(1),
              1,
              onlyCounted: true,
            ).single.copyWith(
              amount: Money(-1 - r.nextInt(30000), 'USD'),
              userCategoryId: budget.categoryId,
              splits: const [],
            );
        final BudgetStatus after = budgetStatus(budget, today, [
          ...transactions,
          more,
        ], lookup);
        expect(after.available, before.available, reason: reason);
        expect(after.spent > before.spent, isTrue, reason: reason);
        expect(
          after.thresholdsCrossed.toSet().containsAll(before.thresholdsCrossed),
          isTrue,
          reason: reason,
        );
        for (final BudgetStatus s in [before, after]) {
          expect(s.thresholdsCrossed, [
            if (s.available.isPositive)
              for (final int bp in budgetAlertThresholds)
                if (s.spent.minorUnits * 10000 >= s.available.minorUnits * bp)
                  bp,
          ], reason: reason);
        }
      }
    });

    test('spending ignores the order of transactions and splits, other '
        'currencies, deleted rows and excluded rows', () {
      for (int seed = base; seed < base + casesPerProperty; seed++) {
        final Random r = Random(seed);
        final (:budget, :today, :transactions) = scenario(r);
        final String reason = describe(seed, budget, today);
        BudgetStatus of(List<Transaction> ts) =>
            budgetStatus(budget, today, ts, lookup, excluded: excludedRow);
        final BudgetStatus s = of(transactions);
        final List<Transaction> shuffled = [
          for (final Transaction t in transactions)
            t.copyWith(splits: [...t.splits]..shuffle(r)),
        ]..shuffle(r);
        final List<Transaction> noise = [
          for (final Transaction t in randomTransactions(
            r,
            budget.startDate.addDays(-40),
            today.addDays(40),
            40,
            onlyCounted: true,
          ))
            switch (r.nextInt(3)) {
              0 => t.copyWith(
                id: 'eur-${t.id}',
                amount: Money(t.amount.minorUnits, 'EUR'),
                splits: const [],
              ),
              1 => t.copyWith(
                id: 'del-${t.id}',
                deletedAt: DateTime.utc(2026, 1, 2),
              ),
              _ => t.copyWith(id: 'hid-${t.id}', tags: const ['hidden']),
            },
        ];
        for (final BudgetStatus other in [
          of(shuffled),
          of([...noise, ...transactions]..shuffle(r)),
        ]) {
          expect(other.spent, s.spent, reason: reason);
          expect(other.carried, s.carried, reason: reason);
          expect(other.projected, s.projected, reason: reason);
          expect(other.thresholdsCrossed, s.thresholdsCrossed, reason: reason);
        }
      }
    });
  });
}
