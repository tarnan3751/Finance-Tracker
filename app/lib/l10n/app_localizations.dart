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

  /// Label of the Budgets tab in the bottom navigation bar, and the title of the Budgets screen.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get navBudgets;

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

  /// Shown when a device's clock is more than an hour ahead, which holds changes back until real time catches up.
  ///
  /// In en, this message translates to:
  /// **'A device\'s clock is far ahead, so some changes wait until it catches up'**
  String get syncClockDrift;

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

  /// An action a newer version of the app added to this rule; kept but not applied.
  ///
  /// In en, this message translates to:
  /// **'Hide (not supported in this version)'**
  String get ruleActionHide;

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
