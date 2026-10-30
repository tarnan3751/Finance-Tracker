/// The Reports segment's body (`docs/reference/reports.md`, **The screen**): the period
/// selector, the headline (spending, income and the savings rate), the comparisons with
/// the period before and the year before, spending or income by category as a donut
/// that drills into a group, income and spending over six periods as bars, the trend
/// over twelve as lines, the top merchants, the top movers, "Worth a look" and the
/// entry to the weekly summary. One
/// Table/Chart switch turns every chart into its table. No Scaffold of its own: the
/// Insights tab mounts it under its app bar.
library;

import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/theme/finance_colors.dart';
import 'package:finance_tracker/features/budgets/presentation/budget_period_selector.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/reports/application/reports_providers.dart';
import 'package:finance_tracker/features/reports/domain/report.dart';
import 'package:finance_tracker/features/reports/domain/report_period.dart';
import 'package:finance_tracker/features/reports/domain/transaction_kind.dart';
import 'package:finance_tracker/features/reports/presentation/anomaly_list.dart';
import 'package:finance_tracker/features/reports/presentation/report_charts.dart';
import 'package:finance_tracker/features/reports/presentation/report_format.dart';
import 'package:finance_tracker/features/reports/presentation/report_tables.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// How many merchants the top merchants list shows.
const int topMerchantCount = 5;

/// The report of the period chosen.
class ReportsView extends ConsumerStatefulWidget {
  const ReportsView({super.key});

  @override
  ConsumerState<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends ConsumerState<ReportsView> {
  TransactionKind _kind = TransactionKind.spend;
  bool _table = false;
  // The category group the donut shows the children of, or null for the top level.
  String? _group;

  void _select(int offset) {
    ref.read(reportPeriodOffsetProvider.notifier).select(offset);
    setState(() => _group = null);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final int offset = ref.watch(reportPeriodOffsetProvider);
    final AsyncValue<Report> report = ref.watch(reportProvider(offset));
    return switch (report) {
      AsyncValue(value: final Report r) => ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          BudgetPeriodSelector(
            offset: offset,
            dates: budgetPeriodLabel(l10n, r.current.range),
            onSelected: _select,
            showNext: offset < 0,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => setState(() => _table = !_table),
                icon: Icon(_table ? Icons.donut_large : Icons.table_rows),
                label: Text(
                  _table ? l10n.reportsShowCharts : l10n.reportsShowTables,
                ),
              ),
            ),
          ),
          _Headline(r.current),
          _Comparisons(r),
          _SectionTitle(l10n.reportsByCategory),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<TransactionKind>(
              segments: [
                ButtonSegment(
                  value: TransactionKind.spend,
                  label: Text(l10n.reportsSpending),
                ),
                ButtonSegment(
                  value: TransactionKind.income,
                  label: Text(l10n.reportsIncome),
                ),
              ],
              selected: {_kind},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() {
                _kind = s.single;
                _group = null;
              }),
            ),
          ),
          _Categories(
            period: r.current,
            kind: _kind,
            group: _group,
            table: _table,
            onGroup: (id) => setState(() => _group = id),
          ),
          _SectionTitle(l10n.reportsIncomeAndSpending),
          if (_table)
            PeriodsTable(r.shortTrend)
          else ...[
            IncomeSpendingBars(r.shortTrend),
            const SeriesLegend(),
          ],
          _SectionTitle(l10n.reportsTrend(longTrendPeriods)),
          if (_table)
            PeriodsTable(r.trend)
          else ...[
            TrendLines(r.trend),
            const SeriesLegend(),
          ],
          _SectionTitle(l10n.reportsTopMerchants),
          _Merchants(r.current),
          _SectionTitle(l10n.reportsTopMovers),
          _Movers(r),
          _SectionTitle(l10n.anomaliesTitle),
          AnomalyList(window: r.current.range),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.date_range),
            title: Text(l10n.reportsWeeklySummary),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => const WeeklySummaryRoute().push<void>(context),
          ),
        ],
      ),
      AsyncValue(hasError: true) => Center(child: Text(l10n.loadFailed)),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

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

/// Spending, income and the savings rate of [period].
class _Headline extends StatelessWidget {
  const _Headline(this.period);

  final ReportPeriod period;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final int? rate = period.savingsRateBasisPoints;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 4,
            children: [
              Text(
                l10n.reportsSpendingAmount(period.spend.format()),
                style: theme.textTheme.titleMedium,
              ),
              Text(
                l10n.reportsIncomeAmount(period.income.format()),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            rate == null
                ? l10n.reportsNoIncome
                : l10n.reportsSavingsRate(percentLabel(l10n, rate)),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: rate != null && rate < 0 ? theme.colorScheme.error : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Spending and income against the period before and the year before.
class _Comparisons extends StatelessWidget {
  const _Comparisons(this.report);

  final Report report;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    Widget row(String label, Change spend, Change income) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.titleSmall),
          Text(l10n.reportsSpendingChange(changeLabel(l10n, spend))),
          Text(l10n.reportsIncomeChange(changeLabel(l10n, income))),
        ],
      ),
    );
    final ReportPeriod current = report.current;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row(
            l10n.reportsVsPrevious,
            report.spendMonthOverMonth,
            report.incomeMonthOverMonth,
          ),
          row(
            l10n.reportsVsYearAgo,
            report.spendYearOverYear,
            report.incomeYearOverYear,
          ),
          if (current.partial)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.reportsSameElapsed(current.elapsedDays),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// [period]'s spending or income by category: the top-level groups, or the rows of
