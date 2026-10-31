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
  String get navPlan => 'Plan';

  @override
  String get planBudgets => 'Budgets';

  @override
  String get planBills => 'Bills';

  @override
  String get planForecast => 'Forecast';

  @override
  String get navInsights => 'Insights';

  @override
  String get insightsReports => 'Reports';

  @override
  String get insightsNetWorth => 'Net worth';

  @override
  String get insightsInvestments => 'Investments';

  @override
  String get insightsGoals => 'Goals';

  @override
  String get insightsComingHeadline => 'Coming soon';

  @override
  String get insightsComingBody => 'This part of Insights is on its way.';

  @override
  String reportsPercent(int percent) {
    return '$percent %';
  }

  @override
  String reportsPercentUp(int percent) {
    return '+$percent %';
  }

  @override
  String reportsChange(String amount, String percent) {
    return '$amount ($percent)';
  }

  @override
  String reportsChangeNew(String amount) {
    return '$amount (new)';
  }

  @override
  String get reportsShowTables => 'Tables';

  @override
  String get reportsShowCharts => 'Charts';

  @override
  String get reportsSpending => 'Spending';

  @override
  String get reportsIncome => 'Income';

  @override
  String reportsSpendingAmount(String amount) {
    return 'Spent $amount';
  }

  @override
  String reportsIncomeAmount(String amount) {
    return 'Income $amount';
  }

  @override
  String reportsNetAmount(String amount) {
    return 'Net $amount';
  }

  @override
  String get reportsNoIncome => 'No income in this period';

  @override
  String reportsSavingsRate(String percent) {
    return 'Kept $percent of income';
  }

  @override
  String get reportsVsPrevious => 'Against the period before';

  @override
  String get reportsVsYearAgo => 'Against a year before';

  @override
  String reportsSpendingChange(String change) {
    return 'Spending $change';
  }

  @override
  String reportsIncomeChange(String change) {
    return 'Income $change';
  }

  @override
  String reportsSameElapsed(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: 'day',
    );
    return 'Compared over the first $_temp0 of each period';
  }

  @override
  String get reportsByCategory => 'By category';

  @override
  String get reportsAllCategories => 'All categories';

  @override
  String reportsGroupOwn(String name) {
    return '$name itself';
  }

  @override
  String get reportsNothingInPeriod => 'Nothing in this period.';

  @override
  String reportsDonutSummary(
    String scope,
    String total,
    String name,
    String amount,
  ) {
    return '$scope by category: $total in all. The largest is $name, $amount.';
  }

  @override
  String reportsCategoryRow(String name, String amount, String share) {
    return '$name: $amount, $share of the total';
  }

  @override
  String get reportsIncomeAndSpending => 'Income and spending';

  @override
  String reportsBarsSummary(int count, String income, String spending) {
    return 'Income and spending over the last $count periods. This period: income $income, spending $spending.';
  }

  @override
  String reportsTrend(int count) {
    return 'Trend over $count periods';
  }

  @override
  String reportsTrendSummary(
    int count,
    String fromSpending,
    String toSpending,
    String fromIncome,
    String toIncome,
  ) {
    return 'Over the last $count periods, spending went from $fromSpending to $toSpending and income from $fromIncome to $toIncome.';
  }

  @override
  String reportsPeriodRow(
    String period,
    String income,
    String spending,
    String net,
  ) {
    return '$period: income $income, spending $spending, net $net';
  }

  @override
  String get reportsTopMerchants => 'Top merchants';

  @override
  String reportsMerchantCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count purchases',
      one: '1 purchase',
    );
    return '$_temp0';
  }

  @override
  String get reportsTopMovers => 'Top movers';

  @override
  String get reportsMoversCategories => 'Categories';

  @override
  String get reportsMoversMerchants => 'Merchants';

  @override
  String get reportsNoMovers => 'Nothing changed from the period before.';

  @override
  String reportsMoverAmounts(String before, String now) {
    return '$before before, $now now';
  }

  @override
  String get anomaliesTitle => 'Worth a look';

  @override
  String get anomaliesNone => 'Nothing stands out in this period.';

  @override
  String anomalyUsualMerchant(String amount) {
    return 'Usually about $amount here';
  }

  @override
  String anomalyUsualCategory(String amount) {
    return 'Usually about $amount in this category';
  }

  @override
  String get anomalyNewMerchant => 'New: not seen in the last six months';

  @override
  String get anomalyDismissed =>
      'Dismissed. It won\'t be flagged again on this device.';

  @override
  String anomalyDismissTooltip(String name) {
    return 'Dismiss $name';
  }

  @override
  String get reportsWeeklySummary => 'Weekly summary';

  @override
  String get weeklyTitle => 'Weekly summary';

  @override
  String weeklyRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String weeklyLastWeek(String range) {
    return 'Last week, $range';
  }

  @override
  String get weeklyThisWeek => 'This week so far';

  @override
  String get weeklyTopCategories => 'Spent most on';

  @override
  String weeklyCategoryLine(String name, String amount) {
    return '$name: $amount';
  }

  @override
  String weeklyTopMerchant(String name, String amount) {
    return 'Spent most at $name: $amount';
  }

  @override
  String get weeklyNoSpending => 'No spending this week.';

  @override
  String get weeklyBillsNextWeek => 'Bills due next week';

  @override
  String get weeklyNoBills => 'No bills due next week.';

  @override
  String get weeklyBudgets => 'Budgets';

  @override
  String get weeklyNoBudgets => 'No budgets yet.';

  @override
  String weeklyBudgetLeft(String spent, String available, String left) {
    return '$spent of $available spent, $left left';
  }

  @override
  String weeklyBudgetOver(String spent, String available, String over) {
    return '$spent of $available spent, over by $over';
  }

  @override
  String get alertWeeklySummary => 'Your weekly summary is ready';

  @override
  String get navSettings => 'Settings';

  @override
  String get paneAccountsEmpty => 'Choose an account to see it here';

  @override
  String get paneTransactionsEmpty => 'Choose a transaction to see it here';

  @override
  String get paneBillsEmpty => 'Choose a bill to edit it here';

  @override
  String get paneSettingsEmpty => 'Choose a setting to open it here';

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
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle =>
      'Pseudo lengthens and brackets every string, to find text that would not fit a translation';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePseudo => 'Pseudo';

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
  String sentencePair(String first, String second) {
    return '$first $second';
  }

  @override
  String listPair(String first, String second) {
    return '$first, $second';
  }

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
  String runningBalanceFromReported(String amount) {
    return 'Running balance $amount, from the reported balance';
  }

  @override
  String get balanceReported => 'reported';

  @override
  String balanceReportedBy(String institution) {
    return 'reported by $institution';
  }

  @override
  String get balanceReportedByBank => 'reported by your bank';

  @override
  String balanceAsOf(String time) {
    return 'as of $time';
  }

  @override
  String get balanceReportedAndFromTransactions =>
      'reported and from transactions';

  @override
  String accountAvailableBalance(String amount) {
    return 'Available $amount';
  }

  @override
  String accountCreditLimit(String amount) {
    return 'Credit limit $amount';
  }

  @override
  String accountMask(String mask) {
    return '•••• $mask';
  }

  @override
  String accountMaskSemantics(String mask) {
    return 'ending in $mask';
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
  String transactionsNoMatchText(String text) {
    return 'No matches for “$text”';
  }

  @override
  String get transactionsNoMatchBody => 'Try other words or remove a filter.';

  @override
  String filterRemove(String label) {
    return 'Remove filter $label';
  }

  @override
  String get filterClear => 'Clear';

  @override
  String get filterSaved => 'Saved';

  @override
  String get filterSaveThese => 'Save these filters';

  @override
  String get savedFilterSaveTitle => 'Save filters';

  @override
  String get savedFilterNameLabel => 'Name';

  @override
  String get savedFilterRenameTitle => 'Rename saved filter';

  @override
  String get savedFilterRename => 'Rename';

  @override
  String savedFilterOptions(String name) {
    return 'Options for $name';
  }

  @override
  String savedFilterDeleteTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get savedFilterDeleteBody =>
      'Only the saved filter goes; no transaction changes.';

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
  String get settingsSecurity => 'Security';

  @override
  String get lockRequireUnlock => 'Require unlock';

  @override
  String get lockRequireUnlockSubtitle =>
      'Ask for your fingerprint, face or screen lock when the app opens';

  @override
  String get lockAfterTitle => 'Lock after';

  @override
  String get lockAfterOff => 'Only when the app starts';

  @override
  String get lockAfterImmediately => 'Immediately';

  @override
  String get lockBlockScreenshots => 'Block screenshots';

  @override
  String get lockBlockScreenshotsSubtitle =>
      'Hide the app in screenshots, recordings and recent apps. Always on while unlock is required';

  @override
  String get lockUnlock => 'Unlock';

  @override
  String get lockTryAgain => 'Try again';

  @override
  String get lockPromptReason => 'Unlock to see your finances';

  @override
  String get lockEnablePromptReason =>
      'Confirm it\'s you to turn on the app lock';

  @override
  String get lockFailed => 'Not recognized. Try again.';

  @override
  String get lockCancelled => 'Unlock was cancelled.';

  @override
  String get lockNoScreenLock => 'Set a screen lock on this device first';

  @override
  String get lockLockedOut =>
      'Too many attempts. Wait a moment, then try again.';

  @override
  String get lockUnavailable =>
      'The device could not check it\'s you. Try again.';

  @override
  String lockAfterMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

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
      'This device already holds another account\'s data. Sign in with that account, or erase this device\'s data to start over.';

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
      'Check your device\'s clock: it is ahead, so some changes wait to sync';

  @override
  String get syncClockBehind =>
      'Check your device\'s clock: it is behind, so changes made here may be overridden';

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
  String get settingsDeveloper => 'Developer';

  @override
  String get developerDevice => 'Device';

  @override
  String get developerDeviceNone => 'Not signed in';

  @override
  String get developerLastSync => 'Last sync';

  @override
  String get developerBankData => 'Bank data pulled';

  @override
  String get developerNever => 'Never';

  @override
  String get developerLedger => 'Outbox';

  @override
  String developerLedgerValue(int pending, int held) {
    return '$pending waiting, $held held';
  }

  @override
  String get developerLedgerUnknown => 'Not read yet';

  @override
  String get developerPullNow => 'Pull now';

  @override
  String developerPulled(String time) {
    return 'Pulled; bank data updated $time';
  }

  @override
  String developerPullFailed(String error) {
    return 'Pull failed: $error';
  }

  @override
  String get developerCopy => 'Copy diagnostics';

  @override
  String get developerCopied => 'Diagnostics copied';

  @override
  String get developerOpenSandbox => 'Sandbox controls';

  @override
  String get developerOpenSandboxDetail =>
      'Refresh, reset login, webhooks, injected transactions, persona provisioning';

  @override
  String get developerItemSection => 'Item';

  @override
  String get developerItem => 'Item';

  @override
  String developerItemOption(String institution, String id) {
    return '$institution ($id)';
  }

  @override
  String get developerNoItems =>
      'No linked banks yet. Link one, or pull, first.';

  @override
  String get developerRefreshTransactions => 'Refresh transactions';

  @override
  String get developerRefreshBalances => 'Refresh balances';

  @override
  String get developerResetLogin => 'Reset login';

  @override
  String get developerWebhookCode => 'Webhook code';

  @override
  String get developerFireWebhook => 'Fire webhook';

  @override
  String get developerRunning => 'Running…';

  @override
  String developerRefreshed(
    String status,
    int added,
    int modified,
    int removed,
  ) {
    return 'Refresh $status: $added added, $modified modified, $removed removed';
  }

  @override
  String developerBalancesRefreshed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Balances refreshed for $count accounts',
      one: 'Balances refreshed for 1 account',
    );
    return '$_temp0';
  }

  @override
  String get developerLoginReset =>
      'Login reset; the Item needs its connection fixed';

  @override
  String get developerWebhookFired => 'Webhook fired';

  @override
  String developerInjected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Injected $count transactions',
      one: 'Injected 1 transaction',
    );
    return '$_temp0';
  }

  @override
  String developerFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String developerThenPullFailed(String result, String error) {
    return '$result; the pull after it failed: $error';
  }

  @override
  String get developerInjectSection => 'Inject transactions';

  @override
  String get developerAccount => 'Account';

  @override
  String get developerNoAccounts =>
      'This Item has no accounts on the device yet.';

  @override
  String get developerCount => 'How many (1 to 10)';

  @override
  String get developerCountInvalid => 'Enter a whole number from 1 to 10';

  @override
  String get developerDescription => 'Description';

  @override
  String get developerDescriptionDefault => 'Developer test';

  @override
  String get developerDescriptionInvalid => 'Enter 1 to 196 characters';

  @override
  String get developerAmount => 'Amount';

  @override
  String get developerAmountHelper => 'Negative is money out of the account';

  @override
  String get developerDaysBack => 'Days before Plaid\'s today (0 to 728)';

  @override
  String get developerDaysBackInvalid => 'Enter a whole number from 0 to 728';

  @override
  String developerDate(String date) {
    return 'Dated $date';
  }

  @override
  String get developerInject => 'Inject';

  @override
  String get developerProvisionSection => 'Provision a persona';

  @override
  String get developerPersona => 'Persona';

  @override
  String get developerSeed => 'Seed';

  @override
  String get developerSeedInvalid => 'Enter a whole number of at least 1';

  @override
  String get developerDays => 'Days of history (30 to 730)';

  @override
  String get developerDaysInvalid => 'Enter a whole number from 30 to 730';

  @override
  String get developerProvision => 'Start';

  @override
  String developerJobStatus(String status) {
    return 'Job $status';
  }

  @override
  String developerJobItems(int linked, int total) {
    return 'Items linked: $linked of $total';
  }

  @override
  String developerJobBatches(int sent, int total) {
    return 'Batches sent: $sent of $total';
  }

  @override
  String developerJobSkipped(int count) {
    return 'Transactions skipped: $count';
  }

  @override
  String developerJobError(String error) {
    return 'Error: $error';
  }

  @override
  String get developerJobProgress => 'Provisioning progress';

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

  @override
  String get transactionMoreOptions => 'More options';

  @override
  String get transactionRunRules => 'Run rules on this transaction';

  @override
  String transactionRulesApplied(String name) {
    return 'Applied the rule “$name”. Save to keep it.';
  }

  @override
  String transactionRulesUnchanged(String name) {
    return 'The rule “$name” matches, but has nothing to change.';
  }

  @override
  String get transactionRulesNoMatch => 'No rule matches this transaction.';

  @override
  String get rulesTitle => 'Rules';

  @override
  String get rulesEmptyHeadline => 'No rules yet';

  @override
  String get rulesEmptyBody =>
      'A rule files, tags or renames transactions as they arrive from your bank. Rules are tried from the top; the first one that matches applies.';

  @override
  String get rulesOrderNote =>
      'Rules are tried from the top; the first one that matches a transaction applies. Drag to reorder.';

  @override
  String get ruleAdd => 'Add rule';

  @override
  String get ruleNewTitle => 'New rule';

  @override
  String get ruleEditTitle => 'Edit rule';

  @override
  String get ruleNotFound => 'This rule no longer exists.';

  @override
  String get ruleName => 'Name';

  @override
  String get ruleNameRequired => 'Enter a name';

  @override
  String get ruleConditionsHeader => 'When a transaction matches all of these';

  @override
  String get ruleActionsHeader => 'Then';

  @override
  String get ruleAddCondition => 'Add condition';

  @override
  String get ruleAddAction => 'Add action';

  @override
  String get ruleNeedsCondition => 'A rule needs at least one condition.';

  @override
  String get ruleNeedsAction => 'A rule needs at least one action.';

  @override
  String get ruleRemoveCondition => 'Remove condition';

  @override
  String get ruleRemoveAction => 'Remove action';

  @override
  String get ruleConditionMerchant => 'Merchant or description contains';

  @override
  String get ruleConditionAmount => 'Amount between';

  @override
  String get ruleConditionAccount => 'Account is';

  @override
  String get ruleConditionBankCategory => 'Bank category is';

  @override
  String get ruleText => 'Text';

  @override
  String get ruleTextRequired => 'Enter some text';

  @override
  String get ruleAmountRequired => 'Enter at least one amount';

  @override
  String get ruleAmountOrder => 'The minimum is above the maximum';

  @override
  String get ruleAccountRequired => 'Choose an account';

  @override
  String get ruleCategoryRequired => 'Choose a category';

  @override
  String get ruleActionSetCategory => 'Set the category';

  @override
  String get ruleActionSetCategoryCaption =>
      'Only for transactions without a category of your own.';

  @override
  String get ruleActionAddTag => 'Add a tag';

  @override
  String get ruleTag => 'Tag';

  @override
  String get ruleTagRequired => 'Enter a tag';

  @override
  String get ruleActionRename => 'Rename';

  @override
  String get ruleNewDescription => 'New description';

  @override
  String get ruleNewDescriptionRequired => 'Enter the new description';

  @override
  String get ruleActionRenameCaption =>
      'Renames manual and imported transactions. Bank transactions keep the description your bank sends.';

  @override
  String get ruleActionHide => 'Hide';

  @override
  String get ruleActionHideCaption =>
      'Hidden transactions leave the list, budgets and reports, and still count toward their account\'s balance.';

  @override
  String get ruleChooseCategory => 'Choose a category';

  @override
  String get ruleDeleted => 'Rule deleted';

  @override
  String ruleDeleteNamed(String name) {
    return 'Delete “$name”';
  }

  @override
  String ruleReorderNamed(String name) {
    return 'Drag to reorder “$name”';
  }

  @override
  String ruleConditionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conditions',
      one: '1 condition',
    );
    return '$_temp0';
  }

  @override
  String ruleActionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actions',
      one: '1 action',
    );
    return '$_temp0';
  }

  @override
  String ruleSummary(String conditions, String actions) {
    return '$conditions · $actions';
  }

  @override
  String get ruleReorderFailed => 'The rules could not be reordered.';

  @override
  String get categoriesMoreOptions => 'More options';

  @override
  String get budgetsEmptyHeadline => 'No budgets yet';

  @override
  String get budgetsEmptyBody =>
      'A budget sets how much to spend on a category each month and shows how far along you are.';

  @override
  String get budgetAdd => 'Add budget';

  @override
  String get budgetPeriodPrevious => 'Previous period';

  @override
  String get budgetPeriodNext => 'Next period';

  @override
  String get budgetPeriodCurrent => 'This period';

  @override
  String budgetPeriodsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count periods ago',
      one: 'Last period',
    );
    return '$_temp0';
  }

  @override
  String budgetPeriodsAhead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count periods',
      one: 'Next period',
    );
    return '$_temp0';
  }

  @override
  String budgetPeriodRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String budgetPeriodShown(String period) {
    return 'Showing $period';
  }

  @override
  String get budgetDeletedCategory => 'Deleted category';

  @override
  String budgetGroupIncludes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Includes $count categories',
      one: 'Includes 1 category',
    );
    return '$_temp0';
  }

  @override
  String budgetAmountCarried(String amount, String carry) {
    return '$amount + $carry carried';
  }

  @override
  String budgetAmountDeficit(String amount, String carry) {
    return '$amount − $carry carried';
  }

  @override
  String budgetPercent(int percent) {
    return '$percent %';
  }

  @override
  String get budgetNothingAvailable => 'Nothing available';

  @override
  String budgetSpent(String amount) {
    return '$amount spent';
  }

  @override
  String budgetLeft(String amount) {
    return '$amount left';
  }

  @override
  String budgetOver(String amount) {
    return '$amount over';
  }

  @override
  String budgetOnPace(String amount) {
    return 'On pace: about $amount by the end';
  }

  @override
  String budgetProjectedOver(String amount) {
    return 'Projected over by $amount';
  }

  @override
  String budgetAvailable(String amount) {
    return '$amount available';
  }

  @override
  String budgetThresholdReached(int percent) {
    return '$percent % reached';
  }

  @override
  String budgetProgressSemantics(
    String name,
    int percent,
    String available,
    String remaining,
  ) {
    return '$name: $percent percent of $available spent, $remaining left';
  }

  @override
  String budgetProgressOverSemantics(
    String name,
    int percent,
    String available,
    String over,
  ) {
    return '$name: $percent percent of $available spent, $over over';
  }

  @override
  String budgetProgressNothingSemantics(String name, String spent) {
    return '$name: $spent spent, nothing available';
  }

  @override
  String get budgetNewTitle => 'New budget';

  @override
  String get budgetEditTitle => 'Edit budget';

  @override
  String get budgetNotFound => 'This budget no longer exists.';

  @override
  String get budgetDeleted => 'Budget deleted';

  @override
  String get budgetCategory => 'Category';

  @override
  String get budgetChooseCategory => 'Choose a category';

  @override
  String get budgetCategoryCaption =>
      'A category with categories under it budgets its whole group.';

  @override
  String get budgetAmount => 'Amount per period';

  @override
  String get budgetStartDay => 'Period starts on day';

  @override
  String get budgetStartDayHelper =>
      '1 to 28: each period starts on this day of the month';

  @override
  String get budgetStartDayInvalid => 'Enter a day from 1 to 28';

  @override
  String get budgetRollover => 'Carry over';

  @override
  String get budgetRolloverCaption =>
      'What is left at the end of a period, or overspent, carries into the next.';

  @override
  String get budgetStartDate => 'First period';

  @override
  String get budgetStartDateCaption =>
      'Carry-over counts from this period. It can start earlier, but no later than the current period.';

  @override
  String get budgetTransactionsEmpty => 'Nothing counted in this period';

  @override
  String alertsTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alerts, $count unread',
      one: 'Alerts, 1 unread',
      zero: 'Alerts',
    );
    return '$_temp0';
  }

  @override
  String get alertsTitle => 'Alerts';

  @override
  String get alertsMarkAllRead => 'Mark all read';

  @override
  String get alertsEmpty =>
      'No alerts yet. A budget alerts you when its spending reaches 80 % and 100 %.';

  @override
  String get alertUnread => 'Unread';

  @override
  String alertBudgetThreshold(
    String category,
    int percent,
    String available,
    String date,
  ) {
    return '$category reached $percent % of $available on $date';
  }

  @override
  String get transactionHidden => 'Hidden';

  @override
  String get transactionHiddenOption => 'Hidden';

  @override
  String get transactionSelect => 'Select';

  @override
  String get transactionSplitLabel => 'Split';

  @override
  String transactionSplitAcross(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Split across $count categories',
      one: 'Split across 1 category',
    );
    return '$_temp0';
  }

  @override
  String get splitsTitle => 'Splits';

  @override
  String get splitAdd => 'Add split';

  @override
  String get splitRemove => 'Remove split';

  @override
  String get splitDistribute => 'Distribute evenly';

  @override
  String get splitAmount => 'Split amount';

  @override
  String get splitChooseCategory => 'Choose a category';

  @override
  String get splitCategoryRequired => 'Choose a category for every split';

  @override
  String splitUnallocated(String amount) {
    return 'Unallocated $amount';
  }

  @override
  String splitOverAllocated(String amount) {
    return 'Over by $amount';
  }

  @override
  String splitMustBalance(String amount) {
    return 'Splits must add up to $amount';
  }

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get receiptTakePhoto => 'Take photo';

  @override
  String get receiptChoosePhoto => 'Choose photo';

  @override
  String get receiptReplace => 'Replace';

  @override
  String get receiptReplaceLabel => 'Replace receipt';

  @override
  String get receiptRemove => 'Remove receipt';

  @override
  String get receiptImage => 'Receipt image';

  @override
  String get receiptOpenHint => 'open the receipt full screen';

  @override
  String get receiptMissing => 'Receipt kept on another device';

  @override
  String get receiptNoCamera => 'No camera is available';

  @override
  String get receiptPickFailed => 'That image can\'t be used';

  @override
  String get receiptSaveFailed => 'The receipt could not be saved';

  @override
  String get filterShowHidden => 'Show hidden';

  @override
  String get filterShowHiddenCaption =>
      'Hidden transactions still count toward their account\'s balance.';

  @override
  String get filterIncludingHidden => 'Including hidden';

  @override
  String transactionsSelected(int count) {
    return '$count selected';
  }

  @override
  String get selectionCancel => 'Cancel selection';

  @override
  String get selectAll => 'Select all';

  @override
  String get bulkSetCategory => 'Set category';

  @override
  String get bulkAddTag => 'Add tag';

  @override
  String get bulkTagLabel => 'Tag';

  @override
  String get bulkTagAdd => 'Add';

  @override
  String get bulkHide => 'Hide';

  @override
  String get bulkUnhide => 'Unhide';

  @override
  String bulkCategorySet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Category set on $count transactions',
      one: 'Category set on 1 transaction',
    );
    return '$_temp0';
  }

  @override
  String bulkTagAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tag added to $count transactions',
      one: 'Tag added to 1 transaction',
    );
    return '$_temp0';
  }

  @override
  String bulkHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions hidden',
      one: '1 transaction hidden',
    );
    return '$_temp0';
  }

  @override
  String bulkUnhidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions unhidden',
      one: '1 transaction unhidden',
    );
    return '$_temp0';
  }

  @override
  String bulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions deleted',
      one: '1 transaction deleted',
    );
    return '$_temp0';
  }

  @override
  String bulkDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count transactions?',
      one: 'Delete 1 transaction?',
    );
    return '$_temp0';
  }

  @override
  String get bulkDeleteBody =>
      'They leave every list and their accounts\' balances.';

  @override
  String get bulkFailed =>
      'Nothing changed: the transactions could not be updated.';

  @override
  String get bulkFailedDeleted =>
      'Nothing changed: one of the transactions was deleted meanwhile.';

  @override
  String rulePreviewCount(int changed, int total) {
    final intl.NumberFormat changedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String changedString = changedNumberFormat.format(changed);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Would change $changedString of $totalString transactions',
      one: 'Would change $changedString of 1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get rulePreviewIncomplete =>
      'Finish the conditions and actions to see what this rule would change.';

  @override
  String get rulePreviewChecking => 'Checking your transactions…';

  @override
  String get rulePreviewOpen => 'Preview';

  @override
  String get rulePreviewTitle => 'What this rule would change';

  @override
  String rulePreviewMore(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString more transactions not shown',
      one: '1 more transaction not shown',
    );
    return '$_temp0';
  }

  @override
  String rulePreviewCategory(String before, String after) {
    return 'Category: $before → $after';
  }

  @override
  String rulePreviewTag(String tag) {
    return 'Tag added: $tag';
  }

  @override
  String rulePreviewName(String before, String after) {
    return 'Description: $before → $after';
  }

  @override
  String get rulePreviewHidden => 'Hidden';

  @override
  String get ruleApplyToHistory => 'Apply to existing transactions';

  @override
  String get ruleApplySaveFirst => 'Save the rule first';

  @override
  String ruleApplyTitle(String name) {
    return 'Apply “$name” to existing transactions?';
  }

  @override
  String get ruleApplyBody =>
      'The rule changes the transactions it matches now, as it would new ones. Categories and tags you have set stay as they are.';

  @override
  String get ruleApplyConfirm => 'Apply';

  @override
  String ruleApplied(
    int count,
    int filed,
    int tagged,
    int renamed,
    int hidden,
  ) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat filedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String filedString = filedNumberFormat.format(filed);
    final intl.NumberFormat taggedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String taggedString = taggedNumberFormat.format(tagged);
    final intl.NumberFormat renamedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String renamedString = renamedNumberFormat.format(renamed);
    final intl.NumberFormat hiddenNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hiddenString = hiddenNumberFormat.format(hidden);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$countString transactions changed: $filedString filed, $taggedString tagged, $renamedString renamed, $hiddenString hidden',
      one:
          '1 transaction changed: $filedString filed, $taggedString tagged, $renamedString renamed, $hiddenString hidden',
    );
    return '$_temp0';
  }

  @override
  String get ruleAppliedNone => 'No transactions changed.';

  @override
  String get ruleApplyFailed =>
      'The rule could not be applied. Nothing changed.';

  @override
  String ruleMoreOptions(String name) {
    return 'More options for “$name”';
  }

  @override
  String get ruleEditorMoreOptions => 'More options';

  @override
  String get ruleApplying => 'Applying the rule to your transactions';

  @override
  String get duplicatesTitle => 'Review duplicates';

  @override
  String duplicatesMenuItem(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Review duplicates ($countString)',
      zero: 'Review duplicates',
    );
    return '$_temp0';
  }

  @override
  String transactionsMoreOptions(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'More options, $countString likely duplicates',
      one: 'More options, 1 likely duplicate',
      zero: 'More options',
    );
    return '$_temp0';
  }

  @override
  String duplicatesBadge(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString';
  }

  @override
  String get duplicatesEmptyHeadline => 'No likely duplicates';

  @override
  String get duplicatesEmptyBody =>
      'Two transactions with the same amount within three days, on different accounts or one from your bank and one you entered, show up here for you to check.';

  @override
  String get duplicatesIntro =>
      'Each pair may be one transaction recorded twice. Nothing is merged or deleted: hide the extra one, or mark the pair as not duplicates.';

  @override
  String duplicatesDaysApart(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Same amount, $days days apart',
      one: 'Same amount, 1 day apart',
      zero: 'Same amount, same day',
    );
    return '$_temp0';
  }

  @override
  String get duplicateHide => 'Hide this one';

  @override
  String duplicateHideNamed(String name) {
    return 'Hide this one: $name';
  }

  @override
  String get duplicateNotDuplicates => 'Not duplicates';

  @override
  String get duplicateDismissed => 'Marked as not duplicates';

  @override
  String get duplicateHidden => 'Transaction hidden';

  @override
  String get duplicateHideFailed => 'The transaction could not be hidden.';

  @override
  String get billRemindersChannelName => 'Bill reminders';

  @override
  String get billRemindersChannelDescription =>
      'Reminders before your bills are due';

  @override
  String get billUnnamed => 'Bill';

  @override
  String billReminderTitleToday(String name) {
    return '$name is due today';
  }

  @override
  String billReminderTitleTomorrow(String name) {
    return '$name is due tomorrow';
  }

  @override
  String billReminderTitleOn(String name, String date) {
    return '$name is due $date';
  }

  @override
  String billReminderBody(String amount) {
    return 'Expected $amount';
  }

  @override
  String get billReminderBodyNoAmount => 'Open the bill to mark it paid';

  @override
  String alertBillDue(String name, String date) {
    return '$name is due $date';
  }

  @override
  String get billNew => 'New bill';

  @override
  String get billNoNextDue => 'No upcoming due date';

  @override
  String get billStatePaid => 'Paid';

  @override
  String get billStateMissed => 'Missed';

  @override
  String get billNotFound => 'This bill no longer exists.';

  @override
  String get billNewTitle => 'New bill';

  @override
  String get billEditTitle => 'Edit bill';

  @override
  String get billDeleted => 'Bill deleted';

  @override
  String get billName => 'Name';

  @override
  String get billNameRequired => 'Enter a name';

  @override
  String get billAmount => 'Expected amount';

  @override
  String get billAmountHelper =>
      'Optional. A payment within 10 % of it marks the bill paid.';

  @override
  String get billDueDate => 'First due date';

  @override
  String get billChooseDueDate => 'Choose a due date';

  @override
  String get billRepeats => 'Repeats';

  @override
  String get billCadenceOnce => 'Once';

  @override
  String get billCadenceWeekly => 'Every week';

  @override
  String get billCadenceBiweekly => 'Every two weeks';

  @override
  String get billCadenceSemiMonthly => 'Twice a month';

  @override
  String get billCadenceMonthly => 'Every month';

  @override
  String get billCadenceQuarterly => 'Every three months';

  @override
  String get billCadenceAnnually => 'Every year';

  @override
  String get billAccount => 'Paid from';

  @override
  String get billAnyAccount => 'Any account';

  @override
  String get billReminders => 'Remind me';

  @override
  String billReminderOffset(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days before',
      one: '1 day before',
      zero: 'On the day',
    );
    return '$_temp0';
  }

  @override
  String get billReminderTime => 'Reminder time';

  @override
  String get billActive => 'Active';

  @override
  String get billActiveCaption =>
      'An inactive bill is kept but never reminded.';

  @override
  String get billAutopay => 'Paid automatically';

  @override
  String get billAutopayCaption =>
      'Never shown as missed when no payment is found.';

  @override
  String get billPermissionTitle => 'Notifications are off';

  @override
  String get billPermissionBody =>
      'Bill reminders need notifications. The bill is saved; to be reminded, allow notifications for the app in the system settings.';

  @override
  String get billPermissionNotNow => 'Not now';

  @override
  String get billPermissionOpenSettings => 'Open settings';

  @override
  String get subscriptionsTitle => 'Subscriptions';

  @override
  String subscriptionsTotal(String total, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subscriptions',
      one: '1 subscription',
    );
    return '$total a year across $_temp0';
  }

  @override
  String get subscriptionsEmptyHeadline => 'No subscriptions yet';

  @override
  String get subscriptionsEmptyBody =>
      'Subscriptions found in your transactions or reported by your bank will appear here.';

  @override
  String subscriptionsMuted(int count) {
    return 'Muted ($count)';
  }

  @override
  String subscriptionsOthers(int count) {
    return 'Other recurring ($count)';
  }

  @override
  String streamCadence(String cadence) {
    String _temp0 = intl.Intl.selectLogic(cadence, {
      'weekly': 'Weekly',
      'biweekly': 'Every two weeks',
      'semiMonthly': 'Twice a month',
      'monthly': 'Monthly',
      'quarterly': 'Quarterly',
      'annually': 'Yearly',
      'other': 'Irregular',
    });
    return '$_temp0';
  }

  @override
  String streamAmountEach(String cadence, String amount) {
    return '$cadence, $amount each';
  }

  @override
  String streamYearly(String amount) {
    return '$amount a year';
  }

  @override
  String get streamDetected => 'Detected from your transactions';

  @override
  String streamActions(String name) {
    return 'Actions for $name';
  }

  @override
  String get streamMute => 'Mute';

  @override
  String get streamUnmute => 'Unmute';

  @override
  String get streamNotSubscription => 'Not a subscription';

  @override
  String get streamMarkSubscription => 'Mark as subscription';

  @override
  String get streamRename => 'Rename';

  @override
  String get streamCreateBill => 'Create a bill';

  @override
  String streamMutedDone(String name) {
    return '$name muted';
  }

  @override
  String streamUnmutedDone(String name) {
    return '$name unmuted';
  }

  @override
  String streamNotSubscriptionDone(String name) {
    return '$name is no longer counted as a subscription';
  }

  @override
  String streamMarkSubscriptionDone(String name) {
    return '$name is counted as a subscription';
  }

  @override
  String streamRenamedDone(String name) {
    return 'Renamed to $name';
  }

  @override
  String get streamRenameLabel => 'Name';

  @override
  String streamRenameHelper(String merchant) {
    return 'Leave empty to use $merchant';
  }

  @override
  String navPlanMissed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count missed bills',
      one: '1 missed bill',
    );
    return 'Plan, $_temp0';
  }

  @override
  String get billsEmptyHeadline => 'No bills yet';

  @override
  String get billsEmptyBody => 'Add a bill to be reminded before it is due.';

  @override
  String get billsGroupOverdue => 'Overdue';

  @override
  String get billsGroupDueSoon => 'Due soon';

  @override
  String get billsGroupLater => 'Later';

  @override
  String billsGroupPaused(int count) {
    return 'Paused ($count)';
  }

  @override
  String get billsSuggested => 'Suggested';

  @override
  String billSuggestionDetail(String cadence, String date) {
    return '$cadence, next due $date';
  }

  @override
  String get billSuggestionAdd => 'Add';

  @override
  String billSuggestionAddLabel(String name) {
    return 'Add $name as a bill';
  }

  @override
  String get billSuggestionDismiss => 'Dismiss';

  @override
  String billSuggestionDismissLabel(String name) {
    return 'Dismiss the suggestion $name';
  }

  @override
  String get billStateAutopay => 'Autopay';

  @override
  String get billMarkPaid => 'Mark paid';

  @override
  String billMarkPaidLabel(String name, String date) {
    return 'Mark $name paid for $date';
  }

  @override
  String billMarkedPaid(String name) {
    return '$name marked paid';
  }

  @override
  String billDueIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Due in $days days',
      one: 'Due tomorrow',
      zero: 'Due today',
    );
    return '$_temp0';
  }

  @override
  String billDueAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Due $days days ago',
      one: 'Due yesterday',
    );
    return '$_temp0';
  }

  @override
  String billDueOn(String date) {
    return 'Due $date';
  }

  @override
  String get billPaused => 'Paused';

  @override
  String get billsListView => 'List';

  @override
  String get billsCalendarView => 'Calendar';

  @override
  String get billsPreviousMonth => 'Previous month';

  @override
  String get billsNextMonth => 'Next month';

  @override
  String billsCalendarDay(String date, int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bills due: $names',
      one: '1 bill due: $names',
      zero: 'no bills due',
    );
    return '$date, $_temp0';
  }

  @override
  String billsCalendarNone(String date) {
    return 'No bills due $date';
  }

  @override
  String billsSuggestedShowAll(int count) {
    return 'Show all ($count)';
  }

  @override
  String billsMissedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count missed bills',
      one: '1 missed bill',
    );
    return '$_temp0';
  }

  @override
  String get forecastTitle => 'Forecast';

  @override
  String forecastEventAmount(String name, String amount) {
    return '$name $amount';
  }

  @override
  String forecastHorizon(int days) {
    return '$days days';
  }

  @override
  String get forecastShowTable => 'Table';

  @override
  String get forecastShowChart => 'Chart';

  @override
  String forecastLowest(String amount, String date) {
    return 'Lowest point $amount on $date';
  }

  @override
  String forecastBelowZero(String date) {
    return 'Below zero on $date';
  }

  @override
  String get forecastChooseAccounts => 'Choose accounts';

  @override
  String get forecastEmptyHeadline => 'No accounts to forecast';

  @override
  String get forecastEmptyBody =>
      'Choose a checking or savings account to see where its balance is heading.';

  @override
  String forecastChartSummary(
    int days,
    String start,
    String end,
    String endDate,
    String lowest,
    String lowestDate,
  ) {
    return '$days-day forecast: $start today, $end on $endDate. Lowest point $lowest on $lowestDate.';
  }

  @override
  String forecastRange(String low, String high) {
    return 'Low $low · High $high';
  }

  @override
  String forecastDaySemantics(
    String date,
    String balance,
    String low,
    String high,
  ) {
    return '$date: balance $balance, low $low, high $high.';
  }

  @override
  String forecastOverdue(String name, String date) {
    return '$name, due $date';
  }

  @override
  String get forecastAccountsTitle => 'Accounts in the forecast';

  @override
  String forecastAccountsHidden(String currency) {
    return '$currency · hidden account';
  }

  @override
  String get forecastCurrency => 'Currency';

  @override
  String get forecastSelectionFailed =>
      'The forecast\'s accounts could not be saved. Try again.';

  @override
  String get goalsNew => 'New goal';

  @override
  String get goalsEmptyTitle => 'No savings goals yet';

  @override
  String get goalsEmptyBody =>
      'Set a target and a date, and see how much to set aside each month.';

  @override
  String goalsArchived(int count) {
    return 'Archived ($count)';
  }

  @override
  String goalProgressOf(String progress, String target) {
    return '$progress of $target';
  }

  @override
  String goalProgressPercent(int percent) {
    return '$percent percent of the target';
  }

  @override
  String get goalOnTrack => 'On track';

  @override
  String goalBehind(String amount) {
    return 'Behind by $amount';
  }

  @override
  String get goalDone => 'Done';

  @override
  String goalSuggestion(String amount) {
    return 'Set aside $amount a month';
  }

  @override
  String goalTargetDateCaption(String date) {
    return 'By $date';
  }

  @override
  String get goalNotFound => 'This goal no longer exists.';

  @override
  String get goalNewTitle => 'New goal';

  @override
  String get goalEditTitle => 'Edit goal';

  @override
  String get goalName => 'Name';

  @override
  String get goalNameRequired => 'Enter a name';

  @override
  String get goalTarget => 'Target amount';

  @override
  String get goalKind => 'Progress from';

  @override
  String get goalKindBalance => 'Account balances';

  @override
  String get goalKindContribution => 'Contributions';

  @override
  String get goalKindBalanceCaption =>
      'Progress is the balance of the accounts you choose.';

  @override
  String get goalKindContributionCaption =>
      'Progress is what you add to the goal yourself.';

  @override
  String get goalAccounts => 'Accounts';

  @override
  String get goalAccountsRequired => 'Choose at least one account';

  @override
  String goalAccountOtherCurrency(String currency) {
    return 'In $currency, not counted';
  }

  @override
  String get goalTargetDate => 'Target date';

  @override
  String get goalNoTargetDate => 'No date';

  @override
  String get goalClearTargetDate => 'Clear date';

  @override
  String get goalNote => 'Note';

  @override
  String get goalArchive => 'Archive';

  @override
  String get goalUnarchive => 'Unarchive';

  @override
  String get goalArchivedMessage => 'Goal archived';

  @override
  String get goalDeleted => 'Goal deleted';

  @override
  String get goalCountedAccounts => 'Counted accounts';

  @override
  String goalNotCounted(String names) {
    return 'Not counted, another currency: $names';
  }

  @override
  String get goalContributions => 'Contributions';

  @override
  String get goalNoContributions => 'No contributions yet.';

  @override
  String get goalAddContribution => 'Add contribution';

  @override
  String get contributionDate => 'Date';

  @override
  String get contributionAmount => 'Amount';

  @override
  String get contributionNote => 'Note';

  @override
  String get contributionWithdrawal => 'Withdrawal';

  @override
  String get contributionWithdrawalCaption =>
      'Takes the amount out of the goal.';

  @override
  String get contributionDelete => 'Delete contribution';

  @override
  String get contributionDeleted => 'Contribution deleted';

  @override
  String get goalTargetDatePast => 'Choose today or a later date';

  @override
  String get goalCurrencyLocked =>
      'The currency stays as it is once the goal has contributions or accounts.';

  @override
  String contributionNotCounted(String currency) {
    return 'Not counted, in $currency';
  }

  @override
  String get contributionDateFuture => 'Choose today or an earlier date';

  @override
  String get investmentsTitle => 'Investments';

  @override
  String get investmentsEmptyHeadline => 'No investment accounts';

  @override
  String get investmentsEmptyBody =>
      'Link a brokerage or retirement account to see its holdings, allocation and value here.';

  @override
  String get investmentsAllocation => 'Allocation';

  @override
  String investmentsAllocationIn(String currency) {
    return 'Allocation in $currency';
  }

  @override
  String investmentsAllocationSummary(
    String total,
    int count,
    String largest,
    String share,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count security types',
      one: 'one security type',
    );
    return 'Holdings worth $total in $_temp0. The largest is $largest at $share.';
  }

  @override
  String investmentsAllocationRow(String type, String value, String share) {
    return '$type: $value, $share';
  }

  @override
  String get investmentsTypeCash => 'Cash';

  @override
  String get investmentsTypeOther => 'Other';

  @override
  String get investmentsTypeEtf => 'ETF';

  @override
  String investmentsPercent(int percent) {
    return '$percent %';
  }

  @override
  String investmentsPercentUp(int percent) {
    return '+$percent %';
  }

  @override
  String investmentsChange(String amount, String percent) {
    return '$amount ($percent)';
  }

  @override
  String investmentsPrice(String price, String currency) {
    return '$price $currency';
  }

  @override
  String investmentsQuantityAtPrice(String quantity, String price) {
    return '$quantity at $price';
  }

  @override
  String investmentsCostBasis(String cost) {
    return 'Cost basis $cost';
  }

  @override
  String investmentsGain(String gain) {
    return 'Gain $gain';
  }

  @override
  String get investmentsCostBasisUnavailable => 'Cost basis unavailable';

  @override
  String investmentsPriceAsOf(String date) {
    return 'Price as of $date';
  }

  @override
  String investmentsNameAmount(String name, String amount) {
    return '$name: $amount';
  }

  @override
  String investmentsDateAndType(String date, String type) {
    return '$date · $type';
  }

  @override
  String investmentsFees(String amount) {
    return 'Fees $amount';
  }

  @override
  String investmentsAccountSemantics(
    String name,
    String balance,
    String caption,
  ) {
    return '$name, $balance, $caption';
  }

  @override
  String get investmentsValueTitle => 'Value over time';

  @override
  String investmentsValueCaption(String date) {
    return 'From install day: recorded on this device since $date';
  }

  @override
  String get investmentsValueNone => 'No values recorded yet';

  @override
  String investmentsValueSummary(
    String start,
    String startDate,
    String end,
    String endDate,
  ) {
    return 'Value $start on $startDate, $end on $endDate.';
  }

  @override
  String investmentsValueSummaryOne(String amount, String date) {
    return 'Value $amount on $date.';
  }

  @override
  String investmentsValueRow(String date, String value) {
    return '$date: $value';
  }

  @override
  String get investmentsShowTable => 'Table';

  @override
  String get investmentsShowChart => 'Chart';

  @override
  String get investmentsHoldings => 'Holdings';

  @override
  String get investmentsNoHoldings => 'No holdings reported';

  @override
  String get investmentsUnknownSecurity => 'Unknown security';

  @override
  String get investmentsTransactions => 'Investment transactions';

  @override
  String get investmentsNoTransactions => 'No investment transactions';

  @override
  String investmentsShowMore(int count) {
    return 'Show more ($count left)';
  }

  @override
  String get netWorthTitle => 'Net worth';

  @override
  String netWorthHeadlineLabel(String date) {
    return 'Net worth on $date';
  }

  @override
  String netWorthChange(String amount) {
    return '$amount over 30 days';
  }

  @override
  String netWorthChangeEstimated(String amount) {
    return '$amount over 30 days, against an estimate';
  }

  @override
  String get netWorthRangeThreeMonths => '3 m';

  @override
  String get netWorthRangeYear => '1 y';

  @override
  String get netWorthRangeAll => 'All';

  @override
  String get netWorthShowTable => 'Table';

  @override
  String get netWorthShowChart => 'Chart';

  @override
  String get netWorthAssets => 'Assets';

  @override
  String get netWorthLiabilitiesLine => 'Liabilities';

  @override
  String get netWorthEstimatedLegend => 'Dashed: estimated from transactions';

  @override
  String netWorthChartSummary(
    String startDate,
    String endDate,
    String start,
    String end,
    String assets,
    String liabilities,
  ) {
    return 'Net worth from $startDate to $endDate: $start to $end. On $endDate, assets $assets and liabilities $liabilities.';
  }

  @override
  String netWorthChartEstimated(String date) {
    return 'Before $date, estimated from transactions.';
  }

  @override
  String netWorthRowSemantics(
    String date,
    String netWorth,
    String assets,
    String liabilities,
  ) {
    return '$date: net worth $netWorth, assets $assets, liabilities $liabilities.';
  }

  @override
  String netWorthRowDetail(String assets, String liabilities) {
    return 'Assets $assets · Liabilities $liabilities';
  }

  @override
  String get netWorthEstimated => 'Estimated from transactions';

  @override
  String get netWorthCarried =>
      'No snapshot this day: the day before\'s values';

  @override
  String get netWorthEmptyHeadline => 'No net worth yet';

  @override
  String get netWorthEmptyBody =>
      'Your net worth is recorded once a day from your accounts\' balances. Add or link an account to start.';

  @override
  String get netWorthLiabilitiesHeading => 'Liabilities';

  @override
  String netWorthOwed(String amount) {
    return '$amount owed';
  }

  @override
  String get netWorthHiddenAccount => 'Hidden account';

  @override
  String netWorthRate(String rate) {
    return '$rate % a year';
  }

  @override
  String netWorthRateEntered(String rate) {
    return '$rate % a year, entered';
  }

  @override
  String get netWorthNoRate => 'No interest rate reported';

  @override
  String netWorthPaymentMinimum(String amount) {
    return 'Minimum payment $amount';
  }

  @override
  String netWorthPaymentMonthly(String amount) {
    return 'Monthly payment $amount';
  }

  @override
  String netWorthPaymentEntered(String amount) {
    return 'Your payment $amount';
  }

  @override
  String get netWorthNoPayment => 'No payment reported';

  @override
  String get netWorthEnterRate => 'Enter rate';

  @override
  String get netWorthEnterPayment => 'Enter payment';

  @override
  String get netWorthEditRate => 'Change rate';

  @override
  String get netWorthEditPayment => 'Change payment';

  @override
  String netWorthPaidOff(int months, String date, String interest) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months months',
      one: '1 month',
    );
    return 'Paid off in $_temp0, $date; $interest in interest';
  }

  @override
  String netWorthNever(String interest) {
    return 'Never paid off: the payment doesn\'t cover the interest of $interest a month';
  }

  @override
  String get netWorthBeyondCap => 'Over 50 years to pay off';

  @override
  String get netWorthNothingOwed => 'Nothing owed';

  @override
  String netWorthExtra(String amount) {
    return 'Extra a month: $amount';
  }

  @override
  String netWorthExtraDifference(int months, String interest) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months months sooner',
      one: '1 month sooner',
      zero: 'no sooner',
    );
    return '$_temp0, $interest less interest';
  }

  @override
  String netWorthWithExtra(String extra, String result) {
    return 'With $extra more a month: $result';
  }

  @override
  String get netWorthRateLabel => 'Interest rate, % a year';

  @override
  String get netWorthRateInvalid =>
      'Enter a rate from 0 to 100, with up to two decimals';

  @override
  String get netWorthPaymentLabel => 'Monthly payment';

  @override
  String get netWorthPaymentInvalid => 'Enter an amount above zero';

  @override
  String get netWorthClearEntry => 'Clear';

  @override
  String get netWorthEntryFailed => 'The entry could not be saved. Try again.';

  @override
  String get exportReportTitle => 'Monthly report';

  @override
  String exportCountedThrough(String date) {
    return 'Counted through $date';
  }

  @override
  String exportAmountsIn(String currency) {
    return 'Amounts in $currency';
  }

  @override
  String get exportOther => 'Other';

  @override
  String get exportColumnCategory => 'Category';

  @override
  String get exportColumnShare => 'Share';

  @override
  String get exportColumnAmount => 'Amount';

  @override
  String get exportColumnMerchant => 'Merchant';

  @override
  String get exportColumnPeriod => 'Period';

  @override
  String get exportColumnNet => 'Net';

  @override
  String get exportColumnBefore => 'Before';

  @override
  String get exportColumnNow => 'Now';

  @override
  String get exportColumnChange => 'Change';

  @override
  String get exportColumnDate => 'Date';

  @override
  String get exportColumnWhy => 'Why';

  @override
  String get exportBills => 'Bills';

  @override
  String get exportColumnBill => 'Bill';

  @override
  String get exportColumnDue => 'Due';

  @override
  String get exportColumnStatus => 'Status';

  @override
  String get exportBillDue => 'Due';

  @override
  String get exportBillUpcoming => 'Upcoming';

  @override
  String get exportNoBills => 'No bills due in this period.';

  @override
  String get exportColumnBudget => 'Budget';

  @override
  String get exportColumnAvailable => 'Available';

  @override
  String get exportColumnLeft => 'Left';

  @override
  String exportPage(int page, int count) {
    return 'Page $page of $count';
  }

  @override
  String get exportTitle => 'Export';

  @override
  String get exportSettingsSubtitle =>
      'The monthly report as a PDF, transactions as a CSV';

  @override
  String get exportReportSection => 'Monthly report (PDF)';

  @override
  String get exportTransactionsSection => 'Transactions (CSV)';

  @override
  String get exportSaveAs => 'Save as…';

  @override
  String get exportShare => 'Share…';

  @override
  String get exportSaveReport => 'Save the monthly report as a PDF';

  @override
  String get exportShareReport => 'Share the monthly report as a PDF';

  @override
  String get exportSaveTransactions => 'Save the transactions as a CSV';

  @override
  String get exportShareTransactions => 'Share the transactions as a CSV';

  @override
  String get exportDates => 'Dates';

  @override
  String get exportAccounts => 'Accounts';

  @override
  String exportTransactionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: 'No transactions in these dates and accounts',
    );
    return '$_temp0';
  }

  @override
  String get exportPrivacyNote =>
      'A file you save or share leaves the app\'s encrypted storage. Anyone who has the file can read it.';

  @override
  String get exportDemoNote => 'In the demo, nothing is saved or shared.';

  @override
  String get exportPreparing => 'Preparing the file';

  @override
  String exportSaved(String fileName) {
    return 'Saved $fileName';
  }

  @override
  String get exportFailed => 'The file could not be exported. Try again.';

  @override
  String get exportReportMenu => 'Export this month as PDF';

  @override
  String get backupTitle => 'Backup';

  @override
  String get backupSettingsSubtitle =>
      'Everything in one encrypted file, or restore one';

  @override
  String get backupDemoNote =>
      'The demo\'s generated data is not kept or backed up';

  @override
  String get backupExportSection => 'Export a backup';

  @override
  String get backupExportExplanation =>
      'Everything on this device in one file, encrypted with a passphrase you choose: accounts, transactions, budgets, bills, goals, settings and receipt photos. Keep it anywhere.';

  @override
  String get backupPassphrase => 'Passphrase';

  @override
  String get backupPassphraseConfirm => 'Passphrase again';

  @override
  String backupPassphraseHelper(int count) {
    return 'At least $count characters';
  }

  @override
  String backupPassphraseTooShort(int count) {
    return 'Use at least $count characters';
  }

  @override
  String get backupPassphraseMismatch => 'The two passphrases differ';

  @override
  String get backupStrengthWeak =>
      'Strength: weak. A longer passphrase is safer.';

  @override
  String get backupStrengthFair => 'Strength: fair';

  @override
  String get backupStrengthStrong => 'Strength: strong';

  @override
  String get backupNoRecovery =>
      'There is no way to recover a forgotten passphrase: without it, the backup cannot be opened.';

  @override
  String get backupSave => 'Save as';

  @override
  String get backupShare => 'Share';

  @override
  String backupSaved(String fileName) {
    return 'Saved $fileName';
  }

  @override
  String get backupExportFailed => 'The backup could not be made. Try again.';

  @override
  String get backupRestoreSection => 'Restore from a backup';

  @override
  String get backupRestoreExplanation =>
      'A backup can be restored only onto a device with no data yet, such as a new install: a device that already has data refuses it.';

  @override
  String get backupRestoreButton => 'Restore from a backup';

  @override
  String get backupRestorePassphraseTitle => 'This backup\'s passphrase';

  @override
  String get backupOpen => 'Open';

  @override
  String get backupStageReading => 'Reading your data';

  @override
  String get backupStageDeriving => 'Securing with your passphrase';

  @override
  String get backupStageEncrypting => 'Encrypting';

  @override
  String get backupStageChecking => 'Checking the backup';

  @override
  String get backupStageRestoring => 'Restoring';

  @override
  String get backupConfirmTitle => 'Restore this backup?';

  @override
  String backupConfirmBody(
    String date,
    String version,
    int records,
    int receipts,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      records,
      locale: localeName,
      other: '$records records',
      one: '1 record',
    );
    String _temp1 = intl.Intl.pluralLogic(
      receipts,
      locale: localeName,
      other: '$receipts receipt photos',
      one: '1 receipt photo',
    );
    return 'Made $date by version $version: $_temp0 and $_temp1.';
  }

  @override
  String get backupConfirmLostKey =>
      'The data on this device that can no longer be opened will be deleted.';

  @override
  String get backupConfirmRestore => 'Restore';

  @override
  String get backupErrorNotABackup =>
      'This file is not a Finance Tracker backup.';

  @override
  String get backupErrorTooLarge =>
      'This file is too large to be a Finance Tracker backup (over 512 MB).';

  @override
  String get backupErrorTooNew =>
      'This backup was made by a newer version of Finance Tracker. Update the app, then restore it.';

  @override
  String get backupErrorUnsafe =>
      'This backup asks for settings this app does not accept, so it was not opened.';

  @override
  String get backupErrorWrongPassphrase =>
      'The passphrase is wrong, or the file is damaged.';

  @override
  String get backupErrorDamaged => 'This backup is damaged or incomplete.';

  @override
  String get backupErrorOtherAccount =>
      'This backup belongs to another account.';

  @override
  String get backupErrorHasData =>
      'This device already has data. Delete the app\'s data first, then restore.';

  @override
  String get backupErrorPick => 'The file could not be opened.';

  @override
  String get backupErrorFailed =>
      'The backup could not be restored. Nothing was changed.';

  @override
  String get backupRestoringTitle => 'Restoring your backup';

  @override
  String get backupRestoreFailedTitle => 'The backup could not be restored';

  @override
  String get backupRestoreFailedBody =>
      'Finance Tracker will start with the data this device holds now.';

  @override
  String get backupContinue => 'Continue';

  @override
  String get restoreOfferTitle => 'Restore from a backup?';

  @override
  String get restoreOfferBody =>
      'If you have a Finance Tracker backup, you can restore it now, before this device fetches your data. Your bank data and synced changes come back from the server either way; a backup also brings receipt photos and what was kept only on your old device.';

  @override
  String get restoreOfferStartFresh => 'Start fresh';

  @override
  String get erasingTitle => 'Erasing this device\'s data…';

  @override
  String get eraseFailedTitle =>
      'This device\'s data could not be erased completely';

  @override
  String eraseFailedBody(String repeated) {
    String _temp0 = intl.Intl.selectLogic(repeated, {
      'true': 'The app does not start on what is left. Try again; what is already erased stays erased. If this keeps failing, clear the app\'s storage in Android\'s settings.',
      'other': 'The app does not start on what is left. Try again; what is already erased stays erased.',
    });
    return '$_temp0';
  }

  @override
  String get eraseTryAgain => 'Try again';

  @override
  String get erasedAccountTitle =>
      'Your account and this device\'s data were deleted';

  @override
  String get erasedAccountBody =>
      'Every linked bank was disconnected, every record on the server was deleted, and your other devices were signed out.';

  @override
  String get erasedDeviceTitle => 'This device\'s data was erased';

  @override
  String get erasedDeviceBody =>
      'Your account is unchanged. Sign in again to bring back your bank data and everything that had synced.';

  @override
  String get erasedDone => 'Done';

  @override
  String get settingsEraseDevice => 'Sign out and erase this device';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountIntro => 'Deleting your account:';

  @override
  String get deleteAccountEffectBanks =>
      'Disconnects every linked bank at Plaid';

  @override
  String get deleteAccountEffectServer =>
      'Deletes every record of yours on the server';

  @override
  String get deleteAccountEffectDevice => 'Erases this device\'s data';

  @override
  String get deleteAccountEffectOthers => 'Signs out your other devices';

  @override
  String get deleteAccountPermanent =>
      'This cannot be undone. Your other devices keep what they hold until you erase them.';

  @override
  String get deleteAccountConfirmLabel => 'Type your email to confirm';

  @override
  String deleteAccountConfirmHelper(String email) {
    return 'Your account\'s email is $email';
  }

  @override
  String get deleteAccountSubmit => 'Delete account';

  @override
  String get deleteAccountDeleting => 'Deleting your account';

  @override
  String deleteAccountFailed(String reason) {
    return 'Your account was not deleted. $reason';
  }

  @override
  String get deleteAccountFailedPlaid =>
      'A linked bank could not be disconnected. Try again later.';

  @override
  String get deleteAccountFailedNetwork =>
      'Can\'t reach the server. Check your connection and try again.';

  @override
  String get deleteAccountFailedOther => 'Something went wrong. Try again.';

  @override
  String get eraseDeviceTitle => 'Erase this device\'s data?';

  @override
  String get eraseDeviceBody =>
      'This device signs out and everything it keeps is deleted from it. Changes not yet synced and receipt photos are lost. Your account stays: your bank data and everything that synced come back when you sign in again.';

  @override
  String eraseDevicePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes not yet synced',
      one: '1 change not yet synced',
    );
    return '$_temp0';
  }

  @override
  String get eraseDeviceConfirm => 'Erase';

  @override
  String get settingsDevices => 'Devices';

  @override
  String get devicesTitle => 'Devices';

  @override
  String get devicesThisDevice => 'This device';

  @override
  String devicesLastSeen(String time) {
    return 'Last seen $time';
  }

  @override
  String get devicesNeverSynced => 'Not synced yet';

  @override
  String devicesActions(String name) {
    return 'Actions for $name';
  }

  @override
  String get devicesRemove => 'Remove';

  @override
  String devicesRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get devicesRemoveBody =>
      'It is signed out and has to sign in again. What it keeps stays on it.';

  @override
  String get devicesRemoveThisTitle => 'Remove this device?';

  @override
  String get devicesRemoveThisBody =>
      'This device signs out. Its data stays on it until you erase it.';

  @override
  String devicesRemoveFailed(String name) {
    return 'Couldn\'t remove $name. Try again.';
  }

  @override
  String get devicesSignOutOthers => 'Sign out everywhere else';

  @override
  String get devicesSignOutOthersTitle => 'Sign out everywhere else?';

  @override
  String get devicesSignOutOthersBody =>
      'Every other device signs out and has to sign in again. This device stays signed in.';

  @override
  String devicesSignOutOthersDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Signed out $count devices',
      one: 'Signed out 1 device',
    );
    return '$_temp0';
  }

  @override
  String devicesSignOutOthersFailed(int failed) {
    String _temp0 = intl.Intl.pluralLogic(
      failed,
      locale: localeName,
      other: '$failed devices could not be signed out. Try again.',
      one: '1 device could not be signed out. Try again.',
    );
    return '$_temp0';
  }

  @override
  String get devicesLoadFailed => 'Couldn\'t load your devices.';

  @override
  String get devicesRetry => 'Try again';

  @override
  String get signInRemoteNotice =>
      'This device was signed out remotely. Its data is still here.';

  @override
  String get signInEraseDevice => 'Erase this device\'s data';

  @override
  String syncConflicts(int count) {
    return 'Conflicts ($count)';
  }

  @override
  String get syncConflictsHint =>
      'Changes made on two devices at about the same time';

  @override
  String get conflictsTitle => 'Conflicts';

  @override
  String get conflictsIntro =>
      'Each of these is a change made on this device that a change from another device replaced a few minutes later. Choose the value to keep.';

  @override
  String get conflictsEmptyHeadline => 'No conflicts';

  @override
  String get conflictsEmptyBody =>
      'When a change made here and one from another device meet within minutes, both are shown here so you can choose.';

  @override
  String conflictEntityType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'transaction': 'Transaction',
      'account': 'Account',
      'category': 'Category',
      'settings': 'Settings',
      'rule': 'Rule',
      'budget': 'Budget',
      'recurringStream': 'Subscription',
      'billReminder': 'Bill',
      'goal': 'Goal',
      'goalContribution': 'Goal contribution',
      'other': 'Record',
    });
    return '$_temp0';
  }

  @override
  String conflictField(String field) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'name': 'Name',
      'notes': 'Notes',
      'category': 'Category',
      'tags': 'Tags',
      'splits': 'Splits',
      'amount': 'Amount',
      'day': 'Date',
      'hidden': 'Hidden',
      'receipt': 'Receipt',
      'account': 'Account',
      'theme': 'Theme',
      'dynamicColor': 'Dynamic colour',
      'muted': 'Muted',
      'subscription': 'Subscription',
      'target': 'Target',
      'targetDay': 'Target date',
      'note': 'Note',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get conflictThisValue => 'This device\'s value';

  @override
  String get conflictOtherValue => 'The other value';

  @override
  String get conflictThisDevice => 'This device';

  @override
  String conflictFrom(String device, String time) {
    return '$device, $time';
  }

  @override
  String get conflictKeepThis => 'Keep this device\'s value';

  @override
  String get conflictKeepOther => 'Keep the other';

  @override
  String get conflictNoValue => 'None';

  @override
  String get conflictYes => 'Yes';

  @override
  String get conflictNo => 'No';

  @override
  String conflictSplits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count splits',
      one: '1 split',
      zero: 'No splits',
    );
    return '$_temp0';
  }

  @override
  String get conflictKeepFailed => 'The value could not be kept. Try again.';

  @override
  String get receiptDownloading => 'Downloading the receipt';

  @override
  String get receiptDownloadFailed => 'The receipt could not be downloaded';

  @override
  String get receiptNotOnServer => 'The receipt has not reached the server yet';

  @override
  String get receiptRetry => 'Try again';

  @override
  String get conflictPhotoHere => 'Photo, on this device';

  @override
  String get conflictPhotoNotHere => 'Photo, not on this device';

  @override
  String get conflictPhotoGone => 'This photo is no longer on this device';

  @override
  String widgetUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get widgetNetWorthObserved => 'From account balances';

  @override
  String widgetNetWorthSpoken(String amount, String basis) {
    return 'Net worth $amount, $basis';
  }

  @override
  String widgetAccountSpoken(String name, String balance, String basis) {
    return '$name, $balance, $basis';
  }

  @override
  String widgetBillMissed(String due) {
    return 'Missed, $due';
  }

  @override
  String widgetBillSpoken(String name, String due, String amount) {
    return '$name, $due, $amount';
  }

  @override
  String widgetBillSpokenNoAmount(String name, String due) {
    return '$name, $due';
  }

  @override
  String get widgetNetWorthSpokenHidden =>
      'Net worth, hidden while the app is locked';

  @override
  String widgetAccountSpokenHidden(String name) {
    return '$name, balance hidden while the app is locked';
  }

  @override
  String widgetBudgetSpokenHidden(String name) {
    return '$name, spending hidden while the app is locked';
  }

  @override
  String widgetBillSpokenHidden(String name, String due) {
    return '$name, $due, amount hidden while the app is locked';
  }

  @override
  String get shortcutAddTransaction => 'Add transaction';

  @override
  String get shortcutScanReceipt => 'Scan receipt';

  @override
  String get shortcutSearch => 'Search transactions';

  @override
  String get shortcutSync => 'Sync now';

  @override
  String get budgetAlertsChannelName => 'Budget alerts';

  @override
  String get budgetAlertsChannelDescription =>
      'When a budget reaches 80 % or all of what it has';

  @override
  String get weeklySummaryChannelName => 'Weekly summary';

  @override
  String get weeklySummaryChannelDescription =>
      'When last week\'s summary is ready';

  @override
  String get syncProblemsChannelName => 'Sync problems';

  @override
  String get syncProblemsChannelDescription =>
      'When sync keeps failing, you are signed out, or a bank needs you to sign in again';

  @override
  String get notificationBudgetTitle => 'Budget alert';

  @override
  String get notificationWeeklySummaryText =>
      'See what came in and went out last week';

  @override
  String get notificationSyncTitle => 'Sync needs you';

  @override
  String alertSyncFailing(String date) {
    return 'Sync has not worked since $date';
  }

  @override
  String get alertSyncSignedOut =>
      'You were signed out. Sign in again to keep syncing';

  @override
  String get alertBankNeedsAttention =>
      'A linked bank needs you to sign in to it again';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsSubtitle =>
      'Alerts, reminders and background sync';

  @override
  String get notificationsAppOff => 'Notifications are off for this app';

  @override
  String get notificationsTurnOn => 'Turn on notifications';

  @override
  String get notificationsChannelOn => 'On';

  @override
  String get notificationsChannelOff => 'Off';

  @override
  String get notificationsChannelAppOff =>
      'Off: notifications are off for this app';

  @override
  String get notificationsChannelHint =>
      'Opens this kind\'s settings in Android';

  @override
  String get backgroundSyncTitle => 'Background sync';

  @override
  String get backgroundSyncSchedule =>
      'About every hour, when online and the battery isn\'t low';

  @override
  String backgroundSyncLastRun(String time, String result) {
    return 'Last run $time: $result';
  }

  @override
  String get backgroundSyncNever => 'Has not run yet';

  @override
  String get backgroundSyncUnavailable => 'Not available in the demo';

  @override
  String get backgroundResultSynced => 'synced';

  @override
  String get backgroundResultOffline => 'no network';

  @override
  String get backgroundResultFailed => 'the server failed';

  @override
  String get backgroundResultSessionEnded => 'signed out';

  @override
  String get backgroundResultSkipped => 'nothing to do';

  @override
  String get backgroundResultTimedOut => 'took too long';

  @override
  String get backgroundRestricted =>
      'Android is limiting this app in the background, so background sync may not run. Allow background use in the app\'s battery settings.';

  @override
  String get backgroundOpenAppSettings => 'App settings';

  @override
  String get backgroundResultHeld => 'held until the restore offer is answered';

  @override
  String get notificationsLoadFailed =>
      'The notification settings could not be read';

  @override
  String get notificationsTryAgain => 'Try again';

  @override
  String get backgroundSyncRunningNow => 'Running now';

  @override
  String get backgroundSyncNotScheduled =>
      'Not scheduled: it starts once you sign in';
}

