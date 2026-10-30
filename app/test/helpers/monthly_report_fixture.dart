// The fixed input of the monthly report's hash golden, shared by the host test
// (test/features/export/domain/monthly_report_pdf_test.dart) and the device test
// (integration_test/export_test.dart), which must produce the same bytes from it.
//
// A synthetic household, October 2026 seen on 5 November (the period complete): a
// salary, the rent, twelve spending groups (so the bars end in "Other"), Food with
// Groceries and Restaurants under it and rows of its own, twelve merchants (one of them
// "Café Olé", outside ASCII), September and the October before for the comparisons and
// movers; three flags built by hand (so a change to the anomaly rule does not move the
// hash), three bill occurrences (paid, missed, and one without a name) and two budgets
// (one over, one whose category is gone). In English, amounts in en_US.
//
// Every value here feeds the golden: a change to it is a change to the hash, made on
// purpose.
import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:finance_tracker/features/export/application/export_providers.dart';
import 'package:finance_tracker/features/export/domain/monthly_report.dart';
import 'package:finance_tracker/features/export/domain/monthly_report_pdf.dart';
import 'package:finance_tracker/features/reports/domain/anomalies.dart';
import 'package:finance_tracker/features/reports/domain/report.dart';
import 'package:finance_tracker/features/reports/domain/transaction_kind.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:shared_models/shared_models.dart';

/// The SHA-256 of the fixture's PDF. A change to the drawing, the fixture, the strings,
/// the fonts or the `pdf` package changes it: regenerate it deliberately (the test
/// prints the new one and leaves the PDF under `build/` to look at), never to make a
/// failure go away.
const String monthlyReportFixtureSha256 =
    'a44aa9368b73eb15d40c8d03253d23e815638c8bbbfc7164f54dc75a59e56aee';

/// The locale the fixture is drawn in.
const String monthlyReportFixtureLocale = 'en_US';

/// The fixture's texts: the app's English strings.
MonthlyReportStrings monthlyReportFixtureStrings() =>
    monthlyReportStrings(lookupAppLocalizations(const Locale('en')));

final DateTime _at = DateTime.utc(2026, 11, 5, 12);

LocalDate _d(int year, int month, int day) => LocalDate(year, month, day);

Category _category(String id, String name, {String? parent}) => Category(
  id: id,
  name: name,
  parentId: parent,
  isSystem: false,
  icon: 'category',
  color: 0,
);

final List<Category> _categories = [
  _category('food', 'Food'),
  _category('groceries', 'Groceries', parent: 'food'),
  _category('restaurants', 'Restaurants', parent: 'food'),
  _category('housing', 'Housing'),
  _category('transport', 'Transport'),
  _category('utilities', 'Utilities'),
  _category('health', 'Health'),
  _category('fun', 'Entertainment'),
  _category('shopping', 'Shopping'),
  _category('travel', 'Travel'),
  _category('gifts', 'Gifts'),
  _category('pets', 'Pets'),
  _category('kids', 'Kids'),
  _category('books', 'Books'),
  _category('salary', 'Salary'),
];

Transaction _t(
  String id,
  LocalDate date,
  int cents,
  String merchant, [
  String? category,
]) => Transaction(
  id: id,
  accountId: 'fixture-checking',
  amount: Money(cents, 'USD'),
  date: date,
  pending: false,
  name: merchant,
  merchantName: merchant,
  userCategoryId: category,
  source: DataSource.manual,
  createdAt: _at,
  updatedAt: _at,
  syncVersion: 0,
);

