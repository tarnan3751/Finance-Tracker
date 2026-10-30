/// The Material 3 light and dark themes.
///
/// Both come from the baseline purple seed (the legacy app was purple) unless the device
/// supplies dynamic color schemes and the user has dynamic color on, in which case those
/// schemes are used (`FinanceTrackerApp` decides). Each carries the matching
/// [FinanceColors] for inflows and outflows, harmonized with a dynamic scheme's primary
/// color. Text scale is never clamped.
library;

import 'package:finance_tracker/core/theme/finance_colors.dart';
import 'package:flutter/material.dart';

/// The app's themes.
abstract final class AppTheme {
  /// The Material 3 baseline purple, the seed of the default schemes.
  static const Color seed = Color(0xFF6750A4);

  /// The light theme, from [dynamicScheme] when given, else from [seed].
  static ThemeData light([ColorScheme? dynamicScheme]) => _theme(
    dynamicScheme ?? ColorScheme.fromSeed(seedColor: seed),
    switch (dynamicScheme) {
      final ColorScheme scheme => FinanceColors.light.harmonized(
        scheme.primary,
      ),
      null => FinanceColors.light,
    },
  );

  /// The dark theme, from [dynamicScheme] when given, else from [seed].
  static ThemeData dark([ColorScheme? dynamicScheme]) => _theme(
    dynamicScheme ??
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
    switch (dynamicScheme) {
      final ColorScheme scheme => FinanceColors.dark.harmonized(scheme.primary),
      null => FinanceColors.dark,
    },
  );

  static ThemeData _theme(ColorScheme scheme, FinanceColors finance) =>
      ThemeData(colorScheme: scheme, useMaterial3: true, extensions: [finance]);
}
