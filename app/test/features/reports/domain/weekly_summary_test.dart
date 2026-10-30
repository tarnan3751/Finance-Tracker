// The weekly summary's week and totals: Monday to Sunday whatever the day, the three
// biggest top-level categories and the biggest merchant, the current week counted to
// today.
import 'package:finance_tracker/features/categories/data/category_defaults.dart';
import 'package:finance_tracker/features/reports/domain/transaction_kind.dart';
import 'package:finance_tracker/features/reports/domain/weekly_summary.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

LocalDate d(int y, int m, int day) => LocalDate(y, m, day);

final CategoryLookup lookup = categoryLookup(systemCategories);

int _n = 0;
Transaction txn(LocalDate date, int minor, String code, String merchant) =>
    Transaction(
      id: 't${_n++}',
      accountId: 'a1',
      amount: Money(minor, 'USD'),
      date: date,
      pending: false,
      name: merchant,
      merchantName: merchant,
      plaidDetailedCategory: code,
      source: DataSource.manual,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      syncVersion: 0,
    );

void main() {
  test('a week runs from Monday to Sunday', () {
    final LocalDateRange week = LocalDateRange(
      d(2026, 10, 19),
      d(2026, 10, 26),
    );
    for (int i = 0; i < 7; i++) {
      expect(weekContaining(d(2026, 10, 19).addDays(i)), week);
    }
    expect(weekContaining(d(2026, 10, 26)).start, d(2026, 10, 26));
    // Across a year's end.
    expect(weekContaining(d(2027, 1, 1)).start, d(2026, 12, 28));
  });

  final List<Transaction> ts = [
    txn(d(2026, 10, 12), 400000, 'INCOME_SALARY', 'Acme Payroll'),
    txn(d(2026, 10, 12), -165000, 'RENT_AND_UTILITIES_RENT', 'Parkside Lofts'),
    txn(d(2026, 10, 13), -8000, 'FOOD_AND_DRINK_GROCERIES', 'Safeway'),
    txn(d(2026, 10, 15), -3000, 'FOOD_AND_DRINK_RESTAURANT', 'Olive Garden'),
    txn(d(2026, 10, 16), -6000, 'TRANSPORTATION_GAS', 'Shell'),
    txn(d(2026, 10, 17), -2000, 'ENTERTAINMENT_TV_AND_MOVIES', 'AMC'),
    txn(d(2026, 10, 18), -50000, 'TRANSFER_OUT_SAVINGS', 'Savings'),
    txn(d(2026, 10, 19), -1000, 'FOOD_AND_DRINK_COFFEE', 'Blue Bottle'),
    txn(d(2026, 10, 22), -2500, 'FOOD_AND_DRINK_COFFEE', 'Blue Bottle'),
  ];
  List<ReportEntry> entries() => reportEntries(
    ts,
    lookup,
    currencyCode: 'USD',
    creditAccountIds: const {},
  ).toList();

  test('a week\'s totals, biggest categories and merchant', () {
    final WeeklySummary w = WeeklySummary.of(
      weekContaining(d(2026, 10, 14)),
      entries(),
      lookup,
      currencyCode: 'USD',
    );
    expect(w.period.spend, Money(184000, 'USD'));
    expect(w.period.income, Money(400000, 'USD'));
    expect(w.period.net, Money(216000, 'USD'));
    expect(
      [for (final c in w.topCategories) (c.categoryId, c.total.minorUnits)],
      [
        ('plaid:RENT_AND_UTILITIES', 165000),
        ('plaid:FOOD_AND_DRINK', 11000),
        ('plaid:TRANSPORTATION', 6000),
      ],
    );
    expect(w.topMerchant?.displayName, 'Parkside Lofts');
  });

  test('the current week is counted to today', () {
    final WeeklySummary w = WeeklySummary.of(
      weekContaining(d(2026, 10, 21)),
      entries(),
      lookup,
      currencyCode: 'USD',
      through: d(2026, 10, 21),
    );
    expect(w.period.spend, Money(1000, 'USD'));
    expect(w.topCategories.single.categoryId, 'plaid:FOOD_AND_DRINK');
  });

  test('an empty week has no biggest merchant', () {
    final WeeklySummary w = WeeklySummary.of(
      weekContaining(d(2026, 11, 2)),
      entries(),
      lookup,
      currencyCode: 'USD',
    );
    expect(w.topCategories, isEmpty);
    expect(w.topMerchant, isNull);
  });
}
