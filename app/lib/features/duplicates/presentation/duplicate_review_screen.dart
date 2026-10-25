/// The duplicate review (`/transactions/duplicates`, from the transaction list's menu):
/// one card per likely duplicate pair, best first, each with both transactions (name,
/// account, date, amount; tapping one opens it), "Hide this one" under each, which sets
/// that transaction's hidden override as bulk edit does, and "Not duplicates", which
/// remembers the pair on this device; both with an undo. Nothing is merged or deleted
/// (`docs/reference/duplicates.md`).
library;

import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/duplicates/application/duplicates_providers.dart';
import 'package:finance_tracker/features/duplicates/domain/duplicate_detector.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/domain/enrichment.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_editor_screen.dart'
    show undoDuration;
import 'package:finance_tracker/features/transactions/presentation/transaction_tile.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// The review of the likely duplicates.
class DuplicateReviewScreen extends ConsumerWidget {
  const DuplicateReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<DuplicateCandidate>> candidates = ref.watch(
      duplicateCandidatesProvider,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.duplicatesTitle)),
      body: switch (candidates.value) {
        null when candidates.hasError => Center(child: Text(l10n.loadFailed)),
        null => const Center(child: CircularProgressIndicator()),
        [] => EmptyState(
          icon: Icons.done_all,
          headline: l10n.duplicatesEmptyHeadline,
          body: l10n.duplicatesEmptyBody,
        ),
        final List<DuplicateCandidate> pairs => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l10n.duplicatesIntro,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final DuplicateCandidate pair in pairs)
              _PairCard(key: ValueKey(pair.key), pair: pair),
          ],
        ),
      },
    );
  }
}

/// One pair: its two transactions and what can be done with them.
class _PairCard extends ConsumerWidget {
  const _PairCard({super.key, required this.pair});

  final DuplicateCandidate pair;

  Future<void> _dismiss(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final DuplicateActions actions = ref.read(duplicateActionsProvider);
    final PairKey key = pair.key;
    await actions.dismiss(key);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.duplicateDismissed),
        duration: undoDuration,
        persist: false,
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => actions.restore(key),
        ),
      ),
    );
  }

  // Hides [transaction] (one recorded batch, stamped now), with an undo that shows it.
  Future<void> _hide(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TransactionActions actions = ref.read(transactionActionsProvider);
    try {
      await actions.setHidden([transaction], true);
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.duplicateHideFailed)));
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.duplicateHidden),
        duration: undoDuration,
        persist: false,
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => actions.setHidden([transaction], false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final Map<String, Account> accounts = ref.watch(accountsByIdProvider);
    Widget side(Transaction t) {
      final EnrichedMerchant merchant = EnrichedMerchant.resolve(t);
      final String? account = accounts[t.accountId]?.name;
      final String date = fullDateLabel(t.date);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TransactionTile(
            merchant: merchant,
            caption: account == null ? date : l10n.captionPair(account, date),
            amount: t.amount,
            pending: t.pending,
            onTap: () => TransactionRoute(t.id).push<void>(context),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: TextButton(
                onPressed: () => _hide(context, ref, t),
                child: Text(
                  l10n.duplicateHide,
                  semanticsLabel: l10n.duplicateHideNamed(merchant.displayName),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                l10n.duplicatesDaysApart(pair.dayDistance),
                style: theme.textTheme.titleSmall,
              ),
            ),
            side(pair.first),
            const Divider(indent: 16, endIndent: 16),
            side(pair.second),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton(
                  onPressed: () => _dismiss(context, ref),
                  child: Text(l10n.duplicateNotDuplicates),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
