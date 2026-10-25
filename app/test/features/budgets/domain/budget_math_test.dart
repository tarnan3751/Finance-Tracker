// Budget periods and math on worked examples (the ones docs/reference/budgets.md walks
// through among them): period boundaries, spending by category group and splits, signs,
// currencies, exclusion, rollover, projection and the thresholds at their edges.
import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:finance_tracker/features/budgets/domain/budget_period.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

const Category food = Category(
  id: 'food',
  name: 'Food',
  isSystem: false,
  icon: 'restaurant',
  color: 0,
);
const Category groceries = Category(
  id: 'groceries',
  name: 'Groceries',
  parentId: 'food',
  isSystem: false,
  icon: 'restaurant',
  color: 0,
);
const Category rides = Category(
  id: 'rides',
  name: 'Rides',
  isSystem: true,
  icon: 'car',
  color: 0,
  plaidCategory: 'TRANSPORTATION_TAXIS_AND_RIDE_SHARES',
);
final CategoryLookup lookup = categoryLookup([food, groceries, rides]);

Budget budget({
  String categoryId = 'food',
  int amount = 40000,
  String currency = 'USD',
  int startDay = 1,
  bool rollover = false,
  LocalDate? startDate,
}) => Budget(
  id: 'b1',
  categoryId: categoryId,
  period: BudgetPeriodKind.monthly,
  periodStartDay: startDay,
  amount: Money(amount, currency),
  rollover: rollover,
  startDate: startDate ?? d(2026, 1, 1),
);

int _n = 0;
Transaction txn(
  LocalDate date,
  int minor, {
  String? category = 'groceries',
  String currency = 'USD',
  List<TransactionSplit> splits = const [],
  bool pending = false,
  String? plaidDetailed,
  List<String> tags = const [],
}) => Transaction(
  id: 't${_n++}',
  accountId: 'a1',
  amount: Money(minor, currency),
  date: date,
  pending: pending,
  name: 'Purchase',
  userCategoryId: category,
  plaidDetailedCategory: plaidDetailed,
  splits: splits,
  tags: tags,
  source: DataSource.manual,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  syncVersion: 0,
);

