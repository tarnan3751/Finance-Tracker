/// The forecast as a line chart (fl_chart): the projected balance, the confidence band
/// filled between its low and high edges (`BetweenBarsData`), a dot on today and on the
/// lowest point, a dashed line at zero when the band reaches it, dates along the bottom,
/// and a tooltip on touch. A screen reader hears one summary instead (the horizon, the
/// start and end balances, the lowest point); the table is the full equivalent.
///
/// fl_chart places points by `double` coordinates, so each point's minor units are handed
/// to it as a `double` for placement only. No amount on screen comes from them: the
/// tooltip and the summary format the point's own `Money`.
library;

import 'package:finance_tracker/features/forecast/domain/cash_flow_forecast.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The chart of [series].
class ForecastChart extends StatelessWidget {
  const ForecastChart(this.series, {super.key});

  final ForecastSeries series;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final DateFormat date = DateFormat.MMMd();
    final List<ForecastPoint> points = series.points;
    final int lowest = points.indexOf(series.lowestPoint);

    List<FlSpot> spots(int Function(ForecastPoint) minorUnits) => [
      for (int i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), minorUnits(points[i]).toDouble()),
    ];
    int low = points.first.lower.minorUnits;
    int high = points.first.upper.minorUnits;
    for (final ForecastPoint p in points) {
      if (p.lower.minorUnits < low) low = p.lower.minorUnits;
      if (p.upper.minorUnits > high) high = p.upper.minorUnits;
    }
    // A margin above and below, and some height for a flat line.
    final double pad = high == low ? 100 : (high - low) / 10;
    final int labelEvery = series.horizonDays ~/ 3;

    final LineChartBarData edge = LineChartBarData(
      color: Colors.transparent,
      barWidth: 0,
      dotData: const FlDotData(show: false),
    );
    final ForecastPoint first = points.first;
    final ForecastPoint last = points.last;
    return Semantics(
      container: true,
      label: l10n.forecastChartSummary(
        series.horizonDays,
        first.balance.format(),
        last.balance.format(),
        date.format(last.date.toDateTime()),
        series.lowestPoint.balance.format(),
        date.format(series.lowestPoint.date.toDateTime()),
      ),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 24, 0),
          child: SizedBox(
            height: 260,
            child: LineChart(
              duration: Duration.zero,
              LineChartData(
                minX: 0,
                maxX: (points.length - 1).toDouble(),
                minY: low - pad,
                maxY: high + pad,
                lineBarsData: [
                  edge.copyWith(spots: spots((p) => p.lower.minorUnits)),
                  edge.copyWith(spots: spots((p) => p.upper.minorUnits)),
                  LineChartBarData(
                    spots: spots((p) => p.balance.minorUnits),
                    color: colors.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      checkToShowDot: (spot, _) =>
                          spot.x == 0 || spot.x == lowest.toDouble(),
                      getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                        radius: 5,
                        color: spot.x == 0 ? colors.primary : colors.tertiary,
                        strokeColor: colors.surface,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ],
                betweenBarsData: [
                  BetweenBarsData(
                    fromIndex: 0,
                    toIndex: 1,
                    color: colors.primary.withValues(alpha: 0.18),
                  ),
                ],
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (low <= 0 && high >= 0)
                      HorizontalLine(
                        y: 0,
                        color: colors.outline,
                        strokeWidth: 1,
                        dashArray: const [6, 4],
                      ),
                  ],
                ),
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
                      interval: labelEvery.toDouble(),
                      getTitlesWidget: (value, meta) {
                        final int i = value.round();
                        if (i % labelEvery != 0 || i >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                          child: Text(
                            date.format(points[i].date.toDateTime()),
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
                        spot.barIndex == 2
                            ? _tooltip(points[spot.x.round()], l10n, theme)
                            : null,
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

  LineTooltipItem _tooltip(
    ForecastPoint point,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final TextStyle? style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onInverseSurface,
    );
    return LineTooltipItem(
      '${DateFormat.MMMEd().format(point.date.toDateTime())}\n',
      style ?? const TextStyle(),
      children: [
        TextSpan(
          text: '${point.balance.format()}\n',
          style: style?.copyWith(fontWeight: FontWeight.bold),
        ),
        TextSpan(
          text: l10n.forecastRange(point.lower.format(), point.upper.format()),
        ),
      ],
    );
  }
}
