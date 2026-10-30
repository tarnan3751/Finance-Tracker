/// What the export is made from (`docs/reference/export.md`, **Providers**): the monthly
/// report's data for a period, its fonts and texts, and the files' names and bytes.
library;

import 'dart:convert';

import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/bills/application/bills_providers.dart';
import 'package:finance_tracker/features/bills/domain/bill_schedule.dart';
import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:finance_tracker/features/budgets/application/budgets_providers.dart';
import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/export/domain/monthly_report.dart';
import 'package:finance_tracker/features/export/domain/monthly_report_pdf.dart';
import 'package:finance_tracker/features/export/domain/transactions_csv.dart';
import 'package:finance_tracker/features/reports/application/anomaly_providers.dart';
import 'package:finance_tracker/features/reports/application/reports_providers.dart';
import 'package:finance_tracker/features/reports/domain/report.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'export_providers.g.dart';

/// The monthly report's regular font asset (Apache-2.0, `assets/fonts/LICENSE.txt`).
const String reportRegularFontAsset = 'assets/fonts/Roboto-Regular.ttf';

/// The monthly report's bold font asset.
const String reportBoldFontAsset = 'assets/fonts/Roboto-Bold.ttf';

/// The PDF's MIME type.
const String pdfMimeType = 'application/pdf';

/// The CSV's MIME type.
const String csvMimeType = 'text/csv';

/// The fonts the monthly report embeds, loaded once from the assets.
@Riverpod(keepAlive: true)
Future<ReportFonts> reportFonts(Ref ref) async => (
  regular: await rootBundle.load(reportRegularFontAsset),
  bold: await rootBundle.load(reportBoldFontAsset),
);

/// The monthly report of the period [offset] periods after today's (the Reports
/// segment's periods): its report, the category names, the flags in it less the
/// dismissed ones, the active bills' occurrences due in it as the Bills calendar reads
/// them, and the budgets in their period of that offset.
@riverpod
Future<MonthlyReportData> monthlyReportData(Ref ref, int offset) async {
  final LocalDate today = ref.watch(todayProvider);
  final Report report = await ref.watch(reportProvider(offset).future);
  final LocalDateRange range = report.current.range;
  final List<Category> categories = await ref.watch(categoriesProvider.future);
  final List<BillReminder> bills = await ref.watch(billsProvider.future);
  final Map<String, LocalDate> liabilityDue = await ref.watch(
    liabilityDueDatesProvider.future,
  );
  final BillPayments payments = await ref.watch(billPaymentsProvider.future);
  final Map<String, String> streamNames = await ref.watch(
    streamNamesProvider.future,
  );
  final List<BudgetStatus> budgets = await ref.watch(
    budgetPeriodStatusesProvider(offset).future,
  );
  final Map<String, String> names = {
    for (final Category c in categories) c.id: c.name,
  };
  final List<ReportBill> due =
      [
        for (final BillReminder b in bills)
          if (b.active)
            for (final LocalDate d in BillSchedule.of(
              b,
              liabilityDue: liabilityDue[b.id],
            ).between(range.start, range.end))
              ReportBill(
                name: switch ((b.name ?? streamNames[b.streamId])?.trim()) {
                  final String n when n.isNotEmpty => n,
                  _ => null,
                },
                due: d,
                amount: b.amount,
                state: occurrenceState(b, d, today, paidBy: payments[b.id]?[d]),
              ),
      ]..sort((a, b) {
        final int byDate = a.due.compareTo(b.due);
        return byDate != 0 ? byDate : (a.name ?? '').compareTo(b.name ?? '');
      });
  return MonthlyReportData(
    report: report,
    categoryNames: names,
    anomalies: await ref.watch(anomaliesProvider(range).future),
    bills: due,
    budgets: [
      for (final BudgetStatus s in budgets)
        ReportBudget(name: names[s.budget.categoryId], status: s),
    ],
  );
}

