/// The language the app is shown in on this device, chosen in Settings → Appearance →
/// Language in the dev and demo flavors (`app-core.md`, **Localization**): the device's
/// own ([system], the only choice in prod), English, or the pseudo-locale that lengthens
/// and brackets every string so a layout that would cut a translation off shows it.
/// Kept in `app_meta` under `app_language`, never synced.
library;

/// A language choice.
enum AppLanguage {
  /// The device's language, when the app has it, else English.
  system,

  /// English, whatever the device's language.
  english,

  /// The pseudo-locale, `en_XA`.
  pseudo;

  /// The choice stored as [value], [system] when absent or unknown.
  static AppLanguage parse(String? value) => AppLanguage.values.firstWhere(
    (l) => l.name == value,
    orElse: () => AppLanguage.system,
  );
}
