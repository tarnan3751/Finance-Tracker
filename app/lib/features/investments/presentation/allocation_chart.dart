/// The holdings' allocation by security type: a donut (fl_chart) with the total in its
/// middle, read by a screen reader as one summary (the total, how many types, the largest
/// and its share), and its table, the full equivalent: a swatch, the type, its share and
/// its value per row, each row one semantics node.
///
/// fl_chart sizes a slice by a `double`, so each slice's minor units are handed to it as a
/// `double` for placement only. No amount on screen comes from them: the labels and the
/// summary format the slices' own `Money`.
library;

import 'package:finance_tracker/features/investments/domain/allocation.dart';
import 'package:finance_tracker/features/investments/presentation/investment_rows.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// The colour of the slice at [index] in the donut and its table.
Color allocationColor(ColorScheme colors, int index) {
  final List<Color> palette = [
    colors.primary,
    colors.tertiary,
    colors.secondary,
    // Never the error colour: a slice is a share, not a loss.
    colors.inversePrimary,
    colors.primaryContainer,
    colors.tertiaryContainer,
    colors.secondaryContainer,
    colors.outline,
  ];
  return palette[index % palette.length];
}

/// The donut of [allocation] (its positive slices are drawn).
class AllocationDonut extends StatelessWidget {
  const AllocationDonut(this.allocation, {super.key});

  final Allocation allocation;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final AllocationSlice largest = allocation.slices.first;
    final int? share = shareBasisPoints(largest.value, allocation.total);
    return Semantics(
      container: true,
      label: l10n.investmentsAllocationSummary(
        allocation.total.format(),
        allocation.slices.length,
        securityTypeLabel(largest.key, l10n),
        share == null ? largest.value.format() : percentLabel(l10n, share),
      ),
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
                  pieTouchData: PieTouchData(enabled: false),
                  sections: [
                    for (int i = 0; i < allocation.slices.length; i++)
                      if (allocation.slices[i].value.isPositive)
                        PieChartSectionData(
                          value: allocation.slices[i].value.minorUnits
                              .toDouble(),
                          color: allocationColor(theme.colorScheme, i),
                          radius: 36,
                          showTitle: false,
                        ),
                  ],
                ),
              ),
              // Inside the hole whatever the text size.
              SizedBox(
                width: 112,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    allocation.total.format(),
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

/// The slices of [allocation] as rows, in the donut's order and colours.
class AllocationTable extends StatelessWidget {
  const AllocationTable(this.allocation, {super.key});

  final Allocation allocation;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < allocation.slices.length; i++) ...[
          () {
            final AllocationSlice slice = allocation.slices[i];
            final String name = securityTypeLabel(slice.key, l10n);
            final String value = slice.value.format();
            final int? bp = shareBasisPoints(slice.value, allocation.total);
            final String share = bp == null ? '' : percentLabel(l10n, bp);
            return Semantics(
              container: true,
              label: bp == null
                  ? l10n.investmentsNameAmount(name, value)
                  : l10n.investmentsAllocationRow(name, value, share),
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: allocationColor(theme.colorScheme, i),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          spacing: 12,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(name),
                            Wrap(
                              spacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(share, style: theme.textTheme.bodySmall),
                                Text(value),
                              ],
                            ),
                          ],
                        ),
                      ),
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