/// The monthly report's texts in [l10n].
MonthlyReportStrings monthlyReportStrings(AppLocalizations l10n) =>
    MonthlyReportStrings(
      title: l10n.exportReportTitle,
      range: l10n.budgetPeriodRange,
      countedThrough: l10n.exportCountedThrough,
      amountsIn: l10n.exportAmountsIn,
      spent: l10n.reportsSpendingAmount,
      income: l10n.reportsIncomeAmount,
      net: l10n.reportsNetAmount,
      savingsRate: l10n.reportsSavingsRate,
      noIncome: l10n.reportsNoIncome,
      vsPrevious: l10n.reportsVsPrevious,
      vsYearAgo: l10n.reportsVsYearAgo,
      spending: l10n.reportsSpending,
      incomeLabel: l10n.reportsIncome,
      change: l10n.reportsChange,
      changeNew: l10n.reportsChangeNew,
      percent: l10n.reportsPercent,
      percentUp: l10n.reportsPercentUp,
      byCategory: l10n.reportsByCategory,
      uncategorized: l10n.uncategorized,
      other: l10n.exportOther,
      groupOwn: l10n.reportsGroupOwn,
      category: l10n.exportColumnCategory,
      share: l10n.exportColumnShare,
      amount: l10n.exportColumnAmount,
      nothingInPeriod: l10n.reportsNothingInPeriod,
      topMerchants: l10n.reportsTopMerchants,
      merchant: l10n.exportColumnMerchant,
      purchases: l10n.reportsMerchantCount,
      incomeAndSpending: l10n.reportsIncomeAndSpending,
      period: l10n.exportColumnPeriod,
      netLabel: l10n.exportColumnNet,
      topMovers: l10n.reportsTopMovers,
      moversCategories: l10n.reportsMoversCategories,
      moversMerchants: l10n.reportsMoversMerchants,
      before: l10n.exportColumnBefore,
      now: l10n.exportColumnNow,
      changeLabel: l10n.exportColumnChange,
      noMovers: l10n.reportsNoMovers,
      worthALook: l10n.anomaliesTitle,
      date: l10n.exportColumnDate,
      why: l10n.exportColumnWhy,
      usualMerchant: l10n.anomalyUsualMerchant,
      usualCategory: l10n.anomalyUsualCategory,
      newMerchant: l10n.anomalyNewMerchant,
      noAnomalies: l10n.anomaliesNone,
      bills: l10n.exportBills,
      bill: l10n.exportColumnBill,
      due: l10n.exportColumnDue,
      status: l10n.exportColumnStatus,
      billPaid: l10n.billStatePaid,
      billDue: l10n.exportBillDue,
      billMissed: l10n.billStateMissed,
      billUpcoming: l10n.exportBillUpcoming,
      unnamedBill: l10n.billUnnamed,
      noBills: l10n.exportNoBills,
      budgets: l10n.weeklyBudgets,
      budget: l10n.exportColumnBudget,
      available: l10n.exportColumnAvailable,
      left: l10n.exportColumnLeft,
      noBudgets: l10n.weeklyNoBudgets,
      deletedCategory: l10n.budgetDeletedCategory,
      page: l10n.exportPage,
    );

/// The monthly report's PDF of [data] in [l10n], amounts and dates in intl's current
/// locale.
Future<Uint8List> monthlyReportPdf(
  MonthlyReportData data,
  AppLocalizations l10n,
  ReportFonts fonts,
) => buildMonthlyReportPdf(
  data,
  monthlyReportStrings(l10n),
  fonts: fonts,
  locale: Intl.getCurrentLocale(),
);

/// The PDF's file name for the period [range]: `report-2026-10.pdf` for a period that
/// starts on the 1st, `report-2026-10-15.pdf` otherwise.
String monthlyReportFileName(LocalDateRange range) {
  final String iso = range.start.toIso();
  return 'report-${range.start.day == 1 ? iso.substring(0, 7) : iso}.pdf';
}

/// The CSV's file name for the dates [range]: `transactions-2026-01-01-to-2026-10-24.csv`.
String transactionsFileName(LocalDateRange range) =>
    'transactions-${range.start.toIso()}-to-${range.end.addDays(-1).toIso()}.csv';

/// Above how many transactions the CSV is written off the UI isolate.
const int csvIsolateThreshold = 2000;

/// [transactionsCsvBytes], written on another isolate when there are more than
/// [isolateThreshold] transactions, so a long ledger does not hold up the UI.
Future<Uint8List> transactionsCsvFile(
  List<Transaction> transactions, {
  required List<Account> accounts,
  required List<Category> categories,
  required LocalDateRange range,
  required Set<String> accountIds,
  int isolateThreshold = csvIsolateThreshold,
}) async {
  Uint8List write() => transactionsCsvBytes(
    transactions,
    accounts: accounts,
    categories: categories,
    range: range,
    accountIds: accountIds,
  );
  return transactions.length > isolateThreshold
      ? compute((_) => write(), null)
      : write();
}

/// The CSV of the live [transactions] in [range] on [accountIds], as UTF-8 bytes with no
/// byte order mark.
Uint8List transactionsCsvBytes(
  List<Transaction> transactions, {
  required List<Account> accounts,
  required List<Category> categories,
  required LocalDateRange range,
  required Set<String> accountIds,
}) => utf8.encode(
  transactionsCsv(
    transactions,
    accounts: {for (final Account a in accounts) a.id: a},
    lookup: categoryLookup(categories),
    range: range,
    accountIds: accountIds,
  ),
);
