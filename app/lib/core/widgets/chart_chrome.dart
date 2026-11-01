/// The chrome every chart shares (`docs/reference/design.md`, **Charts**): the card a
/// chart and its legend sit in ([ChartCard], a `BrandCard`), a legend entry as an
/// ink-outlined pill ([LegendPill], its label in Work Sans `labelSmall` in
/// `onSurfaceVariant`), and the switch between a chart and its table
/// ([ChartTableToggle], a `SegmentedButton`). The charts themselves print in the inks.
library;

import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:finance_tracker/core/widgets/brand_card.dart';
import 'package:flutter/material.dart';

/// [child], a chart and its legend, on a card at the screen's sides.
class ChartCard extends StatelessWidget {
  const ChartCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      SpendthriftTokens.space16,
      SpendthriftTokens.space4,
      SpendthriftTokens.space16,
      SpendthriftTokens.space8,
    ),
    child: BrandCard(
      padding: const EdgeInsets.symmetric(vertical: SpendthriftTokens.space12),
      child: child,
    ),
  );
}

/// One legend entry: [swatch] (a color's square or a line's key) and [label], on an
/// ink-outlined pill.
class LegendPill extends StatelessWidget {
  const LegendPill({super.key, required this.swatch, required this.label});

  final Widget swatch;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: StadiumBorder(
          side: BorderSide(
            color: theme.colorScheme.outline,
            width: SpendthriftTokens.inkLine,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpendthriftTokens.space8,
          vertical: SpendthriftTokens.space4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            swatch,
            const SizedBox(width: SpendthriftTokens.space4),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The switch between a chart ([chartLabel]) and its table ([tableLabel]); [table] is
/// whether the table shows.
class ChartTableToggle extends StatelessWidget {
  const ChartTableToggle({
    super.key,
    required this.table,
    required this.onChanged,
    required this.chartLabel,
    required this.tableLabel,
  });

  final bool table;
  final ValueChanged<bool> onChanged;
  final String chartLabel;
  final String tableLabel;

  @override
  Widget build(BuildContext context) => SegmentedButton<bool>(
    segments: [
      ButtonSegment(value: false, label: Text(chartLabel)),
      ButtonSegment(value: true, label: Text(tableLabel)),
    ],
    selected: {table},
    showSelectedIcon: false,
    onSelectionChanged: (selected) => onChanged(selected.single),
  );
}