/// The translations for English (`en_XA`).
class AppLocalizationsEnXa extends AppLocalizationsEn {
  AppLocalizationsEnXa() : super('en_XA');

  @override
  String get navAccounts => '[Åççöûñţš ~~~~]';

  @override
  String get navTransactions => '[Ţŕåñšåçţîöñš ~~~~~]';

  @override
  String get navPlan => '[Þļåñ ~~]';

  @override
  String get planBudgets => '[Ɓûðĝéţš ~~~]';

  @override
  String get planBills => '[Ɓîļļš ~~]';

  @override
  String get planForecast => '[Ƒöŕéçåšţ ~~~~]';

  @override
  String get navInsights => '[Îñšîĝĥţš ~~~~]';

  @override
  String get insightsReports => '[Ŕéþöŕţš ~~~]';

  @override
  String get insightsNetWorth => '[Ñéţ ŵöŕţĥ ~~~~]';

  @override
  String get insightsInvestments => '[Îñṽéšţɱéñţš ~~~~~]';

  @override
  String get insightsGoals => '[Ĝöåļš ~~]';

  @override
  String get insightsComingHeadline => '[Çöɱîñĝ šööñ ~~~~]';

  @override
  String get insightsComingBody =>
      '[Ţĥîš þåŕţ öƒ Îñšîĝĥţš îš öñ îţš ŵåý. ~~~~~ ~~~~~ ~~]';

