/// The reports' tables, the charts' equivalents: the categories with their amounts and
/// shares, and the periods with their income, spending and net. Each row is one
/// semantics node read as a sentence.
library;

import 'package:finance_tracker/features/reports/domain/report.dart';
import 'package:finance_tracker/features/reports/presentation/report_charts.dart';
import 'package:finance_tracker/features/reports/presentation/report_format.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// The donut's slices as rows: the name, the amount and its share of [total]; a row
/// whose id is in [drillable] opens its children through [onSelected].
class CategoryTable extends StatelessWidget {
  const CategoryTable({
    super.key,
    required this.slices,
    required this.total,
    this.drillable = const {},
    this.onSelected,
  });

  final List<DonutSlice> slices;
  final Money total;
  final Set<String?> drillable;
  final ValueChanged<String?>? onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final DonutSlice s in slices) ...[
          () {
            final String share = total.isPositive
                ? percentLabel(
                    l10n,
                    s.amount
                        .multipliedBy(
                          10000,
                          total.minorUnits,
                          mode: RoundingMode.floor,
                        )
                        .minorUnits,
                  )
                : '';
            final bool opens = drillable.contains(s.id);
            return Semantics(
              container: true,
              button: opens,
              onTap: opens ? () => onSelected?.call(s.id) : null,
              label: l10n.reportsCategoryRow(s.name, s.amount.format(), share),
              child: ExcludeSemantics(
                child: InkWell(
                  onTap: opens ? () => onSelected?.call(s.id) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(width: 12, height: 12, color: s.color),
                        const SizedBox(width: 12),
                        Expanded(child: Text(s.name)),
                        const SizedBox(width: 8),
                        Text(share, style: theme.textTheme.bodySmall),
                        const SizedBox(width: 12),
                        Text(s.amount.format()),
                        if (opens) const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }(),
          const Divider(height: 1),
        ],
      ],
    );
  }
}

/// One row per period of [points], newest first: income, spending and net.
class PeriodsTable extends StatelessWidget {
  const PeriodsTable(this.points, {super.key});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final TrendPoint p in points.reversed) ...[
          Semantics(
            container: true,
            label: l10n.reportsPeriodRow(
              periodName(p.range),
              p.income.format(),
              p.spend.format(),
              p.net.format(),
            ),
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      periodName(p.range),
                      style: theme.textTheme.titleSmall,
                    ),
                    Wrap(
                      spacing: 16,
                      children: [
                        Text(l10n.reportsIncomeAmount(p.income.format())),
                        Text(l10n.reportsSpendingAmount(p.spend.format())),
                        Text(l10n.reportsNetAmount(p.net.format())),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
        ],
      ],
    );
  }
}
