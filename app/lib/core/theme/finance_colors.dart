/// The brand's semantic colors (`docs/reference/design.md`), as a `ThemeExtension` both
/// themes carry: [FinanceColors.outflow] for amounts that leave an account,
/// [FinanceColors.inflow] for amounts that arrive, [FinanceColors.warning] for text that
/// warns (a budget near its limit), [FinanceColors.accent], the pink overprint (never body
/// text on paper), and [FinanceColors.inks], the charts' ordered palette. The three text
/// colors meet the 4.5:1 text contrast ratio on the theme's surfaces up to
/// `surfaceContainerHigh`, light and dark.
///
/// A color the user chose (a category's, through [custom]) is harmonized with the scheme's
/// primary color (`harmonizeWith`, from dynamic_color: the hue moves toward the primary's
/// by at most 15 degrees, the tone stays): the brand's blue with the brand schemes, the
/// device's primary with its dynamic colors. With the dynamic colors
/// ([FinanceColors.harmonized]) the brand's own colors are harmonized too, which keeps
/// their tone and so their contrast; with the brand schemes they stay as they are.
library;

import 'package:dynamic_color/dynamic_color.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// The semantic colors of a theme. Read with [FinanceColors.of].
@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  const FinanceColors({
    required this.outflow,
    required this.inflow,
    required this.warning,
    required this.accent,
    required this.inks,
    this.harmonizeTo,
  });

  /// The light theme's colors, on paper.
  static const FinanceColors light = FinanceColors(
    outflow: Color(0xFFBC2170),
    inflow: Color(0xFF19743E),
    warning: Color(0xFF806000),
    accent: Color(0xFFFF3EA5),
    inks: [
      Color(0xFF1F4FE0),
      Color(0xFFFF3EA5),
      Color(0xFFF2B705),
      Color(0xFF1E8A4A),
      Color(0xFF1F1F1F),
    ],
    harmonizeTo: Color(0xFF1F4FE0),
  );

  /// The dark theme's colors, the night print.
  static const FinanceColors dark = FinanceColors(
    outflow: Color(0xFFFF7AC3),
    inflow: Color(0xFF5FD38B),
    warning: Color(0xFFFFD24D),
    accent: Color(0xFFFF7AC3),
    inks: [
      Color(0xFF8FA8FF),
      Color(0xFFFF7AC3),
      Color(0xFFFFD24D),
      Color(0xFF5FD38B),
      Color(0xFFF1ECE1),
    ],
    harmonizeTo: Color(0xFF8FA8FF),
  );

  /// The color of an amount leaving an account.
  final Color outflow;

  /// The color of an amount arriving in an account.
  final Color inflow;

  /// The color of warning text.
  final Color warning;

  /// The pink overprint: the hero card's offset copy, the demo strip, a chart's second
  /// ink. Not for body text on paper.
  final Color accent;

  /// The charts' inks in order: blue, pink, yellow, green, ink.
  final List<Color> inks;

  /// The scheme's primary color the custom colors are harmonized with.
  final Color? harmonizeTo;

  /// Ink [i], cycling through [inks].
  Color ink(int i) => inks[i % inks.length];

  /// Ink [i] at the tint's opacity, for bands and fills.
  Color tint(int i) => ink(i).withValues(alpha: SpendthriftTokens.tint);

  /// These colors harmonized with [primary], a dynamic scheme's.
  FinanceColors harmonized(Color primary) => FinanceColors(
    outflow: outflow.harmonizeWith(primary),
    inflow: inflow.harmonizeWith(primary),
    warning: warning.harmonizeWith(primary),
    accent: accent.harmonizeWith(primary),
    inks: [for (final Color c in inks) c.harmonizeWith(primary)],
    harmonizeTo: primary,
  );

  /// [color], one the user chose (a category's), as a chart draws it: harmonized with the
  /// scheme's primary color.
  Color custom(Color color) => switch (harmonizeTo) {
    final Color primary => color.harmonizeWith(primary),
    null => color,
  };

  /// The colors of [context]'s theme.
  static FinanceColors of(BuildContext context) =>
      Theme.of(context).extension<FinanceColors>()!;

  @override
  FinanceColors copyWith({
    Color? outflow,
    Color? inflow,
    Color? warning,
    Color? accent,
    List<Color>? inks,
    Color? harmonizeTo,
  }) => FinanceColors(
    outflow: outflow ?? this.outflow,
    inflow: inflow ?? this.inflow,
    warning: warning ?? this.warning,
    accent: accent ?? this.accent,
    inks: inks ?? this.inks,
    harmonizeTo: harmonizeTo ?? this.harmonizeTo,
  );

  @override
  FinanceColors lerp(FinanceColors? other, double t) {
    if (other == null) return this;
    return FinanceColors(
      outflow: Color.lerp(outflow, other.outflow, t)!,
      inflow: Color.lerp(inflow, other.inflow, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      inks: [
        for (int i = 0; i < inks.length; i++)
          Color.lerp(inks[i], other.ink(i), t)!,
      ],
      harmonizeTo: Color.lerp(harmonizeTo, other.harmonizeTo, t),
    );
  }
}
