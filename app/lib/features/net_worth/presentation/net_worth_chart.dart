/// The net worth history as a line chart (fl_chart): net worth, assets and liabilities,
/// each line dashed over the span estimated from transactions and solid from the first
/// stored snapshot (the two parts share the join point), a legend, dates along the
/// bottom and a tooltip on touch. A screen reader hears one summary instead (the span,
/// the first and last net worth, the last day's assets and liabilities, and the day
/// before which the history is estimated); the table is the full equivalent.
///
/// fl_chart places points by `double` coordinates, so each point's minor units are handed
/// to it as a `double` for placement only. No amount on screen comes from them: the
/// tooltip and the summary format the point's own `Money`.
library;

import 'package:finance_tracker/core/l10n/joins.dart';
import 'package:finance_tracker/features/net_worth/domain/net_worth_series.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

/// The chart of [points] (by date, not empty).
class NetWorthChart extends StatelessWidget {
  const NetWorthChart(this.points, {super.key});

  final List<NetWorthPoint> points;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final DateFormat date = DateFormat.yMMMd();
    // The first observed point: the derived span ends there and the solid one starts.
    final int join = points.indexWhere((p) => !p.derived);
    final bool estimated = points.first.derived;
    final List<(Money Function(NetWorthPoint), Color)> lines = [
      ((p) => p.netWorth, colors.primary),
      ((p) => p.assets, colors.tertiary),
      // Grey, not the error colour, which is too close to the tertiary in dark.
      ((p) => p.liabilities, colors.onSurfaceVariant),
    ];
    int low = 0;
    int high = 0;
    for (final NetWorthPoint p in points) {
      for (final (Money Function(NetWorthPoint) of, _) in lines) {
        final int v = of(p).minorUnits;
        if (v < low) low = v;
        if (v > high) high = v;
      }
    }
    final double pad = high == low ? 100 : (high - low) / 10;
    final int labelEvery = points.length < 4 ? 1 : (points.length - 1) ~/ 3;
    // Days within a few months, months beyond.
    final DateFormat axis = points.length <= 120
        ? DateFormat.MMMd()
        : DateFormat.yMMM();

    List<FlSpot> spots(Money Function(NetWorthPoint) of, int from, int to) => [
      for (int i = from; i < to; i++)
        FlSpot(i.toDouble(), of(points[i]).minorUnits.toDouble()),
    ];
    final int derivedEnd = join < 0 ? points.length : join + 1;
    final List<LineChartBarData> bars = [
      for (final (Money Function(NetWorthPoint) of, Color color) in lines) ...[
        // The derived part, dashed (up to and including the join point).
        if (estimated)
          LineChartBarData(
            spots: spots(of, 0, derivedEnd),
            color: color,
            barWidth: 2,
            dashArray: const [6, 4],
            dotData: const FlDotData(show: false),
          ),
        if (join >= 0)
          LineChartBarData(
            spots: spots(of, join, points.length),
            color: color,
            barWidth: 2.5,
            // A lone observed point is a dot, so it shows.
            dotData: FlDotData(show: points.length - join == 1),
          ),
      ],
    ];
    final NetWorthPoint first = points.first;
    final NetWorthPoint last = points.last;
    final String summary = sentenceLine(l10n, [
      l10n.netWorthChartSummary(
        date.format(first.date.toDateTime()),
        date.format(last.date.toDateTime()),
        first.netWorth.format(),
        last.netWorth.format(),
        last.assets.format(),
        last.liabilities.format(),
      ),
      if (estimated && join >= 0)
        l10n.netWorthChartEstimated(
          date.format(points[join].date.toDateTime()),
        ),
    ]);
    return Semantics(
      container: true,
      label: summary,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 240,
                child: LineChart(
                  duration: Duration.zero,
                  LineChartData(
                    minX: 0,
                    maxX: points.length == 1
                        ? 1
                        : (points.length - 1).toDouble(),
                    minY: low - pad,
                    maxY: high + pad,
                    lineBarsData: bars,
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        if (low < 0)
                          HorizontalLine(
                            y: 0,
                            color: colors.outlineVariant,
                            strokeWidth: 1,
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
                              fitInside: SideTitleFitInsideData.fromTitleMeta(
                                meta,
                              ),
                              child: Text(
                                axis.format(points[i].date.toDateTime()),
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
                          // One tooltip for the day, on the first line touched.
                          for (int i = 0; i < touched.length; i++)
                            i == 0
                                ? _tooltip(
                                    points[touched[i].x.round()],
                                    l10n,
                                    theme,
                                  )
                                : null,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _Key(colors.primary, l10n.netWorthTitle),
                  _Key(colors.tertiary, l10n.netWorthAssets),
                  _Key(colors.onSurfaceVariant, l10n.netWorthLiabilitiesLine),
                  if (estimated)
                    _Key(
                      colors.outline,
                      l10n.netWorthEstimatedLegend,
                      dashed: true,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  LineTooltipItem _tooltip(
    NetWorthPoint point,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final TextStyle? style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onInverseSurface,
    );
    return LineTooltipItem(
      '${DateFormat.yMMMEd().format(point.date.toDateTime())}\n',
      style ?? const TextStyle(),
      textAlign: TextAlign.start,
      children: [
        TextSpan(
          text: '${point.netWorth.format()}\n',
          style: style?.copyWith(fontWeight: FontWeight.bold),
        ),
        TextSpan(
          text: l10n.netWorthRowDetail(
            point.assets.format(),
            point.liabilities.format(),
          ),
        ),
        if (point.derived) TextSpan(text: '\n${l10n.netWorthEstimated}'),
      ],
    );
  }
}

// One entry of the legend: a short line in [color], dashed when [dashed], and [label].
class _Key extends StatelessWidget {
  const _Key(this.color, this.label, {this.dashed = false});

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 20,
        height: 10,
        child: CustomPaint(painter: _KeyPainter(color, dashed)),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(label, style: Theme.of(context).textTheme.labelMedium),
      ),
    ],
  );
}

class _KeyPainter extends CustomPainter {
  _KeyPainter(this.color, this.dashed);

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    final double y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, y), Offset(x + 4, y), paint);
    }
  }

  @override
  bool shouldRepaint(_KeyPainter old) =>
      old.color != color || old.dashed != dashed;
}