void main() {
  group('periods', () {
    test('a period starts on its start day on or before the date', () {
      expect(
        periodContaining(d(2026, 10, 24), 1),
        LocalDateRange(d(2026, 10, 1), d(2026, 11, 1)),
      );
      expect(
        periodContaining(d(2026, 10, 24), 25),
        LocalDateRange(d(2026, 9, 25), d(2026, 10, 25)),
      );
      expect(
        periodContaining(d(2026, 10, 25), 25),
        LocalDateRange(d(2026, 10, 25), d(2026, 11, 25)),
      );
      expect(
        periodContaining(d(2027, 1, 10), 15),
        LocalDateRange(d(2026, 12, 15), d(2027, 1, 15)),
      );
      expect(
        periodContaining(d(2024, 2, 29), 28),
        LocalDateRange(d(2024, 2, 28), d(2024, 3, 28)),
      );
      expect(periodContaining(d(2026, 2, 1), 1).length, 28);
      expect(periodContaining(d(2024, 2, 1), 1).length, 29);
    });

    test('a start day outside 1 to 28 is an ArgumentError', () {
      for (final int day in [0, 29, 31, -1]) {
        expect(() => periodContaining(d(2026, 1, 1), day), throwsArgumentError);
        expect(
          () => periodsFrom(d(2026, 1, 1), day, through: d(2026, 3, 1)),
          throwsArgumentError,
        );
      }
    });

    test('periodsFrom lists the periods from the start date through a day', () {
      expect(periodsFrom(d(2026, 8, 10), 15, through: d(2026, 10, 20)), [
        LocalDateRange(d(2026, 7, 15), d(2026, 8, 15)),
        LocalDateRange(d(2026, 8, 15), d(2026, 9, 15)),
        LocalDateRange(d(2026, 9, 15), d(2026, 10, 15)),
        LocalDateRange(d(2026, 10, 15), d(2026, 11, 15)),
      ]);
      expect(periodsFrom(d(2026, 8, 10), 15, through: d(2026, 7, 14)), isEmpty);
      expect(
        periodsFrom(d(2026, 8, 10), 15, through: d(2026, 7, 15)),
        hasLength(1),
      );
    });
  });

  group('spending', () {
    final LocalDateRange october = LocalDateRange(
      d(2026, 10, 1),
      d(2026, 11, 1),
    );

    test('a parent budgets its group; outflows count positive, refunds '
        'negative, pending included', () {
      final List<Transaction> ts = [
        txn(d(2026, 10, 2), -5000),
        txn(d(2026, 10, 3), -2500, category: 'food', pending: true),
        txn(d(2026, 10, 4), 1000), // a refund
        txn(d(2026, 10, 5), -9999, category: 'rides'),
        txn(d(2026, 10, 6), -7000, category: null),
        txn(d(2026, 9, 30), -100000), // the period before
        txn(d(2026, 11, 1), -100000), // the period after
      ];
      expect(spentIn(october, budget(), ts, lookup), Money(6500, 'USD'));
      expect(
        spentIn(october, budget(categoryId: 'groceries'), ts, lookup),
        Money(4000, 'USD'),
      );
    });

    test('splits count by their own category', () {
      final Transaction split = txn(
        d(2026, 10, 2),
        -10000,
        category: 'rides',
        splits: [
          TransactionSplit(
            categoryId: 'groceries',
            amount: Money(-6000, 'USD'),
          ),
          TransactionSplit(categoryId: 'rides', amount: Money(-4000, 'USD')),
        ],
      );
      expect(spentIn(october, budget(), [split], lookup), Money(6000, 'USD'));
      expect(
        spentIn(october, budget(categoryId: 'rides'), [split], lookup),
        Money(4000, 'USD'),
      );
    });

    test('the effective category: a Plaid code when there is no user one', () {
      final Transaction uber = txn(
        d(2026, 10, 2),
        -1800,
        category: null,
        plaidDetailed: 'TRANSPORTATION_TAXIS_AND_RIDE_SHARES',
      );
      final Transaction gone = txn(
        d(2026, 10, 3),
        -700,
        category: 'deleted-category',
        plaidDetailed: 'TRANSPORTATION_TAXIS_AND_RIDE_SHARES',
      );
      expect(
        spentIn(october, budget(categoryId: 'rides'), [uber, gone], lookup),
        Money(2500, 'USD'),
      );
    });

    test('other currencies, deleted rows and excluded rows do not count', () {
      final List<Transaction> ts = [
        txn(d(2026, 10, 2), -5000),
        txn(d(2026, 10, 2), -5000, currency: 'EUR'),
        txn(d(2026, 10, 2), -5000).copyWith(deletedAt: DateTime.utc(2026, 10)),
        txn(d(2026, 10, 2), -5000, tags: ['hidden']),
      ];
      expect(
        spentIn(
          october,
          budget(),
          ts,
          lookup,
          excluded: (t) => t.tags.contains('hidden'),
        ),
        Money(5000, 'USD'),
      );
    });
  });

  group('status', () {
    test('rollover carries the signed remainder of each earlier period', () {
      // $400 a month from August: August spends $350 (+$50), September $460 (-$60).
      final Budget b = budget(rollover: true, startDate: d(2026, 8, 1));
      final List<Transaction> ts = [
        txn(d(2026, 8, 12), -35000),
        txn(d(2026, 9, 3), -46000),
        txn(d(2026, 10, 9), -12000),
      ];
      final BudgetStatus s = budgetStatus(b, d(2026, 10, 15), ts, lookup);
      expect(s.period, LocalDateRange(d(2026, 10, 1), d(2026, 11, 1)));
      expect(s.spent, Money(12000, 'USD'));
      expect(s.carried, Money(-1000, 'USD'));
      expect(s.available, Money(39000, 'USD'));
      expect(s.remaining, Money(27000, 'USD'));
      expect(s.progress, Ratio.of(Money(12000, 'USD'), Money(39000, 'USD')));
      expect(s.progress.percentBasisPoints, 3076);
      expect(s.elapsedDays, 15);
      expect(s.projected, Money(24800, 'USD')); // 120 × 31 ÷ 15
      expect(s.projectedOverspend, isFalse);
      expect(s.thresholdsCrossed, isEmpty);

      final BudgetStatus off = budgetStatus(
        b.copyWith(rollover: false),
        d(2026, 10, 15),
        ts,
        lookup,
      );
      expect(off.carried, Money(0, 'USD'));
      expect(off.available, Money(40000, 'USD'));
    });

    test('the projection is linear on elapsed days, rounded half-even', () {
      // Start day 25: the period is 25 October to 24 November, 31 days; on the 30th,
      // six have elapsed.
      final Budget b = budget(amount: 60000, startDay: 25);
      final BudgetStatus s = budgetStatus(b, d(2026, 10, 30), [
        txn(d(2026, 10, 26), -20000),
        txn(d(2026, 10, 24), -99999), // the period before
      ], lookup);
      expect(s.period, LocalDateRange(d(2026, 10, 25), d(2026, 11, 25)));
      expect(s.elapsedDays, 6);
      expect(s.projected, Money(103333, 'USD')); // 200 × 31 ÷ 6 = 1033.33
      expect(s.projectedOverspend, isTrue);
      final BudgetStatus last = budgetStatus(b, d(2026, 11, 24), [
        txn(d(2026, 10, 26), -20000),
      ], lookup);
      expect(last.elapsedDays, 31);
      expect(last.projected, last.spent);
    });

    test('thresholds are reached exactly at 80 % and 100 % of available', () {
      List<int> crossed(int amount, int spent) => budgetStatus(
        budget(amount: amount),
        d(2026, 10, 15),
        [txn(d(2026, 10, 2), -spent)],
        lookup,
      ).thresholdsCrossed;
      expect(crossed(10000, 7999), isEmpty);
      expect(crossed(10000, 8000), [8000]);
      expect(crossed(10000, 9999), [8000]);
      expect(crossed(10000, 10000), [8000, 10000]);
      expect(crossed(10001, 8000), isEmpty); // 80 % is 8000.8
      expect(crossed(10001, 8001), [8000]);
      expect(crossed(10000, 20000), [8000, 10000]);
    });

    test('nothing available: no thresholds and no percentage', () {
      final BudgetStatus zero = budgetStatus(
        budget(amount: 0),
        d(2026, 10, 15),
        [txn(d(2026, 10, 2), -500)],
        lookup,
      );
      expect(zero.thresholdsCrossed, isEmpty);
      expect(zero.progress.percentBasisPoints, isNull);
      expect(zero.progress.numerator, 500);
      expect(zero.progress.denominator, 0);
      expect(zero.projectedOverspend, isTrue);

      // Overspent so far that the carry wipes out the amount.
      final BudgetStatus negative = budgetStatus(
        budget(amount: 10000, rollover: true, startDate: d(2026, 9, 1)),
        d(2026, 10, 15),
        [txn(d(2026, 9, 2), -30000), txn(d(2026, 10, 2), -100)],
        lookup,
      );
      expect(negative.available, Money(-10000, 'USD'));
      expect(negative.thresholdsCrossed, isEmpty);
      expect(negative.progress.percentBasisPoints, isNull);
    });

    test('a budget that starts after today carries nothing', () {
      final BudgetStatus s = budgetStatus(
        budget(rollover: true, startDate: d(2027, 1, 1)),
        d(2026, 10, 15),
        [txn(d(2026, 10, 2), -500), txn(d(2026, 9, 2), -500)],
        lookup,
      );
      expect(s.carried, Money(0, 'USD'));
      expect(s.spent, Money(500, 'USD'));
    });
  });
}
