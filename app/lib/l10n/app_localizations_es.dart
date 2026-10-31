// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navAccounts => 'Cuentas';

  @override
  String get navTransactions => 'Movimientos';

  @override
  String get navPlan => 'Plan';

  @override
  String get planBudgets => 'Presupuestos';

  @override
  String get planBills => 'Facturas';

  @override
  String get planForecast => 'Previsión';

  @override
  String get navInsights => 'Análisis';

  @override
  String get insightsReports => 'Informes';

  @override
  String get insightsNetWorth => 'Patrimonio';

  @override
  String get insightsInvestments => 'Inversiones';

  @override
  String get insightsGoals => 'Metas';

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
  String get reportsShowTables => 'Tablas';

  @override
  String get reportsShowCharts => 'Gráficos';

  @override
  String get reportsSpending => 'Gastos';

  @override
  String get reportsIncome => 'Ingresos';

  @override
  String reportsSpendingAmount(String amount) {
    return 'Gastado: $amount';
  }

  @override
  String reportsIncomeAmount(String amount) {
    return 'Ingresos: $amount';
  }

  @override
  String reportsNetAmount(String amount) {
    return 'Neto: $amount';
  }

  @override
  String get reportsNoIncome => 'Sin ingresos en este periodo';

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
  String get reportsByCategory => 'Por categoría';

  @override
  String get reportsAllCategories => 'Todas las categorías';

  @override
  String reportsGroupOwn(String name) {
    return '$name itself';
  }

  @override
  String get reportsNothingInPeriod => 'Nada en este periodo.';

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
  String get reportsIncomeAndSpending => 'Ingresos y gastos';

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
  String get reportsTopMerchants => 'Comercios principales';

  @override
  String reportsMerchantCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count compras',
      one: '1 compra',
    );
    return '$_temp0';
  }

  @override
  String get reportsTopMovers => 'Mayores cambios';

  @override
  String get reportsMoversCategories => 'Categorías';

  @override
  String get reportsMoversMerchants => 'Comercios';

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
  String get reportsWeeklySummary => 'Resumen semanal';

  @override
  String get weeklyTitle => 'Resumen semanal';

  @override
  String weeklyRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String weeklyLastWeek(String range) {
    return 'Last week, $range';
  }

  @override
  String get weeklyThisWeek => 'Esta semana hasta hoy';

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
  String get weeklyBudgets => 'Presupuestos';

  @override
  String get weeklyNoBudgets => 'Aún no hay presupuestos.';

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
  String get navSettings => 'Ajustes';

  @override
  String get paneAccountsEmpty => 'Elige una cuenta para verla aquí';

  @override
  String get paneTransactionsEmpty => 'Elige un movimiento para verlo aquí';

  @override
  String get paneBillsEmpty => 'Elige una factura para editarla aquí';

  @override
  String get paneSettingsEmpty => 'Elige un ajuste para abrirlo aquí';

  @override
  String get accountsEmptyHeadline => 'Aún no hay cuentas';

  @override
  String get accountsEmptyBody =>
      'Las cuentas que añadas o conectes aparecerán aquí.';

  @override
  String get transactionsEmptyHeadline => 'Aún no hay movimientos';

  @override
  String get transactionsEmptyBody =>
      'Los movimientos que añadas o sincronices aparecerán aquí.';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsThemeMode => 'Tema';

  @override
  String get themeModeSystem => 'Sistema';

  @override
  String get themeModeLight => 'Claro';

  @override
  String get themeModeDark => 'Oscuro';

  @override
  String get settingsDynamicColor => 'Color dinámico';

  @override
  String get settingsDynamicColorSubtitle =>
      'Usar los colores del fondo de pantalla cuando el dispositivo los ofrezca';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSubtitle =>
      'Pseudo alarga cada texto y lo pone entre corchetes, para encontrar el que no cabría en una traducción';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePseudo => 'Pseudo';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get aboutAppName => 'Aplicación';

  @override
  String get aboutVersion => 'Versión';

  @override
  String aboutVersionValue(String version, String buildNumber) {
    return '$version (compilación $buildNumber)';
  }

  @override
  String get aboutFlavor => 'Flavor';

  @override
  String get aboutTimeZone => 'Zona horaria';

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
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get undo => 'Deshacer';

  @override
  String get loadFailed =>
      'Algo salió mal al cargar esto. Inténtalo de nuevo más tarde.';

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
  String get balanceFromTransactions => 'según los movimientos';

  @override
  String runningBalance(String amount) {
    return 'Running balance $amount';
  }

  @override
  String runningBalanceFromReported(String amount) {
    return 'Running balance $amount, from the reported balance';
  }

  @override
  String get balanceReported => 'informado';

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
  String get uncategorized => 'Sin categoría';

  @override
  String get accountAdd => 'Añadir cuenta';

  @override
  String get accountsTotals => 'Totales';

  @override
  String accountsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cuentas ocultas',
      one: '1 cuenta oculta',
    );
    return '$_temp0';
  }

  @override
  String get accountNotFound => 'This account no longer exists.';

  @override
  String get accountNoTransactions => 'Esta cuenta aún no tiene movimientos.';

  @override
  String get accountHide => 'Ocultar cuenta';

  @override
  String get accountShow => 'Mostrar cuenta';

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
  String get accountNewTitle => 'Cuenta nueva';

  @override
  String get accountEditTitle => 'Editar cuenta';

  @override
  String get accountName => 'Nombre';

  @override
  String get accountNameRequired => 'Enter a name';

  @override
  String get accountType => 'Tipo';

  @override
  String get accountTypeDepository => 'Corriente o de ahorro';

  @override
  String get accountTypeCredit => 'Tarjeta de crédito';

  @override
  String get accountTypeLoan => 'Préstamo';

  @override
  String get accountTypeInvestment => 'Inversión';

  @override
  String get accountTypeOther => 'Otra';

  @override
  String get accountCurrency => 'Moneda';

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
  String get transactionAdd => 'Añadir movimiento';

  @override
  String get transactionPending => 'Pendiente';

  @override
  String get dateToday => 'Hoy';

  @override
  String get dateYesterday => 'Ayer';

  @override
  String get transactionsSearch => 'Buscar';

  @override
  String get transactionsSearchHint => 'Buscar movimientos';

  @override
  String get transactionsSearchClose => 'Cerrar búsqueda';

  @override
  String get transactionsFilter => 'Filtros';

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
  String get filterClear => 'Borrar';

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
  String get filterApply => 'Aplicar';

  @override
  String get filterCategories => 'Categorías';

  @override
  String get filterAddCategory => 'Add category';

  @override
  String get filterDate => 'Fecha';

  @override
  String get filterAmount => 'Importe';

  @override
  String get filterAmountMin => 'At least';

  @override
  String get filterAmountMax => 'At most';

  @override
  String get filterTags => 'Etiquetas';

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
  String get transactionNewTitle => 'Movimiento nuevo';

  @override
  String get transactionTitle => 'Movimiento';

  @override
  String get transactionNotFound => 'This transaction no longer exists.';

  @override
  String get transactionNeedsAccountHeadline => 'Add an account first';

  @override
  String get transactionNeedsAccountBody =>
      'Every transaction belongs to an account.';

  @override
  String get transactionExpense => 'Gasto';

  @override
  String get transactionIncome => 'Ingreso';

  @override
  String get transactionAmount => 'Importe';

  @override
  String get transactionAccount => 'Cuenta';

  @override
  String get transactionDate => 'Fecha';

  @override
  String get transactionDescription => 'Descripción';

  @override
  String get transactionDescriptionRequired => 'Enter a description';

  @override
  String get transactionCategory => 'Categoría';

  @override
  String get transactionCategoryFromBank => 'From your bank\'s category';

  @override
  String get transactionNotes => 'Notas';

  @override
  String get transactionTags => 'Etiquetas';

  @override
  String get transactionTagsHelper =>
      'Press enter or type a comma to add a tag';

  @override
  String get transactionCurrencyMismatch =>
      'The amount must be in the account\'s currency.';

  @override
  String get transactionDeleted => 'Movimiento eliminado';

  @override
  String get transactionRestoreNoAccount =>
      'The transaction can\'t come back: its account was deleted.';

  @override
  String get settingsSecurity => 'Seguridad';

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
  String get lockUnlock => 'Desbloquear';

  @override
  String get lockTryAgain => 'Reintentar';

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
      other: '$minutes minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String get settingsData => 'Datos';

  @override
  String get categoriesTitle => 'Categorías';

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
  String get developerWorkerSection => 'Background worker';

  @override
  String get developerRunWorker => 'Run the background worker in 20 seconds';

  @override
  String get developerRunWorkerDetail =>
      'Kill the app before then to run the worker alone';

  @override
  String developerWorkerScheduled(String time) {
    return 'Scheduled to run after $time';
  }

  @override
  String developerWorkerFailed(String error) {
    return 'Not scheduled: $error';
  }

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
