/// The hero card (`docs/reference/design.md`, **The hero card**): the one solid block of a
/// screen, the figure that matters most printed in paper on the primary blue, with its
/// pink copy offset down and to the end by the misregistration, as a two-ink print slips.
/// The copy is a second `DecoratedBox`, not a shadow, so it is flat and shows in the CI
/// goldens. A label in Work Sans 600 capitals tracked at 0.08 em, the figure in Work Sans
/// 700 with tabular figures, an optional caption, and an optional widget at the end. The
/// label, figure and caption are read as one node; the trailing widget is a node of its
/// own, so a button there stays a button.
library;

import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/theme/finance_colors.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// A solid primary block with [label] over [figure], then [caption], and [trailing] at
/// the end.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.label,
    required this.figure,
    this.caption,
    this.trailing,
  });

  /// What the figure is, shown in capitals and read as written.
  final String label;

  /// The figure: usually an `AmountText`, or several in a `Wrap`; its text takes the
  /// card's figure style unless it sets its own.
  final Widget figure;

  /// A line under the figure (what the figure adds up), or null.
  final String? caption;

  /// A widget at the card's end (an action, a chip), or null.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color paper = theme.colorScheme.surface;
    final BorderRadius radius = BorderRadius.circular(SpendthriftTokens.radius);
    const double d = SpendthriftTokens.misregistration;
    final TextStyle? labelStyle = theme.textTheme.labelLarge;
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          semanticsLabel: label,
          style: labelStyle?.copyWith(
            color: paper,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.08 * (labelStyle.fontSize ?? 14),
          ),
        ),
        const SizedBox(height: SpendthriftTokens.space4),
        DefaultTextStyle.merge(
          style: AppTheme.figure(theme.textTheme.headlineMedium)
              .copyWith(color: paper),
          child: figure,
        ),
        if (caption case final String caption) ...[
          const SizedBox(height: SpendthriftTokens.space4),
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(color: paper),
          ),
        ],
      ],
    );
    return Padding(
      // Room for the copy, which prints past the card.
      padding: const EdgeInsetsDirectional.only(end: d, bottom: d),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            start: d,
            top: d,
            end: -d,
            bottom: -d,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: FinanceColors.of(context).accent,
                borderRadius: radius,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: radius,
            ),
            child: Padding(
              padding: const EdgeInsets.all(SpendthriftTokens.space16),
              child: Row(
                children: [
                  Expanded(child: MergeSemantics(child: content)),
                  if (trailing case final Widget trailing) ...[
                    const SizedBox(width: SpendthriftTokens.space12),
                    IconTheme.merge(
                      data: IconThemeData(color: paper),
                      child: trailing,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
