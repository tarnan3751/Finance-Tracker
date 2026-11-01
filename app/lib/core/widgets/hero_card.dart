/// The hero card (`docs/reference/design.md`, **The hero card**): the one solid block of a
/// screen, the figure that matters most printed in paper on the primary blue, with its
/// pink copy offset down and to the end by the misregistration, as a two-ink print slips.
/// The copy is a second `DecoratedBox`, not a shadow, so it is flat and shows in the CI
/// goldens. A label in Work Sans 600 capitals tracked at 0.08 em, the figure in Work Sans
/// 700 with tabular figures, an optional caption, and an optional widget at the end. The
/// label, figure and caption are read as one node, as one sentence when given a
/// [HeroCard.semanticsLabel] ([heroSentence]); the trailing widget is a node of its own,
/// so a button there stays a button.
///
/// A figure or a caption that carries a direction ([HeroTone]: money in green, money out
/// pink) is set on a paper pill inside the block, in the theme's text green or pink: the
/// inks themselves do not read on the blue (under 3:1), the text inks on paper do.
library;

import 'package:finance_tracker/core/l10n/joins.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/theme/finance_colors.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:finance_tracker/core/widgets/amount_text.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// The direction a hero card's figure or caption carries.
enum HeroTone {
  /// Paper on the blue, the card's own.
  plain,

  /// Money in: the text green on a paper pill.
  inflow,

  /// Money out, or over a limit: the text pink on a paper pill.
  outflow,
}

/// A hero card's spoken sentence: [label], then [figure] (as a screen reader says it),
/// then [caption] when there is one.
String heroSentence(
  AppLocalizations l10n,
  String label,
  String figure, [
  String? caption,
]) => caption == null
    ? l10n.heroSemantics(label, figure)
    : l10n.heroSemanticsCaption(label, figure, caption);

/// [amounts] as a hero card's figure: one amount per currency, never converted, side by
/// side and wrapping.
class HeroAmounts extends StatelessWidget {
  const HeroAmounts(this.amounts, {super.key, this.tones});

  final List<Money> amounts;

  /// Each amount's direction, in order, or null for all plain: an amount toned on its
  /// own, so one currency over its limit prints pink while another does not.
  final List<HeroTone>? tones;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: SpendthriftTokens.space24,
    runSpacing: SpendthriftTokens.space4,
    children: [
      for (int i = 0; i < amounts.length; i++)
        switch (tones?[i] ?? HeroTone.plain) {
          HeroTone.plain => AmountText(amounts[i]),
          final HeroTone tone => _toned(
            context,
            tone,
            (color) => AmountText(
              amounts[i],
              style: DefaultTextStyle.of(context).style.copyWith(color: color),
            ),
          ),
        },
    ],
  );
}

/// [amounts] as a screen reader says them, as one list.
String spokenAmounts(AppLocalizations l10n, Iterable<Money> amounts) =>
    listLine(l10n, [
      for (final Money amount in amounts) amountSemanticsLabel(l10n, amount),
    ]);

/// A solid primary block with [label] over [figure], then [caption], and [trailing] at
/// the end.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.label,
    required this.figure,
    this.caption,
    this.trailing,
    this.figureTone = HeroTone.plain,
    this.captionTone = HeroTone.plain,
    this.semanticsLabel,
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

  /// The direction [figure] carries.
  final HeroTone figureTone;

  /// The direction [caption] carries.
  final HeroTone captionTone;

  /// What a screen reader says for the label, the figure and the caption, as one
  /// sentence ([heroSentence]); null reads the three as they are written.
  final String? semanticsLabel;

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
        _toned(
          context,
          figureTone,
          (color) => DefaultTextStyle.merge(
            style: AppTheme.figure(theme.textTheme.headlineMedium)
                .copyWith(color: color),
            child: figure,
          ),
        ),
        if (caption case final String caption) ...[
          const SizedBox(height: SpendthriftTokens.space4),
          _toned(
            context,
            captionTone,
            (color) => Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
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
                  Expanded(
                    child: MergeSemantics(
                      child: switch (semanticsLabel) {
                        null => content,
                        final String sentence => Semantics(
                          label: sentence,
                          child: ExcludeSemantics(child: content),
                        ),
                      },
                    ),
                  ),
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

/// [build] with paper for [tone] plain, else on a paper pill in the tone's text color.
Widget _toned(
  BuildContext context,
  HeroTone tone,
  Widget Function(Color color) build,
) {
  final Color paper = Theme.of(context).colorScheme.surface;
  final FinanceColors colors = FinanceColors.of(context);
  return switch (tone) {
    HeroTone.plain => build(paper),
    HeroTone.inflow || HeroTone.outflow => DecoratedBox(
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(SpendthriftTokens.radiusPill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpendthriftTokens.space8,
          vertical: 2,
        ),
        child: build(tone == HeroTone.inflow ? colors.inflow : colors.outflow),
      ),
    ),
  };
}
