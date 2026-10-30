/// The weekly summary (`/reports/weekly`, `docs/reference/reports.md`, **The weekly
/// summary**): the last complete week (Monday to Sunday) with its spending, income, net,
/// three biggest categories and biggest merchant; the current week so far; what is
/// worth a look since the last week began; the bills due next week; and where the
/// budgets stand.
library;

import 'package:finance_tracker/core/l10n/joins.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/bills/application/bills_providers.dart';
import 'package:finance_tracker/features/bills/domain/bill_status.dart';
import 'package:finance_tracker/features/budgets/application/budgets_providers.dart';
import 'package:finance_tracker/features/budgets/domain/budget_math.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/reports/application/weekly_summary_providers.dart';
import 'package:finance_tracker/features/reports/domain/report_period.dart';
import 'package:finance_tracker/features/reports/domain/weekly_summary.dart';
import 'package:finance_tracker/features/reports/presentation/anomaly_list.dart';
import 'package:finance_tracker/features/reports/presentation/report_format.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

/// [week] as "Oct 12 – Oct 18".
String weekLabel(AppLocalizations l10n, LocalDateRange week) {
  final DateFormat date = DateFormat.MMMd();
  return l10n.weeklyRange(
    date.format(week.start.toDateTime()),
    date.format(week.end.addDays(-1).toDateTime()),
  );
}

/// The weekly summary screen.
class WeeklySummaryScreen extends ConsumerWidget {
  const WeeklySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<WeeklyReport> report = ref.watch(weeklyReportProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.weeklyTitle)),
      body: switch (report) {
        AsyncValue(value: final WeeklyReport r) => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _Heading(l10n.weeklyLastWeek(weekLabel(l10n, r.lastWeek.week))),
            _Week(r.lastWeek),
            _Heading(l10n.weeklyThisWeek),
            _Week(r.thisWeek, details: false),
            _Heading(l10n.anomaliesTitle),
            AnomalyList(
              window: LocalDateRange(
                r.lastWeek.week.start,
                ref.watch(todayProvider).addDays(1),
              ),
            ),
            _Heading(l10n.weeklyBillsNextWeek),
            _BillsNextWeek(weekContaining(r.thisWeek.week.end)),
            _Heading(l10n.weeklyBudgets),
            const _Budgets(),
          ],
        ),
        AsyncValue(hasError: true) => Center(child: Text(l10n.loadFailed)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}

/// A week's spending, income and net; with [details], its biggest categories and
/// merchant.
class _Week extends ConsumerWidget {
  const _Week(this.summary, {this.details = true});

  final WeeklySummary summary;
  final bool details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final Map<String, Category> byId = ref.watch(categoriesByIdProvider);
    final ReportPeriod p = summary.period;
    final MerchantTotal? merchant = summary.topMerchant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 4,
            children: [
              Text(l10n.reportsSpendingAmount(p.spend.format())),
              Text(l10n.reportsIncomeAmount(p.income.format())),
              Text(l10n.reportsNetAmount(p.net.format())),
            ],
          ),
          if (details) ...[
            const SizedBox(height: 8),
            if (summary.topCategories.isEmpty)
              Text(l10n.weeklyNoSpending)
            else ...[
              Text(l10n.weeklyTopCategories, style: theme.textTheme.titleSmall),
              for (final CategoryTotal c in summary.topCategories)
                Text(
                  l10n.weeklyCategoryLine(
                    categoryName(l10n, byId, c.categoryId),
                    c.total.format(),
                  ),
                ),
            ],
            if (merchant != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.weeklyTopMerchant(
                  merchant.displayName,
                  merchant.total.format(),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// The active bills whose next due date falls in [week].
class _BillsNextWeek extends ConsumerWidget {
  const _BillsNextWeek(this.week);

  final LocalDateRange week;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<BillStatus> due = [
      for (final BillStatus s
          in ref.watch(billStatusesProvider).value ?? const <BillStatus>[])
        if (s.bill.active && s.nextDue != null && week.contains(s.nextDue!)) s,
    ]..sort((a, b) => a.nextDue!.compareTo(b.nextDue!));
    if (due.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(l10n.weeklyNoBills),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final BillStatus s in due)
          MergeSemantics(
            child: ListTile(
              title: Text(billName(s.bill.name, l10n)),
              subtitle: Text(
                captionLine(l10n, [
                  DateFormat.MMMEd().format(s.nextDue!.toDateTime()),
                  if (s.bill.amount case final Money amount)
                    amount.abs().format(),
                ]),
              ),
            ),
          ),
      ],
    );
  }
}

/// Each budget's spending against what is available in its current period.
class _Budgets extends ConsumerWidget {
  const _Budgets();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final Map<String, Category> byId = ref.watch(categoriesByIdProvider);
    final List<BudgetStatus> statuses =
        ref.watch(budgetStatusesProvider).value ?? const [];
    if (statuses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(l10n.weeklyNoBudgets),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final BudgetStatus s in statuses)
          MergeSemantics(
            child: ListTile(
              title: Text(
                byId[s.budget.categoryId]?.name ?? l10n.budgetDeletedCategory,
              ),
              subtitle: Text(
                s.remaining.isNegative
                    ? l10n.weeklyBudgetOver(
                        s.spent.format(),
                        s.available.format(),
                        (-s.remaining).format(),
                      )
                    : l10n.weeklyBudgetLeft(
                        s.spent.format(),
                        s.available.format(),
                        s.remaining.format(),
                      ),
                style: s.remaining.isNegative
                    ? TextStyle(color: theme.colorScheme.error)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
