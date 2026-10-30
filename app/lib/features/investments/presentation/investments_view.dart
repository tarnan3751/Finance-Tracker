/// The Investments segment's body (`docs/reference/investments.md`, **The segment**): the
/// allocation of every holding by security type (a donut and its table per currency),
/// then each investment account in display order with its balance, its value over time
/// from install day (a chart or its table), its holdings, and its investment transactions
/// newest first, a page at a time; the empty state when there is no investment account.
/// No Scaffold of its own: the Insights tab mounts it under its app bar, and
/// `InvestmentsScreen` does for the tests.
library;

import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/investments/application/investments_providers.dart';
import 'package:finance_tracker/features/investments/domain/allocation.dart';
import 'package:finance_tracker/features/investments/domain/holding_repository.dart';
import 'package:finance_tracker/features/investments/presentation/allocation_chart.dart';
import 'package:finance_tracker/features/investments/presentation/investment_rows.dart';
import 'package:finance_tracker/features/investments/presentation/value_history.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_models/shared_models.dart';

/// How many investment transactions an account lists at first, and how many more each
/// "Show more" adds.
const int investmentTransactionsPage = 10;

/// The holdings, allocation, value and investment transactions of the investment
/// accounts.
class InvestmentsView extends ConsumerWidget {
  const InvestmentsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return switch ((
      ref.watch(investmentAccountsProvider),
      ref.watch(holdingsProvider),
      ref.watch(derivedBalancesProvider),
    )) {
      (
        AsyncValue(value: final List<Account> accounts?),
        AsyncValue(value: final List<HoldingView> holdings?),
        AsyncValue(value: final Map<String, Money?> derived?),
      ) =>
        accounts.isEmpty
            ? EmptyState(
                icon: Icons.trending_up,
                headline: l10n.investmentsEmptyHeadline,
                body: l10n.investmentsEmptyBody,
              )
            : _Accounts(accounts, holdings, derived),
      (AsyncValue(hasError: true), _, _) ||
      (_, AsyncValue(hasError: true), _) ||
      (
        _,
        _,
        AsyncValue(hasError: true),
      ) => Center(child: Text(l10n.loadFailed)),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _Accounts extends StatelessWidget {
  const _Accounts(this.accounts, this.holdings, this.derived);

  final List<Account> accounts;
  final List<HoldingView> holdings;
  final Map<String, Money?> derived;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Set<String> shown = {for (final Account a in accounts) a.id};
    final List<HoldingView> held = [
      for (final HoldingView v in holdings)
        if (shown.contains(v.holding.accountId)) v,
    ];
    final List<Allocation> allocations = allocationOf(held);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final Allocation allocation in allocations) ...[
          _Heading(
            allocations.length == 1
                ? l10n.investmentsAllocation
                : l10n.investmentsAllocationIn(allocation.total.currencyCode),
          ),
          AllocationDonut(allocation),
          AllocationTable(allocation),
        ],
        for (final Account account in accounts)
          _AccountSection(
            // Keyed by account, so its switch and page follow it, not its place.
            key: ValueKey(account.id),
            account: account,
            balance: shownBalance(account, derived),
            holdings: [
              for (final HoldingView v in held)
                if (v.holding.accountId == account.id) v,
            ],
          ),
      ],
    );
  }
}

/// A section's heading, announced as one.
class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Semantics(
          header: true,
          child: Text(text, style: Theme.of(context).textTheme.titleSmall),
        ),
        ?trailing,
      ],
    ),
  );
}

/// One investment account: its name and balance, its value over time, its holdings and
/// its investment transactions.
class _AccountSection extends ConsumerStatefulWidget {
  const _AccountSection({
    super.key,
    required this.account,
    required this.balance,
    required this.holdings,
  });

  final Account account;
  final ShownBalance balance;
  final List<HoldingView> holdings;

  @override
  ConsumerState<_AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends ConsumerState<_AccountSection> {
  bool _table = false;
  int _shown = investmentTransactionsPage;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final Account account = widget.account;
    final AsyncValue<List<BalanceSnapshot>> snapshots = ref.watch(
      investmentValueHistoryProvider(account.id),
    );
    final List<BalanceSnapshot> history = [
      for (final BalanceSnapshot s
          in snapshots.value ?? const <BalanceSnapshot>[])
        if (s.current.currencyCode == account.currencyCode) s,
    ];
    final AsyncValue<List<InvestmentTransaction>> transactionsValue = ref.watch(
      investmentTransactionsProvider(account.id),
    );
    final List<InvestmentTransaction> transactions =
        transactionsValue.value ?? const [];
    final String balance = widget.balance.amount.format();
    final String balanceCaption = widget.balance.reported
        ? l10n.balanceReported
        : l10n.balanceFromTransactions;
    final TextStyle? caption = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 32),
        Semantics(
          container: true,
          header: true,
          label: l10n.investmentsAccountSemantics(
            account.name,
            balance,
            balanceCaption,
          ),
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(account.name, style: theme.textTheme.titleMedium),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(balance, style: theme.textTheme.titleMedium),
                      Text(balanceCaption, style: caption),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        _Heading(
          l10n.investmentsValueTitle,
          trailing: history.isEmpty
              ? null
              : TextButton.icon(
                  onPressed: () => setState(() => _table = !_table),
                  icon: Icon(_table ? Icons.show_chart : Icons.table_rows),
                  label: Text(
                    _table
                        ? l10n.investmentsShowChart
                        : l10n.investmentsShowTable,
                  ),
                ),
        ),
        if (!snapshots.hasValue)
          _Pending(failed: snapshots.hasError)
        else if (history.isEmpty)
          _Note(l10n.investmentsValueNone)
        else ...[
          _Note(
            l10n.investmentsValueCaption(
              DateFormat.yMMMd().format(history.first.date.toDateTime()),
            ),
          ),
          if (_table)
            ValueHistoryTable(history)
          else
            ValueHistoryChart(history),
        ],
        _Heading(l10n.investmentsHoldings),
        if (widget.holdings.isEmpty)
          _Note(l10n.investmentsNoHoldings)
        else
          for (final HoldingView v in widget.holdings) ...[
            HoldingRow(v),
            const Divider(height: 1),
          ],
        _Heading(l10n.investmentsTransactions),
        if (!transactionsValue.hasValue)
          _Pending(failed: transactionsValue.hasError)
        else if (transactions.isEmpty)
          _Note(l10n.investmentsNoTransactions)
        else ...[
          for (final InvestmentTransaction t in transactions.take(_shown)) ...[
            InvestmentTransactionRow(t),
            const Divider(height: 1),
          ],
          if (transactions.length > _shown)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () =>
                      setState(() => _shown += investmentTransactionsPage),
                  child: Text(
                    l10n.investmentsShowMore(transactions.length - _shown),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// A list still loading (a progress indicator), or one that failed to load
/// (`loadFailed`).
class _Pending extends StatelessWidget {
  const _Pending({required this.failed});

  final bool failed;

  @override
  Widget build(BuildContext context) => failed
      ? _Note(AppLocalizations.of(context).loadFailed)
      : const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
}

/// A line of supporting text under a heading.
class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
