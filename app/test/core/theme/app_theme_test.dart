// The brand's schemes, hex by hex, the tokens, and the contrast of every text color on
// every surface it is drawn on (4.5:1), light and dark; the type; the flat components
// with their ink line, and the floating button's pink copy.
import 'dart:typed_data';
import 'dart:ui' as ui;

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

  test('the headings are Syne and the rest Work Sans with tabular figures, at '
      "Material 3's sizes", () {
    final TextTheme m3 = Typography.material2021().englishLike;
    for (final ThemeData theme in [AppTheme.light(), AppTheme.dark()]) {
      // As `Theme` gives it, with the sizes of English.
      final TextTheme t = ThemeData.localize(theme, m3).textTheme;
      final Map<String, (TextStyle?, TextStyle?)> styles = {
        'displayLarge': (t.displayLarge, m3.displayLarge),
        'displayMedium': (t.displayMedium, m3.displayMedium),
        'displaySmall': (t.displaySmall, m3.displaySmall),
        'headlineLarge': (t.headlineLarge, m3.headlineLarge),
        'headlineMedium': (t.headlineMedium, m3.headlineMedium),
        'headlineSmall': (t.headlineSmall, m3.headlineSmall),
        'titleLarge': (t.titleLarge, m3.titleLarge),
        'titleMedium': (t.titleMedium, m3.titleMedium),
        'titleSmall': (t.titleSmall, m3.titleSmall),
        'bodyLarge': (t.bodyLarge, m3.bodyLarge),
        'bodyMedium': (t.bodyMedium, m3.bodyMedium),
        'bodySmall': (t.bodySmall, m3.bodySmall),
        'labelLarge': (t.labelLarge, m3.labelLarge),
        'labelMedium': (t.labelMedium, m3.labelMedium),
        'labelSmall': (t.labelSmall, m3.labelSmall),
      };
      for (final MapEntry(key: String name, value: (TextStyle? s, TextStyle? m))
          in styles.entries) {
        expect(
          (s!.fontSize! - m!.fontSize!).abs(),
          lessThanOrEqualTo(2),
          reason: name,
        );
        final bool heading =
            name.startsWith('display') ||
            name.startsWith('headline') ||
            name == 'titleLarge';
        if (heading) {
          expect(s.fontFamily, AppTheme.headingFont, reason: name);
          expect(
            s.fontWeight,
            name.startsWith('display') ? FontWeight.w800 : FontWeight.w700,
            reason: name,
          );
          expect(s.letterSpacing, closeTo(-0.02 * s.fontSize!, 1e-9));
        } else {
          expect(s.fontFamily, AppTheme.bodyFont, reason: name);
          expect(s.fontFeatures, AppTheme.tabularFigures, reason: name);
        }
      }
    }
  });

  test('a figure is Work Sans 700 with tabular figures at its size', () {
    final TextStyle? headline = ThemeData.localize(
      AppTheme.light(),
      Typography.material2021().englishLike,
    ).textTheme.headlineMedium;
    final TextStyle figure = AppTheme.figure(headline);
    expect(figure.fontFamily, AppTheme.bodyFont);
    expect(figure.fontWeight, FontWeight.w700);
    expect(figure.fontFeatures, AppTheme.tabularFigures);
    expect(figure.fontSize, headline!.fontSize);
  });

  for (final ThemeData theme in [AppTheme.light(), AppTheme.dark()]) {
    final ColorScheme s = theme.colorScheme;
    final String name = s.brightness.name;
    final BorderSide ink = BorderSide(
      color: s.outline,
      width: SpendthriftTokens.inkLine,
    );

    test('the $name components are flat and drawn with the ink line', () {
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.scrolledUnderElevation, 0);
      expect(theme.navigationBarTheme.elevation, 0);
      expect(theme.navigationBarTheme.indicatorColor, s.primaryContainer);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.cardTheme.margin, EdgeInsets.zero);
      expect(
        theme.cardTheme.shape,
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpendthriftTokens.radius),
          side: ink,
        ),
      );
      expect(theme.dialogTheme.elevation, 0);
      expect(
        theme.dialogTheme.shape,
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpendthriftTokens.radiusLarge),
          side: ink,
        ),
      );
      expect(theme.bottomSheetTheme.modalElevation, 0);
      expect(theme.popupMenuTheme.elevation, 0);
      expect(theme.menuTheme.style!.elevation!.resolve({}), 0);
      expect(theme.dropdownMenuTheme.menuStyle!.elevation!.resolve({}), 0);
      expect(theme.snackBarTheme.backgroundColor, s.inverseSurface);
      expect(theme.floatingActionButtonTheme.elevation, 0);
      expect(theme.floatingActionButtonTheme.highlightElevation, 0);
      expect(theme.floatingActionButtonTheme.backgroundColor, s.primary);
      final InputDecorationThemeData fields = theme.inputDecorationTheme;
      expect((fields.enabledBorder! as OutlineInputBorder).borderSide, ink);
      expect(
        (fields.focusedBorder! as OutlineInputBorder).borderSide,
        BorderSide(color: s.primary, width: SpendthriftTokens.focusLine),
      );
      final ButtonStyle segments = theme.segmentedButtonTheme.style!;
      expect(segments.side!.resolve({}), ink);
      expect(
        segments.backgroundColor!.resolve({WidgetState.selected}),
        s.primary,
      );
      expect(
        segments.foregroundColor!.resolve({WidgetState.selected}),
        s.onPrimary,
      );
    });

    test('the $name snack bar action reaches 4.5:1 on its ink', () {
      expect(
        _contrast(
          theme.snackBarTheme.actionTextColor!,
          theme.snackBarTheme.backgroundColor!,
        ),
        greaterThanOrEqualTo(4.5),
      );
    });
  }

  testWidgets('the floating button prints its pink copy past its corner', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
    final ShapeBorder shape = tester
        .widget<Material>(
          find.descendant(
            of: find.byType(FloatingActionButton),
            matching: find.byType(Material),
          ),
        )
        .shape!;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    shape.paint(canvas, const Rect.fromLTWH(0, 0, 56, 56));
    final ByteData bytes = (await tester.runAsync<ByteData?>(() async {
      final ui.Image image = await recorder.endRecording().toImage(64, 64);
      return image.toByteData();
    }))!;
    int pixel(int x, int y) {
      final int i = (y * 64 + x) * 4;
      return Color.fromARGB(
        bytes.getUint8(i + 3),
        bytes.getUint8(i),
        bytes.getUint8(i + 1),
        bytes.getUint8(i + 2),
      ).toARGB32();
    }

    // Past the button's lower edge, under it: the accent.
    expect(pixel(30, 59), FinanceColors.light.accent.toARGB32());
    // On the button itself: nothing, so the copy never covers it.
    expect(pixel(30, 30), 0);
  });

  test('the floating button keeps its copy through a theme animation', () {
    final ShapeBorder light = AppTheme.light().floatingActionButtonTheme.shape!;
    final ShapeBorder dark = AppTheme.dark().floatingActionButtonTheme.shape!;
    expect(ShapeBorder.lerp(light, dark, 0.5).runtimeType, light.runtimeType);
    expect(
      ThemeData.lerp(
        AppTheme.light(),
        AppTheme.dark(),
        0.5,
      ).floatingActionButtonTheme.shape.runtimeType,
      light.runtimeType,
    );
    // From a plain rounded border (a button given its own shape) the copy grows in.
    final ShapeBorder plain = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SpendthriftTokens.radius),
    );
    expect(ShapeBorder.lerp(plain, light, 0.5).runtimeType, light.runtimeType);
    // copyWith keeps the copy and honours its arguments.
    const BorderSide side = BorderSide(width: 2);
    final OutlinedBorder sided = (light as OutlinedBorder).copyWith(side: side);
    expect(sided.runtimeType, light.runtimeType);
    expect(sided.side, side);
  });

  testWidgets('halfway through a theme animation the copy still prints', (
    tester,
  ) async {
    final ShapeBorder mid = ShapeBorder.lerp(
      AppTheme.light().floatingActionButtonTheme.shape,
      AppTheme.dark().floatingActionButtonTheme.shape,
      0.5,
    )!;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    mid.paint(Canvas(recorder), const Rect.fromLTWH(0, 0, 56, 56));
    final ByteData bytes = (await tester.runAsync<ByteData?>(() async {
      final ui.Image image = await recorder.endRecording().toImage(64, 64);
      return image.toByteData();
    }))!;
    // Past the button's lower edge: opaque.
    expect(bytes.getUint8((59 * 64 + 30) * 4 + 3), 255);
  });
}
