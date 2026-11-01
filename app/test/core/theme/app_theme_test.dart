// The brand's schemes, hex by hex, the tokens, and the contrast of every text color on
// every surface it is drawn on (4.5:1), light and dark.
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/core/theme/finance_colors.dart';
import 'package:finance_tracker/core/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

Map<String, int> _hex(ColorScheme s) => {
  'surface': s.surface.toARGB32(),
  'onSurface': s.onSurface.toARGB32(),
  'onSurfaceVariant': s.onSurfaceVariant.toARGB32(),
  'surfaceContainerLowest': s.surfaceContainerLowest.toARGB32(),
  'surfaceContainerLow': s.surfaceContainerLow.toARGB32(),
  'surfaceContainer': s.surfaceContainer.toARGB32(),
  'surfaceContainerHigh': s.surfaceContainerHigh.toARGB32(),
  'surfaceContainerHighest': s.surfaceContainerHighest.toARGB32(),
  'primary': s.primary.toARGB32(),
  'onPrimary': s.onPrimary.toARGB32(),
  'primaryContainer': s.primaryContainer.toARGB32(),
  'onPrimaryContainer': s.onPrimaryContainer.toARGB32(),
  'secondary': s.secondary.toARGB32(),
  'onSecondary': s.onSecondary.toARGB32(),
  'secondaryContainer': s.secondaryContainer.toARGB32(),
  'onSecondaryContainer': s.onSecondaryContainer.toARGB32(),
  'tertiary': s.tertiary.toARGB32(),
  'onTertiary': s.onTertiary.toARGB32(),
  'tertiaryContainer': s.tertiaryContainer.toARGB32(),
  'onTertiaryContainer': s.onTertiaryContainer.toARGB32(),
  'error': s.error.toARGB32(),
  'onError': s.onError.toARGB32(),
  'errorContainer': s.errorContainer.toARGB32(),
  'onErrorContainer': s.onErrorContainer.toARGB32(),
  'outline': s.outline.toARGB32(),
  'outlineVariant': s.outlineVariant.toARGB32(),
  'inverseSurface': s.inverseSurface.toARGB32(),
  'onInverseSurface': s.onInverseSurface.toARGB32(),
  'inversePrimary': s.inversePrimary.toARGB32(),
  'surfaceTint': s.surfaceTint.toARGB32(),
};