// One month of the household: [scale] percent of the usual amounts.
List<Transaction> _month(int year, int month, int scale) {
  int c(int cents) => cents * scale ~/ 100;
  final String m = '$year-$month';
  return [
    _t('$m-salary', _d(year, month, 1), 520000, 'Acme Payroll', 'salary'),
    _t('$m-rent', _d(year, month, 2), -180000, 'Oak Street Rentals', 'housing'),
    _t('$m-safeway', _d(year, month, 5), -c(14250), 'Safeway', 'groceries'),
    _t(
      '$m-market',
      _d(year, month, 12),
      -c(6375),
      'Corner Market',
      'groceries',
    ),
    _t('$m-bistro', _d(year, month, 9), -c(8840), 'Café Olé', 'restaurants'),
    _t('$m-deli', _d(year, month, 14), -c(2215), 'Deli on Main', 'food'),
    _t(
      '$m-transit',
      _d(year, month, 3),
      -c(9900),
      'Metro Transit',
      'transport',
    ),
    _t('$m-power', _d(year, month, 16), -c(11320), 'City Power', 'utilities'),
    _t('$m-pharmacy', _d(year, month, 18), -c(3460), 'Walgreens', 'health'),
    _t('$m-cinema', _d(year, month, 20), -c(3200), 'Regal Cinema', 'fun'),
    _t('$m-target', _d(year, month, 22), -c(7815), 'Target', 'shopping'),
    _t('$m-air', _d(year, month, 23), -c(24600), 'Delta Air Lines', 'travel'),
    _t('$m-florist', _d(year, month, 25), -c(4500), 'Bloom Florist', 'gifts'),
    _t('$m-petco', _d(year, month, 26), -c(5630), 'Petco', 'pets'),
    _t('$m-toys', _d(year, month, 27), -c(2999), 'Toy Barn', 'kids'),
    _t('$m-books', _d(year, month, 28), -c(1899), 'Powell\'s Books', 'books'),
    _t('$m-refund', _d(year, month, 29), c(1500), 'Target', 'shopping'),
  ];
}

/// The fixture's transactions: October 2026, the two months before it, and October
/// 2025.
List<Transaction> monthlyReportFixtureTransactions() => [
  ..._month(2025, 10, 90),
  ..._month(2026, 8, 95),
  ..._month(2026, 9, 100),
  ..._month(2026, 10, 110),
  _t('2026-10-guitar', _d(2026, 10, 19), -38900, 'Guitar Center', 'fun'),
];

/// The fixture's data.
MonthlyReportData monthlyReportFixture() {
  final CategoryLookup lookup = categoryLookup(_categories);
  final List<Transaction> ledger = monthlyReportFixtureTransactions();
  final LocalDate today = _d(2026, 11, 5);
  final LocalDateRange october = LocalDateRange(
    _d(2026, 10, 1),
    _d(2026, 11, 1),
  );
  final Report report = buildReport(
    period: october,
    periodStartDay: 1,
    today: today,
    currencyCode: 'USD',
    entries: reportEntries(
      ledger,
      lookup,
      currencyCode: 'USD',
      creditAccountIds: const {},
    ).toList(),
    lookup: lookup,
  );
  Transaction byId(String id) => ledger.firstWhere((t) => t.id == id);
  Budget budget(String id, String category, int cents) => Budget(
    id: id,
    categoryId: category,
    period: BudgetPeriodKind.monthly,
    periodStartDay: 1,
    amount: Money(cents, 'USD'),
    rollover: false,
    startDate: _d(2026, 1, 1),
  );
  BudgetStatus status(Budget b) =>
      budgetStatus(b, _d(2026, 10, 31), ledger, lookup);
  return MonthlyReportData(
    report: report,
    categoryNames: {for (final Category c in _categories) c.id: c.name},
    anomalies: [
      AnomalyFlag(
        kind: AnomalyKind.unusualAmount,
        transaction: byId('2026-10-air'),
        amount: Money(-27060, 'USD'),
        basis: AnomalyBasis.merchant,
        median: Money(9800, 'USD'),
        mad: Money(1200, 'USD'),
      ),
      AnomalyFlag(
        kind: AnomalyKind.unusualAmount,
        transaction: byId('2026-10-power'),
        amount: Money(-12452, 'USD'),
        basis: AnomalyBasis.category,
        median: Money(4100, 'USD'),
        mad: Money(300, 'USD'),
      ),
      AnomalyFlag(
        kind: AnomalyKind.newMerchant,
        transaction: byId('2026-10-guitar'),
        amount: Money(-38900, 'USD'),
        since: _d(2026, 4, 19),
      ),
    ],
    bills: [
      ReportBill(
        name: 'Rent',
        due: _d(2026, 10, 2),
        amount: Money(-180000, 'USD'),
        state: BillState.paid,
      ),
      ReportBill(
        name: 'Streaming',
        due: _d(2026, 10, 14),
        amount: Money(-1599, 'USD'),
        state: BillState.missed,
      ),
      ReportBill(
        name: null,
        due: _d(2026, 10, 30),
        amount: null,
        state: BillState.paid,
      ),
    ],
    budgets: [
      ReportBudget(
        name: 'Food',
        status: status(budget('b-food', 'food', 30000)),
      ),
      ReportBudget(
        name: null,
        status: status(budget('b-gone', 'deleted', 5000)),
      ),
    ],
  );
}
