/// One account: its name, type and balance derived from its transactions, then its
/// transactions newest first, each with the running balance after it. Edit, hide or show,
/// delete (with its transactions, after a confirmation that counts them), and add a
/// transaction on this account.
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/core/widgets/amount_text.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/accounts/presentation/account_errors.dart';
import 'package:finance_tracker/features/accounts/presentation/account_type_style.dart';
import 'package:finance_tracker/features/categories/presentation/category_icons.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_tile.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

/// The detail of account [accountId].
class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<Account?> account = ref.watch(accountProvider(accountId));
    return switch (account) {
      AsyncValue(value: final Account account) => _Detail(account: account),
      AsyncValue(hasValue: true) || AsyncError() => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.accountNotFound)),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

enum _MenuAction { hide, show, delete }

class _Detail extends ConsumerWidget {
  const _Detail({required this.account});

  final Account account;

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    _MenuAction action,
  ) async {
    final AccountActions actions = ref.read(accountActionsProvider);
    switch (action) {
      case _MenuAction.hide || _MenuAction.show:
        await runAccountWrite(
          ScaffoldMessenger.of(context),
          AppLocalizations.of(context),
          () => actions.setHidden(account, hidden: action == _MenuAction.hide),
        );
      case _MenuAction.delete:
        final int count = await ref
            .read(transactionRepositoryProvider)
            .count(TransactionQuery(accountIds: {account.id}));
        if (!context.mounted) return;
        final bool confirmed = await _confirmDelete(context, count);
        if (!confirmed || !context.mounted) return;
        context.pop();
        await actions.delete(account.id);
    }
  }

  Future<bool> _confirmDelete(BuildContext context, int count) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.accountDeleteTitle(account.name)),
        content: Text(l10n.accountDeleteBody(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final List<LedgerEntry> ledger =
        ref.watch(accountLedgerProvider(account.id)).value ?? const [];
    final Money balance =
        ref.watch(derivedBalancesProvider).value?[account.id] ??
        Money.zero(account.currencyCode);
    final CategoryLookup categories = ref.watch(
      transactionCategoryLookupProvider,
    );
    final LocalDate today = ref.watch(todayProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => EditAccountRoute(account.id).push<void>(context),
          ),
          PopupMenuButton<_MenuAction>(
            onSelected: (action) => _onMenu(context, ref, action),
            itemBuilder: (context) => [
              if (account.isHidden)
                PopupMenuItem(
                  value: _MenuAction.show,
                  child: Text(l10n.accountShow),
                )
              else
                PopupMenuItem(
                  value: _MenuAction.hide,
                  child: Text(l10n.accountHide),
                ),
              PopupMenuItem(
                value: _MenuAction.delete,
                child: Text(l10n.delete),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            NewTransactionRoute(account: account.id).push<void>(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.transactionAdd),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: 1 + (ledger.isEmpty ? 1 : ledger.length),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _Header(account: account, balance: balance);
          }
          if (ledger.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.accountNoTransactions,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            );
          }
          final LedgerEntry entry = ledger[index - 1];
          final Transaction transaction = entry.transaction;
          final Category? category = effectiveCategory(transaction, categories);
          return TransactionTile(
            title: transaction.merchantName ?? transaction.name,
            caption: l10n.captionPair(
              transactionDateLabel(l10n, transaction.date, today),
              category?.name ?? l10n.uncategorized,
            ),
            amount: transaction.amount,
            icon: category == null
                ? fallbackCategoryIcon
                : categoryIconFor(category.icon),
            iconColor: category == null
                ? theme.colorScheme.outline
                : categoryColor(context, category.color),
            pending: transaction.pending,
            runningBalance: entry.balance,
            onTap: () => TransactionRoute(transaction.id).push<void>(context),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.account, required this.balance});

  final Account account;
  final Money balance;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final TextStyle? caption = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                accountTypeIcon(account.type),
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  account.isHidden
                      ? l10n.captionPair(
                          accountTypeLabel(l10n, account.type),
                          l10n.accountHiddenLabel,
                        )
                      : accountTypeLabel(l10n, account.type),
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AmountText(balance, style: theme.textTheme.headlineMedium),
          Text(l10n.balanceFromTransactions, style: caption),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              l10n.navTransactions,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
