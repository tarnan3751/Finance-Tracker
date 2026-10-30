/// The colors of money moving: [FinanceColors.outflow] for amounts that leave an account
/// and [FinanceColors.inflow] for amounts that arrive, as a `ThemeExtension` both themes
/// carry. Each meets the 4.5:1 text contrast ratio on the theme's surfaces, light and dark.
///
/// With the device's dynamic colors ([FinanceColors.harmonized]) both are harmonized with
/// the scheme's primary color (`harmonizeWith`, from dynamic_color: the hue moves toward
/// the primary's by at most 15 degrees, the tone stays, so the contrast holds), and so is
/// every color the user chose that a chart draws (a category's, through [custom]). With
/// the baseline scheme they stay as they are.
library;

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

/// The inflow and outflow colors of a theme. Read with [FinanceColors.of].
@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  const FinanceColors({
    required this.outflow,
    required this.inflow,
    this.harmonizeTo,
  });

  /// The light theme's colors: a deep red and a deep green.
  static const FinanceColors light = FinanceColors(
    outflow: Color(0xFFB3261E),
    inflow: Color(0xFF1B6C2A),
  );

  /// The dark theme's colors: a light red and a light green.
  static const FinanceColors dark = FinanceColors(
    outflow: Color(0xFFFFB4AB),
    inflow: Color(0xFF8FD694),
  );

  /// The color of an amount leaving an account.
  final Color outflow;

  /// The color of an amount arriving in an account.
  final Color inflow;

  /// The dynamic scheme's primary color the custom colors are harmonized with, or null
  /// with the baseline scheme.
  final Color? harmonizeTo;

  /// These colors harmonized with [primary], a dynamic scheme's.
  FinanceColors harmonized(Color primary) => FinanceColors(
    outflow: outflow.harmonizeWith(primary),
    inflow: inflow.harmonizeWith(primary),
    harmonizeTo: primary,
  );

  /// [color], one the user chose (a category's), as a chart draws it: harmonized with a
  /// dynamic scheme's primary color, as it is with the baseline scheme.
  Color custom(Color color) => switch (harmonizeTo) {
    final Color primary => color.harmonizeWith(primary),
    null => color,
  };

  /// The colors of [context]'s theme.
  static FinanceColors of(BuildContext context) =>
      Theme.of(context).extension<FinanceColors>()!;

  @override
  FinanceColors copyWith({Color? outflow, Color? inflow, Color? harmonizeTo}) =>
      FinanceColors(
        outflow: outflow ?? this.outflow,
        inflow: inflow ?? this.inflow,
        harmonizeTo: harmonizeTo ?? this.harmonizeTo,
      );

  @override
  FinanceColors lerp(FinanceColors? other, double t) {
    if (other == null) return this;
    return FinanceColors(
      outflow: Color.lerp(outflow, other.outflow, t)!,
      inflow: Color.lerp(inflow, other.inflow, t)!,
      harmonizeTo: Color.lerp(harmonizeTo, other.harmonizeTo, t),
    );
  }
}
