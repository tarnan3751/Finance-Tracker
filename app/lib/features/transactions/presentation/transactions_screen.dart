/// The Transactions tab. Phase 1d replaces the empty state with the transaction list.
library;

import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The list of transactions; empty until Phase 1d.
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTransactions)),
      body: EmptyState(
        icon: Icons.receipt_long_outlined,
        headline: l10n.transactionsEmptyHeadline,
        body: l10n.transactionsEmptyBody,
      ),
    );
  }
}
