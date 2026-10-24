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

  @override
  String get databaseErrorTitle => 'Your data can\'t be opened';

  @override
  String get databaseErrorBody =>
      'Finance Tracker could not open its data on this device. Nothing has been deleted. Close the app and open it again; if this keeps happening, your data cannot be read on this device.';

  @override
  String get databaseErrorKeyLost =>
      'The key that unlocks your data on this device is missing or unreadable, so your data cannot be opened. Nothing has been deleted.';

  @override
  String get databaseErrorKeyMismatch =>
      'Your data on this device does not open with its key. Nothing has been deleted.';

  @override
  String get databaseErrorNoEncryption =>
      'This version of Finance Tracker cannot encrypt data, so it will not open yours. Nothing has been deleted.';
}
