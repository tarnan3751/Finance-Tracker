// The report math on worked examples (docs/reference/reports.md): the classification
// by effective category, splits, signs and currencies; a period's totals with the parent
// roll-up and the merchants; the savings rate; month-over-month and year-over-year on a
// partial period, including a clamp to a short month; the top movers and the trend.
import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:finance_tracker/features/budgets/domain/budget_period.dart';
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/reports/domain/report.dart';
import 'package:finance_tracker/features/reports/domain/report_period.dart';
import 'package:finance_tracker/features/reports/domain/transaction_kind.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

Money usd(int minor) => Money(minor, 'USD');

// A user category under the system "Income" and one with no code anywhere.
const Category sideGigs = Category(
  id: 'side-gigs',
  name: 'Side gigs',
  parentId: 'plaid:INCOME',
  isSystem: false,
  icon: 'payments',
  color: 0,
);
const Category misc = Category(
  id: 'misc',
  name: 'Misc',
  isSystem: false,
  icon: 'category',
  color: 0,
);
final CategoryLookup lookup = categoryLookup([
  ...systemCategories,
  sideGigs,
  misc,
]);

int _n = 0;
Transaction txn(
  LocalDate date,
  int minor, {
  String? code,
  String? category,
  String currency = 'USD',
  String? merchant,
  List<TransactionSplit> splits = const [],
  bool hidden = false,
  bool pending = false,
  DateTime? deletedAt,
}) => Transaction(
  id: 't${(_n++).toString().padLeft(4, '0')}',
  accountId: 'a1',
  amount: Money(minor, currency),
  date: date,
  pending: pending,
  name: merchant ?? 'Purchase',
  merchantName: merchant,
  userCategoryId: category,
  plaidDetailedCategory: code,
  splits: splits,
  hidden: hidden,
  source: DataSource.manual,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  deletedAt: deletedAt,
  syncVersion: 0,
);

List<ReportEntry> entries(List<Transaction> ts, {String currency = 'USD'}) =>
    reportEntries(
      ts,
      lookup,
      currencyCode: currency,
      excluded: (t) => t.hidden,
    ).toList();

ReportPeriod period(
  List<Transaction> ts,
  LocalDateRange range, {
  LocalDate? through,
}) => ReportPeriod.of(
  range,
  entries(ts),
  lookup,
  currencyCode: 'USD',
  through: through,
);

final LocalDateRange october = LocalDateRange(d(2026, 10, 1), d(2026, 11, 1));

