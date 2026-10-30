/// What the monthly report's PDF is drawn from (`docs/reference/export.md`, **The PDF**):
/// a period's report and what the app knows about it, gathered by the export's providers
/// and passed whole, so the drawing reads nothing else. Pure Dart, integer `Money` only.
library;

import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:finance_tracker/features/reports/domain/anomalies.dart';
import 'package:finance_tracker/features/reports/domain/report.dart';
import 'package:shared_models/shared_models.dart';

/// One bill occurrence due in the period, as the Bills calendar reads it.
final class ReportBill {
  /// An occurrence.
  const ReportBill({
    required this.name,
    required this.due,
    required this.amount,
    required this.state,
  });

  /// The bill's name, or its stream's; null when it has neither ("Bill").
  final String? name;

  /// The occurrence's due date.
  final LocalDate due;

  /// The bill's expected amount, in the app's sign; null when it has none.
  final Money? amount;

  /// Whether it was paid, is due, was missed or is still to come.
  final BillState state;
}

/// One budget in the period.
final class ReportBudget {
  /// A budget's line.
  const ReportBudget({required this.name, required this.status});

  /// Its category's name; null when the category is gone.
  final String? name;

  /// Where it stands at the period's end (today, while the period runs).
  final BudgetStatus status;
}

/// Everything the monthly report shows.
final class MonthlyReportData {
  /// The data.
  const MonthlyReportData({
    required this.report,
    required this.categoryNames,
    required this.anomalies,
    required this.bills,
    required this.budgets,
  });

  /// The period's report: the totals, comparisons, movers and trend.
  final Report report;

  /// The names of the categories by id, as the app shows them.
  final Map<String, String> categoryNames;

  /// The flags on the period's transactions, less the dismissed ones, by date then id.
  final List<AnomalyFlag> anomalies;

  /// The bill occurrences due in the period, by date then name.
  final List<ReportBill> bills;

  /// The budgets, in the budgets' order.
  final List<ReportBudget> budgets;
}
