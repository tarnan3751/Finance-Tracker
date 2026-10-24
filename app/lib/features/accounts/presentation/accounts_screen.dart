/// The Accounts tab: one card per visible account with its balance derived from its
/// transactions (labelled so), a total per currency when the accounts hold more than one
/// (never converted, `PLAN.md` §3), the hidden accounts in a collapsed section, reordering
/// by long-press, and "Add account".
library;

import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/widgets/amount_text.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/accounts/presentation/account_errors.dart';
import 'package:finance_tracker/features/accounts/presentation/account_type_style.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// The list of accounts.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<Account>> accounts = ref.watch(accountsProvider);
    final Map<String, Money?> balances =
        ref.watch(derivedBalancesProvider).value ?? const {};
    final bool hasAccounts = accounts.value?.isNotEmpty ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAccounts)),
      floatingActionButton: hasAccounts
          ? FloatingActionButton.extended(
              onPressed: () => const NewAccountRoute().push<void>(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.accountAdd),
            )
          : null,
      body: switch (accounts) {
        AsyncValue(value: final List<Account> list) when list.isEmpty =>
          EmptyState(
            icon: Icons.account_balance_outlined,
            headline: l10n.accountsEmptyHeadline,
            body: l10n.accountsEmptyBody,
            action: FilledButton.icon(
              onPressed: () => const NewAccountRoute().push<void>(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.accountAdd),
            ),
          ),
        AsyncValue(value: final List<Account> list) => _AccountList(
          accounts: list,
          balances: balances,
        ),
        AsyncError() => Center(child: Text(l10n.loadFailed)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _AccountList extends ConsumerStatefulWidget {
  const _AccountList({required this.accounts, required this.balances});

  final List<Account> accounts;
  final Map<String, Money?> balances;

  @override
  ConsumerState<_AccountList> createState() => _AccountListState();
}

class _AccountListState extends ConsumerState<_AccountList> {
  // The visible accounts in the order on screen: changed at once on a drop, so the list
  // does not jump back while the new order is written, and replaced by the repository's
  // order whenever it emits.
  late List<Account> _visible = _visibleOf(widget.accounts);

  static List<Account> _visibleOf(List<Account> accounts) => [
    for (final Account a in accounts)
      if (!a.isHidden) a,
  ];

  @override
  void didUpdateWidget(_AccountList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accounts != widget.accounts) {
      _visible = _visibleOf(widget.accounts);
    }
  }

  Money _balanceOf(Account account) =>
      widget.balances[account.id] ?? Money.zero(account.currencyCode);

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    final List<Account> order = [..._visible];
    order.insert(newIndex, order.removeAt(oldIndex));
    setState(() => _visible = order);
    final AccountActions actions = ref.read(accountActionsProvider);
    final bool written = await runAccountWrite(
      ScaffoldMessenger.of(context),
      AppLocalizations.of(context),
      () => actions.reorder(order),
    );
    // A refused write: back to the order the repository holds.
    if (!written && mounted) {
      setState(() => _visible = _visibleOf(widget.accounts));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<Account> hidden = [
      for (final Account a in widget.accounts)
        if (a.isHidden) a,
    ];
    final Map<String, Money> totals = {};
    for (final Account account in _visible) {
      final Money balance = _balanceOf(account);
      totals[account.currencyCode] =
          (totals[account.currencyCode] ?? Money.zero(account.currencyCode)) +
          balance;
    }
    return ReorderableListView.builder(
      // Room under the last card for the floating button.
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
      header: totals.length > 1 ? _Totals(totals.values.toList()) : null,
      footer: hidden.isEmpty
          ? null
          : ExpansionTile(
              title: Text(l10n.accountsHidden(hidden.length)),
              children: [
                for (final Account account in hidden)
                  _AccountCard(account: account, balance: _balanceOf(account)),
              ],
            ),
      itemCount: _visible.length,
      onReorderItem: _onReorder,
      itemBuilder: (context, index) {
        final Account account = _visible[index];
        return _AccountCard(
          key: ValueKey(account.id),
          account: account,
          balance: _balanceOf(account),
        );
      },
    );
  }
}

/// One total per currency, each the sum of the visible accounts' derived balances.
class _Totals extends StatelessWidget {
  const _Totals(this.totals);

  final List<Money> totals;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.accountsTotals,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 24,
            runSpacing: 4,
            children: [
              for (final Money total in totals)
                AmountText(total, style: theme.textTheme.titleMedium),
            ],
          ),
          Text(
            l10n.balanceFromTransactions,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({super.key, required this.account, required this.balance});

  final Account account;
  final Money balance;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final TextStyle? caption = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final Widget balanceColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AmountText(balance, style: theme.textTheme.titleMedium),
        Text(l10n.balanceFromTransactions, style: caption),
      ],
    );
    // With large text the balance goes under the name, where it has the full width.
    final bool stacked = MediaQuery.textScalerOf(context).scale(1) > 1.5;
    return Card(
      child: MergeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => AccountDetailRoute(account.id).push<void>(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  accountTypeIcon(account.type),
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.name, style: theme.textTheme.titleMedium),
                      Text(
                        accountTypeLabel(l10n, account.type),
                        style: caption,
                      ),
                      if (stacked)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: balanceColumn,
                        ),
                    ],
                  ),
                ),
                if (!stacked) ...[const SizedBox(width: 12), balanceColumn],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
