// The finance colors with the device's dynamic colors: harmonized with the scheme's
// primary and still at the 4.5:1 text contrast ratio on the
// scheme's surface, light and dark, for wallpapers of every hue; a category's color in a
// chart harmonized the same way; and the baseline themes' colors as they were.
import 'package:dynamic_color/dynamic_color.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/theme/finance_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  test('the baseline themes keep the fixed colors', () {
    expect(
      AppTheme.light().extension<FinanceColors>()!.outflow,
      FinanceColors.light.outflow,
    );
    expect(
      AppTheme.dark().extension<FinanceColors>()!.inflow,
      FinanceColors.dark.inflow,
    );
    const Color category = Color(0xFF00897B);
    expect(
      AppTheme.light().extension<FinanceColors>()!.custom(category),
      category,
    );
  });

  for (final Brightness brightness in Brightness.values) {
    for (final Color wallpaper in const [
      Color(0xFF1E88E5),
      Color(0xFF43A047),
      Color(0xFFFDD835),
      Color(0xFFE53935),
      Color(0xFF8E24AA),
    ]) {
      test('a ${brightness.name} dynamic scheme from $wallpaper harmonizes '
          'and keeps the contrast', () {
        final ColorScheme scheme = ColorScheme.fromSeed(
          seedColor: wallpaper,
          brightness: brightness,
        );
        final ThemeData theme = brightness == Brightness.light
            ? AppTheme.light(scheme)
            : AppTheme.dark(scheme);
        final FinanceColors colors = theme.extension<FinanceColors>()!;
        final FinanceColors fixed = brightness == Brightness.light
            ? FinanceColors.light
            : FinanceColors.dark;

        expect(colors.outflow, fixed.outflow.harmonizeWith(scheme.primary));
        expect(colors.inflow, fixed.inflow.harmonizeWith(scheme.primary));
        for (final Color c in [colors.outflow, colors.inflow]) {
          expect(_contrast(c, scheme.surface), greaterThanOrEqualTo(4.5));
        }
        const Color category = Color(0xFF00897B);
        expect(colors.custom(category), category.harmonizeWith(scheme.primary));
      });
    }
  }
}
