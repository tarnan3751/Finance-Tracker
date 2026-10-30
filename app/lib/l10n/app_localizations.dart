import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Label of the Accounts tab in the bottom navigation bar, and the title of the Accounts screen.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get navAccounts;

  /// Label of the Transactions tab in the bottom navigation bar, and the title of the Transactions screen.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// Label of the Plan tab in the bottom navigation bar (budgets, bills and the forecast), and the title of each of its screens.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get navPlan;

  /// The Plan tab's segment that shows the budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get planBudgets;

  /// The Plan tab's segment that shows the bills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get planBills;

  /// The Plan tab's segment that shows the cash-flow forecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get planForecast;

  /// Label of the Insights tab in the bottom navigation bar (reports, net worth, investments and goals), and the title of each of its screens.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navInsights;

  /// The Insights tab's segment that shows the spending and income reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get insightsReports;

  /// The Insights tab's segment that shows net worth over time.
  ///
  /// In en, this message translates to:
  /// **'Net worth'**
  String get insightsNetWorth;

  /// The Insights tab's segment that shows the holdings.
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get insightsInvestments;

  /// The Insights tab's segment that shows the savings goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get insightsGoals;

  /// Headline of an Insights segment whose content is not available yet.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get insightsComingHeadline;

  /// Body of an Insights segment whose content is not available yet.
  ///
  /// In en, this message translates to:
  /// **'This part of Insights is on its way.'**
  String get insightsComingBody;

  /// A whole percent.
  ///
  /// In en, this message translates to:
  /// **'{percent} %'**
  String reportsPercent(int percent);

  /// A whole percent increase, with its plus sign.
  ///
  /// In en, this message translates to:
  /// **'+{percent} %'**
  String reportsPercentUp(int percent);

  /// A change in an amount with its percent, for example "+$12.00 (+15 %)".
  ///
  /// In en, this message translates to:
  /// **'{amount} ({percent})'**
  String reportsChange(String amount, String percent);

  /// A change in an amount that was zero before.
  ///
  /// In en, this message translates to:
  /// **'{amount} (new)'**
  String reportsChangeNew(String amount);

  /// Button that shows the reports' charts as tables.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get reportsShowTables;

  /// Button that shows the reports' tables as charts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get reportsShowCharts;

  /// Spending, as a choice of what the category breakdown shows and in chart legends.
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get reportsSpending;

  /// Income, as a choice of what the category breakdown shows and in chart legends.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get reportsIncome;

  /// How much was spent in a period.
  ///
  /// In en, this message translates to:
  /// **'Spent {amount}'**
  String reportsSpendingAmount(String amount);

  /// How much came in during a period.
  ///
  /// In en, this message translates to:
  /// **'Income {amount}'**
  String reportsIncomeAmount(String amount);

  /// Income less spending in a period.
  ///
  /// In en, this message translates to:
  /// **'Net {amount}'**
  String reportsNetAmount(String amount);

  /// Shown instead of the savings rate when a period has no income.
  ///
  /// In en, this message translates to:
  /// **'No income in this period'**
  String get reportsNoIncome;

  /// The savings rate: the share of a period's income not spent.
  ///
  /// In en, this message translates to:
  /// **'Kept {percent} of income'**
  String reportsSavingsRate(String percent);

  /// Heading of the comparison with the previous period.
  ///
  /// In en, this message translates to:
  /// **'Against the period before'**
  String get reportsVsPrevious;

  /// Heading of the comparison with the same period a year earlier.
  ///
  /// In en, this message translates to:
  /// **'Against a year before'**
  String get reportsVsYearAgo;

  /// The change in spending in a comparison.
  ///
  /// In en, this message translates to:
  /// **'Spending {change}'**
  String reportsSpendingChange(String change);

  /// The change in income in a comparison.
  ///
  /// In en, this message translates to:
  /// **'Income {change}'**
  String reportsIncomeChange(String change);

  /// Note under the comparisons while the period is still running.
  ///
  /// In en, this message translates to:
  /// **'Compared over the first {days, plural, =1{day} other{{days} days}} of each period'**
  String reportsSameElapsed(int days);

  /// Heading of the category breakdown.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get reportsByCategory;

  /// Button that returns from a category group to every category.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get reportsAllCategories;

  /// The rows filed under a category group itself, not under one of its children.
  ///
  /// In en, this message translates to:
  /// **'{name} itself'**
  String reportsGroupOwn(String name);

  /// Shown in a report section with nothing to show.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this period.'**
  String get reportsNothingInPeriod;

  /// What a screen reader hears for the category chart.
  ///
  /// In en, this message translates to:
  /// **'{scope} by category: {total} in all. The largest is {name}, {amount}.'**
  String reportsDonutSummary(
    String scope,
    String total,
    String name,
    String amount,
  );

  /// A row of the category table, read by a screen reader.
  ///
  /// In en, this message translates to:
  /// **'{name}: {amount}, {share} of the total'**
  String reportsCategoryRow(String name, String amount, String share);

  /// Heading of the income and spending bars.
  ///
  /// In en, this message translates to:
  /// **'Income and spending'**
  String get reportsIncomeAndSpending;

  /// What a screen reader hears for the income and spending bars.
  ///
  /// In en, this message translates to:
  /// **'Income and spending over the last {count} periods. This period: income {income}, spending {spending}.'**
  String reportsBarsSummary(int count, String income, String spending);

  /// Heading of the trend chart.
  ///
  /// In en, this message translates to:
  /// **'Trend over {count} periods'**
  String reportsTrend(int count);

  /// What a screen reader hears for the trend chart.
  ///
  /// In en, this message translates to:
  /// **'Over the last {count} periods, spending went from {fromSpending} to {toSpending} and income from {fromIncome} to {toIncome}.'**
  String reportsTrendSummary(
    int count,
    String fromSpending,
    String toSpending,
    String fromIncome,
    String toIncome,
  );

  /// A row of the periods table, read by a screen reader.
  ///
  /// In en, this message translates to:
  /// **'{period}: income {income}, spending {spending}, net {net}'**
  String reportsPeriodRow(
    String period,
    String income,
    String spending,
    String net,
  );

  /// Heading of the merchants spent at most.
  ///
  /// In en, this message translates to:
  /// **'Top merchants'**
  String get reportsTopMerchants;

  /// How many purchases at a merchant.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 purchase} other{{count} purchases}}'**
  String reportsMerchantCount(int count);

  /// Heading of the categories and merchants whose spending changed most.
  ///
  /// In en, this message translates to:
  /// **'Top movers'**
  String get reportsTopMovers;

  /// Subheading of the categories among the top movers.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get reportsMoversCategories;

  /// Subheading of the merchants among the top movers.
  ///
  /// In en, this message translates to:
  /// **'Merchants'**
  String get reportsMoversMerchants;

  /// Shown when no spending changed.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed from the period before.'**
  String get reportsNoMovers;

  /// A mover's spending in the period before and in this one.
  ///
  /// In en, this message translates to:
  /// **'{before} before, {now} now'**
  String reportsMoverAmounts(String before, String now);

  /// Heading of the transactions that stand out (a hint, not a verdict).
  ///
  /// In en, this message translates to:
  /// **'Worth a look'**
  String get anomaliesTitle;

  /// Shown when no transaction stands out.
  ///
  /// In en, this message translates to:
  /// **'Nothing stands out in this period.'**
  String get anomaliesNone;

  /// Why a transaction stands out: far more than usual at its merchant.
  ///
  /// In en, this message translates to:
  /// **'Usually about {amount} here'**
  String anomalyUsualMerchant(String amount);

  /// Why a transaction stands out: far more than usual in its category.
  ///
  /// In en, this message translates to:
  /// **'Usually about {amount} in this category'**
  String anomalyUsualCategory(String amount);

  /// Why a transaction stands out: a merchant not used for six months.
  ///
  /// In en, this message translates to:
  /// **'New: not seen in the last six months'**
  String get anomalyNewMerchant;

  /// Snack bar after dismissing a flagged transaction.
  ///
  /// In en, this message translates to:
  /// **'Dismissed. It won\'t be flagged again on this device.'**
  String get anomalyDismissed;

  /// Tooltip of the button that dismisses a flagged transaction.
  ///
  /// In en, this message translates to:
  /// **'Dismiss {name}'**
  String anomalyDismissTooltip(String name);

  /// The entry on the Reports segment that opens the weekly summary.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary'**
  String get reportsWeeklySummary;

  /// Title of the weekly summary screen.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary'**
  String get weeklyTitle;

  /// A week's first and last days.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String weeklyRange(String start, String end);

  /// Heading of the last complete week in the weekly summary.
  ///
  /// In en, this message translates to:
  /// **'Last week, {range}'**
  String weeklyLastWeek(String range);

  /// Heading of the current week in the weekly summary.
  ///
  /// In en, this message translates to:
  /// **'This week so far'**
  String get weeklyThisWeek;

  /// Heading of a week's biggest categories.
  ///
  /// In en, this message translates to:
  /// **'Spent most on'**
  String get weeklyTopCategories;

  /// One of a week's biggest categories.
  ///
  /// In en, this message translates to:
  /// **'{name}: {amount}'**
  String weeklyCategoryLine(String name, String amount);

  /// A week's biggest merchant.
  ///
  /// In en, this message translates to:
  /// **'Spent most at {name}: {amount}'**
  String weeklyTopMerchant(String name, String amount);

  /// Shown when a week has no spending.
  ///
  /// In en, this message translates to:
  /// **'No spending this week.'**
  String get weeklyNoSpending;

  /// Heading of the bills due in the coming week.
  ///
  /// In en, this message translates to:
  /// **'Bills due next week'**
  String get weeklyBillsNextWeek;

  /// Shown when no bill is due in the coming week.
  ///
  /// In en, this message translates to:
  /// **'No bills due next week.'**
  String get weeklyNoBills;

  /// Heading of the budgets in the weekly summary.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get weeklyBudgets;

  /// Shown in the weekly summary when there are no budgets.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet.'**
  String get weeklyNoBudgets;

  /// A budget's standing in the weekly summary.
  ///
  /// In en, this message translates to:
  /// **'{spent} of {available} spent, {left} left'**
  String weeklyBudgetLeft(String spent, String available, String left);

  /// A budget over its amount in the weekly summary.
  ///
  /// In en, this message translates to:
  /// **'{spent} of {available} spent, over by {over}'**
  String weeklyBudgetOver(String spent, String available, String over);

  /// The in-app notice that the weekly summary for the week just ended is ready.
  ///
  /// In en, this message translates to:
  /// **'Your weekly summary is ready'**
  String get alertWeeklySummary;

  /// Label of the Settings tab in the bottom navigation bar, and the title of the Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Headline of the Accounts screen when the user has no accounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get accountsEmptyHeadline;

  /// Supporting text of the Accounts screen when the user has no accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts you add or connect will appear here.'**
  String get accountsEmptyBody;

  /// Headline of the Transactions screen when there are no transactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get transactionsEmptyHeadline;

  /// Supporting text of the Transactions screen when there are no transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions you add or sync will appear here.'**
  String get transactionsEmptyBody;

  /// Heading of the settings section for theme and colors.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Label above the control that chooses between the system, light and dark themes.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeMode;

  /// Theme choice: follow the device's light or dark setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// Theme choice: always light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// Theme choice: always dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// Title of the switch that takes the app's colors from the device wallpaper (Material You).
  ///
  /// In en, this message translates to:
  /// **'Dynamic color'**
  String get settingsDynamicColor;

  /// Explanation under the dynamic color switch.
  ///
  /// In en, this message translates to:
  /// **'Use colors from your wallpaper when the device provides them'**
  String get settingsDynamicColorSubtitle;

  /// Heading of the settings section with the app's name, version, flavor and time zone.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Label of the row showing the app's name.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get aboutAppName;

  /// Label of the row showing the app's version and build number.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// The app's version followed by its build number, for example 1.0.0 (build 1).
  ///
  /// In en, this message translates to:
  /// **'{version} (build {buildNumber})'**
  String aboutVersionValue(String version, String buildNumber);

  /// Label of the row showing which build flavor runs (dev, demo or prod).
  ///
  /// In en, this message translates to:
  /// **'Flavor'**
  String get aboutFlavor;

  /// Label of the row showing the time zone the app computes dates in.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get aboutTimeZone;

  /// Headline of the screen shown instead of the app when the local database cannot be opened on this device.
  ///
  /// In en, this message translates to:
  /// **'Your data can\'t be opened'**
  String get databaseErrorTitle;

  /// Supporting text of the database error screen when the database failed to open for a reason other than its key or encryption (for example a damaged file).
  ///
  /// In en, this message translates to:
  /// **'Finance Tracker could not open its data on this device. Nothing has been deleted. Close the app and open it again; if this keeps happening, your data cannot be read on this device.'**
  String get databaseErrorBody;

  /// Supporting text of the database error screen when the database's encryption key is missing from, or unreadable in, the device's secure storage.
  ///
  /// In en, this message translates to:
  /// **'The key that unlocks your data on this device is missing or unreadable, so your data cannot be opened. Nothing has been deleted.'**
  String get databaseErrorKeyLost;

  /// Supporting text of the database error screen when the stored encryption key does not open the database file.
  ///
  /// In en, this message translates to:
  /// **'Your data on this device does not open with its key. Nothing has been deleted.'**
  String get databaseErrorKeyMismatch;

  /// Supporting text of the database error screen when the app's database library has no encryption support.
  ///
  /// In en, this message translates to:
  /// **'This version of Finance Tracker cannot encrypt data, so it will not open yours. Nothing has been deleted.'**
  String get databaseErrorNoEncryption;

  /// Button that saves the form being edited.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Button that closes a dialog without doing anything.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button or menu item that deletes the record shown.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Tooltip of the button that opens the editor of the record shown.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Action of the snack bar shown after a delete, which brings the record back.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Shown in place of a list when its data could not be read.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading this. Try again later.'**
  String get loadFailed;

  /// Two pieces of information on one caption line, such as an account name and a category name.
  ///
  /// In en, this message translates to:
  /// **'{first} · {second}'**
  String captionPair(String first, String second);

  /// What a screen reader says for a negative amount: the word for minus, then the amount without its sign.
  ///
  /// In en, this message translates to:
  /// **'minus {amount}'**
  String amountNegative(String amount);

  /// Caption under a balance computed by adding up the account's transactions (not reported by a bank).
  ///
  /// In en, this message translates to:
  /// **'from transactions'**
  String get balanceFromTransactions;

  /// Caption on a transaction in an account's detail: the account's balance after this transaction, computed from its transactions.
  ///
  /// In en, this message translates to:
  /// **'Running balance {amount}'**
  String runningBalance(String amount);

  /// Caption on a transaction in a linked account's detail: the account's balance after this transaction, worked back from the balance the bank reported.
  ///
  /// In en, this message translates to:
  /// **'Running balance {amount}, from the reported balance'**
  String runningBalanceFromReported(String amount);

  /// Caption under a balance the bank reported for a linked account (not computed from its transactions).
  ///
  /// In en, this message translates to:
  /// **'reported'**
  String get balanceReported;

  /// Caption under a linked account's balance on its detail: the balance as the bank reported it.
  ///
  /// In en, this message translates to:
  /// **'reported by {institution}'**
  String balanceReportedBy(String institution);

  /// Caption under a linked account's balance on its detail, when the bank's name is not known on the device yet.
  ///
  /// In en, this message translates to:
  /// **'reported by your bank'**
  String get balanceReportedByBank;

  /// When the bank reported the balance above, in the device's time zone.
  ///
  /// In en, this message translates to:
  /// **'as of {time}'**
  String balanceAsOf(String time);

  /// Caption under totals that add balances banks reported (linked accounts) and balances computed from transactions (manual accounts).
  ///
  /// In en, this message translates to:
  /// **'reported and from transactions'**
  String get balanceReportedAndFromTransactions;

  /// On a linked account's detail: the available balance the bank reported.
  ///
  /// In en, this message translates to:
  /// **'Available {amount}'**
  String accountAvailableBalance(String amount);

  /// On a linked account's detail: the credit limit the bank reported.
  ///
  /// In en, this message translates to:
  /// **'Credit limit {amount}'**
  String accountCreditLimit(String amount);

  /// The last digits of a linked account's number, after dots standing for the hidden digits.
  ///
  /// In en, this message translates to:
  /// **'•••• {mask}'**
  String accountMask(String mask);

  /// What a screen reader says for the last digits of a linked account's number.
  ///
  /// In en, this message translates to:
  /// **'ending in {mask}'**
  String accountMaskSemantics(String mask);

  /// Shown in place of a category name for a transaction with no category, or whose category was deleted.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// Button that opens the editor of a new account.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get accountAdd;

  /// Heading of the per-currency totals at the top of the account list.
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get accountsTotals;

  /// Title of the collapsed section of the account list that holds the hidden accounts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hidden account} other{{count} hidden accounts}}'**
  String accountsHidden(int count);

  /// Shown when the account asked for has been deleted or does not exist.
  ///
  /// In en, this message translates to:
  /// **'This account no longer exists.'**
  String get accountNotFound;

  /// Shown in an account's detail when it has no transactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions on this account yet.'**
  String get accountNoTransactions;

  /// Menu item that hides the account from the account list (it moves to the Hidden section).
  ///
  /// In en, this message translates to:
  /// **'Hide account'**
  String get accountHide;

  /// Menu item that moves a hidden account back into the account list.
  ///
  /// In en, this message translates to:
  /// **'Show account'**
  String get accountShow;

  /// Label in an account's detail saying the account is hidden from the account list.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get accountHiddenLabel;

  /// Title of the confirmation before deleting an account.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String accountDeleteTitle(String name);

  /// Body of the confirmation before deleting an account, saying how many transactions go with it.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{The account will be deleted.} =1{The account and its 1 transaction will be deleted.} other{The account and its {count} transactions will be deleted.}}'**
  String accountDeleteBody(int count);

  /// Title of the editor of a new account.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get accountNewTitle;

  /// Title of the editor of an existing account.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get accountEditTitle;

  /// Label of the account name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountName;

  /// Error under the account name field when it is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get accountNameRequired;

  /// Heading above the account type choices.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get accountType;

  /// Account type: a bank deposit account.
  ///
  /// In en, this message translates to:
  /// **'Checking or savings'**
  String get accountTypeDepository;

  /// Account type: a credit card.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get accountTypeCredit;

  /// Account type: a loan or mortgage.
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get accountTypeLoan;

  /// Account type: a brokerage or retirement account.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get accountTypeInvestment;

  /// Account type: anything else, such as cash.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get accountTypeOther;

  /// Label of the account currency field.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get accountCurrency;

  /// A currency shown as its ISO code and its symbol.
  ///
  /// In en, this message translates to:
  /// **'{code} ({symbol})'**
  String currencyValue(String code, String symbol);

  /// The account's currency, when it can no longer be changed.
  ///
  /// In en, this message translates to:
  /// **'{currency}. It can\'t change once the account has transactions.'**
  String accountCurrencyFixed(String currency);

  /// Snack bar shown when saving an account would change the currency of an account that has transactions.
  ///
  /// In en, this message translates to:
  /// **'The currency can\'t change: this account has transactions.'**
  String get accountCurrencyLocked;

  /// Snack bar shown when saving an account that was deleted meanwhile.
  ///
  /// In en, this message translates to:
  /// **'This account was deleted.'**
  String get accountDeleted;

  /// Label of the field for a new account's starting balance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance (optional)'**
  String get openingBalance;

  /// Explanation under the opening balance field.
  ///
  /// In en, this message translates to:
  /// **'Negative for money owed. Saved as a transaction.'**
  String get openingBalanceHelper;

  /// Label of the date of a new account's opening balance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance date'**
  String get openingBalanceDate;

  /// Description given to the transaction that holds a new account's opening balance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get openingBalanceName;

  /// Title of the currency picker.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyPickerTitle;

  /// Label of the search field of the currency picker.
  ///
  /// In en, this message translates to:
  /// **'Search currencies'**
  String get currencyPickerSearch;

  /// Error under an amount field that is empty or zero.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get amountRequired;

  /// Error under an amount field whose text is not an amount in the currency (for example, too many decimal places); the example shows the expected format.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount such as {example}'**
  String amountInvalid(String example);

  /// Error under an amount field when a negative number is typed where the sign is chosen separately.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount without a sign'**
  String get amountUnsigned;

  /// Button that opens the editor of a new transaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get transactionAdd;

  /// Label on a transaction the bank has not posted yet.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get transactionPending;

  /// Date header for transactions dated today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// Date header for transactions dated yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// Tooltip of the button that opens the transaction search field.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get transactionsSearch;

  /// Hint inside the transaction search field.
  ///
  /// In en, this message translates to:
  /// **'Search transactions'**
  String get transactionsSearchHint;

  /// Tooltip of the button that clears and closes the transaction search field.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get transactionsSearchClose;

  /// Tooltip of the button that opens the transaction filters, and the title of the filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get transactionsFilter;

  /// Headline of the transaction list when the search or filters match nothing.
  ///
  /// In en, this message translates to:
  /// **'No matching transactions'**
  String get transactionsNoMatchHeadline;

  /// Headline of the transaction list when the search text, with any filters, matches nothing; text is what the user typed.
  ///
  /// In en, this message translates to:
  /// **'No matches for “{text}”'**
  String transactionsNoMatchText(String text);

  /// Supporting text of the transaction list when the search or filters match nothing.
  ///
  /// In en, this message translates to:
  /// **'Try other words or remove a filter.'**
  String get transactionsNoMatchBody;

  /// Tooltip of the button on an active filter chip that removes that filter.
  ///
  /// In en, this message translates to:
  /// **'Remove filter {label}'**
  String filterRemove(String label);

  /// Button of the filter sheet that empties every filter.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get filterClear;

  /// Header of the filter sheet's section listing the saved filters.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get filterSaved;

  /// Button of the filter sheet that saves the search and filters set in it under a name.
  ///
  /// In en, this message translates to:
  /// **'Save these filters'**
  String get filterSaveThese;

  /// Title of the dialog asking for a saved filter's name.
  ///
  /// In en, this message translates to:
  /// **'Save filters'**
  String get savedFilterSaveTitle;

  /// Label of the saved filter's name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get savedFilterNameLabel;

  /// Title of the dialog renaming a saved filter.
  ///
  /// In en, this message translates to:
  /// **'Rename saved filter'**
  String get savedFilterRenameTitle;

  /// Menu item and button that rename a saved filter.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get savedFilterRename;

  /// Tooltip of a saved filter's menu button; name is the saved filter's name.
  ///
  /// In en, this message translates to:
  /// **'Options for {name}'**
  String savedFilterOptions(String name);

  /// Title of the dialog confirming that a saved filter is deleted; name is its name.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String savedFilterDeleteTitle(String name);

  /// Body of the dialog confirming that a saved filter is deleted.
  ///
  /// In en, this message translates to:
  /// **'Only the saved filter goes; no transaction changes.'**
  String get savedFilterDeleteBody;

  /// Button of the filter sheet that applies the chosen filters.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// Heading of the category filters in the filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get filterCategories;

  /// Chip of the filter sheet that opens the category picker to filter by one more category.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get filterAddCategory;

  /// Heading of the date range choices in the filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get filterDate;

  /// Heading of the amount range fields in the filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get filterAmount;

  /// Label of the lower bound of the amount filter (an amount, regardless of sign).
  ///
  /// In en, this message translates to:
  /// **'At least'**
  String get filterAmountMin;

  /// Label of the upper bound of the amount filter (an amount, regardless of sign).
  ///
  /// In en, this message translates to:
  /// **'At most'**
  String get filterAmountMax;

  /// Heading of the tag filters in the filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get filterTags;

  /// Shown in the filter sheet when no transaction has a tag.
  ///
  /// In en, this message translates to:
  /// **'No tags yet.'**
  String get filterNoTags;

  /// Date filter choice: no date filter.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get datePresetAny;

  /// Date filter choice: the current calendar month.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get datePresetThisMonth;

  /// Date filter choice: the previous calendar month.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get datePresetLastMonth;

  /// Date filter choice: today and the 89 days before it.
  ///
  /// In en, this message translates to:
  /// **'Last 90 days'**
  String get datePresetLast90Days;

  /// Date filter choice: the current calendar year.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get datePresetThisYear;

  /// Date filter choice that opens a date range picker.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get datePresetCustom;

  /// A range of dates, both included.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String dateRangeValue(String start, String end);

  /// Chip of an amount filter with both bounds.
  ///
  /// In en, this message translates to:
  /// **'{min} – {max}'**
  String amountRangeBetween(String min, String max);

  /// Chip of an amount filter with a lower bound only.
  ///
  /// In en, this message translates to:
  /// **'At least {min}'**
  String amountRangeAtLeast(String min);

  /// Chip of an amount filter with an upper bound only.
  ///
  /// In en, this message translates to:
  /// **'At most {max}'**
  String amountRangeAtMost(String max);

  /// Error under the upper bound of the amount filter when it is below the lower bound.
  ///
  /// In en, this message translates to:
  /// **'At most must not be less than at least'**
  String get amountRangeInverted;

  /// A tag as shown on a chip.
  ///
  /// In en, this message translates to:
  /// **'#{tag}'**
  String tagLabel(String tag);

  /// Tooltip of the button on a tag chip in the editor that removes the tag.
  ///
  /// In en, this message translates to:
  /// **'Remove tag {tag}'**
  String tagRemove(String tag);

  /// Tooltip of a suggested tag chip in the editor that adds the tag.
  ///
  /// In en, this message translates to:
  /// **'Add tag {tag}'**
  String tagAdd(String tag);

  /// Title of the editor of a new transaction.
  ///
  /// In en, this message translates to:
  /// **'New transaction'**
  String get transactionNewTitle;

  /// Title of the editor of an existing transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get transactionTitle;

  /// Shown when the transaction asked for has been deleted or does not exist.
  ///
  /// In en, this message translates to:
  /// **'This transaction no longer exists.'**
  String get transactionNotFound;

  /// Headline of the new transaction screen when there is no account to put it on.
  ///
  /// In en, this message translates to:
  /// **'Add an account first'**
  String get transactionNeedsAccountHeadline;

  /// Supporting text of the new transaction screen when there is no account.
  ///
  /// In en, this message translates to:
  /// **'Every transaction belongs to an account.'**
  String get transactionNeedsAccountBody;

  /// Segment of the transaction editor for money going out.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transactionExpense;

  /// Segment of the transaction editor for money coming in.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transactionIncome;

  /// Label of the transaction amount field.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transactionAmount;

  /// Label of the transaction account field.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get transactionAccount;

  /// Label of the transaction date field.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get transactionDate;

  /// Label of the transaction description field (the merchant or what it was for).
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get transactionDescription;

  /// Error under the description field when it is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a description'**
  String get transactionDescriptionRequired;

  /// Label of the transaction category field.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get transactionCategory;

  /// Caption under the category of a transaction with no category of the user's own, shown when the category comes from the bank's (Plaid's) category code. Choosing a category overrides it.
  ///
  /// In en, this message translates to:
  /// **'From your bank\'s category'**
  String get transactionCategoryFromBank;

  /// Label of the transaction notes field.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get transactionNotes;

  /// Label of the field where tags are typed.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get transactionTags;

  /// Explanation under the tag field.
  ///
  /// In en, this message translates to:
  /// **'Press enter or type a comma to add a tag'**
  String get transactionTagsHelper;

  /// Snack bar shown when a transaction cannot be saved because its amount or splits are in another currency than its account.
  ///
  /// In en, this message translates to:
  /// **'The amount must be in the account\'s currency.'**
  String get transactionCurrencyMismatch;

  /// Snack bar shown after a transaction is deleted, with an Undo action.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get transactionDeleted;

  /// Snack bar shown when undoing a delete fails because the transaction's account has been deleted since.
  ///
  /// In en, this message translates to:
  /// **'The transaction can\'t come back: its account was deleted.'**
  String get transactionRestoreNoAccount;

  /// Heading of the settings section for categories and other data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// Title of the category management screen, and its entry in Settings.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// Label of the category search field.
  ///
  /// In en, this message translates to:
  /// **'Search categories'**
  String get categoriesSearch;

  /// Button of the category picker that opens category management.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get categoriesManage;

  /// Button that opens the editor of a new category.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get categoryAdd;

  /// Screen reader label of the lock icon on a built-in (system) category.
  ///
  /// In en, this message translates to:
  /// **'Built-in category'**
  String get categorySystem;

  /// Tooltip of the button that expands a top-level category.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Show 1 category under {name}} other{Show {count} categories under {name}}}'**
  String categoryExpand(String name, int count);

  /// Tooltip of the button that collapses a top-level category.
  ///
  /// In en, this message translates to:
  /// **'Hide the categories under {name}'**
  String categoryCollapse(String name);

  /// Title of the category picker.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryPickerTitle;

  /// Heading of the recently used categories in the category picker.
  ///
  /// In en, this message translates to:
  /// **'Recently used'**
  String get categoryPickerRecent;

  /// Heading of the full category list in the category picker.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get categoryPickerAll;

  /// Category picker choice for no category.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get categoryNone;

  /// Shown when the category asked for has been deleted or does not exist.
  ///
  /// In en, this message translates to:
  /// **'This category no longer exists.'**
  String get categoryNotFound;

  /// Title of the editor of a new category.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get categoryNewTitle;

  /// Title of the editor of an existing category.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get categoryEditTitle;

  /// Label of the category name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get categoryName;

  /// Error under the category name field when it is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get categoryNameRequired;

  /// Label of the field choosing the top-level category a category sits under.
  ///
  /// In en, this message translates to:
  /// **'Under'**
  String get categoryParent;

  /// Choice of the parent field for a top-level category.
  ///
  /// In en, this message translates to:
  /// **'Nothing (top level)'**
  String get categoryParentNone;

  /// Heading of the icon choices in the category editor.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get categoryIcon;

  /// Heading of the color choices in the category editor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get categoryColor;

  /// Note at the top of the editor of a built-in (system) category.
  ///
  /// In en, this message translates to:
  /// **'A built-in category: only its icon and color can change.'**
  String get categorySystemNote;

  /// Snack bar shown when a change to a built-in category is refused.
  ///
  /// In en, this message translates to:
  /// **'Built-in categories can only change their icon and color.'**
  String get categorySystemReadOnly;

  /// Title of the confirmation before deleting a category.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String categoryDeleteTitle(String name);

  /// Body of the confirmation before deleting a category without subcategories.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No transactions use it.} =1{1 transaction will become uncategorized.} other{{count} transactions will become uncategorized.}}'**
  String categoryDeleteBody(int count);

  /// Body of the confirmation before deleting a category that has categories under it.
  ///
  /// In en, this message translates to:
  /// **'{children, plural, =1{The 1 category under it goes too.} other{The {children} categories under it go too.}} {count, plural, =0{No transactions use them.} =1{1 transaction will become uncategorized.} other{{count} transactions will become uncategorized.}}'**
  String categoryDeleteWithChildrenBody(int children, int count);

  /// Screen reader label of the payments icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get categoryIconPayments;

  /// Screen reader label of the bank icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get categoryIconAccountBalance;

  /// Screen reader label of the credit score icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Credit score'**
  String get categoryIconCreditScore;

  /// Screen reader label of the money in icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get categoryIconCallReceived;

  /// Screen reader label of the money out icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get categoryIconCallMade;

  /// Screen reader label of the receipt icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get categoryIconReceiptLong;

  /// Screen reader label of the movie icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Movie'**
  String get categoryIconMovie;

  /// Screen reader label of the restaurant icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get categoryIconRestaurant;

  /// Screen reader label of the shopping bag icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Shopping bag'**
  String get categoryIconShoppingBag;

  /// Screen reader label of the toolbox icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Toolbox'**
  String get categoryIconHomeRepairService;

  /// Screen reader label of the medical icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get categoryIconMedicalServices;

  /// Screen reader label of the spa icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Spa'**
  String get categoryIconSpa;

  /// Screen reader label of the wrench icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Wrench'**
  String get categoryIconBuild;

  /// Screen reader label of the charity icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Charity'**
  String get categoryIconVolunteerActivism;

  /// Screen reader label of the car icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get categoryIconDirectionsCar;

  /// Screen reader label of the plane icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Plane'**
  String get categoryIconFlight;

  /// Screen reader label of the house icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get categoryIconHouse;

  /// Screen reader label of the shapes icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get categoryIconCategory;

  /// Screen reader label of the groceries icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get categoryIconLocalGroceryStore;

  /// Screen reader label of the coffee icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get categoryIconLocalCafe;

  /// Screen reader label of the bar icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get categoryIconLocalBar;

  /// Screen reader label of the fast food icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Fast food'**
  String get categoryIconFastfood;

  /// Screen reader label of the fuel icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get categoryIconLocalGasStation;

  /// Screen reader label of the bus icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get categoryIconDirectionsBus;

  /// Screen reader label of the train icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get categoryIconTrain;

  /// Screen reader label of the school icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get categoryIconSchool;

  /// Screen reader label of the child care icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Child care'**
  String get categoryIconChildCare;

  /// Screen reader label of the pets icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get categoryIconPets;

  /// Screen reader label of the fitness icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get categoryIconFitnessCenter;

  /// Screen reader label of the games icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get categoryIconSportsEsports;

  /// Screen reader label of the music icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get categoryIconMusicNote;

  /// Screen reader label of the books icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get categoryIconMenuBook;

  /// Screen reader label of the phone icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get categoryIconPhoneIphone;

  /// Screen reader label of the internet icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get categoryIconWifi;

  /// Screen reader label of the electricity icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get categoryIconBolt;

  /// Screen reader label of the water icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get categoryIconWaterDrop;

  /// Screen reader label of the savings icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get categoryIconSavings;

  /// Screen reader label of the gift icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get categoryIconCardGiftcard;

  /// Screen reader label of the clothing icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get categoryIconCheckroom;

  /// Screen reader label of the celebration icon in the category icon choices.
  ///
  /// In en, this message translates to:
  /// **'Celebration'**
  String get categoryIconCelebration;

  /// Name of the red swatch in the category color choices.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// Name of the pink swatch in the category color choices.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colorPink;

  /// Name of the purple swatch in the category color choices.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// Name of the violet swatch in the category color choices.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get colorViolet;

  /// Name of the indigo swatch in the category color choices.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get colorIndigo;

  /// Name of the blue swatch in the category color choices.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// Name of the cyan swatch in the category color choices.
  ///
  /// In en, this message translates to:
  /// **'Cyan'**
  String get colorCyan;

  /// Name of the teal swatch in the category color choices.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get colorTeal;

  /// Name of the green swatch in the category color choices.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// Name of the orange swatch in the category color choices.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// Name of the brown swatch in the category color choices.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get colorBrown;

  /// Name of the grey swatch in the category color choices.
  ///
  /// In en, this message translates to:
  /// **'Grey'**
  String get colorGrey;

  /// Snack bar shown once after the data of the original app was imported into a new account named Imported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 entry into “Imported”, totalling {total}.} other{Imported {count} entries into “Imported”, totalling {total}.}}'**
  String legacyImported(int count, String total);

  /// Snack bar text after the import when some entries of the original app could not be read.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry could not be read and was left in place.} other{{count} entries could not be read and were left in place.}}'**
  String legacyImportSkipped(int count);

  /// Title of the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// Button that signs in with the email and password entered.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInSubmit;

  /// Accessibility label of the progress indicator while signing in.
  ///
  /// In en, this message translates to:
  /// **'Signing in'**
  String get signInSubmitting;

  /// Link from the sign-in screen to the registration screen.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get signInCreateAccount;

  /// Title of the registration screen.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get registerTitle;

  /// Button that creates the account with the details entered.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerSubmit;

  /// Accessibility label of the progress indicator while the account is created.
  ///
  /// In en, this message translates to:
  /// **'Creating your account'**
  String get registerSubmitting;

  /// Link from the registration screen back to the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get registerHaveAccount;

  /// Shows the name this phone is registered under.
  ///
  /// In en, this message translates to:
  /// **'This device: {name}'**
  String registerDeviceName(String name);

  /// Label of the email field on the sign-in and registration screens.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// Label of the password field on the sign-in and registration screens.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// Helper text under the password field of the registration screen.
  ///
  /// In en, this message translates to:
  /// **'8 to 128 characters'**
  String get authPasswordHelper;

  /// Label of the optional display name field on the registration screen.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get authDisplayNameLabel;

  /// Tooltip and accessibility label of the button that shows the password.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// Tooltip and accessibility label of the button that hides the password.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// Error under the email field when it is not an email address.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authEmailInvalid;

  /// Error under the password field when it is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordRequired;

  /// Error under the password field when it is too short or too long.
  ///
  /// In en, this message translates to:
  /// **'Use 8 to 128 characters'**
  String get authPasswordLength;

  /// Error under the display name field when it is too long.
  ///
  /// In en, this message translates to:
  /// **'Use at most 100 characters'**
  String get authDisplayNameLength;

  /// Shown when sign-in fails because the email or password is wrong.
  ///
  /// In en, this message translates to:
  /// **'The email or password is incorrect.'**
  String get authErrorInvalidCredentials;

  /// Shown when the server refuses because of too many attempts, with the wait it asked for.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{Too many attempts. Try again in 1 second.} other{Too many attempts. Try again in {seconds} seconds.}}'**
  String authErrorRateLimited(int seconds);

  /// Shown when the server refuses because of too many attempts and gives no wait.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get authErrorRateLimitedLater;

  /// Shown when registering with an email that already has an account.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get authErrorEmailTaken;

  /// Shown when the server cannot be reached.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server. Check your connection and try again.'**
  String get authErrorNetwork;

  /// Shown when the server refused the details entered.
  ///
  /// In en, this message translates to:
  /// **'Check the highlighted fields and try again.'**
  String get authErrorValidation;

  /// Shown when a sign-in or registration is refused because this install belongs to another account.
  ///
  /// In en, this message translates to:
  /// **'This device already holds another account\'s data. Sign in with that account, or clear the app\'s storage in Android settings to start over.'**
  String get authErrorOtherAccount;

  /// Shown when sign-in or registration fails for another reason.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get authErrorGeneric;

  /// Header of the account section of the Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// The account row of the Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String settingsSignedInAs(String email);

  /// Settings row that signs this device out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// Settings row (dev builds only) showing the server the app talks to.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsServer;

  /// Value of the Server row when the dev build runs on the in-app fake server.
  ///
  /// In en, this message translates to:
  /// **'In-app fake server'**
  String get settingsServerFake;

  /// Heading of the settings section showing how this device's data syncs with the user's other devices.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get settingsSync;

  /// Label of the row showing whether and when this device last synced.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get syncStatus;

  /// Status shown when nobody is signed in, so nothing syncs.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your data between devices'**
  String get syncSignedOut;

  /// Status shown while a sync is running.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncRunning;

  /// Status shown before the first sync has finished.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get syncNever;

  /// Status after a successful sync; time is the date and time it finished, in the device's time zone.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String syncLastAt(String time);

  /// Status when the last sync failed because the server was unreachable.
  ///
  /// In en, this message translates to:
  /// **'The last sync could not reach the server'**
  String get syncFailedOffline;

  /// Status when the server answered the last sync with an error.
  ///
  /// In en, this message translates to:
  /// **'The server could not complete the last sync'**
  String get syncFailedServer;

  /// Status when the last sync failed for another reason.
  ///
  /// In en, this message translates to:
  /// **'The last sync did not finish'**
  String get syncFailedOther;

  /// Title of the Sync section row about pulling the linked banks' Items, accounts and transactions from the server.
  ///
  /// In en, this message translates to:
  /// **'Bank data'**
  String get syncBankData;

  /// Subtitle of the bank data row after a successful pull; time is when it finished, in the device's time zone.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String syncBankDataPulledAt(String time);

  /// Subtitle of the bank data row before the first pull.
  ///
  /// In en, this message translates to:
  /// **'Not updated yet'**
  String get syncBankDataNever;

  /// Subtitle of the bank data row when the last pull failed because the server was unreachable.
  ///
  /// In en, this message translates to:
  /// **'The last update could not reach the server'**
  String get syncBankDataFailedOffline;

  /// Subtitle of the bank data row when the server answered the last pull with an error.
  ///
  /// In en, this message translates to:
  /// **'The server could not complete the last update'**
  String get syncBankDataFailedServer;

  /// Subtitle of the bank data row when the last pull failed for another reason.
  ///
  /// In en, this message translates to:
  /// **'The last update did not finish'**
  String get syncBankDataFailedOther;

  /// How many local changes have not reached the server yet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Every change is synced} =1{1 change waiting to sync} other{{count} changes waiting to sync}}'**
  String syncPending(int count);

  /// Shown when the server refused some of this device's changes because its clock is more than an hour ahead of the server's; the changes stay queued and are retried.
  ///
  /// In en, this message translates to:
  /// **'Check your device\'s clock: it is ahead, so some changes wait to sync'**
  String get syncClockDrift;

  /// Shown when changes pulled from other devices were more than an hour ahead of this device's clock, which means this device's clock is behind and its own edits may lose to theirs.
  ///
  /// In en, this message translates to:
  /// **'Check your device\'s clock: it is behind, so changes made here may be overridden'**
  String get syncClockBehind;

  /// How many local changes the server refused for good, and when the latest of them was made (device time zone).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change was refused by the server, the latest made {time}} other{{count} changes were refused by the server, the latest made {time}}}'**
  String syncRejected(int count, String time);

  /// How many records from other devices this device keeps but cannot show (from a newer app version, or incomplete).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 synced record this version of the app cannot show yet} other{{count} synced records this version of the app cannot show yet}}'**
  String syncHeld(int count);

  /// Button that starts a sync at once.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// Heading of the settings section with the development tools (dev builds only).
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get settingsDeveloper;

  /// Developer row showing this device's id at the server.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get developerDevice;

  /// Value of the Device row when nobody is signed in, so there is no device id.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get developerDeviceNone;

  /// Developer row showing when the last sync session finished.
  ///
  /// In en, this message translates to:
  /// **'Last sync'**
  String get developerLastSync;

  /// Developer row showing when the bank data was last pulled from the server.
  ///
  /// In en, this message translates to:
  /// **'Bank data pulled'**
  String get developerBankData;

  /// Value of a developer time row before the first time it happened.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get developerNever;

  /// Developer row showing the sync outbox and the held records.
  ///
  /// In en, this message translates to:
  /// **'Outbox'**
  String get developerLedger;

  /// Value of the Outbox row: changes waiting to sync, and synced records this version cannot show.
  ///
  /// In en, this message translates to:
  /// **'{pending} waiting, {held} held'**
  String developerLedgerValue(int pending, int held);

  /// Value of the Outbox row before the sync status has read the outbox, or when this build does not sync.
  ///
  /// In en, this message translates to:
  /// **'Not read yet'**
  String get developerLedgerUnknown;

  /// Button that pulls the bank data from the server at once.
  ///
  /// In en, this message translates to:
  /// **'Pull now'**
  String get developerPullNow;

  /// Result of Pull now; time is when the last whole pull finished, in the device's time zone.
  ///
  /// In en, this message translates to:
  /// **'Pulled; bank data updated {time}'**
  String developerPulled(String time);

  /// Result of a pull that failed; error names the exception (its type, status and code).
  ///
  /// In en, this message translates to:
  /// **'Pull failed: {error}'**
  String developerPullFailed(String error);

  /// Button that copies the developer diagnostics (server, device, sync times and counts) as plain text.
  ///
  /// In en, this message translates to:
  /// **'Copy diagnostics'**
  String get developerCopy;

  /// Snack bar after the diagnostics were copied to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics copied'**
  String get developerCopied;

  /// Developer row opening the screen with the Item and Sandbox controls, and the title of that screen.
  ///
  /// In en, this message translates to:
  /// **'Sandbox controls'**
  String get developerOpenSandbox;

  /// Subtitle of the Sandbox controls row: what the screen offers.
  ///
  /// In en, this message translates to:
  /// **'Refresh, reset login, webhooks, injected transactions, persona provisioning'**
  String get developerOpenSandboxDetail;

  /// Heading of the developer screen's Item controls.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get developerItemSection;

  /// Label of the picker choosing which linked Item the controls act on.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get developerItem;

  /// One choice of the Item picker: the institution's name and the Item's id.
  ///
  /// In en, this message translates to:
  /// **'{institution} ({id})'**
  String developerItemOption(String institution, String id);

  /// Shown instead of the Item controls when the device has no linked Item.
  ///
  /// In en, this message translates to:
  /// **'No linked banks yet. Link one, or pull, first.'**
  String get developerNoItems;

  /// Button asking Plaid to refresh the Item's transactions.
  ///
  /// In en, this message translates to:
  /// **'Refresh transactions'**
  String get developerRefreshTransactions;

  /// Button asking Plaid for the Item's current balances.
  ///
  /// In en, this message translates to:
  /// **'Refresh balances'**
  String get developerRefreshBalances;

  /// Button putting the Sandbox Item into the state where its login must be repaired.
  ///
  /// In en, this message translates to:
  /// **'Reset login'**
  String get developerResetLogin;

  /// Label of the picker choosing which Plaid webhook to fire.
  ///
  /// In en, this message translates to:
  /// **'Webhook code'**
  String get developerWebhookCode;

  /// Button asking Plaid Sandbox to fire the chosen webhook for the Item.
  ///
  /// In en, this message translates to:
  /// **'Fire webhook'**
  String get developerFireWebhook;

  /// Shown while a developer operation and the pull after it run.
  ///
  /// In en, this message translates to:
  /// **'Running…'**
  String get developerRunning;

  /// Result of Refresh transactions; status is the server's sync status identifier.
  ///
  /// In en, this message translates to:
  /// **'Refresh {status}: {added} added, {modified} modified, {removed} removed'**
  String developerRefreshed(
    String status,
    int added,
    int modified,
    int removed,
  );

  /// Result of Refresh balances.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Balances refreshed for 1 account} other{Balances refreshed for {count} accounts}}'**
  String developerBalancesRefreshed(int count);

  /// Result of Reset login.
  ///
  /// In en, this message translates to:
  /// **'Login reset; the Item needs its connection fixed'**
  String get developerLoginReset;

  /// Result of Fire webhook.
  ///
  /// In en, this message translates to:
  /// **'Webhook fired'**
  String get developerWebhookFired;

  /// Result of Inject transactions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Injected 1 transaction} other{Injected {count} transactions}}'**
  String developerInjected(int count);

  /// Result of a developer operation that failed; error names the exception (its type, status and code).
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String developerFailed(String error);

  /// Result of an operation that succeeded when the pull after it failed.
  ///
  /// In en, this message translates to:
  /// **'{result}; the pull after it failed: {error}'**
  String developerThenPullFailed(String result, String error);

  /// Heading of the form that injects transactions into the Sandbox Item.
  ///
  /// In en, this message translates to:
  /// **'Inject transactions'**
  String get developerInjectSection;

  /// Label of the picker choosing the Item's account the injected transactions go to.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get developerAccount;

  /// Shown instead of the injection form when the Item's accounts have not been pulled.
  ///
  /// In en, this message translates to:
  /// **'This Item has no accounts on the device yet.'**
  String get developerNoAccounts;

  /// Label of the field for how many transactions to inject.
  ///
  /// In en, this message translates to:
  /// **'How many (1 to 10)'**
  String get developerCount;

  /// Error under the count field.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number from 1 to 10'**
  String get developerCountInvalid;

  /// Label of the field for the injected transactions' description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get developerDescription;

  /// The description field's starting value.
  ///
  /// In en, this message translates to:
  /// **'Developer test'**
  String get developerDescriptionDefault;

  /// Error under the description field (the server takes up to 200, and a number is added to each).
  ///
  /// In en, this message translates to:
  /// **'Enter 1 to 196 characters'**
  String get developerDescriptionInvalid;

  /// Label of the field for the injected transactions' amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get developerAmount;

  /// Helper under the amount field: the app's sign convention.
  ///
  /// In en, this message translates to:
  /// **'Negative is money out of the account'**
  String get developerAmountHelper;

  /// Label of the field for how many days before Plaid Sandbox's current date the transactions are dated.
  ///
  /// In en, this message translates to:
  /// **'Days before Plaid\'s today (0 to 728)'**
  String get developerDaysBack;

  /// Error under the days-back field.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number from 0 to 728'**
  String get developerDaysBackInvalid;

  /// Shows the date the injected transactions will carry.
  ///
  /// In en, this message translates to:
  /// **'Dated {date}'**
  String developerDate(String date);

  /// Button that injects the transactions.
  ///
  /// In en, this message translates to:
  /// **'Inject'**
  String get developerInject;

  /// Heading of the form that provisions a persona's banks into Plaid Sandbox.
  ///
  /// In en, this message translates to:
  /// **'Provision a persona'**
  String get developerProvisionSection;

  /// Label of the picker choosing which persona to provision.
  ///
  /// In en, this message translates to:
  /// **'Persona'**
  String get developerPersona;

  /// Label of the field for the persona generator's seed.
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get developerSeed;

  /// Error under the seed field.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number of at least 1'**
  String get developerSeedInvalid;

  /// Label of the field for how many days of history to provision.
  ///
  /// In en, this message translates to:
  /// **'Days of history (30 to 730)'**
  String get developerDays;

  /// Error under the days-of-history field.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number from 30 to 730'**
  String get developerDaysInvalid;

  /// Button that starts the provisioning job.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get developerProvision;

  /// The provisioning job's state; status is the server's identifier (queued, running, completed, failed).
  ///
  /// In en, this message translates to:
  /// **'Job {status}'**
  String developerJobStatus(String status);

  /// Provisioning progress: Items linked so far.
  ///
  /// In en, this message translates to:
  /// **'Items linked: {linked} of {total}'**
  String developerJobItems(int linked, int total);

  /// Provisioning progress: injection batches sent so far.
  ///
  /// In en, this message translates to:
  /// **'Batches sent: {sent} of {total}'**
  String developerJobBatches(int sent, int total);

  /// Provisioning progress: transactions outside Plaid's 730-day window.
  ///
  /// In en, this message translates to:
  /// **'Transactions skipped: {count}'**
  String developerJobSkipped(int count);

  /// Why the provisioning job failed, as the server says.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String developerJobError(String error);

  /// Semantics label of the provisioning progress bar.
  ///
  /// In en, this message translates to:
  /// **'Provisioning progress'**
  String get developerJobProgress;

  /// Heading of the settings section, in the demo build only, that chooses which made-up household the demo shows.
  ///
  /// In en, this message translates to:
  /// **'Demo data'**
  String get settingsDemoData;

  /// Explanation above the list of demo households.
  ///
  /// In en, this message translates to:
  /// **'Choosing another household starts the demo over; changes made in the demo are not kept.'**
  String get demoDataNote;

  /// Name of the demo household of a renter.
  ///
  /// In en, this message translates to:
  /// **'Renter'**
  String get demoPersonaRenter;

  /// What the renter demo household has.
  ///
  /// In en, this message translates to:
  /// **'Gig income, subscriptions and a credit card'**
  String get demoPersonaRenterDetail;

  /// Name of the demo household of a family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get demoPersonaFamily;

  /// What the family demo household has.
  ///
  /// In en, this message translates to:
  /// **'Two salaries, a mortgage, car loans and a 401(k)'**
  String get demoPersonaFamilyDetail;

  /// Name of the demo household of a student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get demoPersonaStudent;

  /// What the student demo household has.
  ///
  /// In en, this message translates to:
  /// **'Student loans, a campus job and help from a parent'**
  String get demoPersonaStudentDetail;

  /// Name of the demo household of a small business owner.
  ///
  /// In en, this message translates to:
  /// **'Small business owner'**
  String get demoPersonaSmallBusiness;

  /// What the small business owner demo household has.
  ///
  /// In en, this message translates to:
  /// **'Business and personal accounts, and quarterly taxes'**
  String get demoPersonaSmallBusinessDetail;

  /// Title of the linked banks screen, and of the entries that open it from Accounts and Settings.
  ///
  /// In en, this message translates to:
  /// **'Linked banks'**
  String get itemsTitle;

  /// Button that opens Plaid Link to link a new bank.
  ///
  /// In en, this message translates to:
  /// **'Link a bank'**
  String get itemsLink;

  /// Headline of the linked banks screen with no bank linked.
  ///
  /// In en, this message translates to:
  /// **'No linked banks'**
  String get itemsEmptyHeadline;

  /// Body of the linked banks screen with no bank linked.
  ///
  /// In en, this message translates to:
  /// **'Link a bank to see its accounts and transactions here.'**
  String get itemsEmptyBody;

  /// Status chip of a linked bank that is working.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get itemsStatusConnected;

  /// Status chip of a linked bank whose login must be repaired, or soon must be.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get itemsStatusNeedsAttention;

  /// Status chip of a linked bank the server reports an error for.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get itemsStatusError;

  /// Status chip of a bank unlinked with its history kept.
  ///
  /// In en, this message translates to:
  /// **'Unlinked'**
  String get itemsStatusUnlinked;

  /// Screen reader label of a linked bank's status chip.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String itemsStatusLabel(String status);

  /// When the bank was last synced with Plaid, in the device's time zone.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String itemsLastSynced(String time);

  /// A linked bank that has never synced with Plaid.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get itemsNeverSynced;

  /// Button that syncs one linked bank with Plaid and updates its data.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get itemsSyncNow;

  /// Button that opens Plaid Link to sign in to a bank again.
  ///
  /// In en, this message translates to:
  /// **'Fix connection'**
  String get itemsFix;

  /// Button that unlinks a bank, after a choice of what happens to its data.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get itemsUnlink;

  /// Progress while Plaid Link opens or is open.
  ///
  /// In en, this message translates to:
  /// **'Opening Plaid Link…'**
  String get itemsStepLinking;

  /// Progress while the new bank is being connected.
  ///
  /// In en, this message translates to:
  /// **'Connecting your bank…'**
  String get itemsStepExchanging;

  /// Progress while the server syncs the bank with Plaid.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your bank\'s data…'**
  String get itemsStepSyncing;

  /// Progress while the app brings in the bank's accounts and transactions.
  ///
  /// In en, this message translates to:
  /// **'Updating your accounts…'**
  String get itemsStepPulling;

  /// Progress while the bank is being unlinked.
  ///
  /// In en, this message translates to:
  /// **'Unlinking…'**
  String get itemsStepUnlinking;

  /// A bank action failed because the server was unreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server. Try again when you\'re online.'**
  String get itemsFailedOffline;

  /// A bank action failed because the bank's login must be repaired.
  ///
  /// In en, this message translates to:
  /// **'Your bank needs you to sign in again. Use Fix connection.'**
  String get itemsFailedLoginRequired;

  /// A bank action failed because the server was rate limiting.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Try again in a minute.'**
  String get itemsFailedRateLimited;

  /// A bank action failed because the bank is gone at the server.
  ///
  /// In en, this message translates to:
  /// **'This bank is no longer linked.'**
  String get itemsFailedNotFound;

  /// A bank action failed because Plaid failed.
  ///
  /// In en, this message translates to:
  /// **'Plaid couldn\'t complete the request. Try again later.'**
  String get itemsFailedPlaid;

  /// A bank action failed for another reason.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get itemsFailedOther;

  /// Plaid Link closed with an error and gave no message for the user.
  ///
  /// In en, this message translates to:
  /// **'Plaid Link closed with an error.'**
  String get itemsFailedLink;

  /// The bank is linked but its data was not ready after waiting.
  ///
  /// In en, this message translates to:
  /// **'Your bank is still preparing your data. Use Sync now in a minute.'**
  String get itemsStillPreparing;

  /// Title of the unlink dialog.
  ///
  /// In en, this message translates to:
  /// **'Unlink {institution}?'**
  String itemsUnlinkTitle(String institution);

  /// Unlink choice that keeps the bank's accounts and transactions.
  ///
  /// In en, this message translates to:
  /// **'Keep history on this device and others'**
  String get itemsUnlinkKeep;

  /// What keeping the history means.
  ///
  /// In en, this message translates to:
  /// **'Its accounts and transactions stay on every device, no longer updated.'**
  String get itemsUnlinkKeepDetail;

  /// Unlink choice that deletes the bank's accounts and transactions.
  ///
  /// In en, this message translates to:
  /// **'Delete its accounts and transactions'**
  String get itemsUnlinkDelete;

  /// What deleting the history means.
  ///
  /// In en, this message translates to:
  /// **'They are removed from this device and every other device signed in to your account. Your own notes and categories on them go too.'**
  String get itemsUnlinkDeleteDetail;

  /// Confirms the unlink dialog.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get itemsUnlinkConfirm;

  /// Screen reader label of a linked bank's Sync now button, naming the bank.
  ///
  /// In en, this message translates to:
  /// **'Sync now, {institution}'**
  String itemsSyncNowLabel(String institution);

  /// Screen reader label of a linked bank's Fix connection button, naming the bank.
  ///
  /// In en, this message translates to:
  /// **'Fix connection, {institution}'**
  String itemsFixLabel(String institution);

  /// Screen reader label of a linked bank's Unlink button, naming the bank.
  ///
  /// In en, this message translates to:
  /// **'Unlink, {institution}'**
  String itemsUnlinkLabel(String institution);

  /// Button on an unlinked bank whose history was kept: deletes its accounts and transactions.
  ///
  /// In en, this message translates to:
  /// **'Delete history'**
  String get itemsDeleteHistory;

  /// Screen reader label of an unlinked bank's Delete history button, naming the bank.
  ///
  /// In en, this message translates to:
  /// **'Delete history, {institution}'**
  String itemsDeleteHistoryLabel(String institution);

  /// Title of the dialog confirming the deletion of an unlinked bank's kept history.
  ///
  /// In en, this message translates to:
  /// **'Delete the history of {institution}?'**
  String itemsDeleteHistoryTitle(String institution);

  /// What deleting an unlinked bank's kept history does.
  ///
  /// In en, this message translates to:
  /// **'Its accounts and transactions are removed from this device and every other device signed in to your account. Your own notes and categories on them go too.'**
  String get itemsDeleteHistoryBody;

  /// Confirms deleting an unlinked bank's kept history.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get itemsDeleteHistoryConfirm;

  /// Progress while an unlinked bank's kept history is being deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleting its history…'**
  String get itemsStepDeletingHistory;

  /// A bank action failed because the server answered with an error.
  ///
  /// In en, this message translates to:
  /// **'The server could not complete the request. Try again later.'**
  String get itemsFailedServer;

  /// Tooltip of the transaction editor's overflow menu button.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get transactionMoreOptions;

  /// Overflow menu item of the transaction editor that applies the user's rules to the values in the form.
  ///
  /// In en, this message translates to:
  /// **'Run rules on this transaction'**
  String get transactionRunRules;

  /// Snack bar after running the rules changed the form: the rule that applied.
  ///
  /// In en, this message translates to:
  /// **'Applied the rule “{name}”. Save to keep it.'**
  String transactionRulesApplied(String name);

  /// Snack bar after running the rules: a rule matched but changed nothing.
  ///
  /// In en, this message translates to:
  /// **'The rule “{name}” matches, but has nothing to change.'**
  String transactionRulesUnchanged(String name);

  /// Snack bar after running the rules: no rule matched.
  ///
  /// In en, this message translates to:
  /// **'No rule matches this transaction.'**
  String get transactionRulesNoMatch;

  /// Title of the rules screen, and its entry in Settings and in the categories screen's menu.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get rulesTitle;

  /// Headline of the rules screen with no rules.
  ///
  /// In en, this message translates to:
  /// **'No rules yet'**
  String get rulesEmptyHeadline;

  /// Body of the rules screen with no rules.
  ///
  /// In en, this message translates to:
  /// **'A rule files, tags or renames transactions as they arrive from your bank. Rules are tried from the top; the first one that matches applies.'**
  String get rulesEmptyBody;

  /// Note above the list of rules.
  ///
  /// In en, this message translates to:
  /// **'Rules are tried from the top; the first one that matches a transaction applies. Drag to reorder.'**
  String get rulesOrderNote;

  /// Button that opens the editor of a new rule.
  ///
  /// In en, this message translates to:
  /// **'Add rule'**
  String get ruleAdd;

  /// Title of the editor of a new rule.
  ///
  /// In en, this message translates to:
  /// **'New rule'**
  String get ruleNewTitle;

  /// Title of the editor of an existing rule.
  ///
  /// In en, this message translates to:
  /// **'Edit rule'**
  String get ruleEditTitle;

  /// Shown when the rule being edited was deleted.
  ///
  /// In en, this message translates to:
  /// **'This rule no longer exists.'**
  String get ruleNotFound;

  /// Label of the rule name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get ruleName;

  /// Error under an empty rule name field.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get ruleNameRequired;

  /// Heading above a rule's conditions.
  ///
  /// In en, this message translates to:
  /// **'When a transaction matches all of these'**
  String get ruleConditionsHeader;

  /// Heading above a rule's actions.
  ///
  /// In en, this message translates to:
  /// **'Then'**
  String get ruleActionsHeader;

  /// Button that adds a condition to a rule.
  ///
  /// In en, this message translates to:
  /// **'Add condition'**
  String get ruleAddCondition;

  /// Button that adds an action to a rule.
  ///
  /// In en, this message translates to:
  /// **'Add action'**
  String get ruleAddAction;

  /// Shown when a rule has no condition.
  ///
  /// In en, this message translates to:
  /// **'A rule needs at least one condition.'**
  String get ruleNeedsCondition;

  /// Shown when a rule has no action.
  ///
  /// In en, this message translates to:
  /// **'A rule needs at least one action.'**
  String get ruleNeedsAction;

  /// Tooltip of the button that removes a condition.
  ///
  /// In en, this message translates to:
  /// **'Remove condition'**
  String get ruleRemoveCondition;

  /// Tooltip of the button that removes an action.
  ///
  /// In en, this message translates to:
  /// **'Remove action'**
  String get ruleRemoveAction;

  /// Condition kind: text found in the merchant name, or in the description when there is no merchant name.
  ///
  /// In en, this message translates to:
  /// **'Merchant or description contains'**
  String get ruleConditionMerchant;

  /// Condition kind: the amount, ignoring its sign, within a range.
  ///
  /// In en, this message translates to:
  /// **'Amount between'**
  String get ruleConditionAmount;

  /// Condition kind: the transaction is on an account.
  ///
  /// In en, this message translates to:
  /// **'Account is'**
  String get ruleConditionAccount;

  /// Condition kind: the bank's category of the transaction.
  ///
  /// In en, this message translates to:
  /// **'Bank category is'**
  String get ruleConditionBankCategory;

  /// Label of the text field of a "contains" condition.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get ruleText;

  /// Error under an empty text field of a condition.
  ///
  /// In en, this message translates to:
  /// **'Enter some text'**
  String get ruleTextRequired;

  /// Error when an amount condition has neither bound.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one amount'**
  String get ruleAmountRequired;

  /// Error when an amount condition's minimum exceeds its maximum.
  ///
  /// In en, this message translates to:
  /// **'The minimum is above the maximum'**
  String get ruleAmountOrder;

  /// Error when an account condition has no account.
  ///
  /// In en, this message translates to:
  /// **'Choose an account'**
  String get ruleAccountRequired;

  /// Error when a category picker of a rule has no choice.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get ruleCategoryRequired;

  /// Action kind: file the transaction under a category.
  ///
  /// In en, this message translates to:
  /// **'Set the category'**
  String get ruleActionSetCategory;

  /// Caption of the set-category action.
  ///
  /// In en, this message translates to:
  /// **'Only for transactions without a category of your own.'**
  String get ruleActionSetCategoryCaption;

  /// Action kind: add a tag to the transaction.
  ///
  /// In en, this message translates to:
  /// **'Add a tag'**
  String get ruleActionAddTag;

  /// Label of the tag field of an add-tag action.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get ruleTag;

  /// Error under an empty tag field.
  ///
  /// In en, this message translates to:
  /// **'Enter a tag'**
  String get ruleTagRequired;

  /// Action kind: change the transaction's description.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get ruleActionRename;

  /// Label of the text field of a rename action.
  ///
  /// In en, this message translates to:
  /// **'New description'**
  String get ruleNewDescription;

  /// Error under an empty rename field.
  ///
  /// In en, this message translates to:
  /// **'Enter the new description'**
  String get ruleNewDescriptionRequired;

  /// Caption of the rename action, explaining that bank transactions are not renamed.
  ///
  /// In en, this message translates to:
  /// **'Renames manual and imported transactions. Bank transactions keep the description your bank sends.'**
  String get ruleActionRenameCaption;

  /// The rule action that hides the transactions the rule matches.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get ruleActionHide;

  /// Caption of the hide action, explaining what hiding does.
  ///
  /// In en, this message translates to:
  /// **'Hidden transactions leave the list, budgets and reports, and still count toward their account\'s balance.'**
  String get ruleActionHideCaption;

  /// Placeholder of an empty category picker row in the rule editor.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get ruleChooseCategory;

  /// Snack bar after deleting a rule, with an undo action.
  ///
  /// In en, this message translates to:
  /// **'Rule deleted'**
  String get ruleDeleted;

  /// Tooltip of the button that deletes a rule.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”'**
  String ruleDeleteNamed(String name);

  /// Accessibility label of a rule's drag handle.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder “{name}”'**
  String ruleReorderNamed(String name);

  /// How many conditions a rule has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 condition} other{{count} conditions}}'**
  String ruleConditionCount(int count);

  /// How many actions a rule has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 action} other{{count} actions}}'**
  String ruleActionCount(int count);

  /// A rule's subtitle in the list: its condition count, then its action count.
  ///
  /// In en, this message translates to:
  /// **'{conditions} · {actions}'**
  String ruleSummary(String conditions, String actions);

  /// Snack bar when saving a new order of the rules fails; the list shows the stored order again.
  ///
  /// In en, this message translates to:
  /// **'The rules could not be reordered.'**
  String get ruleReorderFailed;

  /// Tooltip of the categories screen's overflow menu button.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get categoriesMoreOptions;

  /// Headline of the Budgets screen when there is no budget.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet'**
  String get budgetsEmptyHeadline;

  /// Body of the Budgets screen when there is no budget.
  ///
  /// In en, this message translates to:
  /// **'A budget sets how much to spend on a category each month and shows how far along you are.'**
  String get budgetsEmptyBody;

  /// Button that opens the editor of a new budget.
  ///
  /// In en, this message translates to:
  /// **'Add budget'**
  String get budgetAdd;

  /// Tooltip of the period selector's button that shows the period before.
  ///
  /// In en, this message translates to:
  /// **'Previous period'**
  String get budgetPeriodPrevious;

  /// Tooltip of the period selector's button that shows the period after.
  ///
  /// In en, this message translates to:
  /// **'Next period'**
  String get budgetPeriodNext;

  /// The period selector's label for the current period, and its button that returns to it.
  ///
  /// In en, this message translates to:
  /// **'This period'**
  String get budgetPeriodCurrent;

  /// The period selector's label for a period before the current one.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Last period} other{{count} periods ago}}'**
  String budgetPeriodsAgo(int count);

  /// The period selector's label for a period after the current one.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Next period} other{In {count} periods}}'**
  String budgetPeriodsAhead(int count);

  /// A budget period's first and last days.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String budgetPeriodRange(String start, String end);

  /// What a screen reader says for the period selector's label.
  ///
  /// In en, this message translates to:
  /// **'Showing {period}'**
  String budgetPeriodShown(String period);

  /// The name shown for a budget whose category has been deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted category'**
  String get budgetDeletedCategory;

  /// Under a budget on a parent category: how many categories its group includes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Includes 1 category} other{Includes {count} categories}}'**
  String budgetGroupIncludes(int count);

  /// A budget's amount and the surplus carried into the period.
  ///
  /// In en, this message translates to:
  /// **'{amount} + {carry} carried'**
  String budgetAmountCarried(String amount, String carry);

  /// A budget's amount less the overspending carried into the period.
  ///
  /// In en, this message translates to:
  /// **'{amount} − {carry} carried'**
  String budgetAmountDeficit(String amount, String carry);

  /// How much of what is available has been spent, in percent.
  ///
  /// In en, this message translates to:
  /// **'{percent} %'**
  String budgetPercent(int percent);

  /// Shown instead of a percent when a budget has nothing available in the period.
  ///
  /// In en, this message translates to:
  /// **'Nothing available'**
  String get budgetNothingAvailable;

  /// What was spent against a budget in the period.
  ///
  /// In en, this message translates to:
  /// **'{amount} spent'**
  String budgetSpent(String amount);

  /// What is left of a budget in the period.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String budgetLeft(String amount);

  /// How much spending is past what the budget had available.
  ///
  /// In en, this message translates to:
  /// **'{amount} over'**
  String budgetOver(String amount);

  /// The projection of a budget's spending to the end of the period, when it stays within what is available.
  ///
  /// In en, this message translates to:
  /// **'On pace: about {amount} by the end'**
  String budgetOnPace(String amount);

  /// The projection of a budget's spending, when it ends above what is available.
  ///
  /// In en, this message translates to:
  /// **'Projected over by {amount}'**
  String budgetProjectedOver(String amount);

  /// What a future period of a budget will have available.
  ///
  /// In en, this message translates to:
  /// **'{amount} available'**
  String budgetAvailable(String amount);

  /// Badge on a budget: the highest alert threshold its spending has reached in the period.
  ///
  /// In en, this message translates to:
  /// **'{percent} % reached'**
  String budgetThresholdReached(int percent);

  /// What a screen reader says for a budget's progress bar.
  ///
  /// In en, this message translates to:
  /// **'{name}: {percent} percent of {available} spent, {remaining} left'**
  String budgetProgressSemantics(
    String name,
    int percent,
    String available,
    String remaining,
  );

  /// What a screen reader says for the progress bar of a budget that is over.
  ///
  /// In en, this message translates to:
  /// **'{name}: {percent} percent of {available} spent, {over} over'**
  String budgetProgressOverSemantics(
    String name,
    int percent,
    String available,
    String over,
  );

  /// What a screen reader says for the progress bar of a budget with nothing available.
  ///
  /// In en, this message translates to:
  /// **'{name}: {spent} spent, nothing available'**
  String budgetProgressNothingSemantics(String name, String spent);

  /// Title of the editor of a new budget.
  ///
  /// In en, this message translates to:
  /// **'New budget'**
  String get budgetNewTitle;

  /// Title of the editor of an existing budget, and the tooltip of the button that opens it.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get budgetEditTitle;

  /// Shown when a budget being viewed or edited has been deleted.
  ///
  /// In en, this message translates to:
  /// **'This budget no longer exists.'**
  String get budgetNotFound;

  /// Snack bar after a budget is deleted, with an Undo action.
  ///
  /// In en, this message translates to:
  /// **'Budget deleted'**
  String get budgetDeleted;

  /// Label of the budget editor's category field.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get budgetCategory;

  /// Placeholder of the budget editor's category field, and its error when none is chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get budgetChooseCategory;

  /// Under the budget editor's category field.
  ///
  /// In en, this message translates to:
  /// **'A category with categories under it budgets its whole group.'**
  String get budgetCategoryCaption;

  /// Label of the budget editor's amount field.
  ///
  /// In en, this message translates to:
  /// **'Amount per period'**
  String get budgetAmount;

  /// Label of the budget editor's period start day field.
  ///
  /// In en, this message translates to:
  /// **'Period starts on day'**
  String get budgetStartDay;

  /// Helper text of the budget editor's period start day field.
  ///
  /// In en, this message translates to:
  /// **'1 to 28: each period starts on this day of the month'**
  String get budgetStartDayHelper;

  /// Error of the budget editor's period start day field.
  ///
  /// In en, this message translates to:
  /// **'Enter a day from 1 to 28'**
  String get budgetStartDayInvalid;

  /// Label of the budget editor's rollover switch.
  ///
  /// In en, this message translates to:
  /// **'Carry over'**
  String get budgetRollover;

  /// Under the budget editor's rollover switch.
  ///
  /// In en, this message translates to:
  /// **'What is left at the end of a period, or overspent, carries into the next.'**
  String get budgetRolloverCaption;

  /// Label of the budget editor's start date field.
  ///
  /// In en, this message translates to:
  /// **'First period'**
  String get budgetStartDate;

  /// Under the budget editor's start date field.
  ///
  /// In en, this message translates to:
  /// **'Carry-over counts from this period. It can start earlier, but no later than the current period.'**
  String get budgetStartDateCaption;

  /// The budget detail's list when no transaction counts in the period.
  ///
  /// In en, this message translates to:
  /// **'Nothing counted in this period'**
  String get budgetTransactionsEmpty;

  /// Tooltip of the Budgets screen's bell, which opens the alerts, with how many are unread.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Alerts} =1{Alerts, 1 unread} other{Alerts, {count} unread}}'**
  String alertsTooltip(int count);

  /// Title of the alerts sheet.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTitle;

  /// Button of the alerts sheet that marks every alert read.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get alertsMarkAllRead;

  /// The alerts sheet when there is no alert.
  ///
  /// In en, this message translates to:
  /// **'No alerts yet. A budget alerts you when its spending reaches 80 % and 100 %.'**
  String get alertsEmpty;

  /// What a screen reader says for the dot of an unread alert.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get alertUnread;

  /// An alert: a budget's spending reached a threshold of what it had available, on a day.
  ///
  /// In en, this message translates to:
  /// **'{category} reached {percent} % of {available} on {date}'**
  String alertBudgetThreshold(
    String category,
    int percent,
    String available,
    String date,
  );

  /// Label on a transaction the user hid from the list, budgets and reports.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get transactionHidden;

  /// Checked item of the transaction editor's overflow menu that hides the transaction.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get transactionHiddenOption;

  /// What a long press on a transaction row does, announced by screen readers.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get transactionSelect;

  /// Shown where a transaction row names its category when the transaction is split across categories.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get transactionSplitLabel;

  /// The transaction editor's category row when the transaction has splits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Split across 1 category} other{Split across {count} categories}}'**
  String transactionSplitAcross(int count);

  /// Heading of the transaction editor's split section.
  ///
  /// In en, this message translates to:
  /// **'Splits'**
  String get splitsTitle;

  /// Button that adds a split row (a category and an amount) to the transaction editor.
  ///
  /// In en, this message translates to:
  /// **'Add split'**
  String get splitAdd;

  /// Tooltip of the button that removes one split row.
  ///
  /// In en, this message translates to:
  /// **'Remove split'**
  String get splitRemove;

  /// Button that divides the transaction's amount evenly across its split rows.
  ///
  /// In en, this message translates to:
  /// **'Distribute evenly'**
  String get splitDistribute;

  /// Label of a split row's amount field.
  ///
  /// In en, this message translates to:
  /// **'Split amount'**
  String get splitAmount;

  /// A split row's category cell before a category is chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get splitChooseCategory;

  /// Error in the split section when a split row has no category.
  ///
  /// In en, this message translates to:
  /// **'Choose a category for every split'**
  String get splitCategoryRequired;

  /// Running line under the splits: how much of the transaction's amount no split takes yet.
  ///
  /// In en, this message translates to:
  /// **'Unallocated {amount}'**
  String splitUnallocated(String amount);

  /// Running line under the splits when they add up to more than the transaction's amount.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String splitOverAllocated(String amount);

  /// Error that refuses Save while the splits do not sum to the transaction's amount.
  ///
  /// In en, this message translates to:
  /// **'Splits must add up to {amount}'**
  String splitMustBalance(String amount);

  /// Heading of the transaction editor's receipt section, and title of the full-screen receipt view.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// Button that takes a receipt photo with the camera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get receiptTakePhoto;

  /// Button that chooses a receipt photo from the gallery.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get receiptChoosePhoto;

  /// Button that replaces the receipt photo with another (camera or gallery).
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get receiptReplace;

  /// What screen readers announce for the Replace button of the receipt.
  ///
  /// In en, this message translates to:
  /// **'Replace receipt'**
  String get receiptReplaceLabel;

  /// Button that removes the receipt photo from the transaction (saved with Save).
  ///
  /// In en, this message translates to:
  /// **'Remove receipt'**
  String get receiptRemove;

  /// What screen readers announce for the receipt photo.
  ///
  /// In en, this message translates to:
  /// **'Receipt image'**
  String get receiptImage;

  /// What a tap on the receipt thumbnail does, announced by screen readers after 'Double tap to'.
  ///
  /// In en, this message translates to:
  /// **'open the receipt full screen'**
  String get receiptOpenHint;

  /// Shown in place of the receipt photo when the transaction has a receipt whose photo is on another device (photos do not sync).
  ///
  /// In en, this message translates to:
  /// **'Receipt kept on another device'**
  String get receiptMissing;

  /// Snack bar when the device has no camera app to take a receipt photo.
  ///
  /// In en, this message translates to:
  /// **'No camera is available'**
  String get receiptNoCamera;

  /// Snack bar when the picked receipt image could not be read, or is in a format whose metadata the app cannot remove (WebP, HEIC), so it is not attached.
  ///
  /// In en, this message translates to:
  /// **'That image can\'t be used'**
  String get receiptPickFailed;

  /// Snack bar when writing the receipt photo to the device failed, so nothing was saved.
  ///
  /// In en, this message translates to:
  /// **'The receipt could not be saved'**
  String get receiptSaveFailed;

  /// Switch in the filter sheet that lists hidden transactions too.
  ///
  /// In en, this message translates to:
  /// **'Show hidden'**
  String get filterShowHidden;

  /// Caption of the Show hidden switch.
  ///
  /// In en, this message translates to:
  /// **'Hidden transactions still count toward their account\'s balance.'**
  String get filterShowHiddenCaption;

  /// Chip under the transactions app bar while hidden transactions are shown; removing it hides them again.
  ///
  /// In en, this message translates to:
  /// **'Including hidden'**
  String get filterIncludingHidden;

  /// Title of the transactions app bar in selection mode.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String transactionsSelected(int count);

  /// Tooltip of the button that leaves selection mode.
  ///
  /// In en, this message translates to:
  /// **'Cancel selection'**
  String get selectionCancel;

  /// Menu item that selects every transaction loaded in the list.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// Tooltip of the selection action that sets the category of the selected transactions.
  ///
  /// In en, this message translates to:
  /// **'Set category'**
  String get bulkSetCategory;

  /// Tooltip of the selection action that adds a tag, and the title of its dialog.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get bulkAddTag;

  /// Label of the field in the add tag dialog.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get bulkTagLabel;

  /// Button of the add tag dialog that adds the tag.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get bulkTagAdd;

  /// Tooltip of the selection action that hides the selected transactions.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get bulkHide;

  /// Tooltip of the selection action that unhides the selected transactions, when all are hidden.
  ///
  /// In en, this message translates to:
  /// **'Unhide'**
  String get bulkUnhide;

  /// Snack bar after setting the category of selected transactions; count is how many changed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Category set on 1 transaction} other{Category set on {count} transactions}}'**
  String bulkCategorySet(int count);

  /// Snack bar after adding a tag to selected transactions; count is how many changed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Tag added to 1 transaction} other{Tag added to {count} transactions}}'**
  String bulkTagAdded(int count);

  /// Snack bar after hiding selected transactions; count is how many changed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction hidden} other{{count} transactions hidden}}'**
  String bulkHidden(int count);

  /// Snack bar after unhiding selected transactions; count is how many changed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction unhidden} other{{count} transactions unhidden}}'**
  String bulkUnhidden(int count);

  /// Snack bar after deleting selected transactions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction deleted} other{{count} transactions deleted}}'**
  String bulkDeleted(int count);

  /// Title of the confirmation before deleting selected transactions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 transaction?} other{Delete {count} transactions?}}'**
  String bulkDeleteTitle(int count);

  /// Body of the confirmation before deleting selected transactions.
  ///
  /// In en, this message translates to:
  /// **'They leave every list and their accounts\' balances.'**
  String get bulkDeleteBody;

  /// Snack bar when a bulk action is refused and nothing is written.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed: the transactions could not be updated.'**
  String get bulkFailed;

  /// Snack bar when a bulk action is refused because a selected transaction was deleted (on another device, say).
  ///
  /// In en, this message translates to:
  /// **'Nothing changed: one of the transactions was deleted meanwhile.'**
  String get bulkFailedDeleted;

  /// Under a rule's actions in the editor: how many existing transactions the rule as edited would change, of how many.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, =1{Would change {changed} of 1 transaction} other{Would change {changed} of {total} transactions}}'**
  String rulePreviewCount(int changed, int total);

  /// Under a rule's actions in the editor, while a condition or an action has no value yet.
  ///
  /// In en, this message translates to:
  /// **'Finish the conditions and actions to see what this rule would change.'**
  String get rulePreviewIncomplete;

  /// Under a rule's actions in the editor, while the preview is computed.
  ///
  /// In en, this message translates to:
  /// **'Checking your transactions…'**
  String get rulePreviewChecking;

  /// Button that opens the list of the existing transactions a rule would change.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get rulePreviewOpen;

  /// Title of the sheet listing the existing transactions a rule would change.
  ///
  /// In en, this message translates to:
  /// **'What this rule would change'**
  String get rulePreviewTitle;

  /// At the end of the preview sheet: how many changed transactions are not listed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more transaction not shown} other{{count} more transactions not shown}}'**
  String rulePreviewMore(int count);

  /// A line of the preview sheet: the category a rule gives a transaction.
  ///
  /// In en, this message translates to:
  /// **'Category: {before} → {after}'**
  String rulePreviewCategory(String before, String after);

  /// A line of the preview sheet: the tag a rule adds to a transaction.
  ///
  /// In en, this message translates to:
  /// **'Tag added: {tag}'**
  String rulePreviewTag(String tag);

  /// A line of the preview sheet: the description a rule gives a transaction.
  ///
  /// In en, this message translates to:
  /// **'Description: {before} → {after}'**
  String rulePreviewName(String before, String after);

  /// A line of the preview sheet: the rule hides the transaction.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get rulePreviewHidden;

  /// Menu item of the rule editor and of a rule in the rules list: apply the rule to the transactions already recorded.
  ///
  /// In en, this message translates to:
  /// **'Apply to existing transactions'**
  String get ruleApplyToHistory;

  /// Under the disabled apply menu item of the rule editor while the rule has unsaved changes or is new.
  ///
  /// In en, this message translates to:
  /// **'Save the rule first'**
  String get ruleApplySaveFirst;

  /// Title of the confirmation before applying a rule to the transactions already recorded.
  ///
  /// In en, this message translates to:
  /// **'Apply “{name}” to existing transactions?'**
  String ruleApplyTitle(String name);

  /// Body of the confirmation before applying a rule to the transactions already recorded.
  ///
  /// In en, this message translates to:
  /// **'The rule changes the transactions it matches now, as it would new ones. Categories and tags you have set stay as they are.'**
  String get ruleApplyBody;

  /// Button that confirms applying a rule to the transactions already recorded.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get ruleApplyConfirm;

  /// Snack bar after applying a rule to the existing transactions: how many changed, and how many of them were given a category, a tag or a new description, or hidden.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction changed: {filed} filed, {tagged} tagged, {renamed} renamed, {hidden} hidden} other{{count} transactions changed: {filed} filed, {tagged} tagged, {renamed} renamed, {hidden} hidden}}'**
  String ruleApplied(int count, int filed, int tagged, int renamed, int hidden);

  /// Snack bar after applying a rule to the existing transactions changed none.
  ///
  /// In en, this message translates to:
  /// **'No transactions changed.'**
  String get ruleAppliedNone;

  /// Snack bar when applying a rule to the existing transactions failed and was rolled back.
  ///
  /// In en, this message translates to:
  /// **'The rule could not be applied. Nothing changed.'**
  String get ruleApplyFailed;

  /// Tooltip of a rule's overflow menu button in the rules list.
  ///
  /// In en, this message translates to:
  /// **'More options for “{name}”'**
  String ruleMoreOptions(String name);

  /// Tooltip of the rule editor's overflow menu button.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get ruleEditorMoreOptions;

  /// Accessibility label of the progress bar shown while a rule is applied to the existing transactions.
  ///
  /// In en, this message translates to:
  /// **'Applying the rule to your transactions'**
  String get ruleApplying;

  /// Title of the duplicate review screen.
  ///
  /// In en, this message translates to:
  /// **'Review duplicates'**
  String get duplicatesTitle;

  /// Item of the transaction list's menu that opens the duplicate review, with how many likely duplicate pairs there are.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Review duplicates} other{Review duplicates ({count})}}'**
  String duplicatesMenuItem(int count);

  /// Tooltip of the transaction list's menu button, with how many likely duplicate pairs its badge counts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{More options} =1{More options, 1 likely duplicate} other{More options, {count} likely duplicates}}'**
  String transactionsMoreOptions(int count);

  /// The badge on the transaction list's menu button: how many likely duplicate pairs there are.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String duplicatesBadge(int count);

  /// Headline of the duplicate review with nothing to review.
  ///
  /// In en, this message translates to:
  /// **'No likely duplicates'**
  String get duplicatesEmptyHeadline;

  /// Body of the duplicate review with nothing to review: what makes a likely duplicate.
  ///
  /// In en, this message translates to:
  /// **'Two transactions with the same amount within three days, on different accounts or one from your bank and one you entered, show up here for you to check.'**
  String get duplicatesEmptyBody;

  /// Note above the pairs of the duplicate review.
  ///
  /// In en, this message translates to:
  /// **'Each pair may be one transaction recorded twice. Nothing is merged or deleted: hide the extra one, or mark the pair as not duplicates.'**
  String get duplicatesIntro;

  /// Heading of a likely duplicate pair: how many days apart its two transactions are.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Same amount, same day} =1{Same amount, 1 day apart} other{Same amount, {days} days apart}}'**
  String duplicatesDaysApart(int days);

  /// Button under a transaction of a likely duplicate pair that hides that transaction.
  ///
  /// In en, this message translates to:
  /// **'Hide this one'**
  String get duplicateHide;

  /// Accessibility label of the button that hides one transaction of a likely duplicate pair.
  ///
  /// In en, this message translates to:
  /// **'Hide this one: {name}'**
  String duplicateHideNamed(String name);

  /// Button of a likely duplicate pair that marks the two transactions as different.
  ///
  /// In en, this message translates to:
  /// **'Not duplicates'**
  String get duplicateNotDuplicates;

  /// Snack bar after marking a pair as not duplicates, with an undo action.
  ///
  /// In en, this message translates to:
  /// **'Marked as not duplicates'**
  String get duplicateDismissed;

  /// Snack bar after hiding one transaction of a likely duplicate pair, with an undo action.
  ///
  /// In en, this message translates to:
  /// **'Transaction hidden'**
  String get duplicateHidden;

  /// Snack bar when hiding one transaction of a likely duplicate pair failed.
  ///
  /// In en, this message translates to:
  /// **'The transaction could not be hidden.'**
  String get duplicateHideFailed;

  /// Name of the system notification channel the bill reminders are posted on, shown in the system's notification settings.
  ///
  /// In en, this message translates to:
  /// **'Bill reminders'**
  String get billRemindersChannelName;

  /// Description of the bill reminders' notification channel in the system's notification settings.
  ///
  /// In en, this message translates to:
  /// **'Reminders before your bills are due'**
  String get billRemindersChannelDescription;

  /// The name shown for a bill that has none.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get billUnnamed;

  /// Title of a bill reminder on its due date.
  ///
  /// In en, this message translates to:
  /// **'{name} is due today'**
  String billReminderTitleToday(String name);

  /// Title of a bill reminder the day before its due date.
  ///
  /// In en, this message translates to:
  /// **'{name} is due tomorrow'**
  String billReminderTitleTomorrow(String name);

  /// Title of a bill reminder days before its due date.
  ///
  /// In en, this message translates to:
  /// **'{name} is due {date}'**
  String billReminderTitleOn(String name, String date);

  /// Text of a bill reminder: the bill's expected amount.
  ///
  /// In en, this message translates to:
  /// **'Expected {amount}'**
  String billReminderBody(String amount);

  /// Text of a bill reminder for a bill with no expected amount.
  ///
  /// In en, this message translates to:
  /// **'Open the bill to mark it paid'**
  String get billReminderBodyNoAmount;

  /// An in-app notification: a bill's occurrence is due today or tomorrow.
  ///
  /// In en, this message translates to:
  /// **'{name} is due {date}'**
  String alertBillDue(String name, String date);

  /// Button that opens the editor of a new bill.
  ///
  /// In en, this message translates to:
  /// **'New bill'**
  String get billNew;

  /// A one-off bill whose due date has passed, in the bills list.
  ///
  /// In en, this message translates to:
  /// **'No upcoming due date'**
  String get billNoNextDue;

  /// A bill's status: its occurrence was paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get billStatePaid;

  /// A bill's status: its last occurrence passed unpaid.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get billStateMissed;

  /// Shown when the bill being opened or saved was deleted.
  ///
  /// In en, this message translates to:
  /// **'This bill no longer exists.'**
  String get billNotFound;

  /// Title of the editor of a new bill.
  ///
  /// In en, this message translates to:
  /// **'New bill'**
  String get billNewTitle;

  /// Title of the editor of an existing bill.
  ///
  /// In en, this message translates to:
  /// **'Edit bill'**
  String get billEditTitle;

  /// Snack bar after deleting a bill, with an undo action.
  ///
  /// In en, this message translates to:
  /// **'Bill deleted'**
  String get billDeleted;

  /// Label of a bill's name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get billName;

  /// Error under an empty bill name.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get billNameRequired;

  /// Label of a bill's expected amount field.
  ///
  /// In en, this message translates to:
  /// **'Expected amount'**
  String get billAmount;

  /// Help under a bill's expected amount field.
  ///
  /// In en, this message translates to:
  /// **'Optional. A payment within 10 % of it marks the bill paid.'**
  String get billAmountHelper;

  /// Label of a bill's first due date, from which it repeats.
  ///
  /// In en, this message translates to:
  /// **'First due date'**
  String get billDueDate;

  /// A bill's due date field before one is chosen, and its error.
  ///
  /// In en, this message translates to:
  /// **'Choose a due date'**
  String get billChooseDueDate;

  /// Label of how often a bill repeats.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get billRepeats;

  /// A bill that does not repeat.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get billCadenceOnce;

  /// A bill due every week.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get billCadenceWeekly;

  /// A bill due every two weeks.
  ///
  /// In en, this message translates to:
  /// **'Every two weeks'**
  String get billCadenceBiweekly;

  /// A bill due twice a month, 15 days apart.
  ///
  /// In en, this message translates to:
  /// **'Twice a month'**
  String get billCadenceSemiMonthly;

  /// A bill due every month.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get billCadenceMonthly;

  /// A bill due every three months.
  ///
  /// In en, this message translates to:
  /// **'Every three months'**
  String get billCadenceQuarterly;

  /// A bill due every year.
  ///
  /// In en, this message translates to:
  /// **'Every year'**
  String get billCadenceAnnually;

  /// Label of the account a bill is paid from.
  ///
  /// In en, this message translates to:
  /// **'Paid from'**
  String get billAccount;

  /// A bill paid from no particular account: a payment from any account counts.
  ///
  /// In en, this message translates to:
  /// **'Any account'**
  String get billAnyAccount;

  /// Heading of a bill's reminder choices.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get billReminders;

  /// A reminder choice: how many days before the due date.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{On the day} =1{1 day before} other{{days} days before}}'**
  String billReminderOffset(int days);

  /// Label of the time of day a bill's reminders go off.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get billReminderTime;

  /// Switch: whether a bill is tracked and reminded.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get billActive;

  /// Caption of a bill's Active switch.
  ///
  /// In en, this message translates to:
  /// **'An inactive bill is kept but never reminded.'**
  String get billActiveCaption;

  /// Switch: whether a bill is on autopay.
  ///
  /// In en, this message translates to:
  /// **'Paid automatically'**
  String get billAutopay;

  /// Caption of a bill's autopay switch.
  ///
  /// In en, this message translates to:
  /// **'Never shown as missed when no payment is found.'**
  String get billAutopayCaption;

  /// Title of the sheet shown when the app may not post notifications and the user turned a reminder on.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off'**
  String get billPermissionTitle;

  /// Text of the notification permission sheet.
  ///
  /// In en, this message translates to:
  /// **'Bill reminders need notifications. The bill is saved; to be reminded, allow notifications for the app in the system settings.'**
  String get billPermissionBody;

  /// Closes the notification permission sheet.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get billPermissionNotNow;

  /// Opens the system's notification settings for the app.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get billPermissionOpenSettings;

  /// Title of the subscriptions screen, and the tooltip of the Bills segment's button that opens it.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptionsTitle;

  /// Top of the subscriptions screen: what the subscriptions with a known yearly cost cost a year together, in one currency.
  ///
  /// In en, this message translates to:
  /// **'{total} a year across {count, plural, =1{1 subscription} other{{count} subscriptions}}'**
  String subscriptionsTotal(String total, int count);

  /// Headline of the subscriptions screen when there are no recurring streams.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions yet'**
  String get subscriptionsEmptyHeadline;

  /// Supporting text of the subscriptions screen when there are no recurring streams.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions found in your transactions or reported by your bank will appear here.'**
  String get subscriptionsEmptyBody;

  /// Folded section of the muted recurring streams.
  ///
  /// In en, this message translates to:
  /// **'Muted ({count})'**
  String subscriptionsMuted(int count);

  /// Folded section of the recurring streams not counted as subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Other recurring ({count})'**
  String subscriptionsOthers(int count);

  /// How often a recurring stream recurs.
  ///
  /// In en, this message translates to:
  /// **'{cadence, select, weekly{Weekly} biweekly{Every two weeks} semiMonthly{Twice a month} monthly{Monthly} quarterly{Quarterly} annually{Yearly} other{Irregular}}'**
  String streamCadence(String cadence);

  /// A recurring stream's cadence and its usual amount.
  ///
  /// In en, this message translates to:
  /// **'{cadence}, {amount} each'**
  String streamAmountEach(String cadence, String amount);

  /// What a subscription costs a year.
  ///
  /// In en, this message translates to:
  /// **'{amount} a year'**
  String streamYearly(String amount);

  /// Caption of a recurring stream the app found itself rather than the bank.
  ///
  /// In en, this message translates to:
  /// **'Detected from your transactions'**
  String get streamDetected;

  /// Tooltip of a recurring stream's menu button.
  ///
  /// In en, this message translates to:
  /// **'Actions for {name}'**
  String streamActions(String name);

  /// Menu item: stop counting and suggesting a recurring stream.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get streamMute;

  /// Menu item: count a muted recurring stream again.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get streamUnmute;

  /// Menu item: stop counting a recurring stream as a subscription.
  ///
  /// In en, this message translates to:
  /// **'Not a subscription'**
  String get streamNotSubscription;

  /// Menu item: count a recurring stream as a subscription.
  ///
  /// In en, this message translates to:
  /// **'Mark as subscription'**
  String get streamMarkSubscription;

  /// Menu item and dialog title: give a recurring stream another name.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get streamRename;

  /// Menu item: open the bill editor prefilled from a recurring stream.
  ///
  /// In en, this message translates to:
  /// **'Create a bill'**
  String get streamCreateBill;

  /// Snack bar after muting a recurring stream.
  ///
  /// In en, this message translates to:
  /// **'{name} muted'**
  String streamMutedDone(String name);

  /// Snack bar after unmuting a recurring stream.
  ///
  /// In en, this message translates to:
  /// **'{name} unmuted'**
  String streamUnmutedDone(String name);

  /// Snack bar after saying a recurring stream is not a subscription.
  ///
  /// In en, this message translates to:
  /// **'{name} is no longer counted as a subscription'**
  String streamNotSubscriptionDone(String name);

  /// Snack bar after marking a recurring stream as a subscription.
  ///
  /// In en, this message translates to:
  /// **'{name} is counted as a subscription'**
  String streamMarkSubscriptionDone(String name);

  /// Snack bar after renaming a recurring stream.
  ///
  /// In en, this message translates to:
  /// **'Renamed to {name}'**
  String streamRenamedDone(String name);

  /// Field of the rename dialog.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get streamRenameLabel;

  /// Helper text of the rename dialog's field.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use {merchant}'**
  String streamRenameHelper(String merchant);

  /// Tooltip of the Plan tab when bills were missed; the tab's badge shows the count.
  ///
  /// In en, this message translates to:
  /// **'Plan, {count, plural, =1{1 missed bill} other{{count} missed bills}}'**
  String navPlanMissed(int count);

  /// Headline of the Bills segment when there are no bills and no suggestions.
  ///
  /// In en, this message translates to:
  /// **'No bills yet'**
  String get billsEmptyHeadline;

  /// Supporting text of the Bills segment when there are no bills.
  ///
  /// In en, this message translates to:
  /// **'Add a bill to be reminded before it is due.'**
  String get billsEmptyBody;

  /// Heading of the bills whose last due date was missed.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get billsGroupOverdue;

  /// Heading of the bills due in the next 7 days (or due in the last few days).
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get billsGroupDueSoon;

  /// Heading of the bills due after the next 7 days.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get billsGroupLater;

  /// Folded section of the inactive bills.
  ///
  /// In en, this message translates to:
  /// **'Paused ({count})'**
  String billsGroupPaused(int count);

  /// Heading of the bills the app suggests from recurring payments and loans.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get billsSuggested;

  /// A suggested bill's cadence and next due date.
  ///
  /// In en, this message translates to:
  /// **'{cadence}, next due {date}'**
  String billSuggestionDetail(String cadence, String date);

  /// Button: open the bill editor prefilled from a suggestion.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get billSuggestionAdd;

  /// Accessibility label of a suggestion's Add button.
  ///
  /// In en, this message translates to:
  /// **'Add {name} as a bill'**
  String billSuggestionAddLabel(String name);

  /// Button: stop suggesting a bill on this device.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get billSuggestionDismiss;

  /// Accessibility label of a suggestion's Dismiss button.
  ///
  /// In en, this message translates to:
  /// **'Dismiss the suggestion {name}'**
  String billSuggestionDismissLabel(String name);

  /// Label of a bill paid automatically.
  ///
  /// In en, this message translates to:
  /// **'Autopay'**
  String get billStateAutopay;

  /// Button: mark a bill's due or missed occurrence paid.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get billMarkPaid;

  /// Accessibility label of a bill's Mark paid button.
  ///
  /// In en, this message translates to:
  /// **'Mark {name} paid for {date}'**
  String billMarkPaidLabel(String name, String date);

  /// Snack bar after marking a bill paid.
  ///
  /// In en, this message translates to:
  /// **'{name} marked paid'**
  String billMarkedPaid(String name);

  /// A bill's due date within the next week.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Due today} =1{Due tomorrow} other{Due in {days} days}}'**
  String billDueIn(int days);

  /// A bill's due date within the last week.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Due yesterday} other{Due {days} days ago}}'**
  String billDueAgo(int days);

  /// A bill's due date more than a week away.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String billDueOn(String date);

  /// Subtitle of an inactive bill.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get billPaused;

  /// Tooltip of the Bills segment's list view button.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get billsListView;

  /// Tooltip of the Bills segment's calendar view button.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get billsCalendarView;

  /// Tooltip of the calendar's previous month button.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get billsPreviousMonth;

  /// Tooltip of the calendar's next month button.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get billsNextMonth;

  /// Accessibility label of a calendar day.
  ///
  /// In en, this message translates to:
  /// **'{date}, {count, plural, =0{no bills due} =1{1 bill due: {names}} other{{count} bills due: {names}}}'**
  String billsCalendarDay(String date, int count, String names);

  /// Under the calendar when the chosen day has no bills.
  ///
  /// In en, this message translates to:
  /// **'No bills due {date}'**
  String billsCalendarNone(String date);

  /// Button under the first three bill suggestions that shows them all.
  ///
  /// In en, this message translates to:
  /// **'Show all ({count})'**
  String billsSuggestedShowAll(int count);

  /// Read by screen readers on the Plan tab's badge: how many bills were missed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 missed bill} other{{count} missed bills}}'**
  String billsMissedCount(int count);

  /// Title of the forecast screen.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get forecastTitle;

  /// A segment of the forecast's horizon control.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String forecastHorizon(int days);

  /// Switches the forecast from its chart to its table.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get forecastShowTable;

  /// Switches the forecast from its table to its chart.
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get forecastShowChart;

  /// The forecast's headline: its lowest projected balance and the day of it.
  ///
  /// In en, this message translates to:
  /// **'Lowest point {amount} on {date}'**
  String forecastLowest(String amount, String date);

  /// The forecast's headline when the projected balance goes below zero: the first day it does.
  ///
  /// In en, this message translates to:
  /// **'Below zero on {date}'**
  String forecastBelowZero(String date);

  /// Opens the sheet choosing the accounts the forecast covers.
  ///
  /// In en, this message translates to:
  /// **'Choose accounts'**
  String get forecastChooseAccounts;

  /// Headline of the forecast when it covers no account.
  ///
  /// In en, this message translates to:
  /// **'No accounts to forecast'**
  String get forecastEmptyHeadline;

  /// Text of the forecast when it covers no account.
  ///
  /// In en, this message translates to:
  /// **'Choose a checking or savings account to see where its balance is heading.'**
  String get forecastEmptyBody;

  /// What a screen reader says for the forecast chart.
  ///
  /// In en, this message translates to:
  /// **'{days}-day forecast: {start} today, {end} on {endDate}. Lowest point {lowest} on {lowestDate}.'**
  String forecastChartSummary(
    int days,
    String start,
    String end,
    String endDate,
    String lowest,
    String lowestDate,
  );

  /// The confidence band of a forecast day, in its table row and the chart's tooltip.
  ///
  /// In en, this message translates to:
  /// **'Low {low} · High {high}'**
  String forecastRange(String low, String high);

  /// What a screen reader says for a day of the forecast's table, before its events.
  ///
  /// In en, this message translates to:
  /// **'{date}: balance {balance}, low {low}, high {high}.'**
  String forecastDaySemantics(
    String date,
    String balance,
    String low,
    String high,
  );

  /// An event of the forecast that was due earlier and is not paid yet, landing on tomorrow.
  ///
  /// In en, this message translates to:
  /// **'{name}, due {date}'**
  String forecastOverdue(String name, String date);

  /// Title of the sheet choosing the forecast's accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts in the forecast'**
  String get forecastAccountsTitle;

  /// Subtitle of a hidden account in the forecast's account sheet: its currency, and that it is hidden.
  ///
  /// In en, this message translates to:
  /// **'{currency} · hidden account'**
  String forecastAccountsHidden(String currency);

  /// Label of the currency chips in the forecast's account sheet.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get forecastCurrency;

  /// Shown when a change to the forecast's accounts or currency could not be kept.
  ///
  /// In en, this message translates to:
  /// **'The forecast\'s accounts could not be saved. Try again.'**
  String get forecastSelectionFailed;

  /// Action that opens the editor of a new savings goal.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get goalsNew;

  /// Shown on the goals screen when there are none.
  ///
  /// In en, this message translates to:
  /// **'No savings goals yet'**
  String get goalsEmptyTitle;

  /// Explains what a savings goal does, on the empty goals screen.
  ///
  /// In en, this message translates to:
  /// **'Set a target and a date, and see how much to set aside each month.'**
  String get goalsEmptyBody;

  /// Heading of the folded section of archived goals, with how many there are.
  ///
  /// In en, this message translates to:
  /// **'Archived ({count})'**
  String goalsArchived(int count);

  /// How far a goal has come: the progress amount and the target amount.
  ///
  /// In en, this message translates to:
  /// **'{progress} of {target}'**
  String goalProgressOf(String progress, String target);

  /// What a screen reader says for a goal's progress bar, read with the goal's name and amounts beside it.
  ///
  /// In en, this message translates to:
  /// **'{percent} percent of the target'**
  String goalProgressPercent(int percent);

  /// Status of a goal whose progress is at least what its plan expects by today.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get goalOnTrack;

  /// Status of a goal whose progress is below what its plan expects by today, by how much.
  ///
  /// In en, this message translates to:
  /// **'Behind by {amount}'**
  String goalBehind(String amount);

  /// Status of a goal that reached its target.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get goalDone;

  /// The monthly amount that reaches a goal's target by its date.
  ///
  /// In en, this message translates to:
  /// **'Set aside {amount} a month'**
  String goalSuggestion(String amount);

  /// A goal's target date, under its name.
  ///
  /// In en, this message translates to:
  /// **'By {date}'**
  String goalTargetDateCaption(String date);

  /// Shown when the goal being opened or saved was deleted.
  ///
  /// In en, this message translates to:
  /// **'This goal no longer exists.'**
  String get goalNotFound;

  /// Title of the editor of a new goal.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get goalNewTitle;

  /// Title of the editor of an existing goal, and the tooltip of the action that opens it.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get goalEditTitle;

  /// Label of a goal's name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get goalName;

  /// Error under an empty goal name.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get goalNameRequired;

  /// Label of a goal's target amount field.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get goalTarget;

  /// Label of the choice of how a goal measures its progress.
  ///
  /// In en, this message translates to:
  /// **'Progress from'**
  String get goalKind;

  /// A goal whose progress is the balance of the accounts chosen for it.
  ///
  /// In en, this message translates to:
  /// **'Account balances'**
  String get goalKindBalance;

  /// A goal whose progress is the sum of the contributions added to it.
  ///
  /// In en, this message translates to:
  /// **'Contributions'**
  String get goalKindContribution;

  /// Explains a balance goal, under the choice.
  ///
  /// In en, this message translates to:
  /// **'Progress is the balance of the accounts you choose.'**
  String get goalKindBalanceCaption;

  /// Explains a contribution goal, under the choice.
  ///
  /// In en, this message translates to:
  /// **'Progress is what you add to the goal yourself.'**
  String get goalKindContributionCaption;

  /// Heading of the accounts a balance goal counts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get goalAccounts;

  /// Error when a balance goal has no account chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one account'**
  String get goalAccountsRequired;

  /// Subtitle of an account in another currency than the goal's target: it does not count toward it.
  ///
  /// In en, this message translates to:
  /// **'In {currency}, not counted'**
  String goalAccountOtherCurrency(String currency);

  /// Label of a goal's optional target date.
  ///
  /// In en, this message translates to:
  /// **'Target date'**
  String get goalTargetDate;

  /// Shown in the target date field when the goal has none.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get goalNoTargetDate;

  /// Action that removes a goal's target date.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get goalClearTargetDate;

  /// Label of a goal's note field.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get goalNote;

  /// Action that archives a goal: it is kept, folded away.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get goalArchive;

  /// Action that brings an archived goal back.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get goalUnarchive;

  /// Snack bar after archiving a goal, with an undo action.
  ///
  /// In en, this message translates to:
  /// **'Goal archived'**
  String get goalArchivedMessage;

  /// Snack bar after deleting a goal, with an undo action.
  ///
  /// In en, this message translates to:
  /// **'Goal deleted'**
  String get goalDeleted;

  /// Heading of the accounts whose balances make a balance goal's progress, on its detail.
  ///
  /// In en, this message translates to:
  /// **'Counted accounts'**
  String get goalCountedAccounts;

  /// The accounts linked to a goal that are in another currency than its target, which do not count.
  ///
  /// In en, this message translates to:
  /// **'Not counted, another currency: {names}'**
  String goalNotCounted(String names);

  /// Heading of a goal's contribution list.
  ///
  /// In en, this message translates to:
  /// **'Contributions'**
  String get goalContributions;

  /// Shown when a contribution goal has none.
  ///
  /// In en, this message translates to:
  /// **'No contributions yet.'**
  String get goalNoContributions;

  /// Action that adds a contribution to a goal, and the title of its editor.
  ///
  /// In en, this message translates to:
  /// **'Add contribution'**
  String get goalAddContribution;

  /// Label of a contribution's date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get contributionDate;

  /// Label of a contribution's amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get contributionAmount;

  /// Label of a contribution's note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get contributionNote;

  /// Switch that makes a contribution take money out of the goal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get contributionWithdrawal;

  /// Explains the withdrawal switch.
  ///
  /// In en, this message translates to:
  /// **'Takes the amount out of the goal.'**
  String get contributionWithdrawalCaption;

  /// Tooltip of the action deleting a contribution.
  ///
  /// In en, this message translates to:
  /// **'Delete contribution'**
  String get contributionDelete;

  /// Snack bar after deleting a contribution, with an undo action.
  ///
  /// In en, this message translates to:
  /// **'Contribution deleted'**
  String get contributionDeleted;

  /// Error under a goal's target date when it is before today.
  ///
  /// In en, this message translates to:
  /// **'Choose today or a later date'**
  String get goalTargetDatePast;

  /// Caption under a goal's currency choice when it can no longer change.
  ///
  /// In en, this message translates to:
  /// **'The currency stays as it is once the goal has contributions or accounts.'**
  String get goalCurrencyLocked;

  /// Shown on a contribution in another currency than its goal's target: it does not count toward it.
  ///
  /// In en, this message translates to:
  /// **'Not counted, in {currency}'**
  String contributionNotCounted(String currency);

  /// Error under a contribution's date when it is after today.
  ///
  /// In en, this message translates to:
  /// **'Choose today or an earlier date'**
  String get contributionDateFuture;

  /// Title of the investments screen.
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get investmentsTitle;

  /// Headline of the Investments segment when no investment account is linked.
  ///
  /// In en, this message translates to:
  /// **'No investment accounts'**
  String get investmentsEmptyHeadline;

  /// Supporting text of the Investments segment's empty state.
  ///
  /// In en, this message translates to:
  /// **'Link a brokerage or retirement account to see its holdings, allocation and value here.'**
  String get investmentsEmptyBody;

  /// Heading of the holdings' allocation by security type.
  ///
  /// In en, this message translates to:
  /// **'Allocation'**
  String get investmentsAllocation;

  /// Heading of the allocation of the holdings valued in one currency, when they are in more than one.
  ///
  /// In en, this message translates to:
  /// **'Allocation in {currency}'**
  String investmentsAllocationIn(String currency);

  /// What a screen reader says for the allocation donut: the total, how many security types, and the largest with its share.
  ///
  /// In en, this message translates to:
  /// **'Holdings worth {total} in {count, plural, =1{one security type} other{{count} security types}}. The largest is {largest} at {share}.'**
  String investmentsAllocationSummary(
    String total,
    int count,
    String largest,
    String share,
  );

  /// A row of the allocation table as a screen reader reads it: the security type, its value and its share of the total.
  ///
  /// In en, this message translates to:
  /// **'{type}: {value}, {share}'**
  String investmentsAllocationRow(String type, String value, String share);

  /// The allocation's name for cash and cash equivalents.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get investmentsTypeCash;

  /// The allocation's name for holdings whose security has no type.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get investmentsTypeOther;

  /// The allocation's name for exchange-traded funds.
  ///
  /// In en, this message translates to:
  /// **'ETF'**
  String get investmentsTypeEtf;

  /// A whole percent.
  ///
  /// In en, this message translates to:
  /// **'{percent} %'**
  String investmentsPercent(int percent);

  /// A whole percent increase, with its plus sign.
  ///
  /// In en, this message translates to:
  /// **'+{percent} %'**
  String investmentsPercentUp(int percent);

  /// A gain with its percent of the cost basis, for example "+$120.00 (+5 %)".
  ///
  /// In en, this message translates to:
  /// **'{amount} ({percent})'**
  String investmentsChange(String amount, String percent);

  /// A per-share price, exact as the institution reports it, with its currency code.
  ///
  /// In en, this message translates to:
  /// **'{price} {currency}'**
  String investmentsPrice(String price, String currency);

  /// How many shares at what price, for example "12.500 at 245.10 USD".
  ///
  /// In en, this message translates to:
  /// **'{quantity} at {price}'**
  String investmentsQuantityAtPrice(String quantity, String price);

  /// A holding's cost basis, as the institution reports it.
  ///
  /// In en, this message translates to:
  /// **'Cost basis {cost}'**
  String investmentsCostBasis(String cost);

  /// A holding's gain (its value less its cost basis), with the gain's percent of the cost basis when there is one.
  ///
  /// In en, this message translates to:
  /// **'Gain {gain}'**
  String investmentsGain(String gain);

  /// Shown on a holding whose institution reports no cost basis, so no gain can be shown.
  ///
  /// In en, this message translates to:
  /// **'Cost basis unavailable'**
  String get investmentsCostBasisUnavailable;

  /// The date of a holding's price.
  ///
  /// In en, this message translates to:
  /// **'Price as of {date}'**
  String investmentsPriceAsOf(String date);

  /// A holding or an investment transaction as a screen reader starts it: its name and its value or amount.
  ///
  /// In en, this message translates to:
  /// **'{name}: {amount}'**
  String investmentsNameAmount(String name, String amount);

  /// An investment transaction's date and type.
  ///
  /// In en, this message translates to:
  /// **'{date} · {type}'**
  String investmentsDateAndType(String date, String type);

  /// An investment transaction's fees.
  ///
  /// In en, this message translates to:
  /// **'Fees {amount}'**
  String investmentsFees(String amount);

  /// An investment account's heading as a screen reader reads it: its name, its balance and whether the balance was reported or computed.
  ///
  /// In en, this message translates to:
  /// **'{name}, {balance}, {caption}'**
  String investmentsAccountSemantics(
    String name,
    String balance,
    String caption,
  );

  /// Heading of an investment account's value history.
  ///
  /// In en, this message translates to:
  /// **'Value over time'**
  String get investmentsValueTitle;

  /// Caption of an investment account's value history: the values are the daily balances this device recorded, from the first one.
  ///
  /// In en, this message translates to:
  /// **'From install day: recorded on this device since {date}'**
  String investmentsValueCaption(String date);

  /// Shown instead of the value history when this device has recorded no balance for the account.
  ///
  /// In en, this message translates to:
  /// **'No values recorded yet'**
  String get investmentsValueNone;

  /// What a screen reader says for an investment account's value chart: the first and the latest values with their dates.
  ///
  /// In en, this message translates to:
  /// **'Value {start} on {startDate}, {end} on {endDate}.'**
  String investmentsValueSummary(
    String start,
    String startDate,
    String end,
    String endDate,
  );

  /// What a screen reader says for an investment account's value chart when one day is recorded.
  ///
  /// In en, this message translates to:
  /// **'Value {amount} on {date}.'**
  String investmentsValueSummaryOne(String amount, String date);

  /// A row of an investment account's value table as a screen reader reads it.
  ///
  /// In en, this message translates to:
  /// **'{date}: {value}'**
  String investmentsValueRow(String date, String value);

  /// Switches an investment account's value history from its chart to its table.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get investmentsShowTable;

  /// Switches an investment account's value history from its table to its chart.
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get investmentsShowChart;

  /// Heading of an investment account's holdings.
  ///
  /// In en, this message translates to:
  /// **'Holdings'**
  String get investmentsHoldings;

  /// Shown when an investment account has no holdings.
  ///
  /// In en, this message translates to:
  /// **'No holdings reported'**
  String get investmentsNoHoldings;

  /// The title of a holding whose security has neither a name nor a ticker.
  ///
  /// In en, this message translates to:
  /// **'Unknown security'**
  String get investmentsUnknownSecurity;

  /// Heading of an investment account's investment transactions.
  ///
  /// In en, this message translates to:
  /// **'Investment transactions'**
  String get investmentsTransactions;

  /// Shown when an investment account has no investment transactions.
  ///
  /// In en, this message translates to:
  /// **'No investment transactions'**
  String get investmentsNoTransactions;

  /// Shows the next page of an account's investment transactions; count is how many are not shown yet.
  ///
  /// In en, this message translates to:
  /// **'Show more ({count} left)'**
  String investmentsShowMore(int count);

  /// The net worth screen's title.
  ///
  /// In en, this message translates to:
  /// **'Net worth'**
  String get netWorthTitle;

  /// Above the headline amount: the day of the latest point.
  ///
  /// In en, this message translates to:
  /// **'Net worth on {date}'**
  String netWorthHeadlineLabel(String date);

  /// The change in net worth against the point 30 days before the latest.
  ///
  /// In en, this message translates to:
  /// **'{amount} over 30 days'**
  String netWorthChange(String amount);

  /// The change in net worth when the point 30 days before is estimated from transactions.
  ///
  /// In en, this message translates to:
  /// **'{amount} over 30 days, against an estimate'**
  String netWorthChangeEstimated(String amount);

  /// The range control: the last three months.
  ///
  /// In en, this message translates to:
  /// **'3 m'**
  String get netWorthRangeThreeMonths;

  /// The range control: the last year.
  ///
  /// In en, this message translates to:
  /// **'1 y'**
  String get netWorthRangeYear;

  /// The range control: the whole history.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get netWorthRangeAll;

  /// Switches the net worth history from its chart to its table.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get netWorthShowTable;

  /// Switches the net worth history from its table to its chart.
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get netWorthShowChart;

  /// The assets line and column.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get netWorthAssets;

  /// The liabilities line and column.
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get netWorthLiabilitiesLine;

  /// The chart legend for the dashed part of each line.
  ///
  /// In en, this message translates to:
  /// **'Dashed: estimated from transactions'**
  String get netWorthEstimatedLegend;

  /// What a screen reader says for the net worth chart.
  ///
  /// In en, this message translates to:
  /// **'Net worth from {startDate} to {endDate}: {start} to {end}. On {endDate}, assets {assets} and liabilities {liabilities}.'**
  String netWorthChartSummary(
    String startDate,
    String endDate,
    String start,
    String end,
    String assets,
    String liabilities,
  );

  /// Added to the chart's summary when part of the history is reconstructed.
  ///
  /// In en, this message translates to:
  /// **'Before {date}, estimated from transactions.'**
  String netWorthChartEstimated(String date);

  /// What a screen reader says for one day of the net worth table.
  ///
  /// In en, this message translates to:
  /// **'{date}: net worth {netWorth}, assets {assets}, liabilities {liabilities}.'**
  String netWorthRowSemantics(
    String date,
    String netWorth,
    String assets,
    String liabilities,
  );

  /// Under a day's net worth in the table.
  ///
  /// In en, this message translates to:
  /// **'Assets {assets} · Liabilities {liabilities}'**
  String netWorthRowDetail(String assets, String liabilities);

  /// Marks a day of the table reconstructed from transactions.
  ///
  /// In en, this message translates to:
  /// **'Estimated from transactions'**
  String get netWorthEstimated;

  /// Marks a day of the table with no stored snapshot.
  ///
  /// In en, this message translates to:
  /// **'No snapshot this day: the day before\'s values'**
  String get netWorthCarried;

  /// The empty state's headline.
  ///
  /// In en, this message translates to:
  /// **'No net worth yet'**
  String get netWorthEmptyHeadline;

  /// The empty state's body.
  ///
  /// In en, this message translates to:
  /// **'Your net worth is recorded once a day from your accounts\' balances. Add or link an account to start.'**
  String get netWorthEmptyBody;

  /// The heading of the payoff projections.
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get netWorthLiabilitiesHeading;

  /// A liability's owed amount.
  ///
  /// In en, this message translates to:
  /// **'{amount} owed'**
  String netWorthOwed(String amount);

  /// Under a liability's name when its account is hidden: net worth still counts it.
  ///
  /// In en, this message translates to:
  /// **'Hidden account'**
  String get netWorthHiddenAccount;

  /// A liability's interest rate, as the bank reports it.
  ///
  /// In en, this message translates to:
  /// **'{rate} % a year'**
  String netWorthRate(String rate);

  /// A liability's interest rate, as the user entered it.
  ///
  /// In en, this message translates to:
  /// **'{rate} % a year, entered'**
  String netWorthRateEntered(String rate);

  /// When neither the bank nor the user gave a rate.
  ///
  /// In en, this message translates to:
  /// **'No interest rate reported'**
  String get netWorthNoRate;

  /// A card's or student loan's payment.
  ///
  /// In en, this message translates to:
  /// **'Minimum payment {amount}'**
  String netWorthPaymentMinimum(String amount);

  /// A mortgage's payment.
  ///
  /// In en, this message translates to:
  /// **'Monthly payment {amount}'**
  String netWorthPaymentMonthly(String amount);

  /// A payment the user entered.
  ///
  /// In en, this message translates to:
  /// **'Your payment {amount}'**
  String netWorthPaymentEntered(String amount);

  /// When neither the bank nor the user gave a payment.
  ///
  /// In en, this message translates to:
  /// **'No payment reported'**
  String get netWorthNoPayment;

  /// Opens the rate entry for a liability with no reported rate.
  ///
  /// In en, this message translates to:
  /// **'Enter rate'**
  String get netWorthEnterRate;

  /// Opens the payment entry for a liability with no reported payment.
  ///
  /// In en, this message translates to:
  /// **'Enter payment'**
  String get netWorthEnterPayment;

  /// Opens the rate entry for a rate the user entered.
  ///
  /// In en, this message translates to:
  /// **'Change rate'**
  String get netWorthEditRate;

  /// Opens the payment entry for a payment the user entered.
  ///
  /// In en, this message translates to:
  /// **'Change payment'**
  String get netWorthEditPayment;

  /// A liability's payoff projection.
  ///
  /// In en, this message translates to:
  /// **'Paid off in {months, plural, =1{1 month} other{{months} months}}, {date}; {interest} in interest'**
  String netWorthPaidOff(int months, String date, String interest);

  /// When the payment does not exceed a month's interest.
  ///
  /// In en, this message translates to:
  /// **'Never paid off: the payment doesn\'t cover the interest of {interest} a month'**
  String netWorthNever(String interest);

  /// When the payoff takes longer than the projection's cap.
  ///
  /// In en, this message translates to:
  /// **'Over 50 years to pay off'**
  String get netWorthBeyondCap;

  /// When the account owes nothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing owed'**
  String get netWorthNothingOwed;

  /// The extra-payment slider's label.
  ///
  /// In en, this message translates to:
  /// **'Extra a month: {amount}'**
  String netWorthExtra(String amount);

  /// What the extra payment changes against the payment alone.
  ///
  /// In en, this message translates to:
  /// **'{months, plural, =0{no sooner} =1{1 month sooner} other{{months} months sooner}}, {interest} less interest'**
  String netWorthExtraDifference(int months, String interest);

  /// The projection with the extra payment.
  ///
  /// In en, this message translates to:
  /// **'With {extra} more a month: {result}'**
  String netWorthWithExtra(String extra, String result);

  /// The rate entry's field.
  ///
  /// In en, this message translates to:
  /// **'Interest rate, % a year'**
  String get netWorthRateLabel;

  /// The rate entry's error.
  ///
  /// In en, this message translates to:
  /// **'Enter a rate from 0 to 100, with up to two decimals'**
  String get netWorthRateInvalid;

  /// The payment entry's field.
  ///
  /// In en, this message translates to:
  /// **'Monthly payment'**
  String get netWorthPaymentLabel;

  /// The payment entry's error.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount above zero'**
  String get netWorthPaymentInvalid;

  /// Removes an entered rate or payment.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get netWorthClearEntry;

  /// Shown when a payoff entry could not be kept.
  ///
  /// In en, this message translates to:
  /// **'The entry could not be saved. Try again.'**
  String get netWorthEntryFailed;

  /// Title at the top of the monthly report's PDF.
  ///
  /// In en, this message translates to:
  /// **'Monthly report'**
  String get exportReportTitle;

  /// Under the monthly report's title while its period is still running: the last day counted.
  ///
  /// In en, this message translates to:
  /// **'Counted through {date}'**
  String exportCountedThrough(String date);

  /// Under the monthly report's title: the currency of every amount in it.
  ///
  /// In en, this message translates to:
  /// **'Amounts in {currency}'**
  String exportAmountsIn(String currency);

  /// The monthly report's bar for the category groups beyond the first ten.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get exportOther;

  /// A column heading in the monthly report's tables.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get exportColumnCategory;

  /// A column heading in the monthly report's tables: the share of the period's spending.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get exportColumnShare;

  /// A column heading in the monthly report's tables.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get exportColumnAmount;

  /// A column heading in the monthly report's tables.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get exportColumnMerchant;

  /// A column heading in the monthly report's tables.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get exportColumnPeriod;

  /// A column heading in the monthly report's tables: income less spending.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get exportColumnNet;

  /// A column heading in the monthly report's movers: the spending in the period before.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get exportColumnBefore;

  /// A column heading in the monthly report's movers: the spending in this period.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get exportColumnNow;

  /// A column heading in the monthly report's movers.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get exportColumnChange;

  /// A column heading in the monthly report's tables.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get exportColumnDate;

  /// A column heading in the monthly report's "Worth a look": why the transaction stands out.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get exportColumnWhy;

  /// The monthly report's section of the bills due in the period.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get exportBills;

  /// A column heading in the monthly report's bills.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get exportColumnBill;

  /// A column heading in the monthly report's bills: the due date.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get exportColumnDue;

  /// A column heading in the monthly report's bills.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get exportColumnStatus;

  /// A bill occurrence in the monthly report that is due now and not yet paid.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get exportBillDue;

  /// A bill occurrence in the monthly report that is still to come.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get exportBillUpcoming;

  /// The monthly report's bills section when none was due.
  ///
  /// In en, this message translates to:
  /// **'No bills due in this period.'**
  String get exportNoBills;

  /// A column heading in the monthly report's budgets.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get exportColumnBudget;

  /// A column heading in the monthly report's budgets: the amount plus what carried over.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get exportColumnAvailable;

  /// A column heading in the monthly report's budgets: what is left, negative when over.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get exportColumnLeft;

  /// The monthly report's page footer.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {count}'**
  String exportPage(int page, int count);

  /// Title of the export screen and its Settings entry.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportTitle;

  /// Subtitle of the Export entry in Settings.
  ///
  /// In en, this message translates to:
  /// **'The monthly report as a PDF, transactions as a CSV'**
  String get exportSettingsSubtitle;

  /// Heading of the export screen's monthly report part.
  ///
  /// In en, this message translates to:
  /// **'Monthly report (PDF)'**
  String get exportReportSection;

  /// Heading of the export screen's transactions part.
  ///
  /// In en, this message translates to:
  /// **'Transactions (CSV)'**
  String get exportTransactionsSection;

  /// Button that saves an exported file through the system's Save as dialog.
  ///
  /// In en, this message translates to:
  /// **'Save as…'**
  String get exportSaveAs;

  /// Button that offers an exported file to the system's share sheet.
  ///
  /// In en, this message translates to:
  /// **'Share…'**
  String get exportShare;

  /// Screen reader label of the Save as button of the monthly report.
  ///
  /// In en, this message translates to:
  /// **'Save the monthly report as a PDF'**
  String get exportSaveReport;

  /// Screen reader label of the Share button of the monthly report.
  ///
  /// In en, this message translates to:
  /// **'Share the monthly report as a PDF'**
  String get exportShareReport;

  /// Screen reader label of the Save as button of the transactions.
  ///
  /// In en, this message translates to:
  /// **'Save the transactions as a CSV'**
  String get exportSaveTransactions;

  /// Screen reader label of the Share button of the transactions.
  ///
  /// In en, this message translates to:
  /// **'Share the transactions as a CSV'**
  String get exportShareTransactions;

  /// Label of the export's date range for the transactions.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get exportDates;

  /// Label of the export's account choice for the transactions.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get exportAccounts;

  /// How many transactions the CSV will hold.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No transactions in these dates and accounts} =1{1 transaction} other{{count} transactions}}'**
  String exportTransactionCount(int count);

  /// The export's privacy note.
  ///
  /// In en, this message translates to:
  /// **'A file you save or share leaves the app\'s encrypted storage. Anyone who has the file can read it.'**
  String get exportPrivacyNote;

  /// Added to the export's privacy note in the demo flavor, where files go nowhere.
  ///
  /// In en, this message translates to:
  /// **'In the demo, nothing is saved or shared.'**
  String get exportDemoNote;

  /// Screen reader label of the progress bar while an exported file is made.
  ///
  /// In en, this message translates to:
  /// **'Preparing the file'**
  String get exportPreparing;

  /// Shown after an exported file was saved.
  ///
  /// In en, this message translates to:
  /// **'Saved {fileName}'**
  String exportSaved(String fileName);

  /// Shown when an exported file could not be saved or shared.
  ///
  /// In en, this message translates to:
  /// **'The file could not be exported. Try again.'**
  String get exportFailed;

  /// The Reports screen's menu item that exports the period shown as a PDF.
  ///
  /// In en, this message translates to:
  /// **'Export this month as PDF'**
  String get exportReportMenu;

  /// Title of the backup screen and its Settings entry.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupTitle;

  /// Subtitle of the Backup entry in Settings.
  ///
  /// In en, this message translates to:
  /// **'Everything in one encrypted file, or restore one'**
  String get backupSettingsSubtitle;

  /// Subtitle of the Backup entry in the demo's Settings, which has no backup.
  ///
  /// In en, this message translates to:
  /// **'The demo\'s generated data is not kept or backed up'**
  String get backupDemoNote;

  /// Header of the backup screen's export section.
  ///
  /// In en, this message translates to:
  /// **'Export a backup'**
  String get backupExportSection;

  /// What a backup holds, above the passphrase fields.
  ///
  /// In en, this message translates to:
  /// **'Everything on this device in one file, encrypted with a passphrase you choose: accounts, transactions, budgets, bills, goals, settings and receipt photos. Keep it anywhere.'**
  String get backupExportExplanation;

  /// Label of the backup passphrase field.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get backupPassphrase;

  /// Label of the field confirming the backup passphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase again'**
  String get backupPassphraseConfirm;

  /// Helper under the backup passphrase field before anything is typed.
  ///
  /// In en, this message translates to:
  /// **'At least {count} characters'**
  String backupPassphraseHelper(int count);

  /// Error under the backup passphrase field when it is too short.
  ///
  /// In en, this message translates to:
  /// **'Use at least {count} characters'**
  String backupPassphraseTooShort(int count);

  /// Error under the confirmation field when it differs from the passphrase.
  ///
  /// In en, this message translates to:
  /// **'The two passphrases differ'**
  String get backupPassphraseMismatch;

  /// Strength hint of a long enough but weak backup passphrase.
  ///
  /// In en, this message translates to:
  /// **'Strength: weak. A longer passphrase is safer.'**
  String get backupStrengthWeak;

  /// Strength hint of a fair backup passphrase.
  ///
  /// In en, this message translates to:
  /// **'Strength: fair'**
  String get backupStrengthFair;

  /// Strength hint of a strong backup passphrase.
  ///
  /// In en, this message translates to:
  /// **'Strength: strong'**
  String get backupStrengthStrong;

  /// Warning under the backup passphrase fields.
  ///
  /// In en, this message translates to:
  /// **'There is no way to recover a forgotten passphrase: without it, the backup cannot be opened.'**
  String get backupNoRecovery;

  /// Button that makes a backup and saves it through the system's Save as dialog.
  ///
  /// In en, this message translates to:
  /// **'Save as'**
  String get backupSave;

  /// Button that makes a backup and shares it through the share sheet.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get backupShare;

  /// Shown after a backup was saved.
  ///
  /// In en, this message translates to:
  /// **'Saved {fileName}'**
  String backupSaved(String fileName);

  /// Shown when a backup could not be made, saved or shared.
  ///
  /// In en, this message translates to:
  /// **'The backup could not be made. Try again.'**
  String get backupExportFailed;

  /// Header of the backup screen's restore section.
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup'**
  String get backupRestoreSection;

  /// What a restore does, on the backup screen.
  ///
  /// In en, this message translates to:
  /// **'A backup can be restored only onto a device with no data yet, such as a new install: a device that already has data refuses it.'**
  String get backupRestoreExplanation;

  /// Button that starts restoring a backup.
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup'**
  String get backupRestoreButton;

  /// Title of the dialog asking for a backup's passphrase.
  ///
  /// In en, this message translates to:
  /// **'This backup\'s passphrase'**
  String get backupRestorePassphraseTitle;

  /// Button of the passphrase dialog that opens the backup.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get backupOpen;

  /// Progress label while a backup reads the database.
  ///
  /// In en, this message translates to:
  /// **'Reading your data'**
  String get backupStageReading;

  /// Progress label while the key is derived from the passphrase.
  ///
  /// In en, this message translates to:
  /// **'Securing with your passphrase'**
  String get backupStageDeriving;

  /// Progress label while a backup is encrypted.
  ///
  /// In en, this message translates to:
  /// **'Encrypting'**
  String get backupStageEncrypting;

  /// Progress label while a backup file is opened and checked.
  ///
  /// In en, this message translates to:
  /// **'Checking the backup'**
  String get backupStageChecking;

  /// Progress label while a backup is restored.
  ///
  /// In en, this message translates to:
  /// **'Restoring'**
  String get backupStageRestoring;

  /// Title of the dialog confirming a restore.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup?'**
  String get backupConfirmTitle;

  /// What the backup about to be restored holds.
  ///
  /// In en, this message translates to:
  /// **'Made {date} by version {version}: {records} records and {receipts} receipt photos.'**
  String backupConfirmBody(
    String date,
    String version,
    int records,
    int receipts,
  );

  /// Warning of the restore confirmation on the screen of a lost database key.
  ///
  /// In en, this message translates to:
  /// **'The data on this device that can no longer be opened will be deleted.'**
  String get backupConfirmLostKey;

  /// Button that confirms a restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupConfirmRestore;

  /// A picked file is not a backup.
  ///
  /// In en, this message translates to:
  /// **'This file is not a Finance Tracker backup.'**
  String get backupErrorNotABackup;

  /// A picked file is over the backup size cap, so it was not read.
  ///
  /// In en, this message translates to:
  /// **'This file is too large to be a Finance Tracker backup (over 512 MB).'**
  String get backupErrorTooLarge;

  /// A backup's format or schema is newer than this app's.
  ///
  /// In en, this message translates to:
  /// **'This backup was made by a newer version of Finance Tracker. Update the app, then restore it.'**
  String get backupErrorTooNew;

  /// A backup's header has a KDF or cost the app refuses.
  ///
  /// In en, this message translates to:
  /// **'This backup asks for settings this app does not accept, so it was not opened.'**
  String get backupErrorUnsafe;

  /// A backup's first frame does not open with the passphrase.
  ///
  /// In en, this message translates to:
  /// **'The passphrase is wrong, or the file is damaged.'**
  String get backupErrorWrongPassphrase;

  /// A backup's later frames or content do not check.
  ///
  /// In en, this message translates to:
  /// **'This backup is damaged or incomplete.'**
  String get backupErrorDamaged;

  /// A backup's user is not the signed-in one.
  ///
  /// In en, this message translates to:
  /// **'This backup belongs to another account.'**
  String get backupErrorOtherAccount;

  /// A restore onto an install that has data is refused.
  ///
  /// In en, this message translates to:
  /// **'This device already has data. Delete the app\'s data first, then restore.'**
  String get backupErrorHasData;

  /// The picked file could not be read.
  ///
  /// In en, this message translates to:
  /// **'The file could not be opened.'**
  String get backupErrorPick;

  /// Any other failure before a restore starts.
  ///
  /// In en, this message translates to:
  /// **'The backup could not be restored. Nothing was changed.'**
  String get backupErrorFailed;

  /// Headline of the screen shown while a restore runs.
  ///
  /// In en, this message translates to:
  /// **'Restoring your backup'**
  String get backupRestoringTitle;

  /// Headline of the restoring screen when the restore failed.
  ///
  /// In en, this message translates to:
  /// **'The backup could not be restored'**
  String get backupRestoreFailedTitle;

  /// Supporting text when a restore failed after it started.
  ///
  /// In en, this message translates to:
  /// **'Finance Tracker will start with the data this device holds now.'**
  String get backupRestoreFailedBody;

  /// Button that starts the app after a failed restore.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get backupContinue;

  /// Headline of the restore offer shown on a new install after sign-in.
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup?'**
  String get restoreOfferTitle;

  /// Supporting text of the restore offer.
  ///
  /// In en, this message translates to:
  /// **'If you have a Finance Tracker backup, you can restore it now, before this device fetches your data. Your bank data and synced changes come back from the server either way; a backup also brings receipt photos and what was kept only on your old device.'**
  String get restoreOfferBody;

  /// Button that declines the restore offer.
  ///
  /// In en, this message translates to:
  /// **'Start fresh'**
  String get restoreOfferStartFresh;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
