/// The Spendthrift light and dark themes (`docs/reference/design.md`).
///
/// Both are built by hand from the brand's palette ([AppTheme.lightScheme], paper and ink,
/// and [AppTheme.darkScheme], the night print) unless the device supplies dynamic color
/// schemes and the user has dynamic color on, in which case those schemes are used
/// (`FinanceTrackerApp` decides). Each carries the matching [FinanceColors], harmonized
/// with a dynamic scheme's primary color. Surfaces carry no tint.
///
/// The type is Syne for the display and headline styles and `titleLarge` (800 for
/// display, 700 otherwise, tracked at -0.02 em) and Work Sans for everything else, with
/// tabular figures so columns of amounts line up; the sizes are Material 3's. Text scale
/// is never clamped.
library;

import 'package:finance_tracker/core/theme/finance_colors.dart';
import 'package:flutter/material.dart';

/// The app's themes.
abstract final class AppTheme {
  /// The heading face, bundled under `assets/fonts/`.
  static const String headingFont = 'Syne';

  /// The body face, for text, lists and every number.
  static const String bodyFont = 'WorkSans';

  /// Digits of one width, so amounts line up.
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  /// [base] as a money figure: Work Sans 700 with tabular figures, at [base]'s size.
  static TextStyle figure(TextStyle? base) =>
      (base ?? const TextStyle()).copyWith(
        fontFamily: bodyFont,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        fontFeatures: tabularFigures,
      );

  /// The light scheme: ink on paper, blue, pink and yellow inks.
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    surface: Color(0xFFF7F3EA),
    onSurface: Color(0xFF1F1F1F),
    onSurfaceVariant: Color(0xFF5C574C),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF3EEE3),
    surfaceContainer: Color(0xFFEFE9DC),
    surfaceContainerHigh: Color(0xFFE9E2D3),
    surfaceContainerHighest: Color(0xFFE2DAC8),
    primary: Color(0xFF1F4FE0),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD6E0FF),
    onPrimaryContainer: Color(0xFF0E1E60),
    secondary: Color(0xFFFF3EA5),
    onSecondary: Color(0xFF1F1F1F),
    secondaryContainer: Color(0xFFFFD6EC),
    onSecondaryContainer: Color(0xFF4A0A2B),
    tertiary: Color(0xFFF2B705),
    onTertiary: Color(0xFF1F1F1F),
    tertiaryContainer: Color(0xFFFFF0B8),
    onTertiaryContainer: Color(0xFF3A2D00),
    error: Color(0xFFC32237),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD9),
    onErrorContainer: Color(0xFF410006),
    outline: Color(0xFF1F1F1F),
    outlineVariant: Color(0xFFB9B2A3),
    inverseSurface: Color(0xFF1F1F1F),
    onInverseSurface: Color(0xFFF7F3EA),
    inversePrimary: Color(0xFF8FA8FF),
    surfaceTint: Colors.transparent,
  );

  /// The dark scheme, the night print: light ink on night paper.
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    surface: Color(0xFF16151C),
    onSurface: Color(0xFFF1ECE1),
    onSurfaceVariant: Color(0xFFB5AFA3),
    surfaceContainerLowest: Color(0xFF0F0E13),
    surfaceContainerLow: Color(0xFF1B1A21),
    surfaceContainer: Color(0xFF1F1E27),
    surfaceContainerHigh: Color(0xFF27262F),
    surfaceContainerHighest: Color(0xFF302F39),
    primary: Color(0xFF8FA8FF),
    onPrimary: Color(0xFF0E1230),
    primaryContainer: Color(0xFF2A3F8F),
    onPrimaryContainer: Color(0xFFE0E7FF),
    secondary: Color(0xFFFF7AC3),
    onSecondary: Color(0xFF2A0A1C),
    secondaryContainer: Color(0xFF6E1F4A),
    onSecondaryContainer: Color(0xFFFFDCEE),
    tertiary: Color(0xFFFFD24D),
    onTertiary: Color(0xFF2A2000),
    tertiaryContainer: Color(0xFF5E4A00),
    onTertiaryContainer: Color(0xFFFFF0B8),
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF3A0000),
    errorContainer: Color(0xFF7A1C1C),
    onErrorContainer: Color(0xFFFFDAD9),
    // The ink line identifies a field: 3:1 against the surfaces it sits on.
    outline: Color(0xFF73727F),
    outlineVariant: Color(0xFF3A3944),
    inverseSurface: Color(0xFFF1ECE1),
    onInverseSurface: Color(0xFF16151C),
    inversePrimary: Color(0xFF1F4FE0),
    surfaceTint: Colors.transparent,
  );

  /// The light theme, from [dynamicScheme] when given, else from [lightScheme].
  static ThemeData light([ColorScheme? dynamicScheme]) =>
      _theme(dynamicScheme ?? lightScheme, switch (dynamicScheme) {
        final ColorScheme scheme => FinanceColors.light.harmonized(
          scheme.primary,
        ),
        null => FinanceColors.light,
      });

  /// The dark theme, from [dynamicScheme] when given, else from [darkScheme].
  static ThemeData dark([ColorScheme? dynamicScheme]) => _theme(
    dynamicScheme ?? darkScheme,
    switch (dynamicScheme) {
      final ColorScheme scheme => FinanceColors.dark.harmonized(scheme.primary),
      null => FinanceColors.dark,
    },
  );

  static ThemeData _theme(ColorScheme scheme, FinanceColors finance) {
    final ThemeData base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: bodyFont,
      extensions: [finance],
    );
    return base.copyWith(textTheme: _textTheme(base.textTheme));
  }

  /// [t], Material 3's scale in Work Sans, with the headings in Syne and tabular figures
  /// in the rest.
  static TextTheme _textTheme(TextTheme t) {
    // The theme's text styles carry no sizes: `Theme` merges in the script's geometry,
    // whose sizes for English are Material 3's.
    final TextTheme geometry = Typography.material2021().englishLike;
    TextStyle heading(TextStyle? style, TextStyle? sized, FontWeight weight) =>
        style!.copyWith(
          fontFamily: headingFont,
          fontWeight: weight,
          letterSpacing: -0.02 * sized!.fontSize!,
        );
    TextStyle body(TextStyle? style) =>
        style!.copyWith(fontFeatures: tabularFigures);
    return t.copyWith(
      displayLarge: heading(
        t.displayLarge,
        geometry.displayLarge,
        FontWeight.w800,
      ),
      displayMedium: heading(
        t.displayMedium,
        geometry.displayMedium,
        FontWeight.w800,
      ),
      displaySmall: heading(
        t.displaySmall,
        geometry.displaySmall,
        FontWeight.w800,
      ),
      headlineLarge: heading(
        t.headlineLarge,
        geometry.headlineLarge,
        FontWeight.w700,
      ),
      headlineMedium: heading(
        t.headlineMedium,
        geometry.headlineMedium,
        FontWeight.w700,
      ),
      headlineSmall: heading(
        t.headlineSmall,
        geometry.headlineSmall,
        FontWeight.w700,
      ),
      titleLarge: heading(t.titleLarge, geometry.titleLarge, FontWeight.w700),
      titleMedium: body(t.titleMedium),
      titleSmall: body(t.titleSmall),
      bodyLarge: body(t.bodyLarge),
      bodyMedium: body(t.bodyMedium),
      bodySmall: body(t.bodySmall),
      labelLarge: body(t.labelLarge),
      labelMedium: body(t.labelMedium),
      labelSmall: body(t.labelSmall),
    );
  }
}