  @override
  String reportsPercent(int percent) {
    return '[$percent %]';
  }

  @override
  String reportsPercentUp(int percent) {
    return '[+$percent %]';
  }

  @override
  String reportsChange(String amount, String percent) {
    return '[$amount ($percent)]';
  }

  @override
  String reportsChangeNew(String amount) {
    return '[$amount (ñéŵ) ~~]';
  }

  @override
  String get reportsShowTables => '[Ţåƀļéš ~~~]';

  @override
  String get reportsShowCharts => '[Çĥåŕţš ~~~]';

  @override
  String get reportsSpending => '[Šþéñðîñĝ ~~~~]';

  @override
  String get reportsIncome => '[Îñçöɱé ~~~]';

  @override
  String reportsSpendingAmount(String amount) {
    return '[Šþéñţ $amount ~~]';
  }

  @override
  String reportsIncomeAmount(String amount) {
    return '[Îñçöɱé $amount ~~~]';
  }

  @override
  String reportsNetAmount(String amount) {
    return '[Ñéţ $amount ~~]';
  }

  @override
  String get reportsNoIncome => '[Ñö îñçöɱé îñ ţĥîš þéŕîöð ~~~~~ ~~~]';

  @override
  String reportsSavingsRate(String percent) {
    return '[Ķéþţ $percent öƒ îñçöɱé ~~~~~]';
  }

  @override
  String get reportsVsPrevious => '[Åĝåîñšţ ţĥé þéŕîöð ƀéƒöŕé ~~~~~ ~~~~]';

  @override
  String get reportsVsYearAgo => '[Åĝåîñšţ å ýéåŕ ƀéƒöŕé ~~~~~ ~~~]';

  @override
  String reportsSpendingChange(String change) {
    return '[Šþéñðîñĝ $change ~~~~]';
  }

  @override
  String reportsIncomeChange(String change) {
    return '[Îñçöɱé $change ~~~]';
  }

