// The finance colors: the brand's values; a category's color harmonized toward the
// brand's blue with the brand schemes; and with the device's dynamic colors, harmonized
// with the scheme's primary and still at the 4.5:1 text contrast ratio on the scheme's
// surface, light and dark, for wallpapers of every hue.
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
  test('the light colors are the brand\'s', () {
    const FinanceColors c = FinanceColors.light;
    expect(c.outflow, const Color(0xFFBC2170));
    expect(c.inflow, const Color(0xFF19743E));
    expect(c.warning, const Color(0xFF806000));
    expect(c.accent, const Color(0xFFFF3EA5));
    expect(c.inks, const [
      Color(0xFF1F4FE0),
      Color(0xFFFF3EA5),
      Color(0xFFF2B705),
      Color(0xFF1E8A4A),
      Color(0xFF1F1F1F),
    ]);
  });

  test('the dark colors are the night print\'s', () {
    const FinanceColors c = FinanceColors.dark;
    expect(c.outflow, const Color(0xFFFF7AC3));
    expect(c.inflow, const Color(0xFF5FD38B));
    expect(c.warning, const Color(0xFFFFD24D));
    expect(c.accent, const Color(0xFFFF7AC3));
    expect(c.inks, const [
      Color(0xFF8FA8FF),
      Color(0xFFFF7AC3),
      Color(0xFFFFD24D),
      Color(0xFF5FD38B),
      Color(0xFFF1ECE1),
    ]);
  });

  test('an ink cycles and its tint is a fifth of it', () {
    const FinanceColors c = FinanceColors.light;
    expect(c.ink(5), c.inks.first);
    expect(c.tint(1), const Color(0xFFFF3EA5).withValues(alpha: 0.2));
  });

  test('the brand themes keep the brand colors and bend a category toward '
      'the blue', () {
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
      category.harmonizeWith(AppTheme.lightScheme.primary),
    );
    expect(
      AppTheme.dark().extension<FinanceColors>()!.custom(category),
      category.harmonizeWith(AppTheme.darkScheme.primary),
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
        expect(colors.warning, fixed.warning.harmonizeWith(scheme.primary));
        expect(colors.ink(0), fixed.ink(0).harmonizeWith(scheme.primary));
        for (final Color c in [colors.outflow, colors.inflow, colors.warning]) {
          expect(_contrast(c, scheme.surface), greaterThanOrEqualTo(4.5));
        }
        const Color category = Color(0xFF00897B);
        expect(colors.custom(category), category.harmonizeWith(scheme.primary));
      });
    }
  }
}
