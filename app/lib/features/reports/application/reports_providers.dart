/// What the Reports segment shows (`docs/reference/reports.md`, **Providers**): the
/// period the reports follow, the currency, and the report of the period chosen.
library;

import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/budgets/application/budgets_providers.dart';
import 'package:finance_tracker/features/budgets/domain/budget_period.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/recurring/application/merged_streams.dart';
import 'package:finance_tracker/features/reports/domain/report.dart';
import 'package:finance_tracker/features/reports/domain/transaction_kind.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'reports_providers.g.dart';

/// The day of the month report periods start: the start day every live budget shares,
/// else 1 (calendar months).
@riverpod
Future<int> reportStartDay(Ref ref) async {
  final Set<int> days = {
    for (final Budget b in await ref.watch(budgetsProvider.future))
      b.periodStartDay,
  };
  return days.length == 1 ? days.single : 1;
}

/// The currency the reports are in: the device's default currency when an account holds
/// it, else the first account's in display order, else the default.
@riverpod
Future<String> reportCurrency(Ref ref) async {
  final List<Account> accounts = await ref.watch(accountsProvider.future);
  final String preferred = defaultCurrencyCode();
  if (accounts.isEmpty || accounts.any((a) => a.currencyCode == preferred)) {
    return preferred;
  }
  return ([...accounts]
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)))
      .first
      .currencyCode;
}

/// The live credit accounts' ids, whose inflows pair the credit card payments
/// (`pairedCardPayments`).
@riverpod
Future<Set<String>> reportCreditAccountIds(Ref ref) async => {
  for (final Account a in await ref.watch(accountsProvider.future))
    if (a.type == AccountType.credit) a.id,
};

/// Which period the Reports segment shows: 0 for the current one, -1 for the one before.
/// Its own, apart from the budgets'.
@riverpod
class ReportPeriodOffset extends _$ReportPeriodOffset {
  @override
  int build() => 0;

  /// Shows the period [offset] periods after the current one.
  void select(int offset) => state = offset;
}

/// The report of the period [offset] periods after today's, over every live
/// transaction (`recurringLedgerProvider`), hidden ones left out, a credit card
/// payment paired against the live credit accounts' inflows.
@riverpod
Future<Report> report(Ref ref, int offset) async {
  final LocalDate today = ref.watch(todayProvider);
  final int startDay = await ref.watch(reportStartDayProvider.future);
  final String currency = await ref.watch(reportCurrencyProvider.future);
  final Set<String> credit = await ref.watch(
    reportCreditAccountIdsProvider.future,
  );
  final List<Category> categories = await ref.watch(categoriesProvider.future);
  final List<Transaction> ledger = await ref.watch(
    recurringLedgerProvider.future,
  );
  final CategoryLookup lookup = categoryLookup(categories);
  return buildReport(
    period: periodAt(today, startDay, offset),
    periodStartDay: startDay,
    today: today,
    currencyCode: currency,
    entries: reportEntries(
      ledger,
      lookup,
      currencyCode: currency,
      creditAccountIds: credit,
      excluded: (t) => t.hidden,
    ).toList(),
    lookup: lookup,
  );
}