  @override
  String reportsSameElapsed(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days ðåýš ~~',
      one: 'ðåý ~~',
    );
    return '[Çöɱþåŕéð öṽéŕ ţĥé ƒîŕšţ $_temp0 öƒ éåçĥ þéŕîöð ~~~~~ ~~~~~ ~~~]';
  }

  @override
  String get reportsByCategory => '[Ɓý çåţéĝöŕý ~~~~]';

  @override
  String get reportsAllCategories => '[Åļļ çåţéĝöŕîéš ~~~~~ ~]';

  @override
  String reportsGroupOwn(String name) {
    return '[$name îţšéļƒ ~~~]';
  }

  @override
  String get reportsNothingInPeriod => '[Ñöţĥîñĝ îñ ţĥîš þéŕîöð. ~~~~~ ~~~]';

  @override
  String reportsDonutSummary(
    String scope,
    String total,
    String name,
    String amount,
  ) {
    return '[$scope ƀý çåţéĝöŕý: $total îñ åļļ. Ţĥé ļåŕĝéšţ îš $name, $amount. ~~~~~ ~~~~~ ~]';
  }

  @override
  String reportsCategoryRow(String name, String amount, String share) {
    return '[$name: $amount, $share öƒ ţĥé ţöţåļ ~~~~]';
  }

  @override
  String get reportsIncomeAndSpending => '[Îñçöɱé åñð šþéñðîñĝ ~~~~~ ~~]';

  @override
  String reportsBarsSummary(int count, String income, String spending) {
    return '[Îñçöɱé åñð šþéñðîñĝ öṽéŕ ţĥé ļåšţ $count þéŕîöðš. Ţĥîš þéŕîöð: îñçöɱé $income, šþéñðîñĝ $spending. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~]';
  }

  @override
  String reportsTrend(int count) {
    return '[Ţŕéñð öṽéŕ $count þéŕîöðš ~~~~~ ~~]';
  }

  @override
  String reportsTrendSummary(
    int count,
    String fromSpending,
    String toSpending,
    String fromIncome,
    String toIncome,
  ) {
    return '[Öṽéŕ ţĥé ļåšţ $count þéŕîöðš, šþéñðîñĝ ŵéñţ ƒŕöɱ $fromSpending ţö $toSpending åñð îñçöɱé ƒŕöɱ $fromIncome ţö $toIncome. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~]';
  }

  @override
  String reportsPeriodRow(
    String period,
    String income,
    String spending,
    String net,
  ) {
    return '[$period: îñçöɱé $income, šþéñðîñĝ $spending, ñéţ $net ~~~~~ ~~]';
  }

  @override
  String get reportsTopMerchants => '[Ţöþ ɱéŕçĥåñţš ~~~~~]';

  @override
  String reportsMerchantCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count þûŕçĥåšéš ~~~~',
      one: '1 þûŕçĥåšé ~~~~',
    );
    return '[$_temp0]';
  }

  @override
  String get reportsTopMovers => '[Ţöþ ɱöṽéŕš ~~~~]';

  @override
  String get reportsMoversCategories => '[Çåţéĝöŕîéš ~~~~]';

  @override
  String get reportsMoversMerchants => '[Ṁéŕçĥåñţš ~~~~]';

  @override
  String get reportsNoMovers =>
      '[Ñöţĥîñĝ çĥåñĝéð ƒŕöɱ ţĥé þéŕîöð ƀéƒöŕé. ~~~~~ ~~~~~ ~~~~]';

  @override
  String reportsMoverAmounts(String before, String now) {
    return '[$before ƀéƒöŕé, $now ñöŵ ~~~~]';
  }

  @override
  String get anomaliesTitle => '[Ŵöŕţĥ å ļööķ ~~~~]';

  @override
  String get anomaliesNone =>
      '[Ñöţĥîñĝ šţåñðš öûţ îñ ţĥîš þéŕîöð. ~~~~~ ~~~~~ ~~]';

  @override
  String anomalyUsualMerchant(String amount) {
    return '[Ûšûåļļý åƀöûţ $amount ĥéŕé ~~~~~ ~~]';
  }

  @override
  String anomalyUsualCategory(String amount) {
    return '[Ûšûåļļý åƀöûţ $amount îñ ţĥîš çåţéĝöŕý ~~~~~ ~~~~~ ~]';
  }

  @override
  String get anomalyNewMerchant =>
      '[Ñéŵ: ñöţ šééñ îñ ţĥé ļåšţ šîẋ ɱöñţĥš ~~~~~ ~~~~~ ~~]';

  @override
  String get anomalyDismissed =>
      '[Ðîšɱîššéð. Îţ ŵöñ\'ţ ƀé ƒļåĝĝéð åĝåîñ öñ ţĥîš ðéṽîçé. ~~~~~ ~~~~~ ~~~~~ ~~]';

  @override
  String anomalyDismissTooltip(String name) {
    return '[Ðîšɱîšš $name ~~~]';
  }

  @override
  String get reportsWeeklySummary => '[Ŵééķļý šûɱɱåŕý ~~~~~ ~]';

  @override
  String get weeklyTitle => '[Ŵééķļý šûɱɱåŕý ~~~~~ ~]';

  @override
  String weeklyRange(String start, String end) {
    return '[$start – $end]';
  }

  @override
  String weeklyLastWeek(String range) {
    return '[Ļåšţ ŵééķ, $range ~~~~]';
  }

  @override
  String get weeklyThisWeek => '[Ţĥîš ŵééķ šö ƒåŕ ~~~~~ ~]';

  @override
  String get weeklyTopCategories => '[Šþéñţ ɱöšţ öñ ~~~~~]';

  @override
  String weeklyCategoryLine(String name, String amount) {
    return '[$name: $amount]';
  }

  @override
  String weeklyTopMerchant(String name, String amount) {
    return '[Šþéñţ ɱöšţ åţ $name: $amount ~~~~~]';
  }

  @override
  String get weeklyNoSpending => '[Ñö šþéñðîñĝ ţĥîš ŵééķ. ~~~~~ ~~~]';

  @override
  String get weeklyBillsNextWeek => '[Ɓîļļš ðûé ñéẋţ ŵééķ ~~~~~ ~~]';

  @override
  String get weeklyNoBills => '[Ñö ƀîļļš ðûé ñéẋţ ŵééķ. ~~~~~ ~~~]';

  @override
  String get weeklyBudgets => '[Ɓûðĝéţš ~~~]';

  @override
  String get weeklyNoBudgets => '[Ñö ƀûðĝéţš ýéţ. ~~~~~]';

  @override
  String weeklyBudgetLeft(String spent, String available, String left) {
    return '[$spent öƒ $available šþéñţ, $left ļéƒţ ~~~~~]';
  }

  @override
  String weeklyBudgetOver(String spent, String available, String over) {
    return '[$spent öƒ $available šþéñţ, öṽéŕ ƀý $over ~~~~~ ~]';
  }

  @override
  String get alertWeeklySummary => '[Ýöûŕ ŵééķļý šûɱɱåŕý îš ŕéåðý ~~~~~ ~~~~~]';

  @override
  String get navSettings => '[Šéţţîñĝš ~~~~]';

  @override
  String get paneAccountsEmpty =>
      '[Çĥööšé åñ åççöûñţ ţö šéé îţ ĥéŕé ~~~~~ ~~~~~ ~]';

  @override
  String get paneTransactionsEmpty =>
      '[Çĥööšé å ţŕåñšåçţîöñ ţö šéé îţ ĥéŕé ~~~~~ ~~~~~ ~~]';

  @override
  String get paneBillsEmpty => '[Çĥööšé å ƀîļļ ţö éðîţ îţ ĥéŕé ~~~~~ ~~~~~]';

  @override
  String get paneSettingsEmpty =>
      '[Çĥööšé å šéţţîñĝ ţö öþéñ îţ ĥéŕé ~~~~~ ~~~~~ ~]';

  @override
  String get accountsEmptyHeadline => '[Ñö åççöûñţš ýéţ ~~~~~ ~]';

  @override
  String get accountsEmptyBody =>
      '[Åççöûñţš ýöû åðð öŕ çöññéçţ ŵîļļ åþþéåŕ ĥéŕé. ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get transactionsEmptyHeadline => '[Ñö ţŕåñšåçţîöñš ýéţ ~~~~~ ~~]';

  @override
  String get transactionsEmptyBody =>
      '[Ţŕåñšåçţîöñš ýöû åðð öŕ šýñç ŵîļļ åþþéåŕ ĥéŕé. ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get settingsAppearance => '[Åþþéåŕåñçé ~~~~]';

  @override
  String get settingsThemeMode => '[Ţĥéɱé ~~]';

  @override
  String get themeModeSystem => '[Šýšţéɱ ~~~]';

  @override
  String get themeModeLight => '[Ļîĝĥţ ~~]';

  @override
  String get themeModeDark => '[Ðåŕķ ~~]';

  @override
  String get settingsDynamicColor => '[Ðýñåɱîç çöļöŕ ~~~~~]';

  @override
  String get settingsDynamicColorSubtitle =>
      '[Ûšé çöļöŕš ƒŕöɱ ýöûŕ ŵåļļþåþéŕ ŵĥéñ ţĥé ðéṽîçé þŕöṽîðéš ţĥéɱ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get settingsLanguage => '[Ļåñĝûåĝé ~~~~]';

  @override
  String get settingsLanguageSubtitle =>
      '[Þšéûðö ļéñĝţĥéñš åñð ƀŕåçķéţš éṽéŕý šţŕîñĝ, ţö ƒîñð ţéẋţ ţĥåţ ŵöûļð ñöţ ƒîţ å ţŕåñšļåţîöñ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get languageSystem => '[Šýšţéɱ ~~~]';

  @override
  String get languageEnglish => '[Éñĝļîšĥ ~~~]';

  @override
  String get languagePseudo => '[Þšéûðö ~~~]';

  @override
  String get settingsAbout => '[Åƀöûţ ~~]';

  @override
  String get aboutAppName => '[Åþþ ~~]';

  @override
  String get aboutVersion => '[Ṽéŕšîöñ ~~~]';

  @override
  String aboutVersionValue(String version, String buildNumber) {
    return '[$version (ƀûîļð $buildNumber) ~~]';
  }

  @override
  String get aboutFlavor => '[Ƒļåṽöŕ ~~~]';

  @override
  String get aboutTimeZone => '[Ţîɱé žöñé ~~~~]';

  @override
  String get databaseErrorTitle => '[Ýöûŕ ðåţå çåñ\'ţ ƀé öþéñéð ~~~~~ ~~~]';

  @override
  String get databaseErrorBody =>
      '[Ƒîñåñçé Ţŕåçķéŕ çöûļð ñöţ öþéñ îţš ðåţå öñ ţĥîš ðéṽîçé. Ñöţĥîñĝ ĥåš ƀééñ ðéļéţéð. Çļöšé ţĥé åþþ åñð öþéñ îţ åĝåîñ; îƒ ţĥîš ķééþš ĥåþþéñîñĝ, ýöûŕ ðåţå çåññöţ ƀé ŕéåð öñ ţĥîš ðéṽîçé. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String get databaseErrorKeyLost =>
      '[Ţĥé ķéý ţĥåţ ûñļöçķš ýöûŕ ðåţå öñ ţĥîš ðéṽîçé îš ɱîššîñĝ öŕ ûñŕéåðåƀļé, šö ýöûŕ ðåţå çåññöţ ƀé öþéñéð. Ñöţĥîñĝ ĥåš ƀééñ ðéļéţéð. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~]';

  @override
  String get databaseErrorKeyMismatch =>
      '[Ýöûŕ ðåţå öñ ţĥîš ðéṽîçé ðöéš ñöţ öþéñ ŵîţĥ îţš ķéý. Ñöţĥîñĝ ĥåš ƀééñ ðéļéţéð. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get databaseErrorNoEncryption =>
      '[Ţĥîš ṽéŕšîöñ öƒ Ƒîñåñçé Ţŕåçķéŕ çåññöţ éñçŕýþţ ðåţå, šö îţ ŵîļļ ñöţ öþéñ ýöûŕš. Ñöţĥîñĝ ĥåš ƀééñ ðéļéţéð. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~]';

  @override
  String get save => '[Šåṽé ~~]';

  @override
  String get cancel => '[Çåñçéļ ~~~]';

  @override
  String get delete => '[Ðéļéţé ~~~]';

  @override
  String get edit => '[Éðîţ ~~]';

  @override
  String get undo => '[Ûñðö ~~]';

  @override
  String get loadFailed =>
      '[Šöɱéţĥîñĝ ŵéñţ ŵŕöñĝ ļöåðîñĝ ţĥîš. Ţŕý åĝåîñ ļåţéŕ. ~~~~~ ~~~~~ ~~~~~ ~~]';

  @override
  String sentencePair(String first, String second) {
    return '[$first $second]';
  }

  @override
  String listPair(String first, String second) {
    return '[$first, $second]';
  }

  @override
  String captionPair(String first, String second) {
    return '[$first · $second]';
  }

  @override
  String amountNegative(String amount) {
    return '[ɱîñûš $amount ~~]';
  }

  @override
  String get balanceFromTransactions => '[ƒŕöɱ ţŕåñšåçţîöñš ~~~~~ ~~]';

  @override
  String runningBalance(String amount) {
    return '[Ŕûññîñĝ ƀåļåñçé $amount ~~~~~ ~]';
  }

  @override
  String runningBalanceFromReported(String amount) {
    return '[Ŕûññîñĝ ƀåļåñçé $amount, ƒŕöɱ ţĥé ŕéþöŕţéð ƀåļåñçé ~~~~~ ~~~~~ ~~~~~]';
  }

  @override
  String get balanceReported => '[ŕéþöŕţéð ~~~~]';

  @override
  String balanceReportedBy(String institution) {
    return '[ŕéþöŕţéð ƀý $institution ~~~~]';
  }

  @override
  String get balanceReportedByBank => '[ŕéþöŕţéð ƀý ýöûŕ ƀåñķ ~~~~~ ~~~]';

  @override
  String balanceAsOf(String time) {
    return '[åš öƒ $time ~~]';
  }

  @override
  String get balanceReportedAndFromTransactions =>
      '[ŕéþöŕţéð åñð ƒŕöɱ ţŕåñšåçţîöñš ~~~~~ ~~~~~ ~]';

  @override
  String accountAvailableBalance(String amount) {
    return '[Åṽåîļåƀļé $amount ~~~~]';
  }

  @override
  String accountCreditLimit(String amount) {
    return '[Çŕéðîţ ļîɱîţ $amount ~~~~~]';
  }

  @override
  String accountMask(String mask) {
    return '[•••• $mask]';
  }

  @override
  String accountMaskSemantics(String mask) {
    return '[éñðîñĝ îñ $mask ~~~~]';
  }

  @override
  String get uncategorized => '[Ûñçåţéĝöŕîžéð ~~~~~ ~]';

  @override
  String get accountAdd => '[Åðð åççöûñţ ~~~~]';

  @override
  String get accountsTotals => '[Ţöţåļš ~~~]';

  @override
  String accountsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ĥîððéñ åççöûñţš ~~~~~ ~',
      one: '1 ĥîððéñ åççöûñţ ~~~~~ ~',
    );
    return '[$_temp0]';
  }

  @override
  String get accountNotFound => '[Ţĥîš åççöûñţ ñö ļöñĝéŕ éẋîšţš. ~~~~~ ~~~~~]';

  @override
  String get accountNoTransactions =>
      '[Ñö ţŕåñšåçţîöñš öñ ţĥîš åççöûñţ ýéţ. ~~~~~ ~~~~~ ~~]';

  @override
  String get accountHide => '[Ĥîðé åççöûñţ ~~~~~]';

  @override
  String get accountShow => '[Šĥöŵ åççöûñţ ~~~~~]';

  @override
  String get accountHiddenLabel => '[Ĥîððéñ ~~~]';

  @override
  String accountDeleteTitle(String name) {
    return '[Ðéļéţé “$name”? ~~~]';
  }

  @override
  String accountDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Ţĥé åççöûñţ åñð îţš $count ţŕåñšåçţîöñš ŵîļļ ƀé ðéļéţéð. ~~~~~ ~~~~~ ~~~~~ ~~',
      one: 'Ţĥé åççöûñţ åñð îţš 1 ţŕåñšåçţîöñ ŵîļļ ƀé ðéļéţéð. ~~~~~ ~~~~~ ~~~~~ ~',
      zero: 'Ţĥé åççöûñţ ŵîļļ ƀé ðéļéţéð. ~~~~~ ~~~~~',
    );
    return '[$_temp0]';
  }

  @override
  String get accountNewTitle => '[Ñéŵ åççöûñţ ~~~~]';

  @override
  String get accountEditTitle => '[Éðîţ åççöûñţ ~~~~~]';

  @override
  String get accountName => '[Ñåɱé ~~]';

  @override
  String get accountNameRequired => '[Éñţéŕ å ñåɱé ~~~~]';

  @override
  String get accountType => '[Ţýþé ~~]';

  @override
  String get accountTypeDepository => '[Çĥéçķîñĝ öŕ šåṽîñĝš ~~~~~ ~~]';

  @override
  String get accountTypeCredit => '[Çŕéðîţ çåŕð ~~~~]';

  @override
  String get accountTypeLoan => '[Ļöåñ ~~]';

  @override
  String get accountTypeInvestment => '[Îñṽéšţɱéñţ ~~~~]';

  @override
  String get accountTypeOther => '[Öţĥéŕ ~~]';

  @override
  String get accountCurrency => '[Çûŕŕéñçý ~~~~]';

  @override
  String currencyValue(String code, String symbol) {
    return '[$code ($symbol)]';
  }

  @override
  String accountCurrencyFixed(String currency) {
    return '[$currency. Îţ çåñ\'ţ çĥåñĝé öñçé ţĥé åççöûñţ ĥåš ţŕåñšåçţîöñš. ~~~~~ ~~~~~ ~~~~~ ~~]';
  }

  @override
  String get accountCurrencyLocked =>
      '[Ţĥé çûŕŕéñçý çåñ\'ţ çĥåñĝé: ţĥîš åççöûñţ ĥåš ţŕåñšåçţîöñš. ~~~~~ ~~~~~ ~~~~~ ~~~~]';

  @override
  String get accountDeleted => '[Ţĥîš åççöûñţ ŵåš ðéļéţéð. ~~~~~ ~~~~]';

  @override
  String get openingBalance => '[Öþéñîñĝ ƀåļåñçé (öþţîöñåļ) ~~~~~ ~~~~]';

  @override
  String get openingBalanceHelper =>
      '[Ñéĝåţîṽé ƒöŕ ɱöñéý öŵéð. Šåṽéð åš å ţŕåñšåçţîöñ. ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get openingBalanceDate => '[Öþéñîñĝ ƀåļåñçé ðåţé ~~~~~ ~~~]';

  @override
  String get openingBalanceName => '[Öþéñîñĝ ƀåļåñçé ~~~~~ ~]';

  @override
  String get currencyPickerTitle => '[Çûŕŕéñçý ~~~~]';

  @override
  String get currencyPickerSearch => '[Šéåŕçĥ çûŕŕéñçîéš ~~~~~ ~~]';

  @override
  String get amountRequired => '[Éñţéŕ åñ åɱöûñţ ~~~~~ ~]';

  @override
  String amountInvalid(String example) {
    return '[Éñţéŕ åñ åɱöûñţ šûçĥ åš $example ~~~~~ ~~~]';
  }

  @override
  String get amountUnsigned =>
      '[Éñţéŕ ţĥé åɱöûñţ ŵîţĥöûţ å šîĝñ ~~~~~ ~~~~~ ~]';

  @override
  String get transactionAdd => '[Åðð ţŕåñšåçţîöñ ~~~~~ ~]';

  @override
  String get transactionPending => '[Þéñðîñĝ ~~~]';

  @override
  String get dateToday => '[Ţöðåý ~~]';

  @override
  String get dateYesterday => '[Ýéšţéŕðåý ~~~~]';

  @override
  String get transactionsSearch => '[Šéåŕçĥ ~~~]';

  @override
  String get transactionsSearchHint => '[Šéåŕçĥ ţŕåñšåçţîöñš ~~~~~ ~~~]';

  @override
  String get transactionsSearchClose => '[Çļöšé šéåŕçĥ ~~~~~]';

  @override
  String get transactionsFilter => '[Ƒîļţéŕš ~~~]';

  @override
  String get transactionsNoMatchHeadline =>
      '[Ñö ɱåţçĥîñĝ ţŕåñšåçţîöñš ~~~~~ ~~~~]';

  @override
  String transactionsNoMatchText(String text) {
    return '[Ñö ɱåţçĥéš ƒöŕ “$text” ~~~~~]';
  }

  @override
  String get transactionsNoMatchBody =>
      '[Ţŕý öţĥéŕ ŵöŕðš öŕ ŕéɱöṽé å ƒîļţéŕ. ~~~~~ ~~~~~ ~~]';

  @override
  String filterRemove(String label) {
    return '[Ŕéɱöṽé ƒîļţéŕ $label ~~~~~]';
  }

  @override
  String get filterClear => '[Çļéåŕ ~~]';

  @override
  String get filterSaved => '[Šåṽéð ~~]';

  @override
  String get filterSaveThese => '[Šåṽé ţĥéšé ƒîļţéŕš ~~~~~ ~~]';

  @override
  String get savedFilterSaveTitle => '[Šåṽé ƒîļţéŕš ~~~~~]';

  @override
  String get savedFilterNameLabel => '[Ñåɱé ~~]';

  @override
  String get savedFilterRenameTitle => '[Ŕéñåɱé šåṽéð ƒîļţéŕ ~~~~~ ~~]';

  @override
  String get savedFilterRename => '[Ŕéñåɱé ~~~]';

  @override
  String savedFilterOptions(String name) {
    return '[Öþţîöñš ƒöŕ $name ~~~~]';
  }

  @override
  String savedFilterDeleteTitle(String name) {
    return '[Ðéļéţé “$name”? ~~~]';
  }

  @override
  String get savedFilterDeleteBody =>
      '[Öñļý ţĥé šåṽéð ƒîļţéŕ ĝöéš; ñö ţŕåñšåçţîöñ çĥåñĝéš. ~~~~~ ~~~~~ ~~~~~ ~~]';

  @override
  String get filterApply => '[Åþþļý ~~]';

  @override
  String get filterCategories => '[Çåţéĝöŕîéš ~~~~]';

  @override
  String get filterAddCategory => '[Åðð çåţéĝöŕý ~~~~~]';

  @override
  String get filterDate => '[Ðåţé ~~]';

  @override
  String get filterAmount => '[Åɱöûñţ ~~~]';

  @override
  String get filterAmountMin => '[Åţ ļéåšţ ~~~]';

  @override
  String get filterAmountMax => '[Åţ ɱöšţ ~~~]';

  @override
  String get filterTags => '[Ţåĝš ~~]';

  @override
  String get filterNoTags => '[Ñö ţåĝš ýéţ. ~~~~]';

  @override
  String get datePresetAny => '[Åñý ţîɱé ~~~]';

  @override
  String get datePresetThisMonth => '[Ţĥîš ɱöñţĥ ~~~~]';

  @override
  String get datePresetLastMonth => '[Ļåšţ ɱöñţĥ ~~~~]';

  @override
  String get datePresetLast90Days => '[Ļåšţ 90 ðåýš ~~~~]';

  @override
  String get datePresetThisYear => '[Ţĥîš ýéåŕ ~~~~]';

  @override
  String get datePresetCustom => '[Çûšţöɱ… ~~~]';

  @override
  String dateRangeValue(String start, String end) {
    return '[$start – $end]';
  }

  @override
  String amountRangeBetween(String min, String max) {
    return '[$min – $max]';
  }

  @override
  String amountRangeAtLeast(String min) {
    return '[Åţ ļéåšţ $min ~~~]';
  }

  @override
  String amountRangeAtMost(String max) {
    return '[Åţ ɱöšţ $max ~~~]';
  }

  @override
  String get amountRangeInverted =>
      '[Åţ ɱöšţ ɱûšţ ñöţ ƀé ļéšš ţĥåñ åţ ļéåšţ ~~~~~ ~~~~~ ~~]';

  @override
  String tagLabel(String tag) {
    return '[#$tag]';
  }

  @override
  String tagRemove(String tag) {
    return '[Ŕéɱöṽé ţåĝ $tag ~~~~]';
  }

  @override
  String tagAdd(String tag) {
    return '[Åðð ţåĝ $tag ~~~]';
  }

  @override
  String get transactionNewTitle => '[Ñéŵ ţŕåñšåçţîöñ ~~~~~ ~]';

  @override
  String get transactionTitle => '[Ţŕåñšåçţîöñ ~~~~~]';

  @override
  String get transactionNotFound =>
      '[Ţĥîš ţŕåñšåçţîöñ ñö ļöñĝéŕ éẋîšţš. ~~~~~ ~~~~~ ~~]';

  @override
  String get transactionNeedsAccountHeadline =>
      '[Åðð åñ åççöûñţ ƒîŕšţ ~~~~~ ~~]';

  @override
  String get transactionNeedsAccountBody =>
      '[Éṽéŕý ţŕåñšåçţîöñ ƀéļöñĝš ţö åñ åççöûñţ. ~~~~~ ~~~~~ ~~~~]';

  @override
  String get transactionExpense => '[Éẋþéñšé ~~~]';

  @override
  String get transactionIncome => '[Îñçöɱé ~~~]';

  @override
  String get transactionAmount => '[Åɱöûñţ ~~~]';

  @override
  String get transactionAccount => '[Åççöûñţ ~~~]';

  @override
  String get transactionDate => '[Ðåţé ~~]';

  @override
  String get transactionDescription => '[Ðéšçŕîþţîöñ ~~~~~]';

  @override
  String get transactionDescriptionRequired => '[Éñţéŕ å ðéšçŕîþţîöñ ~~~~~ ~~]';

  @override
  String get transactionCategory => '[Çåţéĝöŕý ~~~~]';

  @override
  String get transactionCategoryFromBank =>
      '[Ƒŕöɱ ýöûŕ ƀåñķ\'š çåţéĝöŕý ~~~~~ ~~~~]';

  @override
  String get transactionNotes => '[Ñöţéš ~~]';

  @override
  String get transactionTags => '[Ţåĝš ~~]';

  @override
  String get transactionTagsHelper =>
      '[Þŕéšš éñţéŕ öŕ ţýþé å çöɱɱå ţö åðð å ţåĝ ~~~~~ ~~~~~ ~~~]';

  @override
  String get transactionCurrencyMismatch =>
      '[Ţĥé åɱöûñţ ɱûšţ ƀé îñ ţĥé åççöûñţ\'š çûŕŕéñçý. ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get transactionDeleted => '[Ţŕåñšåçţîöñ ðéļéţéð ~~~~~ ~~~]';

  @override
  String get transactionRestoreNoAccount =>
      '[Ţĥé ţŕåñšåçţîöñ çåñ\'ţ çöɱé ƀåçķ: îţš åççöûñţ ŵåš ðéļéţéð. ~~~~~ ~~~~~ ~~~~~ ~~~~]';

  @override
  String get settingsSecurity => '[Šéçûŕîţý ~~~~]';

  @override
  String get lockRequireUnlock => '[Ŕéǫûîŕé ûñļöçķ ~~~~~ ~]';

  @override
  String get lockRequireUnlockSubtitle =>
      '[Åšķ ƒöŕ ýöûŕ ƒîñĝéŕþŕîñţ, ƒåçé öŕ šçŕééñ ļöçķ ŵĥéñ ţĥé åþþ öþéñš ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get lockAfterTitle => '[Ļöçķ åƒţéŕ ~~~~]';

  @override
  String get lockAfterOff => '[Öñļý ŵĥéñ ţĥé åþþ šţåŕţš ~~~~~ ~~~]';

  @override
  String get lockAfterImmediately => '[Îɱɱéðîåţéļý ~~~~~]';

  @override
  String get lockBlockScreenshots => '[Ɓļöçķ šçŕééñšĥöţš ~~~~~ ~~]';

  @override
  String get lockBlockScreenshotsSubtitle =>
      '[Ĥîðé ţĥé åþþ îñ šçŕééñšĥöţš, ŕéçöŕðîñĝš åñð ŕéçéñţ åþþš. Åļŵåýš öñ ŵĥîļé ûñļöçķ îš ŕéǫûîŕéð ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get lockUnlock => '[Ûñļöçķ ~~~]';

  @override
  String get lockTryAgain => '[Ţŕý åĝåîñ ~~~~]';

  @override
  String get lockPromptReason => '[Ûñļöçķ ţö šéé ýöûŕ ƒîñåñçéš ~~~~~ ~~~~~]';

  @override
  String get lockEnablePromptReason =>
      '[Çöñƒîŕɱ îţ\'š ýöû ţö ţûŕñ öñ ţĥé åþþ ļöçķ ~~~~~ ~~~~~ ~~~]';

  @override
  String get lockFailed => '[Ñöţ ŕéçöĝñîžéð. Ţŕý åĝåîñ. ~~~~~ ~~~~]';

  @override
  String get lockCancelled => '[Ûñļöçķ ŵåš çåñçéļļéð. ~~~~~ ~~~]';

  @override
  String get lockNoScreenLock =>
      '[Šéţ å šçŕééñ ļöçķ öñ ţĥîš ðéṽîçé ƒîŕšţ ~~~~~ ~~~~~ ~~~]';

  @override
  String get lockLockedOut =>
      '[Ţöö ɱåñý åţţéɱþţš. Ŵåîţ å ɱöɱéñţ, ţĥéñ ţŕý åĝåîñ. ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get lockUnavailable =>
      '[Ţĥé ðéṽîçé çöûļð ñöţ çĥéçķ îţ\'š ýöû. Ţŕý åĝåîñ. ~~~~~ ~~~~~ ~~~~~]';

  @override
  String lockAfterMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes ɱîñûţéš ~~~',
      one: '1 ɱîñûţé ~~~',
    );
    return '[$_temp0]';
  }

  @override
  String get settingsData => '[Ðåţå ~~]';

  @override
  String get categoriesTitle => '[Çåţéĝöŕîéš ~~~~]';

  @override
  String get categoriesSearch => '[Šéåŕçĥ çåţéĝöŕîéš ~~~~~ ~~]';

  @override
  String get categoriesManage => '[Ṁåñåĝé ~~~]';

  @override
  String get categoryAdd => '[Åðð çåţéĝöŕý ~~~~~]';

  @override
  String get categorySystem => '[Ɓûîļţ-îñ çåţéĝöŕý ~~~~~ ~]';

  @override
  String categoryExpand(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Šĥöŵ $count çåţéĝöŕîéš ûñðéŕ $name ~~~~~ ~~~',
      one: 'Šĥöŵ 1 çåţéĝöŕý ûñðéŕ $name ~~~~~ ~~',
    );
    return '[$_temp0]';
  }

  @override
  String categoryCollapse(String name) {
    return '[Ĥîðé ţĥé çåţéĝöŕîéš ûñðéŕ $name ~~~~~ ~~~~]';
  }

  @override
  String get categoryPickerTitle => '[Çåţéĝöŕý ~~~~]';

  @override
  String get categoryPickerRecent => '[Ŕéçéñţļý ûšéð ~~~~~]';

  @override
  String get categoryPickerAll => '[Åļļ çåţéĝöŕîéš ~~~~~ ~]';

  @override
  String get categoryNone => '[Ñöñé ~~]';

  @override
  String get categoryNotFound =>
      '[Ţĥîš çåţéĝöŕý ñö ļöñĝéŕ éẋîšţš. ~~~~~ ~~~~~ ~]';

  @override
  String get categoryNewTitle => '[Ñéŵ çåţéĝöŕý ~~~~~]';

  @override
  String get categoryEditTitle => '[Éðîţ çåţéĝöŕý ~~~~~]';

  @override
  String get categoryName => '[Ñåɱé ~~]';

  @override
  String get categoryNameRequired => '[Éñţéŕ å ñåɱé ~~~~]';

  @override
  String get categoryParent => '[Ûñðéŕ ~~]';

  @override
  String get categoryParentNone => '[Ñöţĥîñĝ (ţöþ ļéṽéļ) ~~~~~ ~]';

  @override
  String get categoryIcon => '[Îçöñ ~~]';

  @override
  String get categoryColor => '[Çöļöŕ ~~]';

  @override
  String get categorySystemNote =>
      '[Å ƀûîļţ-îñ çåţéĝöŕý: öñļý îţš îçöñ åñð çöļöŕ çåñ çĥåñĝé. ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String get categorySystemReadOnly =>
      '[Ɓûîļţ-îñ çåţéĝöŕîéš çåñ öñļý çĥåñĝé ţĥéîŕ îçöñ åñð çöļöŕ. ~~~~~ ~~~~~ ~~~~~ ~~~~]';

  @override
  String categoryDeleteTitle(String name) {
    return '[Ðéļéţé “$name”? ~~~]';
  }

  @override
  String categoryDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ţŕåñšåçţîöñš ŵîļļ ƀéçöɱé ûñçåţéĝöŕîžéð. ~~~~~ ~~~~~ ~~~~',
      one: '1 ţŕåñšåçţîöñ ŵîļļ ƀéçöɱé ûñçåţéĝöŕîžéð. ~~~~~ ~~~~~ ~~~~',
      zero: 'Ñö ţŕåñšåçţîöñš ûšé îţ. ~~~~~ ~~~',
    );
    return '[$_temp0]';
  }

  @override
  String categoryDeleteWithChildrenBody(int children, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      children,
      locale: localeName,
      other: 'Ţĥé $children çåţéĝöŕîéš ûñðéŕ îţ ĝö ţöö. ~~~~~ ~~~~~',
      one: 'Ţĥé 1 çåţéĝöŕý ûñðéŕ îţ ĝöéš ţöö. ~~~~~ ~~~~~',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ţŕåñšåçţîöñš ŵîļļ ƀéçöɱé ûñçåţéĝöŕîžéð. ~~~~~ ~~~~~ ~~~~',
      one: '1 ţŕåñšåçţîöñ ŵîļļ ƀéçöɱé ûñçåţéĝöŕîžéð. ~~~~~ ~~~~~ ~~~~',
      zero: 'Ñö ţŕåñšåçţîöñš ûšé ţĥéɱ. ~~~~~ ~~~~',
    );
    return '[$_temp0 $_temp1]';
  }

  @override
  String get categoryIconPayments => '[Þåýɱéñţš ~~~~]';

  @override
  String get categoryIconAccountBalance => '[Ɓåñķ ~~]';

  @override
  String get categoryIconCreditScore => '[Çŕéðîţ šçöŕé ~~~~~]';

  @override
  String get categoryIconCallReceived => '[Ṁöñéý îñ ~~~]';

  @override
  String get categoryIconCallMade => '[Ṁöñéý öûţ ~~~~]';

  @override
  String get categoryIconReceiptLong => '[Ŕéçéîþţ ~~~]';

  @override
  String get categoryIconMovie => '[Ṁöṽîé ~~]';

  @override
  String get categoryIconRestaurant => '[Ŕéšţåûŕåñţ ~~~~]';

  @override
  String get categoryIconShoppingBag => '[Šĥöþþîñĝ ƀåĝ ~~~~~]';

  @override
  String get categoryIconHomeRepairService => '[Ţööļƀöẋ ~~~]';

  @override
  String get categoryIconMedicalServices => '[Ṁéðîçåļ ~~~]';

  @override
  String get categoryIconSpa => '[Šþå ~~]';

  @override
  String get categoryIconBuild => '[Ŵŕéñçĥ ~~~]';

  @override
  String get categoryIconVolunteerActivism => '[Çĥåŕîţý ~~~]';

  @override
  String get categoryIconDirectionsCar => '[Çåŕ ~~]';

  @override
  String get categoryIconFlight => '[Þļåñé ~~]';

  @override
  String get categoryIconHouse => '[Ĥöûšé ~~]';

  @override
  String get categoryIconCategory => '[Šĥåþéš ~~~]';

  @override
  String get categoryIconLocalGroceryStore => '[Ĝŕöçéŕîéš ~~~~]';

  @override
  String get categoryIconLocalCafe => '[Çöƒƒéé ~~~]';

  @override
  String get categoryIconLocalBar => '[Ɓåŕ ~~]';

  @override
  String get categoryIconFastfood => '[Ƒåšţ ƒööð ~~~~]';

  @override
  String get categoryIconLocalGasStation => '[Ƒûéļ ~~]';

  @override
  String get categoryIconDirectionsBus => '[Ɓûš ~~]';

  @override
  String get categoryIconTrain => '[Ţŕåîñ ~~]';

  @override
  String get categoryIconSchool => '[Šçĥööļ ~~~]';

  @override
  String get categoryIconChildCare => '[Çĥîļð çåŕé ~~~~]';

  @override
  String get categoryIconPets => '[Þéţš ~~]';

  @override
  String get categoryIconFitnessCenter => '[Ƒîţñéšš ~~~]';

  @override
  String get categoryIconSportsEsports => '[Ĝåɱéš ~~]';

  @override
  String get categoryIconMusicNote => '[Ṁûšîç ~~]';

  @override
  String get categoryIconMenuBook => '[Ɓööķš ~~]';

  @override
  String get categoryIconPhoneIphone => '[Þĥöñé ~~]';

  @override
  String get categoryIconWifi => '[Îñţéŕñéţ ~~~~]';

  @override
  String get categoryIconBolt => '[Éļéçţŕîçîţý ~~~~~]';

  @override
  String get categoryIconWaterDrop => '[Ŵåţéŕ ~~]';

  @override
  String get categoryIconSavings => '[Šåṽîñĝš ~~~]';

  @override
  String get categoryIconCardGiftcard => '[Ĝîƒţ ~~]';

  @override
  String get categoryIconCheckroom => '[Çļöţĥîñĝ ~~~~]';

  @override
  String get categoryIconCelebration => '[Çéļéƀŕåţîöñ ~~~~~]';

  @override
  String get colorRed => '[Ŕéð ~~]';

  @override
  String get colorPink => '[Þîñķ ~~]';

  @override
  String get colorPurple => '[Þûŕþļé ~~~]';

  @override
  String get colorViolet => '[Ṽîöļéţ ~~~]';

  @override
  String get colorIndigo => '[Îñðîĝö ~~~]';

  @override
  String get colorBlue => '[Ɓļûé ~~]';

  @override
  String get colorCyan => '[Çýåñ ~~]';

  @override
  String get colorTeal => '[Ţéåļ ~~]';

  @override
  String get colorGreen => '[Ĝŕééñ ~~]';

  @override
  String get colorOrange => '[Öŕåñĝé ~~~]';

  @override
  String get colorBrown => '[Ɓŕöŵñ ~~]';

  @override
  String get colorGrey => '[Ĝŕéý ~~]';

  @override
  String legacyImported(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Îɱþöŕţéð $count éñţŕîéš îñţö “Îɱþöŕţéð”, ţöţåļļîñĝ $total. ~~~~~ ~~~~~ ~~~~~',
      one:
          'Îɱþöŕţéð 1 éñţŕý îñţö “Îɱþöŕţéð”, ţöţåļļîñĝ $total. ~~~~~ ~~~~~ ~~~~',
    );
    return '[$_temp0]';
  }

  @override
  String legacyImportSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count éñţŕîéš çöûļð ñöţ ƀé ŕéåð åñð ŵéŕé ļéƒţ îñ þļåçé. ~~~~~ ~~~~~ ~~~~~ ~',
      one: '1 éñţŕý çöûļð ñöţ ƀé ŕéåð åñð ŵåš ļéƒţ îñ þļåçé. ~~~~~ ~~~~~ ~~~~~',
    );
    return '[$_temp0]';
  }

  @override
  String get signInTitle => '[Šîĝñ îñ ~~~]';

  @override
  String get signInSubmit => '[Šîĝñ îñ ~~~]';

  @override
  String get signInSubmitting => '[Šîĝñîñĝ îñ ~~~~]';

  @override
  String get signInCreateAccount => '[Çŕéåţé åñ åççöûñţ ~~~~~ ~]';

  @override
  String get registerTitle => '[Çŕéåţé åñ åççöûñţ ~~~~~ ~]';

  @override
  String get registerSubmit => '[Çŕéåţé åççöûñţ ~~~~~ ~]';

  @override
  String get registerSubmitting => '[Çŕéåţîñĝ ýöûŕ åççöûñţ ~~~~~ ~~~]';

  @override
  String get registerHaveAccount => '[Î åļŕéåðý ĥåṽé åñ åççöûñţ ~~~~~ ~~~~]';

  @override
  String registerDeviceName(String name) {
    return '[Ţĥîš ðéṽîçé: $name ~~~~]';
  }

  @override
  String get authEmailLabel => '[Éɱåîļ ~~]';

  @override
  String get authPasswordLabel => '[Þåššŵöŕð ~~~~]';

  @override
  String get authPasswordHelper => '[8 ţö 128 çĥåŕåçţéŕš ~~~~~]';

  @override
  String get authDisplayNameLabel => '[Ñåɱé (öþţîöñåļ) ~~~~~]';

  @override
  String get authShowPassword => '[Šĥöŵ þåššŵöŕð ~~~~~]';

  @override
  String get authHidePassword => '[Ĥîðé þåššŵöŕð ~~~~~]';

  @override
  String get authEmailInvalid => '[Éñţéŕ å ṽåļîð éɱåîļ åððŕéšš ~~~~~ ~~~~~]';

  @override
  String get authPasswordRequired => '[Éñţéŕ ýöûŕ þåššŵöŕð ~~~~~ ~~]';

  @override
  String get authPasswordLength => '[Ûšé 8 ţö 128 çĥåŕåçţéŕš ~~~~~ ~]';

  @override
  String get authDisplayNameLength => '[Ûšé åţ ɱöšţ 100 çĥåŕåçţéŕš ~~~~~ ~~~]';

  @override
  String get authErrorInvalidCredentials =>
      '[Ţĥé éɱåîļ öŕ þåššŵöŕð îš îñçöŕŕéçţ. ~~~~~ ~~~~~ ~~]';

  @override
  String authErrorRateLimited(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other:
          'Ţöö ɱåñý åţţéɱþţš. Ţŕý åĝåîñ îñ $seconds šéçöñðš. ~~~~~ ~~~~~ ~~~',
      one: 'Ţöö ɱåñý åţţéɱþţš. Ţŕý åĝåîñ îñ 1 šéçöñð. ~~~~~ ~~~~~ ~~~',
    );
    return '[$_temp0]';
  }

  @override
  String get authErrorRateLimitedLater =>
      '[Ţöö ɱåñý åţţéɱþţš. Ţŕý åĝåîñ ļåţéŕ. ~~~~~ ~~~~~ ~~]';

  @override
  String get authErrorEmailTaken =>
      '[Åñ åççöûñţ ŵîţĥ ţĥîš éɱåîļ åļŕéåðý éẋîšţš. ~~~~~ ~~~~~ ~~~~]';

  @override
  String get authErrorNetwork =>
      '[Çåñ\'ţ ŕéåçĥ ţĥé šéŕṽéŕ. Çĥéçķ ýöûŕ çöññéçţîöñ åñð ţŕý åĝåîñ. ~~~~~ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get authErrorValidation =>
      '[Çĥéçķ ţĥé ĥîĝĥļîĝĥţéð ƒîéļðš åñð ţŕý åĝåîñ. ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get authErrorOtherAccount =>
      '[Ţĥîš ðéṽîçé åļŕéåðý ĥöļðš åñöţĥéŕ åççöûñţ\'š ðåţå. Šîĝñ îñ ŵîţĥ ţĥåţ åççöûñţ, öŕ éŕåšé ţĥîš ðéṽîçé\'š ðåţå ţö šţåŕţ öṽéŕ. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String get authErrorGeneric =>
      '[Šöɱéţĥîñĝ ŵéñţ ŵŕöñĝ. Ţŕý åĝåîñ. ~~~~~ ~~~~~ ~]';

  @override
  String get settingsAccount => '[Åççöûñţ ~~~]';

  @override
  String settingsSignedInAs(String email) {
    return '[Šîĝñéð îñ åš $email ~~~~]';
  }

  @override
  String get settingsSignOut => '[Šîĝñ öûţ ~~~]';

  @override
  String get settingsServer => '[Šéŕṽéŕ ~~~]';

  @override
  String get settingsServerFake => '[Îñ-åþþ ƒåķé šéŕṽéŕ ~~~~~ ~]';

  @override
  String get settingsSync => '[Šýñç ~~]';

  @override
  String get syncStatus => '[Šţåţûš ~~~]';

  @override
  String get syncSignedOut =>
      '[Šîĝñ îñ ţö šýñç ýöûŕ ðåţå ƀéţŵééñ ðéṽîçéš ~~~~~ ~~~~~ ~~~~]';

  @override
  String get syncRunning => '[Šýñçîñĝ… ~~~]';

  @override
  String get syncNever => '[Ñöţ šýñçéð ýéţ ~~~~~]';

  @override
  String syncLastAt(String time) {
    return '[Ļåšţ šýñçéð $time ~~~~]';
  }

  @override
  String get syncFailedOffline =>
      '[Ţĥé ļåšţ šýñç çöûļð ñöţ ŕéåçĥ ţĥé šéŕṽéŕ ~~~~~ ~~~~~ ~~~~]';

  @override
  String get syncFailedServer =>
      '[Ţĥé šéŕṽéŕ çöûļð ñöţ çöɱþļéţé ţĥé ļåšţ šýñç ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get syncFailedOther => '[Ţĥé ļåšţ šýñç ðîð ñöţ ƒîñîšĥ ~~~~~ ~~~~~]';

  @override
  String get syncBankData => '[Ɓåñķ ðåţå ~~~~]';

  @override
  String syncBankDataPulledAt(String time) {
    return '[Ûþðåţéð $time ~~~]';
  }

  @override
  String get syncBankDataNever => '[Ñöţ ûþðåţéð ýéţ ~~~~~ ~]';

  @override
  String get syncBankDataFailedOffline =>
      '[Ţĥé ļåšţ ûþðåţé çöûļð ñöţ ŕéåçĥ ţĥé šéŕṽéŕ ~~~~~ ~~~~~ ~~~~]';

  @override
  String get syncBankDataFailedServer =>
      '[Ţĥé šéŕṽéŕ çöûļð ñöţ çöɱþļéţé ţĥé ļåšţ ûþðåţé ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get syncBankDataFailedOther =>
      '[Ţĥé ļåšţ ûþðåţé ðîð ñöţ ƒîñîšĥ ~~~~~ ~~~~~]';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count çĥåñĝéš ŵåîţîñĝ ţö šýñç ~~~~~ ~~~',
      one: '1 çĥåñĝé ŵåîţîñĝ ţö šýñç ~~~~~ ~~~',
      zero: 'Éṽéŕý çĥåñĝé îš šýñçéð ~~~~~ ~~~',
    );
    return '[$_temp0]';
  }

  @override
  String get syncClockDrift =>
      '[Çĥéçķ ýöûŕ ðéṽîçé\'š çļöçķ: îţ îš åĥéåð, šö šöɱé çĥåñĝéš ŵåîţ ţö šýñç ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~]';

  @override
  String get syncClockBehind =>
      '[Çĥéçķ ýöûŕ ðéṽîçé\'š çļöçķ: îţ îš ƀéĥîñð, šö çĥåñĝéš ɱåðé ĥéŕé ɱåý ƀé öṽéŕŕîððéñ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String syncRejected(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count çĥåñĝéš ŵéŕé ŕéƒûšéð ƀý ţĥé šéŕṽéŕ, ţĥé ļåţéšţ ɱåðé $time ~~~~~ ~~~~~ ~~~~~ ~~',
      one:
          '1 çĥåñĝé ŵåš ŕéƒûšéð ƀý ţĥé šéŕṽéŕ, ţĥé ļåţéšţ ɱåðé $time ~~~~~ ~~~~~ ~~~~~ ~',
    );
    return '[$_temp0]';
  }

  @override
  String syncHeld(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count šýñçéð ŕéçöŕðš ţĥîš ṽéŕšîöñ öƒ ţĥé åþþ çåññöţ šĥöŵ ýéţ ~~~~~ ~~~~~ ~~~~~ ~~~',
      one: '1 šýñçéð ŕéçöŕð ţĥîš ṽéŕšîöñ öƒ ţĥé åþþ çåññöţ šĥöŵ ýéţ ~~~~~ ~~~~~ ~~~~~ ~~~',
    );
    return '[$_temp0]';
  }

  @override
  String get syncNow => '[Šýñç ñöŵ ~~~]';

  @override
  String get settingsDeveloper => '[Ðéṽéļöþéŕ ~~~~]';

  @override
  String get developerDevice => '[Ðéṽîçé ~~~]';

  @override
  String get developerDeviceNone => '[Ñöţ šîĝñéð îñ ~~~~~]';

  @override
  String get developerLastSync => '[Ļåšţ šýñç ~~~~]';

  @override
  String get developerBankData => '[Ɓåñķ ðåţå þûļļéð ~~~~~ ~]';

  @override
  String get developerNever => '[Ñéṽéŕ ~~]';

  @override
  String get developerLedger => '[Öûţƀöẋ ~~~]';

  @override
  String developerLedgerValue(int pending, int held) {
    return '[$pending ŵåîţîñĝ, $held ĥéļð ~~~~~]';
  }

  @override
  String get developerLedgerUnknown => '[Ñöţ ŕéåð ýéţ ~~~~]';

  @override
  String get developerPullNow => '[Þûļļ ñöŵ ~~~]';

  @override
  String developerPulled(String time) {
    return '[Þûļļéð; ƀåñķ ðåţå ûþðåţéð $time ~~~~~ ~~~~]';
  }

  @override
  String developerPullFailed(String error) {
    return '[Þûļļ ƒåîļéð: $error ~~~~]';
  }

  @override
  String get developerCopy => '[Çöþý ðîåĝñöšţîçš ~~~~~ ~]';

  @override
  String get developerCopied => '[Ðîåĝñöšţîçš çöþîéð ~~~~~ ~~]';

  @override
  String get developerOpenSandbox => '[Šåñðƀöẋ çöñţŕöļš ~~~~~ ~]';

  @override
  String get developerOpenSandboxDetail =>
      '[Ŕéƒŕéšĥ, ŕéšéţ ļöĝîñ, ŵéƀĥööķš, îñĵéçţéð ţŕåñšåçţîöñš, þéŕšöñå þŕöṽîšîöñîñĝ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get developerItemSection => '[Îţéɱ ~~]';

  @override
  String get developerItem => '[Îţéɱ ~~]';

  @override
  String developerItemOption(String institution, String id) {
    return '[$institution ($id)]';
  }

  @override
  String get developerNoItems =>
      '[Ñö ļîñķéð ƀåñķš ýéţ. Ļîñķ öñé, öŕ þûļļ, ƒîŕšţ. ~~~~~ ~~~~~ ~~~~]';

  @override
  String get developerRefreshTransactions => '[Ŕéƒŕéšĥ ţŕåñšåçţîöñš ~~~~~ ~~~]';

  @override
  String get developerRefreshBalances => '[Ŕéƒŕéšĥ ƀåļåñçéš ~~~~~ ~]';

  @override
  String get developerResetLogin => '[Ŕéšéţ ļöĝîñ ~~~~]';

  @override
  String get developerWebhookCode => '[Ŵéƀĥööķ çöðé ~~~~~]';

  @override
  String get developerFireWebhook => '[Ƒîŕé ŵéƀĥööķ ~~~~~]';

  @override
  String get developerRunning => '[Ŕûññîñĝ… ~~~]';

  @override
  String developerRefreshed(
    String status,
    int added,
    int modified,
    int removed,
  ) {
    return '[Ŕéƒŕéšĥ $status: $added åððéð, $modified ɱöðîƒîéð, $removed ŕéɱöṽéð ~~~~~ ~~~~~ ~]';
  }

  @override
  String developerBalancesRefreshed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ɓåļåñçéš ŕéƒŕéšĥéð ƒöŕ $count åççöûñţš ~~~~~ ~~~~~ ~~',
      one: 'Ɓåļåñçéš ŕéƒŕéšĥéð ƒöŕ 1 åççöûñţ ~~~~~ ~~~~~ ~',
    );
    return '[$_temp0]';
  }

  @override
  String get developerLoginReset =>
      '[Ļöĝîñ ŕéšéţ; ţĥé Îţéɱ ñééðš îţš çöññéçţîöñ ƒîẋéð ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get developerWebhookFired => '[Ŵéƀĥööķ ƒîŕéð ~~~~~]';

  @override
  String developerInjected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Îñĵéçţéð $count ţŕåñšåçţîöñš ~~~~~ ~~~',
      one: 'Îñĵéçţéð 1 ţŕåñšåçţîöñ ~~~~~ ~~~',
    );
    return '[$_temp0]';
  }

  @override
  String developerFailed(String error) {
    return '[Ƒåîļéð: $error ~~~]';
  }

  @override
  String developerThenPullFailed(String result, String error) {
    return '[$result; ţĥé þûļļ åƒţéŕ îţ ƒåîļéð: $error ~~~~~ ~~~]';
  }

  @override
  String get developerInjectSection => '[Îñĵéçţ ţŕåñšåçţîöñš ~~~~~ ~~~]';

  @override
  String get developerAccount => '[Åççöûñţ ~~~]';

  @override
  String get developerNoAccounts =>
      '[Ţĥîš Îţéɱ ĥåš ñö åççöûñţš öñ ţĥé ðéṽîçé ýéţ. ~~~~~ ~~~~~ ~~~~]';

  @override
  String get developerCount => '[Ĥöŵ ɱåñý (1 ţö 10) ~~~~]';

  @override
  String get developerCountInvalid =>
      '[Éñţéŕ å ŵĥöļé ñûɱƀéŕ ƒŕöɱ 1 ţö 10 ~~~~~ ~~~~~]';

  @override
  String get developerDescription => '[Ðéšçŕîþţîöñ ~~~~~]';

  @override
  String get developerDescriptionDefault => '[Ðéṽéļöþéŕ ţéšţ ~~~~~ ~]';

  @override
  String get developerDescriptionInvalid =>
      '[Éñţéŕ 1 ţö 196 çĥåŕåçţéŕš ~~~~~ ~~]';

  @override
  String get developerAmount => '[Åɱöûñţ ~~~]';

  @override
  String get developerAmountHelper =>
      '[Ñéĝåţîṽé îš ɱöñéý öûţ öƒ ţĥé åççöûñţ ~~~~~ ~~~~~ ~~]';

  @override
  String get developerDaysBack =>
      '[Ðåýš ƀéƒöŕé Þļåîð\'š ţöðåý (0 ţö 728) ~~~~~ ~~~~~]';

  @override
  String get developerDaysBackInvalid =>
      '[Éñţéŕ å ŵĥöļé ñûɱƀéŕ ƒŕöɱ 0 ţö 728 ~~~~~ ~~~~~]';

  @override
  String developerDate(String date) {
    return '[Ðåţéð $date ~~]';
  }

  @override
  String get developerInject => '[Îñĵéçţ ~~~]';

  @override
  String get developerProvisionSection => '[Þŕöṽîšîöñ å þéŕšöñå ~~~~~ ~~]';

  @override
  String get developerPersona => '[Þéŕšöñå ~~~]';

  @override
  String get developerSeed => '[Šééð ~~]';

  @override
  String get developerSeedInvalid =>
      '[Éñţéŕ å ŵĥöļé ñûɱƀéŕ öƒ åţ ļéåšţ 1 ~~~~~ ~~~~~ ~]';

  @override
  String get developerDays => '[Ðåýš öƒ ĥîšţöŕý (30 ţö 730) ~~~~~ ~]';

  @override
  String get developerDaysInvalid =>
      '[Éñţéŕ å ŵĥöļé ñûɱƀéŕ ƒŕöɱ 30 ţö 730 ~~~~~ ~~~~~]';

  @override
  String get developerProvision => '[Šţåŕţ ~~]';

  @override
  String developerJobStatus(String status) {
    return '[Ĵöƀ $status ~~]';
  }

  @override
  String developerJobItems(int linked, int total) {
    return '[Îţéɱš ļîñķéð: $linked öƒ $total ~~~~~ ~]';
  }

  @override
  String developerJobBatches(int sent, int total) {
    return '[Ɓåţçĥéš šéñţ: $sent öƒ $total ~~~~~ ~]';
  }

  @override
  String developerJobSkipped(int count) {
    return '[Ţŕåñšåçţîöñš šķîþþéð: $count ~~~~~ ~~~]';
  }

  @override
  String developerJobError(String error) {
    return '[Éŕŕöŕ: $error ~~]';
  }

  @override
  String get developerJobProgress => '[Þŕöṽîšîöñîñĝ þŕöĝŕéšš ~~~~~ ~~~]';

  @override
  String get settingsDemoData => '[Ðéɱö ðåţå ~~~~]';

  @override
  String get demoDataNote =>
      '[Çĥööšîñĝ åñöţĥéŕ ĥöûšéĥöļð šţåŕţš ţĥé ðéɱö öṽéŕ; çĥåñĝéš ɱåðé îñ ţĥé ðéɱö åŕé ñöţ ķéþţ. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~]';

  @override
  String get demoPersonaRenter => '[Ŕéñţéŕ ~~~]';

  @override
  String get demoPersonaRenterDetail =>
      '[Ĝîĝ îñçöɱé, šûƀšçŕîþţîöñš åñð å çŕéðîţ çåŕð ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get demoPersonaFamily => '[Ƒåɱîļý ~~~]';

  @override
  String get demoPersonaFamilyDetail =>
      '[Ţŵö šåļåŕîéš, å ɱöŕţĝåĝé, çåŕ ļöåñš åñð å 401(ķ) ~~~~~ ~~~~~ ~~~~]';

  @override
  String get demoPersonaStudent => '[Šţûðéñţ ~~~]';

  @override
  String get demoPersonaStudentDetail =>
      '[Šţûðéñţ ļöåñš, å çåɱþûš ĵöƀ åñð ĥéļþ ƒŕöɱ å þåŕéñţ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get demoPersonaSmallBusiness => '[Šɱåļļ ƀûšîñéšš öŵñéŕ ~~~~~ ~~~]';

  @override
  String get demoPersonaSmallBusinessDetail =>
      '[Ɓûšîñéšš åñð þéŕšöñåļ åççöûñţš, åñð ǫûåŕţéŕļý ţåẋéš ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String get itemsTitle => '[Ļîñķéð ƀåñķš ~~~~~]';

  @override
  String get itemsLink => '[Ļîñķ å ƀåñķ ~~~~]';

  @override
  String get itemsEmptyHeadline => '[Ñö ļîñķéð ƀåñķš ~~~~~ ~]';

  @override
  String get itemsEmptyBody =>
      '[Ļîñķ å ƀåñķ ţö šéé îţš åççöûñţš åñð ţŕåñšåçţîöñš ĥéŕé. ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String get itemsStatusConnected => '[Çöññéçţéð ~~~~]';

  @override
  String get itemsStatusNeedsAttention => '[Ñééðš åţţéñţîöñ ~~~~~ ~]';

  @override
  String get itemsStatusError => '[Éŕŕöŕ ~~]';

  @override
  String get itemsStatusUnlinked => '[Ûñļîñķéð ~~~~]';

  @override
  String itemsStatusLabel(String status) {
    return '[Šţåţûš: $status ~~~]';
  }

  @override
  String itemsLastSynced(String time) {
    return '[Ļåšţ šýñçéð $time ~~~~]';
  }

  @override
  String get itemsNeverSynced => '[Ñöţ šýñçéð ýéţ ~~~~~]';

  @override
  String get itemsSyncNow => '[Šýñç ñöŵ ~~~]';

  @override
  String get itemsFix => '[Ƒîẋ çöññéçţîöñ ~~~~~ ~]';

  @override
  String get itemsUnlink => '[Ûñļîñķ ~~~]';

  @override
  String get itemsStepLinking => '[Öþéñîñĝ Þļåîð Ļîñķ… ~~~~~ ~~]';

  @override
  String get itemsStepExchanging => '[Çöññéçţîñĝ ýöûŕ ƀåñķ… ~~~~~ ~~~]';

  @override
  String get itemsStepSyncing => '[Ŵåîţîñĝ ƒöŕ ýöûŕ ƀåñķ\'š ðåţå… ~~~~~ ~~~~~]';

  @override
  String get itemsStepPulling => '[Ûþðåţîñĝ ýöûŕ åççöûñţš… ~~~~~ ~~~]';

  @override
  String get itemsStepUnlinking => '[Ûñļîñķîñĝ… ~~~~]';

  @override
  String get itemsFailedOffline =>
      '[Çöûļðñ\'ţ ŕéåçĥ ţĥé šéŕṽéŕ. Ţŕý åĝåîñ ŵĥéñ ýöû\'ŕé öñļîñé. ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String get itemsFailedLoginRequired =>
      '[Ýöûŕ ƀåñķ ñééðš ýöû ţö šîĝñ îñ åĝåîñ. Ûšé Ƒîẋ çöññéçţîöñ. ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String get itemsFailedRateLimited =>
      '[Ţöö ɱåñý ŕéǫûéšţš. Ţŕý åĝåîñ îñ å ɱîñûţé. ~~~~~ ~~~~~ ~~~]';

  @override
  String get itemsFailedNotFound =>
      '[Ţĥîš ƀåñķ îš ñö ļöñĝéŕ ļîñķéð. ~~~~~ ~~~~~]';

  @override
  String get itemsFailedPlaid =>
      '[Þļåîð çöûļðñ\'ţ çöɱþļéţé ţĥé ŕéǫûéšţ. Ţŕý åĝåîñ ļåţéŕ. ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String get itemsFailedOther =>
      '[Šöɱéţĥîñĝ ŵéñţ ŵŕöñĝ. Ţŕý åĝåîñ. ~~~~~ ~~~~~ ~]';

  @override
  String get itemsFailedLink =>
      '[Þļåîð Ļîñķ çļöšéð ŵîţĥ åñ éŕŕöŕ. ~~~~~ ~~~~~ ~]';

  @override
  String get itemsStillPreparing =>
      '[Ýöûŕ ƀåñķ îš šţîļļ þŕéþåŕîñĝ ýöûŕ ðåţå. Ûšé Šýñç ñöŵ îñ å ɱîñûţé. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String itemsUnlinkTitle(String institution) {
    return '[Ûñļîñķ $institution? ~~~]';
  }

  @override
  String get itemsUnlinkKeep =>
      '[Ķééþ ĥîšţöŕý öñ ţĥîš ðéṽîçé åñð öţĥéŕš ~~~~~ ~~~~~ ~~~]';

  @override
  String get itemsUnlinkKeepDetail =>
      '[Îţš åççöûñţš åñð ţŕåñšåçţîöñš šţåý öñ éṽéŕý ðéṽîçé, ñö ļöñĝéŕ ûþðåţéð. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~]';

  @override
  String get itemsUnlinkDelete =>
      '[Ðéļéţé îţš åççöûñţš åñð ţŕåñšåçţîöñš ~~~~~ ~~~~~ ~~~]';

  @override
  String get itemsUnlinkDeleteDetail =>
      '[Ţĥéý åŕé ŕéɱöṽéð ƒŕöɱ ţĥîš ðéṽîçé åñð éṽéŕý öţĥéŕ ðéṽîçé šîĝñéð îñ ţö ýöûŕ åççöûñţ. Ýöûŕ öŵñ ñöţéš åñð çåţéĝöŕîéš öñ ţĥéɱ ĝö ţöö. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~]';

  @override
  String get itemsUnlinkConfirm => '[Ûñļîñķ ~~~]';

  @override
  String itemsSyncNowLabel(String institution) {
    return '[Šýñç ñöŵ, $institution ~~~]';
  }

  @override
  String itemsFixLabel(String institution) {
    return '[Ƒîẋ çöññéçţîöñ, $institution ~~~~~ ~]';
  }

  @override
  String itemsUnlinkLabel(String institution) {
    return '[Ûñļîñķ, $institution ~~~]';
  }

  @override
  String get itemsDeleteHistory => '[Ðéļéţé ĥîšţöŕý ~~~~~ ~]';

  @override
  String itemsDeleteHistoryLabel(String institution) {
    return '[Ðéļéţé ĥîšţöŕý, $institution ~~~~~ ~]';
  }

  @override
  String itemsDeleteHistoryTitle(String institution) {
    return '[Ðéļéţé ţĥé ĥîšţöŕý öƒ $institution? ~~~~~ ~~~]';
  }

  @override
  String get itemsDeleteHistoryBody =>
      '[Îţš åççöûñţš åñð ţŕåñšåçţîöñš åŕé ŕéɱöṽéð ƒŕöɱ ţĥîš ðéṽîçé åñð éṽéŕý öţĥéŕ ðéṽîçé šîĝñéð îñ ţö ýöûŕ åççöûñţ. Ýöûŕ öŵñ ñöţéš åñð çåţéĝöŕîéš öñ ţĥéɱ ĝö ţöö. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get itemsDeleteHistoryConfirm => '[Ðéļéţé ~~~]';

  @override
  String get itemsStepDeletingHistory => '[Ðéļéţîñĝ îţš ĥîšţöŕý… ~~~~~ ~~~]';

  @override
  String get itemsFailedServer =>
      '[Ţĥé šéŕṽéŕ çöûļð ñöţ çöɱþļéţé ţĥé ŕéǫûéšţ. Ţŕý åĝåîñ ļåţéŕ. ~~~~~ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get transactionMoreOptions => '[Ṁöŕé öþţîöñš ~~~~~]';

  @override
  String get transactionRunRules =>
      '[Ŕûñ ŕûļéš öñ ţĥîš ţŕåñšåçţîöñ ~~~~~ ~~~~~]';

  @override
  String transactionRulesApplied(String name) {
    return '[Åþþļîéð ţĥé ŕûļé “$name”. Šåṽé ţö ķééþ îţ. ~~~~~ ~~~~~ ~]';
  }

  @override
  String transactionRulesUnchanged(String name) {
    return '[Ţĥé ŕûļé “$name” ɱåţçĥéš, ƀûţ ĥåš ñöţĥîñĝ ţö çĥåñĝé. ~~~~~ ~~~~~ ~~~~]';
  }

  @override
  String get transactionRulesNoMatch =>
      '[Ñö ŕûļé ɱåţçĥéš ţĥîš ţŕåñšåçţîöñ. ~~~~~ ~~~~~ ~~]';

  @override
  String get rulesTitle => '[Ŕûļéš ~~]';

  @override
  String get rulesEmptyHeadline => '[Ñö ŕûļéš ýéţ ~~~~]';

  @override
  String get rulesEmptyBody =>
      '[Å ŕûļé ƒîļéš, ţåĝš öŕ ŕéñåɱéš ţŕåñšåçţîöñš åš ţĥéý åŕŕîṽé ƒŕöɱ ýöûŕ ƀåñķ. Ŕûļéš åŕé ţŕîéð ƒŕöɱ ţĥé ţöþ; ţĥé ƒîŕšţ öñé ţĥåţ ɱåţçĥéš åþþļîéš. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get rulesOrderNote =>
      '[Ŕûļéš åŕé ţŕîéð ƒŕöɱ ţĥé ţöþ; ţĥé ƒîŕšţ öñé ţĥåţ ɱåţçĥéš å ţŕåñšåçţîöñ åþþļîéš. Ðŕåĝ ţö ŕéöŕðéŕ. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get ruleAdd => '[Åðð ŕûļé ~~~]';

  @override
  String get ruleNewTitle => '[Ñéŵ ŕûļé ~~~]';

  @override
  String get ruleEditTitle => '[Éðîţ ŕûļé ~~~~]';

  @override
  String get ruleNotFound => '[Ţĥîš ŕûļé ñö ļöñĝéŕ éẋîšţš. ~~~~~ ~~~~]';

  @override
  String get ruleName => '[Ñåɱé ~~]';

  @override
  String get ruleNameRequired => '[Éñţéŕ å ñåɱé ~~~~]';

  @override
  String get ruleConditionsHeader =>
      '[Ŵĥéñ å ţŕåñšåçţîöñ ɱåţçĥéš åļļ öƒ ţĥéšé ~~~~~ ~~~~~ ~~~~]';

  @override
  String get ruleActionsHeader => '[Ţĥéñ ~~]';

  @override
  String get ruleAddCondition => '[Åðð çöñðîţîöñ ~~~~~]';

  @override
  String get ruleAddAction => '[Åðð åçţîöñ ~~~~]';

  @override
  String get ruleNeedsCondition =>
      '[Å ŕûļé ñééðš åţ ļéåšţ öñé çöñðîţîöñ. ~~~~~ ~~~~~ ~~]';

  @override
  String get ruleNeedsAction =>
      '[Å ŕûļé ñééðš åţ ļéåšţ öñé åçţîöñ. ~~~~~ ~~~~~ ~]';

  @override
  String get ruleRemoveCondition => '[Ŕéɱöṽé çöñðîţîöñ ~~~~~ ~]';

  @override
  String get ruleRemoveAction => '[Ŕéɱöṽé åçţîöñ ~~~~~]';

  @override
  String get ruleConditionMerchant =>
      '[Ṁéŕçĥåñţ öŕ ðéšçŕîþţîöñ çöñţåîñš ~~~~~ ~~~~~ ~~]';

  @override
  String get ruleConditionAmount => '[Åɱöûñţ ƀéţŵééñ ~~~~~ ~]';

  @override
  String get ruleConditionAccount => '[Åççöûñţ îš ~~~~]';

  @override
  String get ruleConditionBankCategory => '[Ɓåñķ çåţéĝöŕý îš ~~~~~ ~]';

  @override
  String get ruleText => '[Ţéẋţ ~~]';

  @override
  String get ruleTextRequired => '[Éñţéŕ šöɱé ţéẋţ ~~~~~ ~]';

  @override
  String get ruleAmountRequired => '[Éñţéŕ åţ ļéåšţ öñé åɱöûñţ ~~~~~ ~~~~]';

  @override
  String get ruleAmountOrder =>
      '[Ţĥé ɱîñîɱûɱ îš åƀöṽé ţĥé ɱåẋîɱûɱ ~~~~~ ~~~~~ ~]';

  @override
  String get ruleAccountRequired => '[Çĥööšé åñ åççöûñţ ~~~~~ ~]';

  @override
  String get ruleCategoryRequired => '[Çĥööšé å çåţéĝöŕý ~~~~~ ~]';

  @override
  String get ruleActionSetCategory => '[Šéţ ţĥé çåţéĝöŕý ~~~~~ ~]';

  @override
  String get ruleActionSetCategoryCaption =>
      '[Öñļý ƒöŕ ţŕåñšåçţîöñš ŵîţĥöûţ å çåţéĝöŕý öƒ ýöûŕ öŵñ. ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String get ruleActionAddTag => '[Åðð å ţåĝ ~~~]';

  @override
  String get ruleTag => '[Ţåĝ ~~]';

  @override
  String get ruleTagRequired => '[Éñţéŕ å ţåĝ ~~~~]';

  @override
  String get ruleActionRename => '[Ŕéñåɱé ~~~]';

  @override
  String get ruleNewDescription => '[Ñéŵ ðéšçŕîþţîöñ ~~~~~ ~]';

  @override
  String get ruleNewDescriptionRequired =>
      '[Éñţéŕ ţĥé ñéŵ ðéšçŕîþţîöñ ~~~~~ ~~~~]';

  @override
  String get ruleActionRenameCaption =>
      '[Ŕéñåɱéš ɱåñûåļ åñð îɱþöŕţéð ţŕåñšåçţîöñš. Ɓåñķ ţŕåñšåçţîöñš ķééþ ţĥé ðéšçŕîþţîöñ ýöûŕ ƀåñķ šéñðš. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~]';

  @override
  String get ruleActionHide => '[Ĥîðé ~~]';

  @override
  String get ruleActionHideCaption =>
      '[Ĥîððéñ ţŕåñšåçţîöñš ļéåṽé ţĥé ļîšţ, ƀûðĝéţš åñð ŕéþöŕţš, åñð šţîļļ çöûñţ ţöŵåŕð ţĥéîŕ åççöûñţ\'š ƀåļåñçé. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get ruleChooseCategory => '[Çĥööšé å çåţéĝöŕý ~~~~~ ~]';

  @override
  String get ruleDeleted => '[Ŕûļé ðéļéţéð ~~~~~]';

  @override
  String ruleDeleteNamed(String name) {
    return '[Ðéļéţé “$name” ~~~]';
  }

  @override
  String ruleReorderNamed(String name) {
    return '[Ðŕåĝ ţö ŕéöŕðéŕ “$name” ~~~~~ ~]';
  }

  @override
  String ruleConditionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count çöñðîţîöñš ~~~~',
      one: '1 çöñðîţîöñ ~~~~',
    );
    return '[$_temp0]';
  }

  @override
  String ruleActionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count åçţîöñš ~~~',
      one: '1 åçţîöñ ~~~',
    );
    return '[$_temp0]';
  }

  @override
  String ruleSummary(String conditions, String actions) {
    return '[$conditions · $actions]';
  }

  @override
  String get ruleReorderFailed =>
      '[Ţĥé ŕûļéš çöûļð ñöţ ƀé ŕéöŕðéŕéð. ~~~~~ ~~~~~ ~]';

  @override
  String get categoriesMoreOptions => '[Ṁöŕé öþţîöñš ~~~~~]';

  @override
  String get budgetsEmptyHeadline => '[Ñö ƀûðĝéţš ýéţ ~~~~~]';

  @override
  String get budgetsEmptyBody =>
      '[Å ƀûðĝéţ šéţš ĥöŵ ɱûçĥ ţö šþéñð öñ å çåţéĝöŕý éåçĥ ɱöñţĥ åñð šĥöŵš ĥöŵ ƒåŕ åļöñĝ ýöû åŕé. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String get budgetAdd => '[Åðð ƀûðĝéţ ~~~~]';

  @override
  String get budgetPeriodPrevious => '[Þŕéṽîöûš þéŕîöð ~~~~~ ~]';

  @override
  String get budgetPeriodNext => '[Ñéẋţ þéŕîöð ~~~~]';

  @override
  String get budgetPeriodCurrent => '[Ţĥîš þéŕîöð ~~~~]';

  @override
  String budgetPeriodsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count þéŕîöðš åĝö ~~~~',
      one: 'Ļåšţ þéŕîöð ~~~~',
    );
    return '[$_temp0]';
  }

  @override
  String budgetPeriodsAhead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Îñ $count þéŕîöðš ~~~~',
      one: 'Ñéẋţ þéŕîöð ~~~~',
    );
    return '[$_temp0]';
  }

  @override
  String budgetPeriodRange(String start, String end) {
    return '[$start – $end]';
  }

  @override
  String budgetPeriodShown(String period) {
    return '[Šĥöŵîñĝ $period ~~~]';
  }

  @override
  String get budgetDeletedCategory => '[Ðéļéţéð çåţéĝöŕý ~~~~~ ~]';

  @override
  String budgetGroupIncludes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Îñçļûðéš $count çåţéĝöŕîéš ~~~~~ ~~~',
      one: 'Îñçļûðéš 1 çåţéĝöŕý ~~~~~ ~~',
    );
    return '[$_temp0]';
  }

  @override
  String budgetAmountCarried(String amount, String carry) {
    return '[$amount + $carry çåŕŕîéð ~~~]';
  }

  @override
  String budgetAmountDeficit(String amount, String carry) {
    return '[$amount − $carry çåŕŕîéð ~~~]';
  }

  @override
  String budgetPercent(int percent) {
    return '[$percent %]';
  }

  @override
  String get budgetNothingAvailable => '[Ñöţĥîñĝ åṽåîļåƀļé ~~~~~ ~~]';

  @override
  String budgetSpent(String amount) {
    return '[$amount šþéñţ ~~]';
  }

  @override
  String budgetLeft(String amount) {
    return '[$amount ļéƒţ ~~]';
  }

  @override
  String budgetOver(String amount) {
    return '[$amount öṽéŕ ~~]';
  }

  @override
  String budgetOnPace(String amount) {
    return '[Öñ þåçé: åƀöûţ $amount ƀý ţĥé éñð ~~~~~ ~~~]';
  }

  @override
  String budgetProjectedOver(String amount) {
    return '[Þŕöĵéçţéð öṽéŕ ƀý $amount ~~~~~ ~]';
  }

  @override
  String budgetAvailable(String amount) {
    return '[$amount åṽåîļåƀļé ~~~~]';
  }

  @override
  String budgetThresholdReached(int percent) {
    return '[$percent % ŕéåçĥéð ~~~]';
  }

  @override
  String budgetProgressSemantics(
    String name,
    int percent,
    String available,
    String remaining,
  ) {
    return '[$name: $percent þéŕçéñţ öƒ $available šþéñţ, $remaining ļéƒţ ~~~~~ ~~~]';
  }

  @override
  String budgetProgressOverSemantics(
    String name,
    int percent,
    String available,
    String over,
  ) {
    return '[$name: $percent þéŕçéñţ öƒ $available šþéñţ, $over öṽéŕ ~~~~~ ~~~]';
  }

  @override
  String budgetProgressNothingSemantics(String name, String spent) {
    return '[$name: $spent šþéñţ, ñöţĥîñĝ åṽåîļåƀļé ~~~~~ ~~~~]';
  }

  @override
  String get budgetNewTitle => '[Ñéŵ ƀûðĝéţ ~~~~]';

  @override
  String get budgetEditTitle => '[Éðîţ ƀûðĝéţ ~~~~]';

  @override
  String get budgetNotFound => '[Ţĥîš ƀûðĝéţ ñö ļöñĝéŕ éẋîšţš. ~~~~~ ~~~~~]';

  @override
  String get budgetDeleted => '[Ɓûðĝéţ ðéļéţéð ~~~~~ ~]';

  @override
  String get budgetCategory => '[Çåţéĝöŕý ~~~~]';

  @override
  String get budgetChooseCategory => '[Çĥööšé å çåţéĝöŕý ~~~~~ ~]';

  @override
  String get budgetCategoryCaption =>
      '[Å çåţéĝöŕý ŵîţĥ çåţéĝöŕîéš ûñðéŕ îţ ƀûðĝéţš îţš ŵĥöļé ĝŕöûþ. ~~~~~ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get budgetAmount => '[Åɱöûñţ þéŕ þéŕîöð ~~~~~ ~]';

  @override
  String get budgetStartDay => '[Þéŕîöð šţåŕţš öñ ðåý ~~~~~ ~~]';

  @override
  String get budgetStartDayHelper =>
      '[1 ţö 28: éåçĥ þéŕîöð šţåŕţš öñ ţĥîš ðåý öƒ ţĥé ɱöñţĥ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get budgetStartDayInvalid => '[Éñţéŕ å ðåý ƒŕöɱ 1 ţö 28 ~~~~~ ~]';

  @override
  String get budgetRollover => '[Çåŕŕý öṽéŕ ~~~~]';

  @override
  String get budgetRolloverCaption =>
      '[Ŵĥåţ îš ļéƒţ åţ ţĥé éñð öƒ å þéŕîöð, öŕ öṽéŕšþéñţ, çåŕŕîéš îñţö ţĥé ñéẋţ. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String get budgetStartDate => '[Ƒîŕšţ þéŕîöð ~~~~~]';

  @override
  String get budgetStartDateCaption =>
      '[Çåŕŕý-öṽéŕ çöûñţš ƒŕöɱ ţĥîš þéŕîöð. Îţ çåñ šţåŕţ éåŕļîéŕ, ƀûţ ñö ļåţéŕ ţĥåñ ţĥé çûŕŕéñţ þéŕîöð. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get budgetTransactionsEmpty =>
      '[Ñöţĥîñĝ çöûñţéð îñ ţĥîš þéŕîöð ~~~~~ ~~~~~ ~]';

  @override
  String alertsTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Åļéŕţš, $count ûñŕéåð ~~~~~',
      one: 'Åļéŕţš, 1 ûñŕéåð ~~~~~',
      zero: 'Åļéŕţš ~~~',
    );
    return '[$_temp0]';
  }

  @override
  String get alertsTitle => '[Åļéŕţš ~~~]';

  @override
  String get alertsMarkAllRead => '[Ṁåŕķ åļļ ŕéåð ~~~~~]';

  @override
  String get alertsEmpty =>
      '[Ñö åļéŕţš ýéţ. Å ƀûðĝéţ åļéŕţš ýöû ŵĥéñ îţš šþéñðîñĝ ŕéåçĥéš 80 % åñð 100 %. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get alertUnread => '[Ûñŕéåð ~~~]';

  @override
  String alertBudgetThreshold(
    String category,
    int percent,
    String available,
    String date,
  ) {
    return '[$category ŕéåçĥéð $percent % öƒ $available öñ $date ~~~~~]';
  }

  @override
  String get transactionHidden => '[Ĥîððéñ ~~~]';

  @override
  String get transactionHiddenOption => '[Ĥîððéñ ~~~]';

  @override
  String get transactionSelect => '[Šéļéçţ ~~~]';

  @override
  String get transactionSplitLabel => '[Šþļîţ ~~]';

  @override
  String transactionSplitAcross(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Šþļîţ åçŕöšš $count çåţéĝöŕîéš ~~~~~ ~~~~',
      one: 'Šþļîţ åçŕöšš 1 çåţéĝöŕý ~~~~~ ~~~',
    );
    return '[$_temp0]';
  }

  @override
  String get splitsTitle => '[Šþļîţš ~~~]';

  @override
  String get splitAdd => '[Åðð šþļîţ ~~~~]';

  @override
  String get splitRemove => '[Ŕéɱöṽé šþļîţ ~~~~~]';

  @override
  String get splitDistribute => '[Ðîšţŕîƀûţé éṽéñļý ~~~~~ ~~]';

  @override
  String get splitAmount => '[Šþļîţ åɱöûñţ ~~~~~]';

  @override
  String get splitChooseCategory => '[Çĥööšé å çåţéĝöŕý ~~~~~ ~]';

  @override
  String get splitCategoryRequired =>
      '[Çĥööšé å çåţéĝöŕý ƒöŕ éṽéŕý šþļîţ ~~~~~ ~~~~~ ~~]';

  @override
  String splitUnallocated(String amount) {
    return '[Ûñåļļöçåţéð $amount ~~~~~]';
  }

  @override
  String splitOverAllocated(String amount) {
    return '[Öṽéŕ ƀý $amount ~~~]';
  }

  @override
  String splitMustBalance(String amount) {
    return '[Šþļîţš ɱûšţ åðð ûþ ţö $amount ~~~~~ ~~]';
  }

  @override
  String get receiptTitle => '[Ŕéçéîþţ ~~~]';

  @override
  String get receiptTakePhoto => '[Ţåķé þĥöţö ~~~~]';

  @override
  String get receiptChoosePhoto => '[Çĥööšé þĥöţö ~~~~~]';

  @override
  String get receiptReplace => '[Ŕéþļåçé ~~~]';

  @override
  String get receiptReplaceLabel => '[Ŕéþļåçé ŕéçéîþţ ~~~~~ ~]';

  @override
  String get receiptRemove => '[Ŕéɱöṽé ŕéçéîþţ ~~~~~ ~]';

  @override
  String get receiptImage => '[Ŕéçéîþţ îɱåĝé ~~~~~]';

  @override
  String get receiptOpenHint => '[öþéñ ţĥé ŕéçéîþţ ƒûļļ šçŕééñ ~~~~~ ~~~~~]';

  @override
  String get receiptMissing => '[Ŕéçéîþţ ķéþţ öñ åñöţĥéŕ ðéṽîçé ~~~~~ ~~~~~ ~]';

  @override
  String get receiptNoCamera => '[Ñö çåɱéŕå îš åṽåîļåƀļé ~~~~~ ~~~]';

  @override
  String get receiptPickFailed => '[Ţĥåţ îɱåĝé çåñ\'ţ ƀé ûšéð ~~~~~ ~~~]';

  @override
  String get receiptSaveFailed =>
      '[Ţĥé ŕéçéîþţ çöûļð ñöţ ƀé šåṽéð ~~~~~ ~~~~~]';

  @override
  String get filterShowHidden => '[Šĥöŵ ĥîððéñ ~~~~]';

  @override
  String get filterShowHiddenCaption =>
      '[Ĥîððéñ ţŕåñšåçţîöñš šţîļļ çöûñţ ţöŵåŕð ţĥéîŕ åççöûñţ\'š ƀåļåñçé. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~]';

  @override
  String get filterIncludingHidden => '[Îñçļûðîñĝ ĥîððéñ ~~~~~ ~]';

  @override
  String transactionsSelected(int count) {
    return '[$count šéļéçţéð ~~~~]';
  }

  @override
  String get selectionCancel => '[Çåñçéļ šéļéçţîöñ ~~~~~ ~]';

  @override
  String get selectAll => '[Šéļéçţ åļļ ~~~~]';

  @override
  String get bulkSetCategory => '[Šéţ çåţéĝöŕý ~~~~~]';

  @override
  String get bulkAddTag => '[Åðð ţåĝ ~~~]';

  @override
  String get bulkTagLabel => '[Ţåĝ ~~]';

  @override
  String get bulkTagAdd => '[Åðð ~~]';

  @override
  String get bulkHide => '[Ĥîðé ~~]';

  @override
  String get bulkUnhide => '[Ûñĥîðé ~~~]';

  @override
  String bulkCategorySet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Çåţéĝöŕý šéţ öñ $count ţŕåñšåçţîöñš ~~~~~ ~~~~~',
      one: 'Çåţéĝöŕý šéţ öñ 1 ţŕåñšåçţîöñ ~~~~~ ~~~~~',
    );
    return '[$_temp0]';
  }

  @override
  String bulkTagAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ţåĝ åððéð ţö $count ţŕåñšåçţîöñš ~~~~~ ~~~~',
      one: 'Ţåĝ åððéð ţö 1 ţŕåñšåçţîöñ ~~~~~ ~~~~',
    );
    return '[$_temp0]';
  }

  @override
  String bulkHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ţŕåñšåçţîöñš ĥîððéñ ~~~~~ ~~~',
      one: '1 ţŕåñšåçţîöñ ĥîððéñ ~~~~~ ~~',
    );
    return '[$_temp0]';
  }

  @override
  String bulkUnhidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ţŕåñšåçţîöñš ûñĥîððéñ ~~~~~ ~~~',
      one: '1 ţŕåñšåçţîöñ ûñĥîððéñ ~~~~~ ~~~',
    );
    return '[$_temp0]';
  }

  @override
  String bulkDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ţŕåñšåçţîöñš ðéļéţéð ~~~~~ ~~~',
      one: '1 ţŕåñšåçţîöñ ðéļéţéð ~~~~~ ~~~',
    );
    return '[$_temp0]';
  }

  @override
  String bulkDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ðéļéţé $count ţŕåñšåçţîöñš? ~~~~~ ~~~',
      one: 'Ðéļéţé 1 ţŕåñšåçţîöñ? ~~~~~ ~~',
    );
    return '[$_temp0]';
  }

  @override
  String get bulkDeleteBody =>
      '[Ţĥéý ļéåṽé éṽéŕý ļîšţ åñð ţĥéîŕ åççöûñţš\' ƀåļåñçéš. ~~~~~ ~~~~~ ~~~~~ ~~]';

  @override
  String get bulkFailed =>
      '[Ñöţĥîñĝ çĥåñĝéð: ţĥé ţŕåñšåçţîöñš çöûļð ñöţ ƀé ûþðåţéð. ~~~~~ ~~~~~ ~~~~~ ~~~~]';

  @override
  String get bulkFailedDeleted =>
      '[Ñöţĥîñĝ çĥåñĝéð: öñé öƒ ţĥé ţŕåñšåçţîöñš ŵåš ðéļéţéð ɱéåñŵĥîļé. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~]';

  @override
  String rulePreviewCount(int changed, int total) {
    final intl.NumberFormat changedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String changedString = changedNumberFormat.format(changed);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other:
          'Ŵöûļð çĥåñĝé $changedString öƒ $totalString ţŕåñšåçţîöñš ~~~~~ ~~~~~',
      one: 'Ŵöûļð çĥåñĝé $changedString öƒ 1 ţŕåñšåçţîöñ ~~~~~ ~~~~~',
    );
    return '[$_temp0]';
  }

  @override
  String get rulePreviewIncomplete =>
      '[Ƒîñîšĥ ţĥé çöñðîţîöñš åñð åçţîöñš ţö šéé ŵĥåţ ţĥîš ŕûļé ŵöûļð çĥåñĝé. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String get rulePreviewChecking => '[Çĥéçķîñĝ ýöûŕ ţŕåñšåçţîöñš… ~~~~~ ~~~~~]';

  @override
  String get rulePreviewOpen => '[Þŕéṽîéŵ ~~~]';

  @override
  String get rulePreviewTitle => '[Ŵĥåţ ţĥîš ŕûļé ŵöûļð çĥåñĝé ~~~~~ ~~~~~]';

  @override
  String rulePreviewMore(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ɱöŕé ţŕåñšåçţîöñš ñöţ šĥöŵñ ~~~~~ ~~~~~',
      one: '1 ɱöŕé ţŕåñšåçţîöñ ñöţ šĥöŵñ ~~~~~ ~~~~~',
    );
    return '[$_temp0]';
  }

  @override
  String rulePreviewCategory(String before, String after) {
    return '[Çåţéĝöŕý: $before → $after ~~~~]';
  }

  @override
  String rulePreviewTag(String tag) {
    return '[Ţåĝ åððéð: $tag ~~~~]';
  }

  @override
  String rulePreviewName(String before, String after) {
    return '[Ðéšçŕîþţîöñ: $before → $after ~~~~~]';
  }

  @override
  String get rulePreviewHidden => '[Ĥîððéñ ~~~]';

  @override
  String get ruleApplyToHistory =>
      '[Åþþļý ţö éẋîšţîñĝ ţŕåñšåçţîöñš ~~~~~ ~~~~~ ~]';

  @override
  String get ruleApplySaveFirst => '[Šåṽé ţĥé ŕûļé ƒîŕšţ ~~~~~ ~~]';

  @override
  String ruleApplyTitle(String name) {
    return '[Åþþļý “$name” ţö éẋîšţîñĝ ţŕåñšåçţîöñš? ~~~~~ ~~~~~ ~]';
  }

  @override
  String get ruleApplyBody =>
      '[Ţĥé ŕûļé çĥåñĝéš ţĥé ţŕåñšåçţîöñš îţ ɱåţçĥéš ñöŵ, åš îţ ŵöûļð ñéŵ öñéš. Çåţéĝöŕîéš åñð ţåĝš ýöû ĥåṽé šéţ šţåý åš ţĥéý åŕé. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~]';

  @override
  String get ruleApplyConfirm => '[Åþþļý ~~]';

  @override
  String ruleApplied(
    int count,
    int filed,
    int tagged,
    int renamed,
    int hidden,
  ) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat filedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String filedString = filedNumberFormat.format(filed);
    final intl.NumberFormat taggedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String taggedString = taggedNumberFormat.format(tagged);
    final intl.NumberFormat renamedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String renamedString = renamedNumberFormat.format(renamed);
    final intl.NumberFormat hiddenNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String hiddenString = hiddenNumberFormat.format(hidden);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$countString ţŕåñšåçţîöñš çĥåñĝéð: $filedString ƒîļéð, $taggedString ţåĝĝéð, $renamedString ŕéñåɱéð, $hiddenString ĥîððéñ ~~~~~ ~~~~~ ~~~~~ ~~~',
      one:
          '1 ţŕåñšåçţîöñ çĥåñĝéð: $filedString ƒîļéð, $taggedString ţåĝĝéð, $renamedString ŕéñåɱéð, $hiddenString ĥîððéñ ~~~~~ ~~~~~ ~~~~~ ~~',
    );
    return '[$_temp0]';
  }

  @override
  String get ruleAppliedNone => '[Ñö ţŕåñšåçţîöñš çĥåñĝéð. ~~~~~ ~~~~]';

  @override
  String get ruleApplyFailed =>
      '[Ţĥé ŕûļé çöûļð ñöţ ƀé åþþļîéð. Ñöţĥîñĝ çĥåñĝéð. ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String ruleMoreOptions(String name) {
    return '[Ṁöŕé öþţîöñš ƒöŕ “$name” ~~~~~ ~]';
  }

  @override
  String get ruleEditorMoreOptions => '[Ṁöŕé öþţîöñš ~~~~~]';

  @override
  String get ruleApplying =>
      '[Åþþļýîñĝ ţĥé ŕûļé ţö ýöûŕ ţŕåñšåçţîöñš ~~~~~ ~~~~~ ~~~~]';

  @override
  String get duplicatesTitle => '[Ŕéṽîéŵ ðûþļîçåţéš ~~~~~ ~~]';

  @override
  String duplicatesMenuItem(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ŕéṽîéŵ ðûþļîçåţéš ($countString) ~~~~~ ~~',
      zero: 'Ŕéṽîéŵ ðûþļîçåţéš ~~~~~ ~~',
    );
    return '[$_temp0]';
  }

  @override
  String transactionsMoreOptions(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ṁöŕé öþţîöñš, $countString ļîķéļý ðûþļîçåţéš ~~~~~ ~~~~~ ~',
      one: 'Ṁöŕé öþţîöñš, 1 ļîķéļý ðûþļîçåţé ~~~~~ ~~~~~ ~',
      zero: 'Ṁöŕé öþţîöñš ~~~~~',
    );
    return '[$_temp0]';
  }

  @override
  String duplicatesBadge(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '[$countString]';
  }

  @override
  String get duplicatesEmptyHeadline => '[Ñö ļîķéļý ðûþļîçåţéš ~~~~~ ~~~]';

  @override
  String get duplicatesEmptyBody =>
      '[Ţŵö ţŕåñšåçţîöñš ŵîţĥ ţĥé šåɱé åɱöûñţ ŵîţĥîñ ţĥŕéé ðåýš, öñ ðîƒƒéŕéñţ åççöûñţš öŕ öñé ƒŕöɱ ýöûŕ ƀåñķ åñð öñé ýöû éñţéŕéð, šĥöŵ ûþ ĥéŕé ƒöŕ ýöû ţö çĥéçķ. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~]';

  @override
  String get duplicatesIntro =>
      '[Éåçĥ þåîŕ ɱåý ƀé öñé ţŕåñšåçţîöñ ŕéçöŕðéð ţŵîçé. Ñöţĥîñĝ îš ɱéŕĝéð öŕ ðéļéţéð: ĥîðé ţĥé éẋţŕå öñé, öŕ ɱåŕķ ţĥé þåîŕ åš ñöţ ðûþļîçåţéš. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String duplicatesDaysApart(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Šåɱé åɱöûñţ, $days ðåýš åþåŕţ ~~~~~ ~~~',
      one: 'Šåɱé åɱöûñţ, 1 ðåý åþåŕţ ~~~~~ ~~~',
      zero: 'Šåɱé åɱöûñţ, šåɱé ðåý ~~~~~ ~~',
    );
    return '[$_temp0]';
  }

  @override
  String get duplicateHide => '[Ĥîðé ţĥîš öñé ~~~~~]';

  @override
  String duplicateHideNamed(String name) {
    return '[Ĥîðé ţĥîš öñé: $name ~~~~~]';
  }

  @override
  String get duplicateNotDuplicates => '[Ñöţ ðûþļîçåţéš ~~~~~ ~]';

  @override
  String get duplicateDismissed => '[Ṁåŕķéð åš ñöţ ðûþļîçåţéš ~~~~~ ~~~~]';

  @override
  String get duplicateHidden => '[Ţŕåñšåçţîöñ ĥîððéñ ~~~~~ ~~]';

  @override
  String get duplicateHideFailed =>
      '[Ţĥé ţŕåñšåçţîöñ çöûļð ñöţ ƀé ĥîððéñ. ~~~~~ ~~~~~ ~~]';

  @override
  String get billRemindersChannelName => '[Ɓîļļ ŕéɱîñðéŕš ~~~~~ ~]';

  @override
  String get billRemindersChannelDescription =>
      '[Ŕéɱîñðéŕš ƀéƒöŕé ýöûŕ ƀîļļš åŕé ðûé ~~~~~ ~~~~~ ~~]';

  @override
  String get billUnnamed => '[Ɓîļļ ~~]';

  @override
  String billReminderTitleToday(String name) {
    return '[$name îš ðûé ţöðåý ~~~~]';
  }

  @override
  String billReminderTitleTomorrow(String name) {
    return '[$name îš ðûé ţöɱöŕŕöŵ ~~~~~ ~]';
  }

  @override
  String billReminderTitleOn(String name, String date) {
    return '[$name îš ðûé $date ~~]';
  }

  @override
  String billReminderBody(String amount) {
    return '[Éẋþéçţéð $amount ~~~~]';
  }

  @override
  String get billReminderBodyNoAmount =>
      '[Öþéñ ţĥé ƀîļļ ţö ɱåŕķ îţ þåîð ~~~~~ ~~~~~]';

  @override
  String alertBillDue(String name, String date) {
    return '[$name îš ðûé $date ~~]';
  }

  @override
  String get billNew => '[Ñéŵ ƀîļļ ~~~]';

  @override
  String get billNoNextDue => '[Ñö ûþçöɱîñĝ ðûé ðåţé ~~~~~ ~~]';

  @override
  String get billStatePaid => '[Þåîð ~~]';

  @override
  String get billStateMissed => '[Ṁîššéð ~~~]';

  @override
  String get billNotFound => '[Ţĥîš ƀîļļ ñö ļöñĝéŕ éẋîšţš. ~~~~~ ~~~~]';

  @override
  String get billNewTitle => '[Ñéŵ ƀîļļ ~~~]';

  @override
  String get billEditTitle => '[Éðîţ ƀîļļ ~~~~]';

  @override
  String get billDeleted => '[Ɓîļļ ðéļéţéð ~~~~~]';

  @override
  String get billName => '[Ñåɱé ~~]';

  @override
  String get billNameRequired => '[Éñţéŕ å ñåɱé ~~~~]';

  @override
  String get billAmount => '[Éẋþéçţéð åɱöûñţ ~~~~~ ~]';

  @override
  String get billAmountHelper =>
      '[Öþţîöñåļ. Å þåýɱéñţ ŵîţĥîñ 10 % öƒ îţ ɱåŕķš ţĥé ƀîļļ þåîð. ~~~~~ ~~~~~ ~~~~~ ~~]';

  @override
  String get billDueDate => '[Ƒîŕšţ ðûé ðåţé ~~~~~]';

  @override
  String get billChooseDueDate => '[Çĥööšé å ðûé ðåţé ~~~~~ ~]';

  @override
  String get billRepeats => '[Ŕéþéåţš ~~~]';

  @override
  String get billCadenceOnce => '[Öñçé ~~]';

  @override
  String get billCadenceWeekly => '[Éṽéŕý ŵééķ ~~~~]';

  @override
  String get billCadenceBiweekly => '[Éṽéŕý ţŵö ŵééķš ~~~~~ ~]';

  @override
  String get billCadenceSemiMonthly => '[Ţŵîçé å ɱöñţĥ ~~~~~]';

  @override
  String get billCadenceMonthly => '[Éṽéŕý ɱöñţĥ ~~~~]';

  @override
  String get billCadenceQuarterly => '[Éṽéŕý ţĥŕéé ɱöñţĥš ~~~~~ ~~]';

  @override
  String get billCadenceAnnually => '[Éṽéŕý ýéåŕ ~~~~]';

  @override
  String get billAccount => '[Þåîð ƒŕöɱ ~~~~]';

  @override
  String get billAnyAccount => '[Åñý åççöûñţ ~~~~]';

  @override
  String get billReminders => '[Ŕéɱîñð ɱé ~~~~]';

  @override
  String billReminderOffset(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days ðåýš ƀéƒöŕé ~~~~',
      one: '1 ðåý ƀéƒöŕé ~~~~',
      zero: 'Öñ ţĥé ðåý ~~~~',
    );
    return '[$_temp0]';
  }

  @override
  String get billReminderTime => '[Ŕéɱîñðéŕ ţîɱé ~~~~~]';

  @override
  String get billActive => '[Åçţîṽé ~~~]';

  @override
  String get billActiveCaption =>
      '[Åñ îñåçţîṽé ƀîļļ îš ķéþţ ƀûţ ñéṽéŕ ŕéɱîñðéð. ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get billAutopay => '[Þåîð åûţöɱåţîçåļļý ~~~~~ ~~]';

  @override
  String get billAutopayCaption =>
      '[Ñéṽéŕ šĥöŵñ åš ɱîššéð ŵĥéñ ñö þåýɱéñţ îš ƒöûñð. ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get billPermissionTitle => '[Ñöţîƒîçåţîöñš åŕé öƒƒ ~~~~~ ~~~]';

  @override
  String get billPermissionBody =>
      '[Ɓîļļ ŕéɱîñðéŕš ñééð ñöţîƒîçåţîöñš. Ţĥé ƀîļļ îš šåṽéð; ţö ƀé ŕéɱîñðéð, åļļöŵ ñöţîƒîçåţîöñš ƒöŕ ţĥé åþþ îñ ţĥé šýšţéɱ šéţţîñĝš. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get billPermissionNotNow => '[Ñöţ ñöŵ ~~~]';

  @override
  String get billPermissionOpenSettings => '[Öþéñ šéţţîñĝš ~~~~~]';

  @override
  String get subscriptionsTitle => '[Šûƀšçŕîþţîöñš ~~~~~ ~]';

  @override
  String subscriptionsTotal(String total, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šûƀšçŕîþţîöñš ~~~~~ ~',
      one: '1 šûƀšçŕîþţîöñ ~~~~~',
    );
    return '[$total å ýéåŕ åçŕöšš $_temp0 ~~~~~]';
  }

  @override
  String get subscriptionsEmptyHeadline => '[Ñö šûƀšçŕîþţîöñš ýéţ ~~~~~ ~~~]';

  @override
  String get subscriptionsEmptyBody =>
      '[Šûƀšçŕîþţîöñš ƒöûñð îñ ýöûŕ ţŕåñšåçţîöñš öŕ ŕéþöŕţéð ƀý ýöûŕ ƀåñķ ŵîļļ åþþéåŕ ĥéŕé. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String subscriptionsMuted(int count) {
    return '[Ṁûţéð ($count) ~~]';
  }

  @override
  String subscriptionsOthers(int count) {
    return '[Öţĥéŕ ŕéçûŕŕîñĝ ($count) ~~~~~ ~]';
  }

  @override
  String streamCadence(String cadence) {
    String _temp0 = intl.Intl.selectLogic(cadence, {
      'weekly': 'Ŵééķļý ~~~',
      'biweekly': 'Éṽéŕý ţŵö ŵééķš ~~~~~ ~',
      'semiMonthly': 'Ţŵîçé å ɱöñţĥ ~~~~~',
      'monthly': 'Ṁöñţĥļý ~~~',
      'quarterly': 'Ǫûåŕţéŕļý ~~~~',
      'annually': 'Ýéåŕļý ~~~',
      'other': 'Îŕŕéĝûļåŕ ~~~~',
    });
    return '[$_temp0]';
  }

  @override
  String streamAmountEach(String cadence, String amount) {
    return '[$cadence, $amount éåçĥ ~~]';
  }

  @override
  String streamYearly(String amount) {
    return '[$amount å ýéåŕ ~~]';
  }

  @override
  String get streamDetected =>
      '[Ðéţéçţéð ƒŕöɱ ýöûŕ ţŕåñšåçţîöñš ~~~~~ ~~~~~ ~~]';

  @override
  String streamActions(String name) {
    return '[Åçţîöñš ƒöŕ $name ~~~~]';
  }

  @override
  String get streamMute => '[Ṁûţé ~~]';

  @override
  String get streamUnmute => '[Ûñɱûţé ~~~]';

  @override
  String get streamNotSubscription => '[Ñöţ å šûƀšçŕîþţîöñ ~~~~~ ~~]';

  @override
  String get streamMarkSubscription => '[Ṁåŕķ åš šûƀšçŕîþţîöñ ~~~~~ ~~~]';

  @override
  String get streamRename => '[Ŕéñåɱé ~~~]';

  @override
  String get streamCreateBill => '[Çŕéåţé å ƀîļļ ~~~~~]';

  @override
  String streamMutedDone(String name) {
    return '[$name ɱûţéð ~~]';
  }

  @override
  String streamUnmutedDone(String name) {
    return '[$name ûñɱûţéð ~~~]';
  }

  @override
  String streamNotSubscriptionDone(String name) {
    return '[$name îš ñö ļöñĝéŕ çöûñţéð åš å šûƀšçŕîþţîöñ ~~~~~ ~~~~~ ~~~]';
  }

  @override
  String streamMarkSubscriptionDone(String name) {
    return '[$name îš çöûñţéð åš å šûƀšçŕîþţîöñ ~~~~~ ~~~~~]';
  }

  @override
  String streamRenamedDone(String name) {
    return '[Ŕéñåɱéð ţö $name ~~~~]';
  }

  @override
  String get streamRenameLabel => '[Ñåɱé ~~]';

  @override
  String streamRenameHelper(String merchant) {
    return '[Ļéåṽé éɱþţý ţö ûšé $merchant ~~~~~ ~]';
  }

  @override
  String navPlanMissed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ɱîššéð ƀîļļš ~~~~~',
      one: '1 ɱîššéð ƀîļļ ~~~~',
    );
    return '[Þļåñ, $_temp0 ~~]';
  }

  @override
  String get billsEmptyHeadline => '[Ñö ƀîļļš ýéţ ~~~~]';

  @override
  String get billsEmptyBody =>
      '[Åðð å ƀîļļ ţö ƀé ŕéɱîñðéð ƀéƒöŕé îţ îš ðûé. ~~~~~ ~~~~~ ~~~~]';

  @override
  String get billsGroupOverdue => '[Öṽéŕðûé ~~~]';

  @override
  String get billsGroupDueSoon => '[Ðûé šööñ ~~~]';

  @override
  String get billsGroupLater => '[Ļåţéŕ ~~]';

  @override
  String billsGroupPaused(int count) {
    return '[Þåûšéð ($count) ~~~]';
  }

  @override
  String get billsSuggested => '[Šûĝĝéšţéð ~~~~]';

  @override
  String billSuggestionDetail(String cadence, String date) {
    return '[$cadence, ñéẋţ ðûé $date ~~~]';
  }

  @override
  String get billSuggestionAdd => '[Åðð ~~]';

  @override
  String billSuggestionAddLabel(String name) {
    return '[Åðð $name åš å ƀîļļ ~~~~]';
  }

  @override
  String get billSuggestionDismiss => '[Ðîšɱîšš ~~~]';

  @override
  String billSuggestionDismissLabel(String name) {
    return '[Ðîšɱîšš ţĥé šûĝĝéšţîöñ $name ~~~~~ ~~~]';
  }

  @override
  String get billStateAutopay => '[Åûţöþåý ~~~]';

  @override
  String get billMarkPaid => '[Ṁåŕķ þåîð ~~~~]';

  @override
  String billMarkPaidLabel(String name, String date) {
    return '[Ṁåŕķ $name þåîð ƒöŕ $date ~~~~~]';
  }

  @override
  String billMarkedPaid(String name) {
    return '[$name ɱåŕķéð þåîð ~~~~]';
  }

  @override
  String billDueIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Ðûé îñ $days ðåýš ~~~~',
      one: 'Ðûé ţöɱöŕŕöŵ ~~~~~',
      zero: 'Ðûé ţöðåý ~~~~',
    );
    return '[$_temp0]';
  }

  @override
  String billDueAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Ðûé $days ðåýš åĝö ~~~~',
      one: 'Ðûé ýéšţéŕðåý ~~~~~',
    );
    return '[$_temp0]';
  }

  @override
  String billDueOn(String date) {
    return '[Ðûé $date ~~]';
  }

  @override
  String get billPaused => '[Þåûšéð ~~~]';

  @override
  String get billsListView => '[Ļîšţ ~~]';

  @override
  String get billsCalendarView => '[Çåļéñðåŕ ~~~~]';

  @override
  String get billsPreviousMonth => '[Þŕéṽîöûš ɱöñţĥ ~~~~~ ~]';

  @override
  String get billsNextMonth => '[Ñéẋţ ɱöñţĥ ~~~~]';

  @override
  String billsCalendarDay(String date, int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ƀîļļš ðûé: $names ~~~~',
      one: '1 ƀîļļ ðûé: $names ~~~',
      zero: 'ñö ƀîļļš ðûé ~~~~',
    );
    return '[$date, $_temp0]';
  }

  @override
  String billsCalendarNone(String date) {
    return '[Ñö ƀîļļš ðûé $date ~~~~]';
  }

  @override
  String billsSuggestedShowAll(int count) {
    return '[Šĥöŵ åļļ ($count) ~~~]';
  }

  @override
  String billsMissedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ɱîššéð ƀîļļš ~~~~~',
      one: '1 ɱîššéð ƀîļļ ~~~~',
    );
    return '[$_temp0]';
  }

  @override
  String get forecastTitle => '[Ƒöŕéçåšţ ~~~~]';

  @override
  String forecastEventAmount(String name, String amount) {
    return '[$name $amount]';
  }

  @override
  String forecastHorizon(int days) {
    return '[$days ðåýš ~~]';
  }

  @override
  String get forecastShowTable => '[Ţåƀļé ~~]';

  @override
  String get forecastShowChart => '[Çĥåŕţ ~~]';

  @override
  String forecastLowest(String amount, String date) {
    return '[Ļöŵéšţ þöîñţ $amount öñ $date ~~~~~ ~]';
  }

  @override
  String forecastBelowZero(String date) {
    return '[Ɓéļöŵ žéŕö öñ $date ~~~~~]';
  }

  @override
  String get forecastChooseAccounts => '[Çĥööšé åççöûñţš ~~~~~ ~]';

  @override
  String get forecastEmptyHeadline => '[Ñö åççöûñţš ţö ƒöŕéçåšţ ~~~~~ ~~~]';

  @override
  String get forecastEmptyBody =>
      '[Çĥööšé å çĥéçķîñĝ öŕ šåṽîñĝš åççöûñţ ţö šéé ŵĥéŕé îţš ƀåļåñçé îš ĥéåðîñĝ. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~]';

  @override
  String forecastChartSummary(
    int days,
    String start,
    String end,
    String endDate,
    String lowest,
    String lowestDate,
  ) {
    return '[$days-ðåý ƒöŕéçåšţ: $start ţöðåý, $end öñ $endDate. Ļöŵéšţ þöîñţ $lowest öñ $lowestDate. ~~~~~ ~~~~~ ~~~]';
  }

  @override
  String forecastRange(String low, String high) {
    return '[Ļöŵ $low · Ĥîĝĥ $high ~~~]';
  }

  @override
  String forecastDaySemantics(
    String date,
    String balance,
    String low,
    String high,
  ) {
    return '[$date: ƀåļåñçé $balance, ļöŵ $low, ĥîĝĥ $high. ~~~~~ ~]';
  }

  @override
  String forecastOverdue(String name, String date) {
    return '[$name, ðûé $date ~~]';
  }

  @override
  String get forecastAccountsTitle => '[Åççöûñţš îñ ţĥé ƒöŕéçåšţ ~~~~~ ~~~~]';

  @override
  String forecastAccountsHidden(String currency) {
    return '[$currency · ĥîððéñ åççöûñţ ~~~~~ ~]';
  }

  @override
  String get forecastCurrency => '[Çûŕŕéñçý ~~~~]';

  @override
  String get forecastSelectionFailed =>
      '[Ţĥé ƒöŕéçåšţ\'š åççöûñţš çöûļð ñöţ ƀé šåṽéð. Ţŕý åĝåîñ. ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String get goalsNew => '[Ñéŵ ĝöåļ ~~~]';

  @override
  String get goalsEmptyTitle => '[Ñö šåṽîñĝš ĝöåļš ýéţ ~~~~~ ~~]';

  @override
  String get goalsEmptyBody =>
      '[Šéţ å ţåŕĝéţ åñð å ðåţé, åñð šéé ĥöŵ ɱûçĥ ţö šéţ åšîðé éåçĥ ɱöñţĥ. ~~~~~ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String goalsArchived(int count) {
    return '[Åŕçĥîṽéð ($count) ~~~~]';
  }

  @override
  String goalProgressOf(String progress, String target) {
    return '[$progress öƒ $target ~]';
  }

  @override
  String goalProgressPercent(int percent) {
    return '[$percent þéŕçéñţ öƒ ţĥé ţåŕĝéţ ~~~~~ ~~~]';
  }

  @override
  String get goalOnTrack => '[Öñ ţŕåçķ ~~~]';

  @override
  String goalBehind(String amount) {
    return '[Ɓéĥîñð ƀý $amount ~~~~]';
  }

  @override
  String get goalDone => '[Ðöñé ~~]';

  @override
  String goalSuggestion(String amount) {
    return '[Šéţ åšîðé $amount å ɱöñţĥ ~~~~~ ~]';
  }

  @override
  String goalTargetDateCaption(String date) {
    return '[Ɓý $date ~]';
  }

  @override
  String get goalNotFound => '[Ţĥîš ĝöåļ ñö ļöñĝéŕ éẋîšţš. ~~~~~ ~~~~]';

  @override
  String get goalNewTitle => '[Ñéŵ ĝöåļ ~~~]';

  @override
  String get goalEditTitle => '[Éðîţ ĝöåļ ~~~~]';

  @override
  String get goalName => '[Ñåɱé ~~]';

  @override
  String get goalNameRequired => '[Éñţéŕ å ñåɱé ~~~~]';

  @override
  String get goalTarget => '[Ţåŕĝéţ åɱöûñţ ~~~~~]';

  @override
  String get goalKind => '[Þŕöĝŕéšš ƒŕöɱ ~~~~~]';

  @override
  String get goalKindBalance => '[Åççöûñţ ƀåļåñçéš ~~~~~ ~]';

  @override
  String get goalKindContribution => '[Çöñţŕîƀûţîöñš ~~~~~ ~]';

  @override
  String get goalKindBalanceCaption =>
      '[Þŕöĝŕéšš îš ţĥé ƀåļåñçé öƒ ţĥé åççöûñţš ýöû çĥööšé. ~~~~~ ~~~~~ ~~~~~ ~~]';

  @override
  String get goalKindContributionCaption =>
      '[Þŕöĝŕéšš îš ŵĥåţ ýöû åðð ţö ţĥé ĝöåļ ýöûŕšéļƒ. ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get goalAccounts => '[Åççöûñţš ~~~~]';

  @override
  String get goalAccountsRequired =>
      '[Çĥööšé åţ ļéåšţ öñé åççöûñţ ~~~~~ ~~~~~]';

  @override
  String goalAccountOtherCurrency(String currency) {
    return '[Îñ $currency, ñöţ çöûñţéð ~~~~~]';
  }

  @override
  String get goalTargetDate => '[Ţåŕĝéţ ðåţé ~~~~]';

  @override
  String get goalNoTargetDate => '[Ñö ðåţé ~~~]';

  @override
  String get goalClearTargetDate => '[Çļéåŕ ðåţé ~~~~]';

  @override
  String get goalNote => '[Ñöţé ~~]';

  @override
  String get goalArchive => '[Åŕçĥîṽé ~~~]';

  @override
  String get goalUnarchive => '[Ûñåŕçĥîṽé ~~~~]';

  @override
  String get goalArchivedMessage => '[Ĝöåļ åŕçĥîṽéð ~~~~~]';

  @override
  String get goalDeleted => '[Ĝöåļ ðéļéţéð ~~~~~]';

  @override
  String get goalCountedAccounts => '[Çöûñţéð åççöûñţš ~~~~~ ~]';

  @override
  String goalNotCounted(String names) {
    return '[Ñöţ çöûñţéð, åñöţĥéŕ çûŕŕéñçý: $names ~~~~~ ~~~~~]';
  }

  @override
  String get goalContributions => '[Çöñţŕîƀûţîöñš ~~~~~ ~]';

  @override
  String get goalNoContributions => '[Ñö çöñţŕîƀûţîöñš ýéţ. ~~~~~ ~~~]';

  @override
  String get goalAddContribution => '[Åðð çöñţŕîƀûţîöñ ~~~~~ ~]';

  @override
  String get contributionDate => '[Ðåţé ~~]';

  @override
  String get contributionAmount => '[Åɱöûñţ ~~~]';

  @override
  String get contributionNote => '[Ñöţé ~~]';

  @override
  String get contributionWithdrawal => '[Ŵîţĥðŕåŵåļ ~~~~]';

  @override
  String get contributionWithdrawalCaption =>
      '[Ţåķéš ţĥé åɱöûñţ öûţ öƒ ţĥé ĝöåļ. ~~~~~ ~~~~~ ~]';

  @override
  String get contributionDelete => '[Ðéļéţé çöñţŕîƀûţîöñ ~~~~~ ~~~]';

  @override
  String get contributionDeleted => '[Çöñţŕîƀûţîöñ ðéļéţéð ~~~~~ ~~~]';

  @override
  String get goalTargetDatePast => '[Çĥööšé ţöðåý öŕ å ļåţéŕ ðåţé ~~~~~ ~~~~~]';

  @override
  String get goalCurrencyLocked =>
      '[Ţĥé çûŕŕéñçý šţåýš åš îţ îš öñçé ţĥé ĝöåļ ĥåš çöñţŕîƀûţîöñš öŕ åççöûñţš. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~]';

  @override
  String contributionNotCounted(String currency) {
    return '[Ñöţ çöûñţéð, îñ $currency ~~~~~]';
  }

  @override
  String get contributionDateFuture =>
      '[Çĥööšé ţöðåý öŕ åñ éåŕļîéŕ ðåţé ~~~~~ ~~~~~ ~]';

  @override
  String get investmentsTitle => '[Îñṽéšţɱéñţš ~~~~~]';

  @override
  String get investmentsEmptyHeadline => '[Ñö îñṽéšţɱéñţ åççöûñţš ~~~~~ ~~~]';

  @override
  String get investmentsEmptyBody =>
      '[Ļîñķ å ƀŕöķéŕåĝé öŕ ŕéţîŕéɱéñţ åççöûñţ ţö šéé îţš ĥöļðîñĝš, åļļöçåţîöñ åñð ṽåļûé ĥéŕé. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~]';

  @override
  String get investmentsAllocation => '[Åļļöçåţîöñ ~~~~]';

  @override
  String investmentsAllocationIn(String currency) {
    return '[Åļļöçåţîöñ îñ $currency ~~~~~]';
  }

  @override
  String investmentsAllocationSummary(
    String total,
    int count,
    String largest,
    String share,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šéçûŕîţý ţýþéš ~~~~~ ~',
      one: 'öñé šéçûŕîţý ţýþé ~~~~~ ~',
    );
    return '[Ĥöļðîñĝš ŵöŕţĥ $total îñ $_temp0. Ţĥé ļåŕĝéšţ îš $largest åţ $share. ~~~~~ ~~~~~ ~~]';
  }

  @override
  String investmentsAllocationRow(String type, String value, String share) {
    return '[$type: $value, $share]';
  }

  @override
  String get investmentsTypeCash => '[Çåšĥ ~~]';

  @override
  String get investmentsTypeOther => '[Öţĥéŕ ~~]';

  @override
  String get investmentsTypeEtf => '[ÉŢƑ ~~]';

  @override
  String investmentsPercent(int percent) {
    return '[$percent %]';
  }

  @override
  String investmentsPercentUp(int percent) {
    return '[+$percent %]';
  }

  @override
  String investmentsChange(String amount, String percent) {
    return '[$amount ($percent)]';
  }

  @override
  String investmentsPrice(String price, String currency) {
    return '[$price $currency]';
  }

  @override
  String investmentsQuantityAtPrice(String quantity, String price) {
    return '[$quantity åţ $price ~]';
  }

  @override
  String investmentsCostBasis(String cost) {
    return '[Çöšţ ƀåšîš $cost ~~~~]';
  }

  @override
  String investmentsGain(String gain) {
    return '[Ĝåîñ $gain ~~]';
  }

  @override
  String get investmentsCostBasisUnavailable =>
      '[Çöšţ ƀåšîš ûñåṽåîļåƀļé ~~~~~ ~~~]';

  @override
  String investmentsPriceAsOf(String date) {
    return '[Þŕîçé åš öƒ $date ~~~~]';
  }

  @override
  String investmentsNameAmount(String name, String amount) {
    return '[$name: $amount]';
  }

  @override
  String investmentsDateAndType(String date, String type) {
    return '[$date · $type]';
  }

  @override
  String investmentsFees(String amount) {
    return '[Ƒééš $amount ~~]';
  }

  @override
  String investmentsAccountSemantics(
    String name,
    String balance,
    String caption,
  ) {
    return '[$name, $balance, $caption]';
  }

  @override
  String get investmentsValueTitle => '[Ṽåļûé öṽéŕ ţîɱé ~~~~~ ~]';

  @override
  String investmentsValueCaption(String date) {
    return '[Ƒŕöɱ îñšţåļļ ðåý: ŕéçöŕðéð öñ ţĥîš ðéṽîçé šîñçé $date ~~~~~ ~~~~~ ~~~~~ ~]';
  }

  @override
  String get investmentsValueNone => '[Ñö ṽåļûéš ŕéçöŕðéð ýéţ ~~~~~ ~~~]';

  @override
  String investmentsValueSummary(
    String start,
    String startDate,
    String end,
    String endDate,
  ) {
    return '[Ṽåļûé $start öñ $startDate, $end öñ $endDate. ~~~~]';
  }

  @override
  String investmentsValueSummaryOne(String amount, String date) {
    return '[Ṽåļûé $amount öñ $date. ~~~]';
  }

  @override
  String investmentsValueRow(String date, String value) {
    return '[$date: $value]';
  }

  @override
  String get investmentsShowTable => '[Ţåƀļé ~~]';

  @override
  String get investmentsShowChart => '[Çĥåŕţ ~~]';

  @override
  String get investmentsHoldings => '[Ĥöļðîñĝš ~~~~]';

  @override
  String get investmentsNoHoldings => '[Ñö ĥöļðîñĝš ŕéþöŕţéð ~~~~~ ~~~]';

  @override
  String get investmentsUnknownSecurity => '[Ûñķñöŵñ šéçûŕîţý ~~~~~ ~]';

  @override
  String get investmentsTransactions => '[Îñṽéšţɱéñţ ţŕåñšåçţîöñš ~~~~~ ~~~~]';

  @override
  String get investmentsNoTransactions =>
      '[Ñö îñṽéšţɱéñţ ţŕåñšåçţîöñš ~~~~~ ~~~~~]';

  @override
  String investmentsShowMore(int count) {
    return '[Šĥöŵ ɱöŕé ($count ļéƒţ) ~~~~~]';
  }

  @override
  String get netWorthTitle => '[Ñéţ ŵöŕţĥ ~~~~]';

  @override
  String netWorthHeadlineLabel(String date) {
    return '[Ñéţ ŵöŕţĥ öñ $date ~~~~]';
  }

  @override
  String netWorthChange(String amount) {
    return '[$amount öṽéŕ 30 ðåýš ~~~~]';
  }

  @override
  String netWorthChangeEstimated(String amount) {
    return '[$amount öṽéŕ 30 ðåýš, åĝåîñšţ åñ éšţîɱåţé ~~~~~ ~~~~~]';
  }

  @override
  String get netWorthRangeThreeMonths => '[3 ɱ ~]';

  @override
  String get netWorthRangeYear => '[1 ý ~]';

  @override
  String get netWorthRangeAll => '[Åļļ ~~]';

  @override
  String get netWorthShowTable => '[Ţåƀļé ~~]';

  @override
  String get netWorthShowChart => '[Çĥåŕţ ~~]';

  @override
  String get netWorthAssets => '[Åššéţš ~~~]';

  @override
  String get netWorthLiabilitiesLine => '[Ļîåƀîļîţîéš ~~~~~]';

  @override
  String get netWorthEstimatedLegend =>
      '[Ðåšĥéð: éšţîɱåţéð ƒŕöɱ ţŕåñšåçţîöñš ~~~~~ ~~~~~ ~~~]';

  @override
  String netWorthChartSummary(
    String startDate,
    String endDate,
    String start,
    String end,
    String assets,
    String liabilities,
  ) {
    return '[Ñéţ ŵöŕţĥ ƒŕöɱ $startDate ţö $endDate: $start ţö $end. Öñ $endDate, åššéţš $assets åñð ļîåƀîļîţîéš $liabilities. ~~~~~ ~~~~~ ~~~~~ ~]';
  }

  @override
  String netWorthChartEstimated(String date) {
    return '[Ɓéƒöŕé $date, éšţîɱåţéð ƒŕöɱ ţŕåñšåçţîöñš. ~~~~~ ~~~~~ ~~~]';
  }

  @override
  String netWorthRowSemantics(
    String date,
    String netWorth,
    String assets,
    String liabilities,
  ) {
    return '[$date: ñéţ ŵöŕţĥ $netWorth, åššéţš $assets, ļîåƀîļîţîéš $liabilities. ~~~~~ ~~~~~]';
  }

  @override
  String netWorthRowDetail(String assets, String liabilities) {
    return '[Åššéţš $assets · Ļîåƀîļîţîéš $liabilities ~~~~~ ~~]';
  }

  @override
  String get netWorthEstimated => '[Éšţîɱåţéð ƒŕöɱ ţŕåñšåçţîöñš ~~~~~ ~~~~~]';

  @override
  String get netWorthCarried =>
      '[Ñö šñåþšĥöţ ţĥîš ðåý: ţĥé ðåý ƀéƒöŕé\'š ṽåļûéš ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get netWorthEmptyHeadline => '[Ñö ñéţ ŵöŕţĥ ýéţ ~~~~~ ~]';

  @override
  String get netWorthEmptyBody =>
      '[Ýöûŕ ñéţ ŵöŕţĥ îš ŕéçöŕðéð öñçé å ðåý ƒŕöɱ ýöûŕ åççöûñţš\' ƀåļåñçéš. Åðð öŕ ļîñķ åñ åççöûñţ ţö šţåŕţ. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~]';

  @override
  String get netWorthLiabilitiesHeading => '[Ļîåƀîļîţîéš ~~~~~]';

  @override
  String netWorthOwed(String amount) {
    return '[$amount öŵéð ~~]';
  }

  @override
  String get netWorthHiddenAccount => '[Ĥîððéñ åççöûñţ ~~~~~ ~]';

  @override
  String netWorthRate(String rate) {
    return '[$rate % å ýéåŕ ~~]';
  }

  @override
  String netWorthRateEntered(String rate) {
    return '[$rate % å ýéåŕ, éñţéŕéð ~~~~~]';
  }

  @override
  String get netWorthNoRate => '[Ñö îñţéŕéšţ ŕåţé ŕéþöŕţéð ~~~~~ ~~~~]';

  @override
  String netWorthPaymentMinimum(String amount) {
    return '[Ṁîñîɱûɱ þåýɱéñţ $amount ~~~~~ ~]';
  }

  @override
  String netWorthPaymentMonthly(String amount) {
    return '[Ṁöñţĥļý þåýɱéñţ $amount ~~~~~ ~]';
  }

  @override
  String netWorthPaymentEntered(String amount) {
    return '[Ýöûŕ þåýɱéñţ $amount ~~~~~]';
  }

  @override
  String get netWorthNoPayment => '[Ñö þåýɱéñţ ŕéþöŕţéð ~~~~~ ~~]';

  @override
  String get netWorthEnterRate => '[Éñţéŕ ŕåţé ~~~~]';

  @override
  String get netWorthEnterPayment => '[Éñţéŕ þåýɱéñţ ~~~~~]';

  @override
  String get netWorthEditRate => '[Çĥåñĝé ŕåţé ~~~~]';

  @override
  String get netWorthEditPayment => '[Çĥåñĝé þåýɱéñţ ~~~~~ ~]';

  @override
  String netWorthPaidOff(int months, String date, String interest) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months ɱöñţĥš ~~~',
      one: '1 ɱöñţĥ ~~',
    );
    return '[Þåîð öƒƒ îñ $_temp0, $date; $interest îñ îñţéŕéšţ ~~~~~ ~~~]';
  }

  @override
  String netWorthNever(String interest) {
    return '[Ñéṽéŕ þåîð öƒƒ: ţĥé þåýɱéñţ ðöéšñ\'ţ çöṽéŕ ţĥé îñţéŕéšţ öƒ $interest å ɱöñţĥ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~]';
  }

  @override
  String get netWorthBeyondCap => '[Öṽéŕ 50 ýéåŕš ţö þåý öƒƒ ~~~~~ ~~]';

  @override
  String get netWorthNothingOwed => '[Ñöţĥîñĝ öŵéð ~~~~~]';

  @override
  String netWorthExtra(String amount) {
    return '[Éẋţŕå å ɱöñţĥ: $amount ~~~~~]';
  }

  @override
  String netWorthExtraDifference(int months, String interest) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months ɱöñţĥš šööñéŕ ~~~~~',
      one: '1 ɱöñţĥ šööñéŕ ~~~~~',
      zero: 'ñö šööñéŕ ~~~~',
    );
    return '[$_temp0, $interest ļéšš îñţéŕéšţ ~~~~~]';
  }

  @override
  String netWorthWithExtra(String extra, String result) {
    return '[Ŵîţĥ $extra ɱöŕé å ɱöñţĥ: $result ~~~~~ ~]';
  }

  @override
  String get netWorthRateLabel => '[Îñţéŕéšţ ŕåţé, % å ýéåŕ ~~~~~ ~~]';

  @override
  String get netWorthRateInvalid =>
      '[Éñţéŕ å ŕåţé ƒŕöɱ 0 ţö 100, ŵîţĥ ûþ ţö ţŵö ðéçîɱåļš ~~~~~ ~~~~~ ~~~~]';

  @override
  String get netWorthPaymentLabel => '[Ṁöñţĥļý þåýɱéñţ ~~~~~ ~]';

  @override
  String get netWorthPaymentInvalid =>
      '[Éñţéŕ åñ åɱöûñţ åƀöṽé žéŕö ~~~~~ ~~~~]';

  @override
  String get netWorthClearEntry => '[Çļéåŕ ~~]';

  @override
  String get netWorthEntryFailed =>
      '[Ţĥé éñţŕý çöûļð ñöţ ƀé šåṽéð. Ţŕý åĝåîñ. ~~~~~ ~~~~~ ~~~]';

  @override
  String get exportReportTitle => '[Ṁöñţĥļý ŕéþöŕţ ~~~~~ ~]';

  @override
  String exportCountedThrough(String date) {
    return '[Çöûñţéð ţĥŕöûĝĥ $date ~~~~~ ~]';
  }

  @override
  String exportAmountsIn(String currency) {
    return '[Åɱöûñţš îñ $currency ~~~~]';
  }

  @override
  String get exportOther => '[Öţĥéŕ ~~]';

  @override
  String get exportColumnCategory => '[Çåţéĝöŕý ~~~~]';

  @override
  String get exportColumnShare => '[Šĥåŕé ~~]';

  @override
  String get exportColumnAmount => '[Åɱöûñţ ~~~]';

  @override
  String get exportColumnMerchant => '[Ṁéŕçĥåñţ ~~~~]';

  @override
  String get exportColumnPeriod => '[Þéŕîöð ~~~]';

  @override
  String get exportColumnNet => '[Ñéţ ~~]';

  @override
  String get exportColumnBefore => '[Ɓéƒöŕé ~~~]';

  @override
  String get exportColumnNow => '[Ñöŵ ~~]';

  @override
  String get exportColumnChange => '[Çĥåñĝé ~~~]';

  @override
  String get exportColumnDate => '[Ðåţé ~~]';

  @override
  String get exportColumnWhy => '[Ŵĥý ~~]';

  @override
  String get exportBills => '[Ɓîļļš ~~]';

  @override
  String get exportColumnBill => '[Ɓîļļ ~~]';

  @override
  String get exportColumnDue => '[Ðûé ~~]';

  @override
  String get exportColumnStatus => '[Šţåţûš ~~~]';

  @override
  String get exportBillDue => '[Ðûé ~~]';

  @override
  String get exportBillUpcoming => '[Ûþçöɱîñĝ ~~~~]';

  @override
  String get exportNoBills => '[Ñö ƀîļļš ðûé îñ ţĥîš þéŕîöð. ~~~~~ ~~~~]';

  @override
  String get exportColumnBudget => '[Ɓûðĝéţ ~~~]';

  @override
  String get exportColumnAvailable => '[Åṽåîļåƀļé ~~~~]';

  @override
  String get exportColumnLeft => '[Ļéƒţ ~~]';

  @override
  String exportPage(int page, int count) {
    return '[Þåĝé $page öƒ $count ~~~]';
  }

  @override
  String get exportTitle => '[Éẋþöŕţ ~~~]';

  @override
  String get exportSettingsSubtitle =>
      '[Ţĥé ɱöñţĥļý ŕéþöŕţ åš å ÞÐƑ, ţŕåñšåçţîöñš åš å ÇŠṼ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get exportReportSection => '[Ṁöñţĥļý ŕéþöŕţ (ÞÐƑ) ~~~~~ ~~]';

  @override
  String get exportTransactionsSection => '[Ţŕåñšåçţîöñš (ÇŠṼ) ~~~~~ ~]';

  @override
  String get exportSaveAs => '[Šåṽé åš… ~~~]';

  @override
  String get exportShare => '[Šĥåŕé… ~~]';

  @override
  String get exportSaveReport =>
      '[Šåṽé ţĥé ɱöñţĥļý ŕéþöŕţ åš å ÞÐƑ ~~~~~ ~~~~~ ~]';

  @override
  String get exportShareReport =>
      '[Šĥåŕé ţĥé ɱöñţĥļý ŕéþöŕţ åš å ÞÐƑ ~~~~~ ~~~~~ ~]';

  @override
  String get exportSaveTransactions =>
      '[Šåṽé ţĥé ţŕåñšåçţîöñš åš å ÇŠṼ ~~~~~ ~~~~~]';

  @override
  String get exportShareTransactions =>
      '[Šĥåŕé ţĥé ţŕåñšåçţîöñš åš å ÇŠṼ ~~~~~ ~~~~~ ~]';

  @override
  String get exportDates => '[Ðåţéš ~~]';

  @override
  String get exportAccounts => '[Åççöûñţš ~~~~]';

  @override
  String exportTransactionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ţŕåñšåçţîöñš ~~~~~',
      one: '1 ţŕåñšåçţîöñ ~~~~~',
      zero: 'Ñö ţŕåñšåçţîöñš îñ ţĥéšé ðåţéš åñð åççöûñţš ~~~~~ ~~~~~ ~~~~~',
    );
    return '[$_temp0]';
  }

  @override
  String get exportPrivacyNote =>
      '[Å ƒîļé ýöû šåṽé öŕ šĥåŕé ļéåṽéš ţĥé åþþ\'š éñçŕýþţéð šţöŕåĝé. Åñýöñé ŵĥö ĥåš ţĥé ƒîļé çåñ ŕéåð îţ. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get exportDemoNote =>
      '[Îñ ţĥé ðéɱö, ñöţĥîñĝ îš šåṽéð öŕ šĥåŕéð. ~~~~~ ~~~~~ ~~~]';

  @override
  String get exportPreparing => '[Þŕéþåŕîñĝ ţĥé ƒîļé ~~~~~ ~~]';

  @override
  String exportSaved(String fileName) {
    return '[Šåṽéð $fileName ~~]';
  }

  @override
  String get exportFailed =>
      '[Ţĥé ƒîļé çöûļð ñöţ ƀé éẋþöŕţéð. Ţŕý åĝåîñ. ~~~~~ ~~~~~ ~~~~]';

  @override
  String get exportReportMenu => '[Éẋþöŕţ ţĥîš ɱöñţĥ åš ÞÐƑ ~~~~~ ~~~]';

  @override
  String get backupTitle => '[Ɓåçķûþ ~~~]';

  @override
  String get backupSettingsSubtitle =>
      '[Éṽéŕýţĥîñĝ îñ öñé éñçŕýþţéð ƒîļé, öŕ ŕéšţöŕé öñé ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get backupDemoNote =>
      '[Ţĥé ðéɱö\'š ĝéñéŕåţéð ðåţå îš ñöţ ķéþţ öŕ ƀåçķéð ûþ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get backupExportSection => '[Éẋþöŕţ å ƀåçķûþ ~~~~~ ~]';

  @override
  String get backupExportExplanation =>
      '[Éṽéŕýţĥîñĝ öñ ţĥîš ðéṽîçé îñ öñé ƒîļé, éñçŕýþţéð ŵîţĥ å þåššþĥŕåšé ýöû çĥööšé: åççöûñţš, ţŕåñšåçţîöñš, ƀûðĝéţš, ƀîļļš, ĝöåļš, šéţţîñĝš åñð ŕéçéîþţ þĥöţöš. Ķééþ îţ åñýŵĥéŕé. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get backupPassphrase => '[Þåššþĥŕåšé ~~~~]';

  @override
  String get backupPassphraseConfirm => '[Þåššþĥŕåšé åĝåîñ ~~~~~ ~]';

  @override
  String backupPassphraseHelper(int count) {
    return '[Åţ ļéåšţ $count çĥåŕåçţéŕš ~~~~~ ~~]';
  }

  @override
  String backupPassphraseTooShort(int count) {
    return '[Ûšé åţ ļéåšţ $count çĥåŕåçţéŕš ~~~~~ ~~~]';
  }

  @override
  String get backupPassphraseMismatch =>
      '[Ţĥé ţŵö þåššþĥŕåšéš ðîƒƒéŕ ~~~~~ ~~~~~]';

  @override
  String get backupStrengthWeak =>
      '[Šţŕéñĝţĥ: ŵéåķ. Å ļöñĝéŕ þåššþĥŕåšé îš šåƒéŕ. ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get backupStrengthFair => '[Šţŕéñĝţĥ: ƒåîŕ ~~~~~]';

  @override
  String get backupStrengthStrong => '[Šţŕéñĝţĥ: šţŕöñĝ ~~~~~ ~]';

  @override
  String get backupNoRecovery =>
      '[Ţĥéŕé îš ñö ŵåý ţö ŕéçöṽéŕ å ƒöŕĝöţţéñ þåššþĥŕåšé: ŵîţĥöûţ îţ, ţĥé ƀåçķûþ çåññöţ ƀé öþéñéð. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get backupSave => '[Šåṽé åš ~~~]';

  @override
  String get backupShare => '[Šĥåŕé ~~]';

  @override
  String backupSaved(String fileName) {
    return '[Šåṽéð $fileName ~~]';
  }

  @override
  String get backupExportFailed =>
      '[Ţĥé ƀåçķûþ çöûļð ñöţ ƀé ɱåðé. Ţŕý åĝåîñ. ~~~~~ ~~~~~ ~~~]';

  @override
  String get backupRestoreSection => '[Ŕéšţöŕé ƒŕöɱ å ƀåçķûþ ~~~~~ ~~~]';

  @override
  String get backupRestoreExplanation =>
      '[Å ƀåçķûþ çåñ ƀé ŕéšţöŕéð öñļý öñţö å ðéṽîçé ŵîţĥ ñö ðåţå ýéţ, šûçĥ åš å ñéŵ îñšţåļļ: å ðéṽîçé ţĥåţ åļŕéåðý ĥåš ðåţå ŕéƒûšéš îţ. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get backupRestoreButton => '[Ŕéšţöŕé ƒŕöɱ å ƀåçķûþ ~~~~~ ~~~]';

  @override
  String get backupRestorePassphraseTitle =>
      '[Ţĥîš ƀåçķûþ\'š þåššþĥŕåšé ~~~~~ ~~~~]';

  @override
  String get backupOpen => '[Öþéñ ~~]';

  @override
  String get backupStageReading => '[Ŕéåðîñĝ ýöûŕ ðåţå ~~~~~ ~]';

  @override
  String get backupStageDeriving =>
      '[Šéçûŕîñĝ ŵîţĥ ýöûŕ þåššþĥŕåšé ~~~~~ ~~~~~ ~]';

  @override
  String get backupStageEncrypting => '[Éñçŕýþţîñĝ ~~~~]';

  @override
  String get backupStageChecking => '[Çĥéçķîñĝ ţĥé ƀåçķûþ ~~~~~ ~~]';

  @override
  String get backupStageRestoring => '[Ŕéšţöŕîñĝ ~~~~]';

  @override
  String get backupConfirmTitle => '[Ŕéšţöŕé ţĥîš ƀåçķûþ? ~~~~~ ~~]';

  @override
  String backupConfirmBody(
    String date,
    String version,
    int records,
    int receipts,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      records,
      locale: localeName,
      other: '$records ŕéçöŕðš ~~~',
      one: '1 ŕéçöŕð ~~~',
    );
    String _temp1 = intl.Intl.pluralLogic(
      receipts,
      locale: localeName,
      other: '$receipts ŕéçéîþţ þĥöţöš ~~~~~ ~',
      one: '1 ŕéçéîþţ þĥöţö ~~~~~',
    );
    return '[Ṁåðé $date ƀý ṽéŕšîöñ $version: $_temp0 åñð $_temp1. ~~~~~ ~~]';
  }

  @override
  String get backupConfirmLostKey =>
      '[Ţĥé ðåţå öñ ţĥîš ðéṽîçé ţĥåţ çåñ ñö ļöñĝéŕ ƀé öþéñéð ŵîļļ ƀé ðéļéţéð. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~]';

  @override
  String get backupConfirmRestore => '[Ŕéšţöŕé ~~~]';

  @override
  String get backupErrorNotABackup =>
      '[Ţĥîš ƒîļé îš ñöţ å Ƒîñåñçé Ţŕåçķéŕ ƀåçķûþ. ~~~~~ ~~~~~ ~~~~]';

  @override
  String get backupErrorTooLarge =>
      '[Ţĥîš ƒîļé îš ţöö ļåŕĝé ţö ƀé å Ƒîñåñçé Ţŕåçķéŕ ƀåçķûþ (öṽéŕ 512 ṀƁ). ~~~~~ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get backupErrorTooNew =>
      '[Ţĥîš ƀåçķûþ ŵåš ɱåðé ƀý å ñéŵéŕ ṽéŕšîöñ öƒ Ƒîñåñçé Ţŕåçķéŕ. Ûþðåţé ţĥé åþþ, ţĥéñ ŕéšţöŕé îţ. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get backupErrorUnsafe =>
      '[Ţĥîš ƀåçķûþ åšķš ƒöŕ šéţţîñĝš ţĥîš åþþ ðöéš ñöţ åççéþţ, šö îţ ŵåš ñöţ öþéñéð. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get backupErrorWrongPassphrase =>
      '[Ţĥé þåššþĥŕåšé îš ŵŕöñĝ, öŕ ţĥé ƒîļé îš ðåɱåĝéð. ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get backupErrorDamaged =>
      '[Ţĥîš ƀåçķûþ îš ðåɱåĝéð öŕ îñçöɱþļéţé. ~~~~~ ~~~~~ ~~~]';

  @override
  String get backupErrorOtherAccount =>
      '[Ţĥîš ƀåçķûþ ƀéļöñĝš ţö åñöţĥéŕ åççöûñţ. ~~~~~ ~~~~~ ~~~~]';

  @override
  String get backupErrorHasData =>
      '[Ţĥîš ðéṽîçé åļŕéåðý ĥåš ðåţå. Ðéļéţé ţĥé åþþ\'š ðåţå ƒîŕšţ, ţĥéñ ŕéšţöŕé. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String get backupErrorPick => '[Ţĥé ƒîļé çöûļð ñöţ ƀé öþéñéð. ~~~~~ ~~~~~]';

  @override
  String get backupErrorFailed =>
      '[Ţĥé ƀåçķûþ çöûļð ñöţ ƀé ŕéšţöŕéð. Ñöţĥîñĝ ŵåš çĥåñĝéð. ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String get backupRestoringTitle => '[Ŕéšţöŕîñĝ ýöûŕ ƀåçķûþ ~~~~~ ~~~]';

  @override
  String get backupRestoreFailedTitle =>
      '[Ţĥé ƀåçķûþ çöûļð ñöţ ƀé ŕéšţöŕéð ~~~~~ ~~~~~ ~]';

  @override
  String get backupRestoreFailedBody =>
      '[Ƒîñåñçé Ţŕåçķéŕ ŵîļļ šţåŕţ ŵîţĥ ţĥé ðåţå ţĥîš ðéṽîçé ĥöļðš ñöŵ. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get backupContinue => '[Çöñţîñûé ~~~~]';

  @override
  String get restoreOfferTitle => '[Ŕéšţöŕé ƒŕöɱ å ƀåçķûþ? ~~~~~ ~~~]';

  @override
  String get restoreOfferBody =>
      '[Îƒ ýöû ĥåṽé å Ƒîñåñçé Ţŕåçķéŕ ƀåçķûþ, ýöû çåñ ŕéšţöŕé îţ ñöŵ, ƀéƒöŕé ţĥîš ðéṽîçé ƒéţçĥéš ýöûŕ ðåţå. Ýöûŕ ƀåñķ ðåţå åñð šýñçéð çĥåñĝéš çöɱé ƀåçķ ƒŕöɱ ţĥé šéŕṽéŕ éîţĥéŕ ŵåý; å ƀåçķûþ åļšö ƀŕîñĝš ŕéçéîþţ þĥöţöš åñð ŵĥåţ ŵåš ķéþţ öñļý öñ ýöûŕ öļð ðéṽîçé. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get restoreOfferStartFresh => '[Šţåŕţ ƒŕéšĥ ~~~~]';

  @override
  String get erasingTitle => '[Éŕåšîñĝ ţĥîš ðéṽîçé\'š ðåţå… ~~~~~ ~~~~]';

  @override
  String get eraseFailedTitle =>
      '[Ţĥîš ðéṽîçé\'š ðåţå çöûļð ñöţ ƀé éŕåšéð çöɱþļéţéļý ~~~~~ ~~~~~ ~~~~~ ~~]';

  @override
  String eraseFailedBody(String repeated) {
    String _temp0 = intl.Intl.selectLogic(repeated, {
      'true': 'Ţĥé åþþ ðöéš ñöţ šţåŕţ öñ ŵĥåţ îš ļéƒţ. Ţŕý åĝåîñ; ŵĥåţ îš åļŕéåðý éŕåšéð šţåýš éŕåšéð. Îƒ ţĥîš ķééþš ƒåîļîñĝ, çļéåŕ ţĥé åþþ\'š šţöŕåĝé îñ Åñðŕöîð\'š šéţţîñĝš. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~',
      'other': 'Ţĥé åþþ ðöéš ñöţ šţåŕţ öñ ŵĥåţ îš ļéƒţ. Ţŕý åĝåîñ; ŵĥåţ îš åļŕéåðý éŕåšéð šţåýš éŕåšéð. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~',
    });
    return '[$_temp0]';
  }

  @override
  String get eraseTryAgain => '[Ţŕý åĝåîñ ~~~~]';

  @override
  String get erasedAccountTitle =>
      '[Ýöûŕ åççöûñţ åñð ţĥîš ðéṽîçé\'š ðåţå ŵéŕé ðéļéţéð ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get erasedAccountBody =>
      '[Éṽéŕý ļîñķéð ƀåñķ ŵåš ðîšçöññéçţéð, éṽéŕý ŕéçöŕð öñ ţĥé šéŕṽéŕ ŵåš ðéļéţéð, åñð ýöûŕ öţĥéŕ ðéṽîçéš ŵéŕé šîĝñéð öûţ. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String get erasedDeviceTitle =>
      '[Ţĥîš ðéṽîçé\'š ðåţå ŵåš éŕåšéð ~~~~~ ~~~~~]';

  @override
  String get erasedDeviceBody =>
      '[Ýöûŕ åççöûñţ îš ûñçĥåñĝéð. Šîĝñ îñ åĝåîñ ţö ƀŕîñĝ ƀåçķ ýöûŕ ƀåñķ ðåţå åñð éṽéŕýţĥîñĝ ţĥåţ ĥåð šýñçéð. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String get erasedDone => '[Ðöñé ~~]';

  @override
  String get settingsEraseDevice =>
      '[Šîĝñ öûţ åñð éŕåšé ţĥîš ðéṽîçé ~~~~~ ~~~~~]';

  @override
  String get settingsDeleteAccount => '[Ðéļéţé åççöûñţ ~~~~~ ~]';

  @override
  String get deleteAccountTitle => '[Ðéļéţé åççöûñţ ~~~~~ ~]';

  @override
  String get deleteAccountIntro => '[Ðéļéţîñĝ ýöûŕ åççöûñţ: ~~~~~ ~~~]';

  @override
  String get deleteAccountEffectBanks =>
      '[Ðîšçöññéçţš éṽéŕý ļîñķéð ƀåñķ åţ Þļåîð ~~~~~ ~~~~~ ~~~~]';

  @override
  String get deleteAccountEffectServer =>
      '[Ðéļéţéš éṽéŕý ŕéçöŕð öƒ ýöûŕš öñ ţĥé šéŕṽéŕ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get deleteAccountEffectDevice =>
      '[Éŕåšéš ţĥîš ðéṽîçé\'š ðåţå ~~~~~ ~~~~]';

  @override
  String get deleteAccountEffectOthers =>
      '[Šîĝñš öûţ ýöûŕ öţĥéŕ ðéṽîçéš ~~~~~ ~~~~~]';

  @override
  String get deleteAccountPermanent =>
      '[Ţĥîš çåññöţ ƀé ûñðöñé. Ýöûŕ öţĥéŕ ðéṽîçéš ķééþ ŵĥåţ ţĥéý ĥöļð ûñţîļ ýöû éŕåšé ţĥéɱ. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~]';

  @override
  String get deleteAccountConfirmLabel =>
      '[Ţýþé ýöûŕ éɱåîļ ţö çöñƒîŕɱ ~~~~~ ~~~~]';

  @override
  String deleteAccountConfirmHelper(String email) {
    return '[Ýöûŕ åççöûñţ\'š éɱåîļ îš $email ~~~~~ ~~~]';
  }

  @override
  String get deleteAccountSubmit => '[Ðéļéţé åççöûñţ ~~~~~ ~]';

  @override
  String get deleteAccountDeleting => '[Ðéļéţîñĝ ýöûŕ åççöûñţ ~~~~~ ~~~]';

  @override
  String deleteAccountFailed(String reason) {
    return '[Ýöûŕ åççöûñţ ŵåš ñöţ ðéļéţéð. $reason ~~~~~ ~~~~~]';
  }

  @override
  String get deleteAccountFailedPlaid =>
      '[Å ļîñķéð ƀåñķ çöûļð ñöţ ƀé ðîšçöññéçţéð. Ţŕý åĝåîñ ļåţéŕ. ~~~~~ ~~~~~ ~~~~~ ~~~~]';

  @override
  String get deleteAccountFailedNetwork =>
      '[Çåñ\'ţ ŕéåçĥ ţĥé šéŕṽéŕ. Çĥéçķ ýöûŕ çöññéçţîöñ åñð ţŕý åĝåîñ. ~~~~~ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get deleteAccountFailedOther =>
      '[Šöɱéţĥîñĝ ŵéñţ ŵŕöñĝ. Ţŕý åĝåîñ. ~~~~~ ~~~~~ ~]';

  @override
  String get eraseDeviceTitle => '[Éŕåšé ţĥîš ðéṽîçé\'š ðåţå? ~~~~~ ~~~]';

  @override
  String get eraseDeviceBody =>
      '[Ţĥîš ðéṽîçé šîĝñš öûţ åñð éṽéŕýţĥîñĝ îţ ķééþš îš ðéļéţéð ƒŕöɱ îţ. Çĥåñĝéš ñöţ ýéţ šýñçéð åñð ŕéçéîþţ þĥöţöš åŕé ļöšţ. Ýöûŕ åççöûñţ šţåýš: ýöûŕ ƀåñķ ðåţå åñð éṽéŕýţĥîñĝ ţĥåţ šýñçéð çöɱé ƀåçķ ŵĥéñ ýöû šîĝñ îñ åĝåîñ. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~]';

  @override
  String eraseDevicePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count çĥåñĝéš ñöţ ýéţ šýñçéð ~~~~~ ~~~',
      one: '1 çĥåñĝé ñöţ ýéţ šýñçéð ~~~~~ ~~~',
    );
    return '[$_temp0]';
  }

  @override
  String get eraseDeviceConfirm => '[Éŕåšé ~~]';

  @override
  String get settingsDevices => '[Ðéṽîçéš ~~~]';

  @override
  String get devicesTitle => '[Ðéṽîçéš ~~~]';

  @override
  String get devicesThisDevice => '[Ţĥîš ðéṽîçé ~~~~]';

  @override
  String devicesLastSeen(String time) {
    return '[Ļåšţ šééñ $time ~~~~]';
  }

  @override
  String get devicesNeverSynced => '[Ñöţ šýñçéð ýéţ ~~~~~]';

  @override
  String devicesActions(String name) {
    return '[Åçţîöñš ƒöŕ $name ~~~~]';
  }

  @override
  String get devicesRemove => '[Ŕéɱöṽé ~~~]';

  @override
  String devicesRemoveTitle(String name) {
    return '[Ŕéɱöṽé $name? ~~~]';
  }

  @override
  String get devicesRemoveBody =>
      '[Îţ îš šîĝñéð öûţ åñð ĥåš ţö šîĝñ îñ åĝåîñ. Ŵĥåţ îţ ķééþš šţåýš öñ îţ. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get devicesRemoveThisTitle => '[Ŕéɱöṽé ţĥîš ðéṽîçé? ~~~~~ ~~]';

  @override
  String get devicesRemoveThisBody =>
      '[Ţĥîš ðéṽîçé šîĝñš öûţ. Îţš ðåţå šţåýš öñ îţ ûñţîļ ýöû éŕåšé îţ. ~~~~~ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String devicesRemoveFailed(String name) {
    return '[Çöûļðñ\'ţ ŕéɱöṽé $name. Ţŕý åĝåîñ. ~~~~~ ~~~~]';
  }

  @override
  String get devicesSignOutOthers => '[Šîĝñ öûţ éṽéŕýŵĥéŕé éļšé ~~~~~ ~~~~]';

  @override
  String get devicesSignOutOthersTitle =>
      '[Šîĝñ öûţ éṽéŕýŵĥéŕé éļšé? ~~~~~ ~~~~]';

  @override
  String get devicesSignOutOthersBody =>
      '[Éṽéŕý öţĥéŕ ðéṽîçé šîĝñš öûţ åñð ĥåš ţö šîĝñ îñ åĝåîñ. Ţĥîš ðéṽîçé šţåýš šîĝñéð îñ. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~]';

  @override
  String devicesSignOutOthersDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Šîĝñéð öûţ $count ðéṽîçéš ~~~~~ ~~',
      one: 'Šîĝñéð öûţ 1 ðéṽîçé ~~~~~ ~',
    );
    return '[$_temp0]';
  }

  @override
  String devicesSignOutOthersFailed(int failed) {
    String _temp0 = intl.Intl.pluralLogic(
      failed,
      locale: localeName,
      other:
          '$failed ðéṽîçéš çöûļð ñöţ ƀé šîĝñéð öûţ. Ţŕý åĝåîñ. ~~~~~ ~~~~~ ~~~~',
      one: '1 ðéṽîçé çöûļð ñöţ ƀé šîĝñéð öûţ. Ţŕý åĝåîñ. ~~~~~ ~~~~~ ~~~~',
    );
    return '[$_temp0]';
  }

  @override
  String get devicesLoadFailed => '[Çöûļðñ\'ţ ļöåð ýöûŕ ðéṽîçéš. ~~~~~ ~~~~]';

  @override
  String get devicesRetry => '[Ţŕý åĝåîñ ~~~~]';

  @override
  String get signInRemoteNotice =>
      '[Ţĥîš ðéṽîçé ŵåš šîĝñéð öûţ ŕéɱöţéļý. Îţš ðåţå îš šţîļļ ĥéŕé. ~~~~~ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get signInEraseDevice => '[Éŕåšé ţĥîš ðéṽîçé\'š ðåţå ~~~~~ ~~~]';

  @override
  String syncConflicts(int count) {
    return '[Çöñƒļîçţš ($count) ~~~~]';
  }

  @override
  String get syncConflictsHint =>
      '[Çĥåñĝéš ɱåðé öñ ţŵö ðéṽîçéš åţ åƀöûţ ţĥé šåɱé ţîɱé ~~~~~ ~~~~~ ~~~~~ ~~]';

  @override
  String get conflictsTitle => '[Çöñƒļîçţš ~~~~]';

  @override
  String get conflictsIntro =>
      '[Éåçĥ öƒ ţĥéšé îš å çĥåñĝé ɱåðé öñ ţĥîš ðéṽîçé ţĥåţ å çĥåñĝé ƒŕöɱ åñöţĥéŕ ðéṽîçé ŕéþļåçéð å ƒéŵ ɱîñûţéš ļåţéŕ. Çĥööšé ţĥé ṽåļûé ţö ķééþ. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~]';

  @override
  String get conflictsEmptyHeadline => '[Ñö çöñƒļîçţš ~~~~~]';

  @override
  String get conflictsEmptyBody =>
      '[Ŵĥéñ å çĥåñĝé ɱåðé ĥéŕé åñð öñé ƒŕöɱ åñöţĥéŕ ðéṽîçé ɱééţ ŵîţĥîñ ɱîñûţéš, ƀöţĥ åŕé šĥöŵñ ĥéŕé šö ýöû çåñ çĥööšé. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String conflictEntityType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'transaction': 'Ţŕåñšåçţîöñ ~~~~~',
      'account': 'Åççöûñţ ~~~',
      'category': 'Çåţéĝöŕý ~~~~',
      'settings': 'Šéţţîñĝš ~~~~',
      'rule': 'Ŕûļé ~~',
      'budget': 'Ɓûðĝéţ ~~~',
      'recurringStream': 'Šûƀšçŕîþţîöñ ~~~~~',
      'billReminder': 'Ɓîļļ ~~',
      'goal': 'Ĝöåļ ~~',
      'goalContribution': 'Ĝöåļ çöñţŕîƀûţîöñ ~~~~~ ~~',
      'other': 'Ŕéçöŕð ~~~',
    });
    return '[$_temp0]';
  }

  @override
  String conflictField(String field) {
    String _temp0 = intl.Intl.selectLogic(field, {
      'name': 'Ñåɱé ~~',
      'notes': 'Ñöţéš ~~',
      'category': 'Çåţéĝöŕý ~~~~',
      'tags': 'Ţåĝš ~~',
      'splits': 'Šþļîţš ~~~',
      'amount': 'Åɱöûñţ ~~~',
      'day': 'Ðåţé ~~',
      'hidden': 'Ĥîððéñ ~~~',
      'receipt': 'Ŕéçéîþţ ~~~',
      'account': 'Åççöûñţ ~~~',
      'theme': 'Ţĥéɱé ~~',
      'dynamicColor': 'Ðýñåɱîç çöļöûŕ ~~~~~ ~',
      'muted': 'Ṁûţéð ~~',
      'subscription': 'Šûƀšçŕîþţîöñ ~~~~~',
      'target': 'Ţåŕĝéţ ~~~',
      'targetDay': 'Ţåŕĝéţ ðåţé ~~~~',
      'note': 'Ñöţé ~~',
      'other': '',
    });
    return '[$_temp0]';
  }

  @override
  String get conflictThisValue => '[Ţĥîš ðéṽîçé\'š ṽåļûé ~~~~~ ~~]';

  @override
  String get conflictOtherValue => '[Ţĥé öţĥéŕ ṽåļûé ~~~~~ ~]';

  @override
  String get conflictThisDevice => '[Ţĥîš ðéṽîçé ~~~~]';

  @override
  String conflictFrom(String device, String time) {
    return '[$device, $time]';
  }

  @override
  String get conflictKeepThis => '[Ķééþ ţĥîš ðéṽîçé\'š ṽåļûé ~~~~~ ~~~]';

  @override
  String get conflictKeepOther => '[Ķééþ ţĥé öţĥéŕ ~~~~~]';

  @override
  String get conflictNoValue => '[Ñöñé ~~]';

  @override
  String get conflictYes => '[Ýéš ~~]';

  @override
  String get conflictNo => '[Ñö ~]';

  @override
  String conflictSplits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šþļîţš ~~~',
      one: '1 šþļîţ ~~',
      zero: 'Ñö šþļîţš ~~~~',
    );
    return '[$_temp0]';
  }

  @override
  String get conflictKeepFailed =>
      '[Ţĥé ṽåļûé çöûļð ñöţ ƀé ķéþţ. Ţŕý åĝåîñ. ~~~~~ ~~~~~ ~~]';

  @override
  String get receiptDownloading => '[Ðöŵñļöåðîñĝ ţĥé ŕéçéîþţ ~~~~~ ~~~~]';

  @override
  String get receiptDownloadFailed =>
      '[Ţĥé ŕéçéîþţ çöûļð ñöţ ƀé ðöŵñļöåðéð ~~~~~ ~~~~~ ~~]';

  @override
  String get receiptNotOnServer =>
      '[Ţĥé ŕéçéîþţ ĥåš ñöţ ŕéåçĥéð ţĥé šéŕṽéŕ ýéţ ~~~~~ ~~~~~ ~~~~]';

  @override
  String get receiptRetry => '[Ţŕý åĝåîñ ~~~~]';

  @override
  String get conflictPhotoHere => '[Þĥöţö, öñ ţĥîš ðéṽîçé ~~~~~ ~~]';

  @override
  String get conflictPhotoNotHere => '[Þĥöţö, ñöţ öñ ţĥîš ðéṽîçé ~~~~~ ~~~]';

  @override
  String get conflictPhotoGone =>
      '[Ţĥîš þĥöţö îš ñö ļöñĝéŕ öñ ţĥîš ðéṽîçé ~~~~~ ~~~~~ ~~~]';

  @override
  String widgetUpdated(String time) {
    return '[Ûþðåţéð $time ~~~]';
  }

  @override
  String get widgetNetWorthObserved => '[Ƒŕöɱ åççöûñţ ƀåļåñçéš ~~~~~ ~~~]';

  @override
  String widgetNetWorthSpoken(String amount, String basis) {
    return '[Ñéţ ŵöŕţĥ $amount, $basis ~~~~]';
  }

  @override
  String widgetAccountSpoken(String name, String balance, String basis) {
    return '[$name, $balance, $basis]';
  }

  @override
  String widgetBillMissed(String due) {
    return '[Ṁîššéð, $due ~~~]';
  }

  @override
  String widgetBillSpoken(String name, String due, String amount) {
    return '[$name, $due, $amount]';
  }

  @override
  String widgetBillSpokenNoAmount(String name, String due) {
    return '[$name, $due]';
  }

  @override
  String get widgetNetWorthSpokenHidden =>
      '[Ñéţ ŵöŕţĥ, ĥîððéñ ŵĥîļé ţĥé åþþ îš ļöçķéð ~~~~~ ~~~~~ ~~~~]';

  @override
  String widgetAccountSpokenHidden(String name) {
    return '[$name, ƀåļåñçé ĥîððéñ ŵĥîļé ţĥé åþþ îš ļöçķéð ~~~~~ ~~~~~ ~~~]';
  }

  @override
  String widgetBudgetSpokenHidden(String name) {
    return '[$name, šþéñðîñĝ ĥîððéñ ŵĥîļé ţĥé åþþ îš ļöçķéð ~~~~~ ~~~~~ ~~~~]';
  }

  @override
  String widgetBillSpokenHidden(String name, String due) {
    return '[$name, $due, åɱöûñţ ĥîððéñ ŵĥîļé ţĥé åþþ îš ļöçķéð ~~~~~ ~~~~~ ~~~]';
  }

  @override
  String get shortcutAddTransaction => '[Åðð ţŕåñšåçţîöñ ~~~~~ ~]';

  @override
  String get shortcutScanReceipt => '[Šçåñ ŕéçéîþţ ~~~~~]';

  @override
  String get shortcutSearch => '[Šéåŕçĥ ţŕåñšåçţîöñš ~~~~~ ~~~]';

  @override
  String get shortcutSync => '[Šýñç ñöŵ ~~~]';

  @override
  String get budgetAlertsChannelName => '[Ɓûðĝéţ åļéŕţš ~~~~~]';

  @override
  String get budgetAlertsChannelDescription =>
      '[Ŵĥéñ å ƀûðĝéţ ŕéåçĥéš 80 % öŕ åļļ öƒ ŵĥåţ îţ ĥåš ~~~~~ ~~~~~ ~~~~]';

  @override
  String get weeklySummaryChannelName => '[Ŵééķļý šûɱɱåŕý ~~~~~ ~]';

  @override
  String get weeklySummaryChannelDescription =>
      '[Ŵĥéñ ļåšţ ŵééķ\'š šûɱɱåŕý îš ŕéåðý ~~~~~ ~~~~~ ~]';

  @override
  String get syncProblemsChannelName => '[Šýñç þŕöƀļéɱš ~~~~~]';

  @override
  String get syncProblemsChannelDescription =>
      '[Ŵĥéñ šýñç ķééþš ƒåîļîñĝ, ýöû åŕé šîĝñéð öûţ, öŕ å ƀåñķ ñééðš ýöû ţö šîĝñ îñ åĝåîñ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get notificationBudgetTitle => '[Ɓûðĝéţ åļéŕţ ~~~~~]';

  @override
  String get notificationWeeklySummaryText =>
      '[Šéé ŵĥåţ çåɱé îñ åñð ŵéñţ öûţ ļåšţ ŵééķ ~~~~~ ~~~~~ ~~~]';

  @override
  String get notificationSyncTitle => '[Šýñç ñééðš ýöû ~~~~~]';

  @override
  String alertSyncFailing(String date) {
    return '[Šýñç ĥåš ñöţ ŵöŕķéð šîñçé $date ~~~~~ ~~~~]';
  }

  @override
  String get alertSyncSignedOut =>
      '[Ýöû ŵéŕé šîĝñéð öûţ. Šîĝñ îñ åĝåîñ ţö ķééþ šýñçîñĝ ~~~~~ ~~~~~ ~~~~~ ~]';

  @override
  String get alertBankNeedsAttention =>
      '[Å ļîñķéð ƀåñķ ñééðš ýöû ţö šîĝñ îñ ţö îţ åĝåîñ ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get settingsNotifications => '[Ñöţîƒîçåţîöñš ~~~~~ ~]';

  @override
  String get settingsNotificationsSubtitle =>
      '[Åļéŕţš, ŕéɱîñðéŕš åñð ƀåçķĝŕöûñð šýñç ~~~~~ ~~~~~ ~~~]';

  @override
  String get notificationsAppOff =>
      '[Ñöţîƒîçåţîöñš åŕé öƒƒ ƒöŕ ţĥîš åþþ ~~~~~ ~~~~~ ~~]';

  @override
  String get notificationsTurnOn => '[Ţûŕñ öñ ñöţîƒîçåţîöñš ~~~~~ ~~~]';

  @override
  String get notificationsChannelOn => '[Öñ ~]';

  @override
  String get notificationsChannelOff => '[Öƒƒ ~~]';

  @override
  String get notificationsChannelAppOff =>
      '[Öƒƒ: ñöţîƒîçåţîöñš åŕé öƒƒ ƒöŕ ţĥîš åþþ ~~~~~ ~~~~~ ~~~]';

  @override
  String get notificationsChannelHint =>
      '[Öþéñš ţĥîš ķîñð\'š šéţţîñĝš îñ Åñðŕöîð ~~~~~ ~~~~~ ~~~]';

  @override
  String get backgroundSyncTitle => '[Ɓåçķĝŕöûñð šýñç ~~~~~ ~]';

  @override
  String get backgroundSyncSchedule =>
      '[Åƀöûţ éṽéŕý ĥöûŕ, ŵĥéñ öñļîñé åñð ţĥé ƀåţţéŕý îšñ\'ţ ļöŵ ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String backgroundSyncLastRun(String time, String result) {
    return '[Ļåšţ ŕûñ $time: $result ~~~]';
  }

  @override
  String get backgroundSyncNever => '[Ĥåš ñöţ ŕûñ ýéţ ~~~~~]';

  @override
  String get backgroundSyncUnavailable =>
      '[Ñöţ åṽåîļåƀļé îñ ţĥé ðéɱö ~~~~~ ~~~~]';

  @override
  String get backgroundResultSynced => '[šýñçéð ~~~]';

  @override
  String get backgroundResultOffline => '[ñö ñéţŵöŕķ ~~~~]';

  @override
  String get backgroundResultFailed => '[ţĥé šéŕṽéŕ ƒåîļéð ~~~~~ ~]';

  @override
  String get backgroundResultSessionEnded => '[šîĝñéð öûţ ~~~~]';

  @override
  String get backgroundResultSkipped => '[ñöţĥîñĝ ţö ðö ~~~~~]';

  @override
  String get backgroundResultTimedOut => '[ţööķ ţöö ļöñĝ ~~~~~]';

  @override
  String get backgroundRestricted =>
      '[Åñðŕöîð îš ļîɱîţîñĝ ţĥîš åþþ îñ ţĥé ƀåçķĝŕöûñð, šö ƀåçķĝŕöûñð šýñç ɱåý ñöţ ŕûñ. Åļļöŵ ƀåçķĝŕöûñð ûšé îñ ţĥé åþþ\'š ƀåţţéŕý šéţţîñĝš. ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~]';

  @override
  String get backgroundOpenAppSettings => '[Åþþ šéţţîñĝš ~~~~~]';

  @override
  String get backgroundResultHeld =>
      '[ĥéļð ûñţîļ ţĥé ŕéšţöŕé öƒƒéŕ îš åñšŵéŕéð ~~~~~ ~~~~~ ~~~~]';

  @override
  String get notificationsLoadFailed =>
      '[Ţĥé ñöţîƒîçåţîöñ šéţţîñĝš çöûļð ñöţ ƀé ŕéåð ~~~~~ ~~~~~ ~~~~~]';

  @override
  String get notificationsTryAgain => '[Ţŕý åĝåîñ ~~~~]';

  @override
  String get backgroundSyncRunningNow => '[Ŕûññîñĝ ñöŵ ~~~~]';

  @override
  String get backgroundSyncNotScheduled =>
      '[Ñöţ šçĥéðûļéð: îţ šţåŕţš öñçé ýöû šîĝñ îñ ~~~~~ ~~~~~ ~~~~]';
}
