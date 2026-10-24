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
  String get edit => 'Edit';

  @override
  String get undo => 'Undo';

  @override
  String get loadFailed =>
      'Something went wrong loading this. Try again later.';

  @override
  String captionPair(String first, String second) {
    return '$first · $second';
  }

  @override
  String amountNegative(String amount) {
    return 'minus $amount';
  }

  @override
  String get balanceFromTransactions => 'from transactions';

  @override
  String runningBalance(String amount) {
    return 'Running balance $amount';
  }

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get accountAdd => 'Add account';

  @override
  String get accountsTotals => 'Totals';

  @override
  String accountsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hidden accounts',
      one: '1 hidden account',
    );
    return '$_temp0';
  }

  @override
  String get accountNotFound => 'This account no longer exists.';

  @override
  String get accountNoTransactions => 'No transactions on this account yet.';

  @override
  String get accountHide => 'Hide account';

  @override
  String get accountShow => 'Show account';

  @override
  String get accountHiddenLabel => 'Hidden';

  @override
  String accountDeleteTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String accountDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The account and its $count transactions will be deleted.',
      one: 'The account and its 1 transaction will be deleted.',
      zero: 'The account will be deleted.',
    );
    return '$_temp0';
  }

  @override
  String get accountNewTitle => 'New account';

  @override
  String get accountEditTitle => 'Edit account';

  @override
  String get accountName => 'Name';

  @override
  String get accountNameRequired => 'Enter a name';

  @override
  String get accountType => 'Type';

  @override
  String get accountTypeDepository => 'Checking or savings';

  @override
  String get accountTypeCredit => 'Credit card';

  @override
  String get accountTypeLoan => 'Loan';

  @override
  String get accountTypeInvestment => 'Investment';

  @override
  String get accountTypeOther => 'Other';

  @override
  String get accountCurrency => 'Currency';

  @override
  String currencyValue(String code, String symbol) {
    return '$code ($symbol)';
  }

  @override
  String accountCurrencyFixed(String currency) {
    return '$currency. It can\'t change once the account has transactions.';
  }

  @override
  String get accountCurrencyLocked =>
      'The currency can\'t change: this account has transactions.';

  @override
  String get accountDeleted => 'This account was deleted.';

  @override
  String get openingBalance => 'Opening balance (optional)';

  @override
  String get openingBalanceHelper =>
      'Negative for money owed. Saved as a transaction.';

  @override
  String get openingBalanceDate => 'Opening balance date';

  @override
  String get openingBalanceName => 'Opening balance';

  @override
  String get currencyPickerTitle => 'Currency';

  @override
  String get currencyPickerSearch => 'Search currencies';

  @override
  String get amountRequired => 'Enter an amount';

  @override
  String amountInvalid(String example) {
    return 'Enter an amount such as $example';
  }

  @override
  String get amountUnsigned => 'Enter the amount without a sign';

  @override
  String get transactionAdd => 'Add transaction';

  @override
  String get transactionPending => 'Pending';

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String get transactionsSearch => 'Search';

  @override
  String get transactionsSearchHint => 'Search transactions';

  @override
  String get transactionsSearchClose => 'Close search';

  @override
  String get transactionsFilter => 'Filters';

  @override
  String get transactionsNoMatchHeadline => 'No matching transactions';

  @override
  String get transactionsNoMatchBody => 'Try other words or remove a filter.';

  @override
  String filterRemove(String label) {
    return 'Remove filter $label';
  }

  @override
  String get filterClear => 'Clear';

  @override
  String get filterApply => 'Apply';

  @override
  String get filterCategories => 'Categories';

  @override
  String get filterAddCategory => 'Add category';

  @override
  String get filterDate => 'Date';

  @override
  String get filterAmount => 'Amount';

  @override
  String get filterAmountMin => 'At least';

  @override
  String get filterAmountMax => 'At most';

  @override
  String get filterTags => 'Tags';

  @override
  String get filterNoTags => 'No tags yet.';

  @override
  String get datePresetAny => 'Any time';

  @override
  String get datePresetThisMonth => 'This month';

  @override
  String get datePresetLastMonth => 'Last month';

  @override
  String get datePresetLast90Days => 'Last 90 days';

  @override
  String get datePresetThisYear => 'This year';

  @override
  String get datePresetCustom => 'Custom…';

  @override
  String dateRangeValue(String start, String end) {
    return '$start – $end';
  }

  @override
  String amountRangeBetween(String min, String max) {
    return '$min – $max';
  }

  @override
  String amountRangeAtLeast(String min) {
    return 'At least $min';
  }

  @override
  String amountRangeAtMost(String max) {
    return 'At most $max';
  }

  @override
  String get amountRangeInverted => 'At most must not be less than at least';

  @override
  String tagLabel(String tag) {
    return '#$tag';
  }

  @override
  String tagRemove(String tag) {
    return 'Remove tag $tag';
  }

  @override
  String tagAdd(String tag) {
    return 'Add tag $tag';
  }

  @override
  String get transactionNewTitle => 'New transaction';

  @override
  String get transactionTitle => 'Transaction';

  @override
  String get transactionNotFound => 'This transaction no longer exists.';

  @override
  String get transactionNeedsAccountHeadline => 'Add an account first';

  @override
  String get transactionNeedsAccountBody =>
      'Every transaction belongs to an account.';

  @override
  String get transactionExpense => 'Expense';

  @override
  String get transactionIncome => 'Income';

  @override
  String get transactionAmount => 'Amount';

  @override
  String get transactionAccount => 'Account';

  @override
  String get transactionDate => 'Date';

  @override
  String get transactionDescription => 'Description';

  @override
  String get transactionDescriptionRequired => 'Enter a description';

  @override
  String get transactionCategory => 'Category';

  @override
  String get transactionCategoryFromBank => 'From your bank\'s category';

  @override
  String get transactionNotes => 'Notes';

  @override
  String get transactionTags => 'Tags';

  @override
  String get transactionTagsHelper =>
      'Press enter or type a comma to add a tag';

  @override
  String get transactionCurrencyMismatch =>
      'The amount must be in the account\'s currency.';

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String get transactionRestoreNoAccount =>
      'The transaction can\'t come back: its account was deleted.';

  @override
  String get settingsData => 'Data';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesSearch => 'Search categories';

  @override
  String get categoriesManage => 'Manage';

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
  String get categoryPickerTitle => 'Category';

  @override
  String get categoryPickerRecent => 'Recently used';

  @override
  String get categoryPickerAll => 'All categories';

  @override
  String get categoryNone => 'None';

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

  @override
  String legacyImported(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count entries into “Imported”, totalling $total.',
      one: 'Imported 1 entry into “Imported”, totalling $total.',
    );
    return '$_temp0';
  }

  @override
  String legacyImportSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries could not be read and were left in place.',
      one: '1 entry could not be read and was left in place.',
    );
    return '$_temp0';
  }

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInSubmit => 'Sign in';

  @override
  String get signInSubmitting => 'Signing in';

  @override
  String get signInCreateAccount => 'Create an account';

  @override
  String get registerTitle => 'Create an account';

  @override
  String get registerSubmit => 'Create account';

  @override
  String get registerSubmitting => 'Creating your account';

  @override
  String get registerHaveAccount => 'I already have an account';

  @override
  String registerDeviceName(String name) {
    return 'This device: $name';
  }

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordHelper => '8 to 128 characters';

  @override
  String get authDisplayNameLabel => 'Name (optional)';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authEmailInvalid => 'Enter a valid email address';

  @override
  String get authPasswordRequired => 'Enter your password';

  @override
  String get authPasswordLength => 'Use 8 to 128 characters';

  @override
  String get authDisplayNameLength => 'Use at most 100 characters';

  @override
  String get authErrorInvalidCredentials =>
      'The email or password is incorrect.';

  @override
  String authErrorRateLimited(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Too many attempts. Try again in $seconds seconds.',
      one: 'Too many attempts. Try again in 1 second.',
    );
    return '$_temp0';
  }

  @override
  String get authErrorRateLimitedLater => 'Too many attempts. Try again later.';

  @override
  String get authErrorEmailTaken =>
      'An account with this email already exists.';

  @override
  String get authErrorNetwork =>
      'Can\'t reach the server. Check your connection and try again.';

  @override
  String get authErrorValidation =>
      'Check the highlighted fields and try again.';

  @override
  String get authErrorOtherAccount =>
      'This device already holds another account\'s data. Sign in with that account, or clear the app\'s storage in Android settings to start over.';

  @override
  String get authErrorGeneric => 'Something went wrong. Try again.';

  @override
  String get settingsAccount => 'Account';

  @override
  String settingsSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsServer => 'Server';

  @override
  String get settingsServerFake => 'In-app fake server';

  @override
  String get settingsSync => 'Sync';

  @override
  String get syncStatus => 'Status';

  @override
  String get syncSignedOut => 'Sign in to sync your data between devices';

  @override
  String get syncRunning => 'Syncing…';

  @override
  String get syncNever => 'Not synced yet';

  @override
  String syncLastAt(String time) {
    return 'Last synced $time';
  }

  @override
  String get syncFailedOffline => 'The last sync could not reach the server';

  @override
  String get syncFailedServer => 'The server could not complete the last sync';

  @override
  String get syncFailedOther => 'The last sync did not finish';

  @override
  String get syncBankData => 'Bank data';

  @override
  String syncBankDataPulledAt(String time) {
    return 'Updated $time';
  }

  @override
  String get syncBankDataNever => 'Not updated yet';

  @override
  String get syncBankDataFailedOffline =>
      'The last update could not reach the server';

  @override
  String get syncBankDataFailedServer =>
      'The server could not complete the last update';

  @override
  String get syncBankDataFailedOther => 'The last update did not finish';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to sync',
      one: '1 change waiting to sync',
      zero: 'Every change is synced',
    );
    return '$_temp0';
  }

  @override
  String get syncClockDrift =>
      'A device\'s clock is far ahead, so some changes wait until it catches up';

  @override
  String syncRejected(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes were refused by the server, the latest made $time',
      one: '1 change was refused by the server, the latest made $time',
    );
    return '$_temp0';
  }

  @override
  String syncHeld(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count synced records this version of the app cannot show yet',
      one: '1 synced record this version of the app cannot show yet',
    );
    return '$_temp0';
  }

  @override
  String get syncNow => 'Sync now';

  @override
  String get settingsDemoData => 'Demo data';

  @override
  String get demoDataNote =>
      'Choosing another household starts the demo over; changes made in the demo are not kept.';

  @override
  String get demoPersonaRenter => 'Renter';

  @override
  String get demoPersonaRenterDetail =>
      'Gig income, subscriptions and a credit card';

  @override
  String get demoPersonaFamily => 'Family';

  @override
  String get demoPersonaFamilyDetail =>
      'Two salaries, a mortgage, car loans and a 401(k)';

  @override
  String get demoPersonaStudent => 'Student';

  @override
  String get demoPersonaStudentDetail =>
      'Student loans, a campus job and help from a parent';

  @override
  String get demoPersonaSmallBusiness => 'Small business owner';

  @override
  String get demoPersonaSmallBusinessDetail =>
      'Business and personal accounts, and quarterly taxes';

  @override
  String get itemsTitle => 'Linked banks';

  @override
  String get itemsLink => 'Link a bank';

  @override
  String get itemsEmptyHeadline => 'No linked banks';

  @override
  String get itemsEmptyBody =>
      'Link a bank to see its accounts and transactions here.';

  @override
  String get itemsStatusConnected => 'Connected';

  @override
  String get itemsStatusNeedsAttention => 'Needs attention';

  @override
  String get itemsStatusError => 'Error';

  @override
  String get itemsStatusUnlinked => 'Unlinked';

  @override
  String itemsStatusLabel(String status) {
    return 'Status: $status';
  }

  @override
  String itemsLastSynced(String time) {
    return 'Last synced $time';
  }

  @override
  String get itemsNeverSynced => 'Not synced yet';

  @override
  String get itemsSyncNow => 'Sync now';

  @override
  String get itemsFix => 'Fix connection';

  @override
  String get itemsUnlink => 'Unlink';

  @override
  String get itemsStepLinking => 'Opening Plaid Link…';

  @override
  String get itemsStepExchanging => 'Connecting your bank…';

  @override
  String get itemsStepSyncing => 'Waiting for your bank\'s data…';

  @override
  String get itemsStepPulling => 'Updating your accounts…';

  @override
  String get itemsStepUnlinking => 'Unlinking…';

  @override
  String get itemsFailedOffline =>
      'Couldn\'t reach the server. Try again when you\'re online.';

  @override
  String get itemsFailedLoginRequired =>
      'Your bank needs you to sign in again. Use Fix connection.';

  @override
  String get itemsFailedRateLimited =>
      'Too many requests. Try again in a minute.';

  @override
  String get itemsFailedNotFound => 'This bank is no longer linked.';

  @override
  String get itemsFailedPlaid =>
      'Plaid couldn\'t complete the request. Try again later.';

  @override
  String get itemsFailedOther => 'Something went wrong. Try again.';

  @override
  String get itemsFailedLink => 'Plaid Link closed with an error.';

  @override
  String get itemsStillPreparing =>
      'Your bank is still preparing your data. Use Sync now in a minute.';

  @override
  String itemsUnlinkTitle(String institution) {
    return 'Unlink $institution?';
  }

  @override
  String get itemsUnlinkKeep => 'Keep history on this device and others';

  @override
  String get itemsUnlinkKeepDetail =>
      'Its accounts and transactions stay on every device, no longer updated.';

  @override
  String get itemsUnlinkDelete => 'Delete its accounts and transactions';

  @override
  String get itemsUnlinkDeleteDetail =>
      'They are removed from this device and every other device signed in to your account. Your own notes and categories on them go too.';

  @override
  String get itemsUnlinkConfirm => 'Unlink';

  @override
  String itemsSyncNowLabel(String institution) {
    return 'Sync now, $institution';
  }

  @override
  String itemsFixLabel(String institution) {
    return 'Fix connection, $institution';
  }

  @override
  String itemsUnlinkLabel(String institution) {
    return 'Unlink, $institution';
  }

  @override
  String get itemsDeleteHistory => 'Delete history';

  @override
  String itemsDeleteHistoryLabel(String institution) {
    return 'Delete history, $institution';
  }

  @override
  String itemsDeleteHistoryTitle(String institution) {
    return 'Delete the history of $institution?';
  }

  @override
  String get itemsDeleteHistoryBody =>
      'Its accounts and transactions are removed from this device and every other device signed in to your account. Your own notes and categories on them go too.';

  @override
  String get itemsDeleteHistoryConfirm => 'Delete';

  @override
  String get itemsStepDeletingHistory => 'Deleting its history…';

  @override
  String get itemsFailedServer =>
      'The server could not complete the request. Try again later.';
}
