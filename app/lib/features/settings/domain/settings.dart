/// The user's app preferences: the theme mode and whether to use the device's dynamic
/// colors. Pure Dart, no Flutter import; the presentation layer maps [AppThemeMode] onto
/// Flutter's `ThemeMode`.
library;

/// Which brightness the app uses.
enum AppThemeMode {
  /// Follow the device's light or dark setting.
  system,

  /// Always light.
  light,

  /// Always dark.
  dark,
}

/// An immutable snapshot of the app preferences.
final class Settings {
  /// Settings with every field given.
  const Settings({required this.themeMode, required this.useDynamicColor});

  /// The settings of a fresh install: follow the system theme, use dynamic color.
  const Settings.defaults()
    : themeMode = AppThemeMode.system,
      useDynamicColor = true;

  final AppThemeMode themeMode;

  /// Whether the app takes its colors from the device (Android 12 and later) when the
  /// device provides them; the seed palette is used otherwise.
  final bool useDynamicColor;

  /// A copy with the given fields replaced.
  Settings copyWith({AppThemeMode? themeMode, bool? useDynamicColor}) =>
      Settings(
        themeMode: themeMode ?? this.themeMode,
        useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      );

  @override
  bool operator ==(Object other) =>
      other is Settings &&
      other.themeMode == themeMode &&
      other.useDynamicColor == useDynamicColor;

  @override
  int get hashCode => Object.hash(themeMode, useDynamicColor);

  @override
  String toString() =>
      'Settings(themeMode: ${themeMode.name}, useDynamicColor: $useDynamicColor)';
}