/// [group] (its children, and its own rows) when one is chosen.
class _Categories extends ConsumerWidget {
  const _Categories({
    required this.period,
    required this.kind,
    required this.group,
    required this.table,
    required this.onGroup,
  });

  final ReportPeriod period;
  final TransactionKind kind;
  final String? group;
  final bool table;
  final ValueChanged<String?> onGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Map<String, Category> byId = ref.watch(categoriesByIdProvider);
    final List<CategoryTotal> totals = kind == TransactionKind.spend
        ? period.spendByCategory
        : period.incomeByCategory;
    final List<Color> palette = [
      colors.primary,
      colors.tertiary,
      colors.secondary,
      colors.error,
      colors.primaryContainer,
      colors.tertiaryContainer,
      colors.secondaryContainer,
      colors.outline,
    ];
    final String? shown = group;
    final CategoryTotal? parent = shown == null
        ? null
        : totals.where((t) => t.categoryId == shown).firstOrNull;
    final List<CategoryTotal> level = shown == null
        ? ReportPeriod.topLevel(totals)
        : ReportPeriod.childrenOf(totals, shown);
    int i = 0;
    Color colorOf(String? id) {
      final Category? c = byId[id];
      if (shown == null && c != null && c.color != 0) {
        return FinanceColors.of(context).custom(Color(c.color));
      }
      return palette[i++ % palette.length];
    }

    final List<DonutSlice> slices = [
      for (final CategoryTotal t in level)
        (
          id: t.categoryId,
          name: categoryName(l10n, byId, t.categoryId),
          amount: t.total,
          color: colorOf(t.categoryId),
        ),
      if (parent != null && !parent.own.isZero)
        (
          id: null,
          name: l10n.reportsGroupOwn(categoryName(l10n, byId, shown)),
          amount: parent.own,
          color: colorOf(null),
        ),
    ];
    final Money total =
        parent?.total ??
        (kind == TransactionKind.spend ? period.spend : period.income);
    // The largest slice: the group's own rows, appended last, may be it.
    final DonutSlice? largest = slices.isEmpty
        ? null
        : slices.reduce((a, b) => b.amount > a.amount ? b : a);
    final Set<String?> drillable = shown != null
        ? const {}
        : {
            for (final CategoryTotal t in level)
              if (t.categoryId != null &&
                  ReportPeriod.childrenOf(totals, t.categoryId!).isNotEmpty)
                t.categoryId,
          };
    void open(String? id) {
      if (drillable.contains(id)) onGroup(id);
    }

    final String kindName = kind == TransactionKind.spend
        ? l10n.reportsSpending
        : l10n.reportsIncome;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (shown != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton.icon(
                onPressed: () => onGroup(null),
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.reportsAllCategories),
              ),
            ),
          ),
        if (slices.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(l10n.reportsNothingInPeriod),
          )
        else if (table)
          CategoryTable(
            slices: slices,
            total: total,
            drillable: drillable,
            onSelected: open,
          )
        else
          CategoryDonut(
            slices: slices,
            total: total,
            summary: l10n.reportsDonutSummary(
              shown == null ? kindName : categoryName(l10n, byId, shown),
              total.format(),
              largest!.name,
              largest.amount.format(),
            ),
            onSelected: open,
          ),
      ],
    );
  }
}

/// The merchants [period] spent most at.
class _Merchants extends StatelessWidget {
  const _Merchants(this.period);

  final ReportPeriod period;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<MerchantTotal> top = period.spendByMerchant
        .take(topMerchantCount)
        .toList();
    if (top.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(l10n.reportsNothingInPeriod),
      );
    }
    return Column(
      children: [
        for (final MerchantTotal m in top)
          MergeSemantics(
            child: ListTile(
              title: Text(m.displayName),
              subtitle: Text(l10n.reportsMerchantCount(m.count)),
              trailing: Text(m.total.format()),
            ),
          ),
      ],
    );
  }
}

/// The categories and merchants whose spending moved most.
class _Movers extends ConsumerWidget {
  const _Movers(this.report);

  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Map<String, Category> byId = ref.watch(categoriesByIdProvider);
    if (report.categoryMovers.isEmpty && report.merchantMovers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(l10n.reportsNoMovers),
      );
    }
    final ThemeData theme = Theme.of(context);
    Widget tile(String name, Change change) => MergeSemantics(
      child: ListTile(
        title: Text(name),
        subtitle: Text(
          '${changeLabel(l10n, change)}\n'
          '${l10n.reportsMoverAmounts(change.previous.format(), change.current.format())}',
        ),
        isThreeLine: true,
      ),
    );
    Widget subheading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Text(text, style: theme.textTheme.labelLarge),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (report.categoryMovers.isNotEmpty)
          subheading(l10n.reportsMoversCategories),
        for (final Mover m in report.categoryMovers)
          tile(categoryName(l10n, byId, m.id), m.change),
        if (report.merchantMovers.isNotEmpty)
          subheading(l10n.reportsMoversMerchants),
        for (final Mover m in report.merchantMovers)
          tile(m.displayName!, m.change),
      ],
    );
  }
}
