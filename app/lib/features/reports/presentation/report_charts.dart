/// The reports' charts (fl_chart): the category donut, the income and spending bars and
/// the trend lines. Each is one semantics node, a summary a screen reader hears instead
/// of the drawing; the tables (`report_tables.dart`) are the full equivalents.
///
/// fl_chart places marks by `double` values, so each amount's minor units are handed to
/// it as a `double` for placement only. No amount on screen comes from them: the labels,
/// tooltips and summaries format the amounts' own `Money`.
library;

import 'package:finance_tracker/features/reports/domain/report.dart';
import 'package:finance_tracker/features/reports/presentation/report_format.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// One slice of the donut.
typedef DonutSlice = ({String? id, String name, Money amount, Color color});

/// The donut of [slices] (the positive ones are drawn), [total] in its middle, read as
/// [summary]; tapping a slice calls [onSelected] with its id.
class CategoryDonut extends StatelessWidget {
  const CategoryDonut({
    super.key,
    required this.slices,
    required this.total,
    required this.summary,
    this.onSelected,
  });

  final List<DonutSlice> slices;
  final Money total;
  final String summary;
  final ValueChanged<String?>? onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<DonutSlice> drawn = [
      for (final DonutSlice s in slices)
        if (s.amount.isPositive) s,
    ];
    return Semantics(
      container: true,
      label: summary,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                duration: Duration.zero,
                PieChartData(
                  centerSpaceRadius: 64,
                  sectionsSpace: 1,
                  startDegreeOffset: -90,
                  sections: [
                    for (final DonutSlice s in drawn)
                      PieChartSectionData(
                        value: s.amount.minorUnits.toDouble(),
                        color: s.color,
                        radius: 36,
                        showTitle: false,
                      ),
                  ],
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      final int? i =
                          response?.touchedSection?.touchedSectionIndex;
                      if (event is! FlTapUpEvent ||
                          i == null ||
                          i < 0 ||
                          i >= drawn.length) {
                        return;
                      }
                      onSelected?.call(drawn[i].id);
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 72),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    total.format(),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The colours for income and spending in the bars and the trend.
({Color income, Color spending}) _seriesColors(ColorScheme colors) =>
    (income: colors.tertiary, spending: colors.primary);

/// A legend under a chart: a swatch and the name of each series.
class SeriesLegend extends StatelessWidget {
  const SeriesLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ({Color income, Color spending}) c = _seriesColors(theme.colorScheme);
    Widget item(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            item(c.income, l10n.reportsIncome),
            item(c.spending, l10n.reportsSpending),
          ],
        ),
      ),
    );
  }
}

/// Income and spending of each period of [points], side by side.
class IncomeSpendingBars extends StatelessWidget {
  const IncomeSpendingBars(this.points, {super.key});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ({Color income, Color spending}) c = _seriesColors(theme.colorScheme);
    int high = 0;
    int low = 0;
    for (final TrendPoint p in points) {
      for (final int v in [p.income.minorUnits, p.spend.minorUnits]) {
        if (v > high) high = v;
        if (v < low) low = v;
      }
    }
    final TrendPoint last = points.last;
    return Semantics(
      container: true,
      label: l10n.reportsBarsSummary(
        points.length,
        last.income.format(),
        last.spend.format(),
      ),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SizedBox(
            height: 200,
            child: BarChart(
              duration: Duration.zero,
              BarChartData(
                maxY: high == 0 ? 100 : high * 1.05,
                minY: low.toDouble(),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: const BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(
                          periodShortName(points[value.round()].range),
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < points.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: points[i].income.minorUnits.toDouble(),
                          color: c.income,
                          width: 10,
                        ),
                        BarChartRodData(
                          toY: points[i].spend.minorUnits.toDouble(),
                          color: c.spending,
                          width: 10,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Spending and income over the periods of [points], as two lines.
class TrendLines extends StatelessWidget {
  const TrendLines(this.points, {super.key});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ({Color income, Color spending}) c = _seriesColors(theme.colorScheme);
    List<FlSpot> spots(Money Function(TrendPoint) of) => [
      for (int i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), of(points[i]).minorUnits.toDouble()),
    ];
    int high = 0;
    int low = 0;
    for (final TrendPoint p in points) {
      for (final int v in [p.income.minorUnits, p.spend.minorUnits]) {
        if (v > high) high = v;
        if (v < low) low = v;
      }
    }
    final double pad = high == low ? 100 : (high - low) / 10;
    return Semantics(
      container: true,
      label: l10n.reportsTrendSummary(
        points.length,
        points.first.spend.format(),
        points.last.spend.format(),
        points.first.income.format(),
        points.last.income.format(),
      ),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 24, 0),
          child: SizedBox(
            height: 200,
            child: LineChart(
              duration: Duration.zero,
              LineChartData(
                minX: 0,
                maxX: (points.length - 1).toDouble(),
                minY: low - pad,
                maxY: high + pad,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        final int i = value.round();
                        if (i % 3 != 0 || i >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                          child: Text(
                            periodShortName(points[i].range),
                            style: theme.textTheme.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots((p) => p.income),
                    color: c.income,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: spots((p) => p.spend),
                    color: c.spending,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
