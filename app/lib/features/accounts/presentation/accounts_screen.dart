/// The Accounts tab. Phase 1d replaces the empty state with the account list.
library;

import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The list of accounts; empty until Phase 1d.
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAccounts)),
      body: EmptyState(
        icon: Icons.account_balance_outlined,
        headline: l10n.accountsEmptyHeadline,
        body: l10n.accountsEmptyBody,
      ),
    );
  }
}