void main() {
  group('the classification', () {
    TransactionKind kind(int minor, {String? code, String? category}) =>
        transactionKind(
          txn(d(2026, 10, 1), minor, code: code, category: category),
          lookup,
        );

    test('transfers both ways are transfers', () {
      expect(
        kind(-5000, code: 'TRANSFER_OUT_SAVINGS'),
        TransactionKind.transfer,
      );
      expect(
        kind(5000, code: 'TRANSFER_IN_ACCOUNT_TRANSFER'),
        TransactionKind.transfer,
      );
    });

    test('a loan payment is spending, its receiving leg a transfer', () {
      expect(
        kind(-30000, code: 'LOAN_PAYMENTS_CAR_PAYMENT'),
        TransactionKind.spend,
      );
      expect(
        kind(30000, code: 'LOAN_PAYMENTS_CREDIT_CARD_PAYMENT'),
        TransactionKind.transfer,
      );
    });

    test('a loan disbursement received is a transfer', () {
      expect(
        kind(500000, code: 'LOAN_DISBURSEMENTS_STUDENT'),
        TransactionKind.transfer,
      );
    });

    test('income is income whatever its sign', () {
      expect(kind(300000, code: 'INCOME_SALARY'), TransactionKind.income);
      expect(kind(-2000, code: 'INCOME_SALARY'), TransactionKind.income);
    });

    test('a refund under a spending category is spending', () {
      expect(
        kind(1500, code: 'FOOD_AND_DRINK_GROCERIES'),
        TransactionKind.spend,
      );
    });

    test('a user category takes its nearest ancestor\'s code', () {
      expect(kind(9000, category: 'side-gigs'), TransactionKind.income);
    });

    test('with no code at all the sign decides', () {
      expect(kind(9000, category: 'misc'), TransactionKind.income);
      expect(kind(-9000, category: 'misc'), TransactionKind.spend);
      expect(kind(9000), TransactionKind.income);
      expect(kind(-9000), TransactionKind.spend);
    });

    test('deleted, hidden and other-currency rows are not counted', () {
      expect(
        entries([
          txn(d(2026, 10, 2), -100, deletedAt: DateTime.utc(2026, 10, 3)),
          txn(d(2026, 10, 2), -100, hidden: true),
          txn(d(2026, 10, 2), -100, currency: 'EUR'),
          txn(d(2026, 10, 2), -100, pending: true),
        ]),
        hasLength(1),
      );
    });

    test('a split counts each split under its own category', () {
      final Transaction t = txn(
        d(2026, 10, 4),
        -10000,
        code: 'GENERAL_MERCHANDISE_SUPERSTORES',
        splits: [
          TransactionSplit(
            categoryId: 'plaid:FOOD_AND_DRINK_GROCERIES',
            amount: usd(-6000),
          ),
          TransactionSplit(
            categoryId: 'plaid:TRANSFER_OUT_SAVINGS',
            amount: usd(-3000),
          ),
          TransactionSplit(categoryId: 'gone', amount: usd(-1000)),
        ],
      );
      final List<ReportEntry> e = entries([t]);
      expect(
        [for (final x in e) (x.categoryId, x.kind, x.amount)],
        [
          ('plaid:FOOD_AND_DRINK_GROCERIES', TransactionKind.spend, usd(-6000)),
          ('plaid:TRANSFER_OUT_SAVINGS', TransactionKind.transfer, usd(-3000)),
          (null, TransactionKind.spend, usd(-1000)),
        ],
      );
    });

    test('spending in a category agrees with the budget math', () {
      final List<Transaction> ts = [
        txn(d(2026, 10, 3), -4500, code: 'FOOD_AND_DRINK_GROCERIES'),
        txn(d(2026, 10, 9), -2500, code: 'FOOD_AND_DRINK_RESTAURANT'),
        txn(d(2026, 10, 12), 700, code: 'FOOD_AND_DRINK_GROCERIES'),
        txn(
          d(2026, 10, 20),
          -9000,
          code: 'GENERAL_MERCHANDISE_SUPERSTORES',
          splits: [
            TransactionSplit(
              categoryId: 'plaid:FOOD_AND_DRINK_GROCERIES',
              amount: usd(-5000),
            ),
            TransactionSplit(
              categoryId: 'plaid:GENERAL_MERCHANDISE_SUPERSTORES',
              amount: usd(-4000),
            ),
          ],
        ),
        txn(d(2026, 10, 21), -800, code: 'FOOD_AND_DRINK_COFFEE', hidden: true),
      ];
      final ReportPeriod p = period(ts, october);
      final Money food = p.spendByCategory
          .firstWhere((t) => t.categoryId == 'plaid:FOOD_AND_DRINK')
          .total;
      final Money budgeted = spentIn(
        october,
        Budget(
          id: 'b',
          categoryId: 'plaid:FOOD_AND_DRINK',
          period: BudgetPeriodKind.monthly,
          periodStartDay: 1,
          amount: usd(100000),
          rollover: false,
          startDate: d(2026, 1, 1),
        ),
        ts,
        lookup,
        excluded: (t) => t.hidden,
      );
      expect(food, usd(11300));
      expect(food, budgeted);
    });
  });

  group('a period', () {
    final List<Transaction> ts = [
      txn(
        d(2026, 10, 1),
        400000,
        code: 'INCOME_SALARY',
        merchant: 'Acme Payroll',
      ),
      txn(
        d(2026, 10, 2),
        -165000,
        code: 'RENT_AND_UTILITIES_RENT',
        merchant: 'Parkside Lofts',
      ),
      txn(
        d(2026, 10, 5),
        -6000,
        code: 'FOOD_AND_DRINK_GROCERIES',
        merchant: 'Whole Foods',
      ),
      txn(
        d(2026, 10, 12),
        -4000,
        code: 'FOOD_AND_DRINK_GROCERIES',
        merchant: 'Whole Foods',
      ),
      txn(
        d(2026, 10, 15),
        -2500,
        code: 'FOOD_AND_DRINK_RESTAURANT',
        merchant: 'Sweetgreen',
      ),
      txn(
        d(2026, 10, 16),
        1000,
        code: 'FOOD_AND_DRINK_GROCERIES',
        merchant: 'Whole Foods',
      ),
      txn(d(2026, 10, 20), -50000, code: 'TRANSFER_OUT_SAVINGS'),
      txn(
        d(2026, 10, 31),
        -1500,
        code: 'FOOD_AND_DRINK_COFFEE',
        merchant: 'Starbucks',
      ),
      // Outside the period.
      txn(d(2026, 11, 1), -9999, code: 'FOOD_AND_DRINK_COFFEE'),
      txn(d(2026, 9, 30), -9999, code: 'FOOD_AND_DRINK_COFFEE'),
    ];

    test('totals by kind, the roll-up and the merchants', () {
      final ReportPeriod p = period(ts, october);
      expect(p.spend, usd(178000));
      expect(p.income, usd(400000));
      expect(p.transferNet, usd(-50000));
      expect(p.net, usd(222000));
      expect(p.counts, {
        TransactionKind.spend: 6,
        TransactionKind.income: 1,
        TransactionKind.transfer: 1,
      });
      expect(p.partial, isFalse);

      final List<CategoryTotal> top = ReportPeriod.topLevel(p.spendByCategory);
      expect(
        [for (final t in top) (t.categoryId, t.total)],
        [
          ('plaid:RENT_AND_UTILITIES', usd(165000)),
          ('plaid:FOOD_AND_DRINK', usd(13000)),
        ],
      );
      expect(
        [
          for (final t in ReportPeriod.childrenOf(
            p.spendByCategory,
            'plaid:FOOD_AND_DRINK',
          ))
            (t.categoryId, t.own),
        ],
        [
          ('plaid:FOOD_AND_DRINK_GROCERIES', usd(9000)),
          ('plaid:FOOD_AND_DRINK_RESTAURANT', usd(2500)),
          ('plaid:FOOD_AND_DRINK_COFFEE', usd(1500)),
        ],
      );
      expect(
        [for (final m in p.spendByMerchant) (m.displayName, m.total, m.count)],
        [
          ('Parkside Lofts', usd(165000), 1),
          ('Whole Foods', usd(9000), 3),
          ('Sweetgreen', usd(2500), 1),
          ('Starbucks', usd(1500), 1),
        ],
      );
    });

    test('the savings rate is kept income in basis points, rounded down', () {
      // 222000 / 400000 = 55.5 %.
      expect(period(ts, october).savingsRateBasisPoints, 5550);
      final ReportPeriod third = period([
        txn(d(2026, 10, 1), 30000, code: 'INCOME_SALARY'),
        txn(d(2026, 10, 2), -20000, code: 'FOOD_AND_DRINK_GROCERIES'),
      ], october);
      // 1/3 is 3333.33... basis points.
      expect(third.savingsRateBasisPoints, 3333);
      final ReportPeriod overspent = period([
        txn(d(2026, 10, 1), 10000, code: 'INCOME_SALARY'),
        txn(d(2026, 10, 2), -15001, code: 'FOOD_AND_DRINK_GROCERIES'),
      ], october);
      expect(overspent.savingsRateBasisPoints, -5001);
      expect(
        period([
          txn(d(2026, 10, 2), -100, code: 'FOOD_AND_DRINK_GROCERIES'),
        ], october).savingsRateBasisPoints,
        isNull,
      );
    });

    test('a running period is counted to today', () {
      final ReportPeriod p = period(ts, october, through: d(2026, 10, 12));
      expect(p.partial, isTrue);
      expect(p.elapsedDays, 12);
      expect(p.spend, usd(175000));
    });
  });

  group('the report', () {
    // Each month: income 3000.00 on the 1st, groceries on the 3rd and the 20th; a
    // restaurant only in September; coffee new in October.
    final List<Transaction> ts = [
      for (int m = 1; m <= 12; m++) ...[
        txn(d(2025, m, 1), 300000, code: 'INCOME_SALARY'),
        txn(
          d(2025, m, 3),
          -10000,
          code: 'FOOD_AND_DRINK_GROCERIES',
          merchant: 'Safeway',
        ),
      ],
      for (int m = 1; m <= 10; m++) ...[
        txn(d(2026, m, 1), 300000, code: 'INCOME_SALARY'),
        txn(
          d(2026, m, 3),
          -12000,
          code: 'FOOD_AND_DRINK_GROCERIES',
          merchant: 'Safeway',
        ),
        txn(
          d(2026, m, 20),
          -8000,
          code: 'FOOD_AND_DRINK_GROCERIES',
          merchant: 'Safeway',
        ),
      ],
      txn(
        d(2026, 9, 10),
        -30000,
        code: 'FOOD_AND_DRINK_RESTAURANT',
        merchant: 'Olive Garden',
      ),
      txn(
        d(2026, 10, 10),
        -500,
        code: 'FOOD_AND_DRINK_COFFEE',
        merchant: 'Starbucks',
      ),
    ];

    Report report(LocalDate today, {LocalDateRange? shown, int startDay = 1}) =>
        buildReport(
          period: shown ?? periodContaining(today, startDay),
          periodStartDay: startDay,
          today: today,
          currencyCode: 'USD',
          entries: entries(ts),
          lookup: lookup,
        );

    test('a partial period is compared on the same elapsed day', () {
      final Report r = report(d(2026, 10, 15));
      expect(r.current.through, d(2026, 10, 15));
      expect(r.previous.range, LocalDateRange(d(2026, 9, 1), d(2026, 10, 1)));
      expect(r.previous.through, d(2026, 9, 15));
      expect(r.yearAgo.through, d(2025, 10, 15));
      // October to the 15th: 120.00 + 5.00; September to the 15th: 120.00 + 300.00.
      expect(r.spendMonthOverMonth.current, usd(12500));
      expect(r.spendMonthOverMonth.previous, usd(42000));
      expect(r.spendMonthOverMonth.change, usd(-29500));
      // -295 / 420 = -70.238 % -> -7024 basis points.
      expect(r.spendMonthOverMonth.percentBasisPoints, -7024);
      // A year before, to the 15th: 100.00.
      expect(r.spendYearOverYear.previous, usd(10000));
      expect(r.spendYearOverYear.percentBasisPoints, 2500);
      expect(r.incomeYearOverYear.percentBasisPoints, 0);
    });

    test('a past period is compared whole', () {
      final Report r = report(
        d(2026, 10, 15),
        shown: LocalDateRange(d(2026, 9, 1), d(2026, 10, 1)),
      );
      expect(r.current.partial, isFalse);
      expect(r.current.spend, usd(50000));
      expect(r.previous.spend, usd(20000));
      expect(r.previous.through, d(2026, 8, 31));
    });

    test('the same elapsed day is clamped to a shorter month', () {
      // 31 March, 31 days in: February is counted whole, to the 28th.
      final Report r = report(d(2026, 3, 31));
      expect(r.previous.range, LocalDateRange(d(2026, 2, 1), d(2026, 3, 1)));
      expect(r.previous.through, d(2026, 2, 28));
      expect(r.previous.partial, isFalse);
    });

    test('the top movers, with "new" on a zero base', () {
      final Report r = report(d(2026, 10, 31));
      expect(
        [
          for (final Mover m in r.categoryMovers)
            (m.id, m.change.change, m.change.percentBasisPoints),
        ],
        [
          ('plaid:FOOD_AND_DRINK_RESTAURANT', usd(-30000), -10000),
          ('plaid:FOOD_AND_DRINK_COFFEE', usd(500), null),
        ],
      );
      expect(
        [for (final m in r.merchantMovers) m.displayName],
        ['Olive Garden', 'Starbucks'],
      );
    });

    test('at most ten movers, by the size of the change, then by id', () {
      final List<Transaction> many = [
        for (int i = 0; i < 12; i++)
          txn(
            d(2026, 10, 5),
            -(1000 + (i ~/ 2) * 100),
            merchant: 'Shop ${i.toString().padLeft(2, '0')}',
          ),
      ];
      final Report r = buildReport(
        period: october,
        periodStartDay: 1,
        today: d(2026, 10, 31),
        currencyCode: 'USD',
        entries: entries(many),
        lookup: lookup,
      );
      expect(r.merchantMovers, hasLength(topMoverLimit));
      expect(
        [for (final m in r.merchantMovers.take(3)) m.displayName],
        ['Shop 10', 'Shop 11', 'Shop 08'],
      );
    });

    test('the trends end with the period shown', () {
      final Report r = report(d(2026, 10, 15));
      expect(r.trend, hasLength(longTrendPeriods));
      expect(r.shortTrend, hasLength(shortTrendPeriods));
      expect(r.trend.first.range.start, d(2025, 11, 1));
      expect(r.trend.last.range.start, d(2026, 10, 1));
      expect(r.trend.last.spend, usd(12500));
      expect(r.trend[10].spend, usd(50000));
      expect(r.trend[10].net, usd(250000));
      expect(r.shortTrend.first.range.start, d(2026, 5, 1));
    });

    test('periods follow the start day', () {
      final Report r = report(d(2026, 10, 15), startDay: 20);
      expect(r.current.range, LocalDateRange(d(2026, 9, 20), d(2026, 10, 20)));
      // 20 Sep (80.00), 3 Oct (120.00) and 10 Oct (5.00), to the 15th.
      expect(r.current.spend, usd(20500));
    });
  });
}
