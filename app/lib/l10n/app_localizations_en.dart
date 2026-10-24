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

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get settingsData => 'Data';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesSearch => 'Search categories';

  @override
  String get categoryAdd => 'Add category';

  @override
  String get categorySystem => 'Built-in category';

  @override
  String categoryExpand(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count categories under $name',
      one: 'Show 1 category under $name',
    );
    return '$_temp0';
  }

  @override
  String categoryCollapse(String name) {
    return 'Hide the categories under $name';
  }

  @override
  String get categoryNotFound => 'This category no longer exists.';

  @override
  String get categoryNewTitle => 'New category';

  @override
  String get categoryEditTitle => 'Edit category';

  @override
  String get categoryName => 'Name';

  @override
  String get categoryNameRequired => 'Enter a name';

  @override
  String get categoryParent => 'Under';

  @override
  String get categoryParentNone => 'Nothing (top level)';

  @override
  String get categoryIcon => 'Icon';

  @override
  String get categoryColor => 'Color';

  @override
  String get categorySystemNote =>
      'A built-in category: only its icon and color can change.';

  @override
  String get categorySystemReadOnly =>
      'Built-in categories can only change their icon and color.';

  @override
  String categoryDeleteTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String categoryDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions will become uncategorized.',
      one: '1 transaction will become uncategorized.',
      zero: 'No transactions use it.',
    );
    return '$_temp0';
  }

  @override
  String categoryDeleteWithChildrenBody(int children, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      children,
      locale: localeName,
      other: 'The $children categories under it go too.',
      one: 'The 1 category under it goes too.',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions will become uncategorized.',
      one: '1 transaction will become uncategorized.',
      zero: 'No transactions use them.',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String get categoryIconPayments => 'Payments';

  @override
  String get categoryIconAccountBalance => 'Bank';

  @override
  String get categoryIconCreditScore => 'Credit score';

  @override
  String get categoryIconCallReceived => 'Money in';

  @override
  String get categoryIconCallMade => 'Money out';

  @override
  String get categoryIconReceiptLong => 'Receipt';

  @override
  String get categoryIconMovie => 'Movie';

  @override
  String get categoryIconRestaurant => 'Restaurant';

  @override
  String get categoryIconShoppingBag => 'Shopping bag';

  @override
  String get categoryIconHomeRepairService => 'Toolbox';

  @override
  String get categoryIconMedicalServices => 'Medical';

  @override
  String get categoryIconSpa => 'Spa';

  @override
  String get categoryIconBuild => 'Wrench';

  @override
  String get categoryIconVolunteerActivism => 'Charity';

  @override
  String get categoryIconDirectionsCar => 'Car';

  @override
  String get categoryIconFlight => 'Plane';

  @override
  String get categoryIconHouse => 'House';

  @override
  String get categoryIconCategory => 'Shapes';

  @override
  String get categoryIconLocalGroceryStore => 'Groceries';

  @override
  String get categoryIconLocalCafe => 'Coffee';

  @override
  String get categoryIconLocalBar => 'Bar';

  @override
  String get categoryIconFastfood => 'Fast food';

  @override
  String get categoryIconLocalGasStation => 'Fuel';

  @override
  String get categoryIconDirectionsBus => 'Bus';

  @override
  String get categoryIconTrain => 'Train';

  @override
  String get categoryIconSchool => 'School';

  @override
  String get categoryIconChildCare => 'Child care';

  @override
  String get categoryIconPets => 'Pets';

  @override
  String get categoryIconFitnessCenter => 'Fitness';

  @override
  String get categoryIconSportsEsports => 'Games';

  @override
  String get categoryIconMusicNote => 'Music';

  @override
  String get categoryIconMenuBook => 'Books';

  @override
  String get categoryIconPhoneIphone => 'Phone';

  @override
  String get categoryIconWifi => 'Internet';

  @override
  String get categoryIconBolt => 'Electricity';

  @override
  String get categoryIconWaterDrop => 'Water';

  @override
  String get categoryIconSavings => 'Savings';

  @override
  String get categoryIconCardGiftcard => 'Gift';

  @override
  String get categoryIconCheckroom => 'Clothing';

  @override
  String get categoryIconCelebration => 'Celebration';

  @override
  String get colorRed => 'Red';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorViolet => 'Violet';

  @override
  String get colorIndigo => 'Indigo';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorCyan => 'Cyan';

  @override
  String get colorTeal => 'Teal';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorBrown => 'Brown';

  @override
  String get colorGrey => 'Grey';
}
