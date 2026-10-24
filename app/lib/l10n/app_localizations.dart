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
