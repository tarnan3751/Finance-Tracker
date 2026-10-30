/// An investment account's value over time from its balance snapshots
/// (`docs/reference/net-worth.md`): a line chart (fl_chart, the forecast's pattern) with a
/// dot on the latest value, the first and last dates along the bottom and a tooltip on
/// touch, read by a screen reader as one summary (the first and latest values and their
/// dates); and its table, the full equivalent, one row per recorded day, newest first.
///
/// The x axis is days from the first snapshot, so a day with no snapshot (the app not
/// opened) is a gap the line spans, never a value made up. fl_chart places points by
/// `double` coordinates, so each value's minor units are handed to it as a `double` for
/// placement only: the tooltip, the summary and the table format the snapshots' `Money`.
library;

import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

/// The line of [snapshots] (one account's, by date, at least one).
class ValueHistoryChart extends StatelessWidget {
  const ValueHistoryChart(this.snapshots, {super.key});

  final List<BalanceSnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final DateFormat date = DateFormat.MMMd();
    final BalanceSnapshot first = snapshots.first;
    final BalanceSnapshot last = snapshots.last;
    final int span = first.date.daysUntil(last.date);
    final Map<int, BalanceSnapshot> byDay = {
      for (final BalanceSnapshot s in snapshots)
        first.date.daysUntil(s.date): s,
    };
    int low = first.current.minorUnits;
    int high = low;
    for (final BalanceSnapshot s in snapshots) {
      if (s.current.minorUnits < low) low = s.current.minorUnits;
      if (s.current.minorUnits > high) high = s.current.minorUnits;
    }
    // A margin above and below, and some height for a flat line.
    final double pad = high == low ? 100 : (high - low) / 10;
    return Semantics(
      container: true,
      label: span == 0
          ? l10n.investmentsValueSummaryOne(
              last.current.format(),
              date.format(last.date.toDateTime()),
            )
          : l10n.investmentsValueSummary(
              first.current.format(),
              date.format(first.date.toDateTime()),
              last.current.format(),
              date.format(last.date.toDateTime()),
            ),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 24, 0),
          child: SizedBox(
            height: 200,
            child: LineChart(
              duration: Duration.zero,
              LineChartData(
                // One day alone sits in the middle.
                minX: span == 0 ? -1 : 0,
                maxX: span == 0 ? 1 : span.toDouble(),
                minY: low - pad,
                maxY: high + pad,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (final MapEntry(:key, :value) in byDay.entries)
                        FlSpot(
                          key.toDouble(),
                          value.current.minorUnits.toDouble(),
                        ),
                    ],
                    color: colors.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      checkToShowDot: (spot, _) => spot.x == span.toDouble(),
                      getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                        radius: 5,
                        color: colors.primary,
                        strokeColor: colors.surface,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ],
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: span == 0 ? 1 : span.toDouble(),
                      getTitlesWidget: (value, meta) {
                        final BalanceSnapshot? s = byDay[value.round()];
                        if (s == null || value != value.roundToDouble()) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                          child: Text(
                            date.format(s.date.toDateTime()),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => colors.inverseSurface,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touched) => [
                      for (final LineBarSpot spot in touched)
                        _tooltip(byDay[spot.x.round()]!, theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  LineTooltipItem _tooltip(BalanceSnapshot snapshot, ThemeData theme) {
    final TextStyle? style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onInverseSurface,
    );
    return LineTooltipItem(
      '${DateFormat.MMMEd().format(snapshot.date.toDateTime())}\n',
      style ?? const TextStyle(),
      children: [
        TextSpan(
          text: snapshot.current.format(),
          style: style?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// The days of [snapshots] (one account's, by date) as rows, newest first.
class ValueHistoryTable extends StatelessWidget {
  const ValueHistoryTable(this.snapshots, {super.key});

  final List<BalanceSnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final BalanceSnapshot s in snapshots.reversed) ...[
          () {
            final String date = DateFormat.yMMMEd().format(s.date.toDateTime());
            final String value = s.current.format();
            return Semantics(
              container: true,
              label: l10n.investmentsValueRow(date, value),
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(date)),
                      const SizedBox(width: 8),
                      Text(value),
                    ],
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
