// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navAccounts => 'Accounts';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navSettings => 'Settings';

  @override
  String get accountsEmptyHeadline => 'No accounts yet';

  @override
  String get accountsEmptyBody =>
      'Accounts you add or connect will appear here.';

  @override
  String get transactionsEmptyHeadline => 'No transactions yet';

  @override
  String get transactionsEmptyBody =>
      'Transactions you add or sync will appear here.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeMode => 'Theme';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get settingsDynamicColor => 'Dynamic color';

  @override
  String get settingsDynamicColorSubtitle =>
      'Use colors from your wallpaper when the device provides them';

  @override
  String get settingsAbout => 'About';

  @override
  String get aboutAppName => 'App';

  @override
  String get aboutVersion => 'Version';

  @override
  String aboutVersionValue(String version, String buildNumber) {
    return '$version (build $buildNumber)';
  }

  @override
  String get aboutFlavor => 'Flavor';

  @override
  String get aboutTimeZone => 'Time zone';
}