void main() {
  test('the light scheme is paper and ink', () {
    expect(AppTheme.lightScheme.brightness, Brightness.light);
    expect(_hex(AppTheme.lightScheme), {
      'surface': 0xFFF7F3EA,
      'onSurface': 0xFF1F1F1F,
      'onSurfaceVariant': 0xFF5C574C,
      'surfaceContainerLowest': 0xFFFFFFFF,
      'surfaceContainerLow': 0xFFF3EEE3,
      'surfaceContainer': 0xFFEFE9DC,
      'surfaceContainerHigh': 0xFFE9E2D3,
      'surfaceContainerHighest': 0xFFE2DAC8,
      'primary': 0xFF1F4FE0,
      'onPrimary': 0xFFFFFFFF,
      'primaryContainer': 0xFFD6E0FF,
      'onPrimaryContainer': 0xFF0E1E60,
      'secondary': 0xFFFF3EA5,
      'onSecondary': 0xFF1F1F1F,
      'secondaryContainer': 0xFFFFD6EC,
      'onSecondaryContainer': 0xFF4A0A2B,
      'tertiary': 0xFFF2B705,
      'onTertiary': 0xFF1F1F1F,
      'tertiaryContainer': 0xFFFFF0B8,
      'onTertiaryContainer': 0xFF3A2D00,
      'error': 0xFFC32237,
      'onError': 0xFFFFFFFF,
      'errorContainer': 0xFFFFDAD9,
      'onErrorContainer': 0xFF410006,
      'outline': 0xFF1F1F1F,
      'outlineVariant': 0xFFB9B2A3,
      'inverseSurface': 0xFF1F1F1F,
      'onInverseSurface': 0xFFF7F3EA,
      'inversePrimary': 0xFF8FA8FF,
      'surfaceTint': 0x00000000,
    });
  });

  test('the dark scheme is the night print', () {
    expect(AppTheme.darkScheme.brightness, Brightness.dark);
    expect(_hex(AppTheme.darkScheme), {
      'surface': 0xFF16151C,
      'onSurface': 0xFFF1ECE1,
      'onSurfaceVariant': 0xFFB5AFA3,
      'surfaceContainerLowest': 0xFF0F0E13,
      'surfaceContainerLow': 0xFF1B1A21,
      'surfaceContainer': 0xFF1F1E27,
      'surfaceContainerHigh': 0xFF27262F,
      'surfaceContainerHighest': 0xFF302F39,
      'primary': 0xFF8FA8FF,
      'onPrimary': 0xFF0E1230,
      'primaryContainer': 0xFF2A3F8F,
      'onPrimaryContainer': 0xFFE0E7FF,
      'secondary': 0xFFFF7AC3,
      'onSecondary': 0xFF2A0A1C,
      'secondaryContainer': 0xFF6E1F4A,
      'onSecondaryContainer': 0xFFFFDCEE,
      'tertiary': 0xFFFFD24D,
      'onTertiary': 0xFF2A2000,
      'tertiaryContainer': 0xFF5E4A00,
      'onTertiaryContainer': 0xFFFFF0B8,
      'error': 0xFFFF6B6B,
      'onError': 0xFF3A0000,
      'errorContainer': 0xFF7A1C1C,
      'onErrorContainer': 0xFFFFDAD9,
      'outline': 0xFF73727F,
      'outlineVariant': 0xFF3A3944,
      'inverseSurface': 0xFFF1ECE1,
      'onInverseSurface': 0xFF16151C,
      'inversePrimary': 0xFF1F4FE0,
      'surfaceTint': 0x00000000,
    });
  });

  test('the brand themes use the brand schemes and colors', () {
    expect(AppTheme.light().colorScheme, AppTheme.lightScheme);
    expect(AppTheme.dark().colorScheme, AppTheme.darkScheme);
    expect(AppTheme.light().extension<FinanceColors>(), FinanceColors.light);
    expect(AppTheme.dark().extension<FinanceColors>(), FinanceColors.dark);
  });

  test('the tokens', () {
    expect(SpendthriftTokens.radius, 8);
    expect(SpendthriftTokens.radiusLarge, 16);
    expect(SpendthriftTokens.radiusPill, 999);
    expect(SpendthriftTokens.inkLine, 1.5);
    expect(SpendthriftTokens.focusLine, 2);
    expect(
      [
        SpendthriftTokens.space4,
        SpendthriftTokens.space8,
        SpendthriftTokens.space12,
        SpendthriftTokens.space16,
        SpendthriftTokens.space24,
        SpendthriftTokens.space32,
      ],
      [4, 8, 12, 16, 24, 32],
    );
    expect(SpendthriftTokens.misregistration, 5);
    expect(SpendthriftTokens.iconMisregistration, 3);
    expect(SpendthriftTokens.tint, 0.2);
  });

  for (final (String name, ColorScheme s, FinanceColors f) in [
    ('light', AppTheme.lightScheme, FinanceColors.light),
    ('dark', AppTheme.darkScheme, FinanceColors.dark),
  ]) {
    test('every $name text color reaches 4.5:1 on the surfaces it is drawn '
        'on', () {
      final Map<String, Color> surfaces = {
        'surface': s.surface,
        'surfaceContainerLowest': s.surfaceContainerLowest,
        'surfaceContainerLow': s.surfaceContainerLow,
        'surfaceContainer': s.surfaceContainer,
        'surfaceContainerHigh': s.surfaceContainerHigh,
      };
      final Map<String, Color> texts = {
        'onSurface': s.onSurface,
        'onSurfaceVariant': s.onSurfaceVariant,
        'primary': s.primary,
        'error': s.error,
        'outflow': f.outflow,
        'inflow': f.inflow,
        'warning': f.warning,
      };
      for (final MapEntry(key: String bg, value: Color b) in surfaces.entries) {
        for (final MapEntry(key: String fg, value: Color c) in texts.entries) {
          expect(
            _contrast(c, b),
            greaterThanOrEqualTo(4.5),
            reason: '$fg on $bg',
          );
        }
      }
      // The pairs drawn on each other.
      for (final (String pair, Color fg, Color bg) in [
        ('onPrimary', s.onPrimary, s.primary),
        ('surface on primary (the hero card)', s.surface, s.primary),
        ('onPrimaryContainer', s.onPrimaryContainer, s.primaryContainer),
        ('onSecondary', s.onSecondary, s.secondary),
        ('onSecondaryContainer', s.onSecondaryContainer, s.secondaryContainer),
        ('onTertiary', s.onTertiary, s.tertiary),
        ('onTertiaryContainer', s.onTertiaryContainer, s.tertiaryContainer),
        ('onError', s.onError, s.error),
        ('onErrorContainer', s.onErrorContainer, s.errorContainer),
        ('onInverseSurface', s.onInverseSurface, s.inverseSurface),
        (
          'onSurfaceVariant on highest',
          s.onSurfaceVariant,
          s.surfaceContainerHighest,
        ),
        ('onSurface on highest', s.onSurface, s.surfaceContainerHighest),
      ]) {
        expect(_contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: pair);
      }
    });

    test('the $name ink line reaches 3:1 on the surfaces fields sit on', () {
      // WCAG 1.4.11: the outline is what marks a text field's bounds.
      for (final Color bg in [s.surface, s.surfaceContainerHigh]) {
        expect(_contrast(s.outline, bg), greaterThanOrEqualTo(3));
      }
    });
  }
}
