/// The icon and the label of each `AccountType`, shared by the account list, the detail
/// and the editor's type chooser.
library;

import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

/// The icon of an account of [type].
IconData accountTypeIcon(AccountType type) => switch (type) {
  AccountType.depository => Icons.account_balance_outlined,
  AccountType.credit => Icons.credit_card_outlined,
  AccountType.loan => Icons.request_quote_outlined,
  AccountType.investment => Icons.trending_up,
  AccountType.other => Icons.account_balance_wallet_outlined,
};

/// The name of [type] as the user sees it.
String accountTypeLabel(AppLocalizations l10n, AccountType type) =>
    switch (type) {
      AccountType.depository => l10n.accountTypeDepository,
      AccountType.credit => l10n.accountTypeCredit,
      AccountType.loan => l10n.accountTypeLoan,
      AccountType.investment => l10n.accountTypeInvestment,
      AccountType.other => l10n.accountTypeOther,
    };
