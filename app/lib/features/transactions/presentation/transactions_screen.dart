/// The Transactions tab: every account's transactions, newest first, under date headers,
/// loaded fifty at a time as the list scrolls. Search from the app bar; filter by account,
/// category, date range, amount and tag in a bottom sheet, the active filters shown as
/// removable chips; tap a row to open it; "Add transaction".
library;

import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/transactions/application/transaction_filters.dart';
import 'package:finance_tracker/features/transactions/application/transactions_providers.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/features/transactions/domain/enrichment.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_dates.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_filter_sheet.dart';
import 'package:finance_tracker/features/transactions/presentation/transaction_tile.dart';
import 'package:finance_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

/// The list of transactions.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _search = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  TransactionListController get _controller =>
      ref.read(transactionListControllerProvider.notifier);

  void _closeSearch() {
    _search.clear();
    _controller.setText('');
    setState(() => _searching = false);
  }

  Future<void> _openFilters(TransactionFilters current) async {
    final TransactionFilters? chosen = await showTransactionFilterSheet(
      context,
      current,
    );
    if (chosen != null && mounted) _controller.setFilters(chosen);
  }

  // Loads the next page when the list is scrolled near its end.
  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.extentAfter < 600) {
      final AsyncValue<TransactionPage> page = ref.read(
        transactionPageProvider,
      );
      final TransactionPage? loaded = page.value;
      if (loaded != null && loaded.hasMore) {
        _controller.loadMore(loaded: loaded.transactions.length);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TransactionFilters filters = ref
        .watch(transactionListControllerProvider)
        .filters;
    final AsyncValue<TransactionPage> page = ref.watch(transactionPageProvider);
    final bool filtered = filters.hasFilters || filters.text.trim().isNotEmpty;
    final List<Transaction>? transactions = page.value?.transactions;
    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _search,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.transactionsSearchHint,
                  border: InputBorder.none,
                ),
                onChanged: _controller.setText,
              )
            : Text(l10n.navTransactions),
        actions: [
          if (_searching)
            IconButton(
              tooltip: l10n.transactionsSearchClose,
              icon: const Icon(Icons.close),
              onPressed: _closeSearch,
            )
          else
            IconButton(
              tooltip: l10n.transactionsSearch,
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _searching = true),
            ),
          IconButton(
            tooltip: l10n.transactionsFilter,
            icon: Badge(
              isLabelVisible: filters.hasFilters,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _openFilters(filters),
          ),
        ],
      ),
      floatingActionButton:
          transactions == null || transactions.isEmpty && !filtered
          ? null
          : FloatingActionButton.extended(
              onPressed: () => const NewTransactionRoute().push<void>(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.transactionAdd),
            ),
      body: Column(
        children: [
          if (filters.hasFilters) _ActiveFilters(filters),
          Expanded(
            child: switch (transactions) {
              null when page.hasError => Center(child: Text(l10n.loadFailed)),
              null => const Center(child: CircularProgressIndicator()),
              [] when filtered => EmptyState(
                icon: Icons.search_off,
                headline: l10n.transactionsNoMatchHeadline,
                body: l10n.transactionsNoMatchBody,
              ),
              [] => EmptyState(
                icon: Icons.receipt_long_outlined,
                headline: l10n.transactionsEmptyHeadline,
                body: l10n.transactionsEmptyBody,
                action: FilledButton.icon(
                  onPressed: () =>
                      const NewTransactionRoute().push<void>(context),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.transactionAdd),
                ),
              ),
              final List<Transaction> list =>
                NotificationListener<ScrollNotification>(
                  onNotification: _onScroll,
                  child: _TransactionList(
                    items: groupByDate(list),
                    hasMore: page.value!.hasMore,
                  ),
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends ConsumerWidget {
  const _TransactionList({required this.items, required this.hasMore});

  final List<TransactionListItem> items;
  final bool hasMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Map<String, Account> accounts = ref.watch(accountsByIdProvider);
    final CategoryLookup categories = ref.watch(
      transactionCategoryLookupProvider,
    );
    final LocalDate today = ref.watch(todayProvider);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: items.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        switch (items[index]) {
          case DateHeaderItem(:final LocalDate date):
            return _DateHeader(transactionDateLabel(l10n, date, today));
          case TransactionItem(:final Transaction transaction):
            final Category? category = effectiveCategory(
              transaction,
              categories,
            );
            return TransactionTile(
              key: ValueKey(transaction.id),
              merchant: EnrichedMerchant.resolve(transaction),
              caption: switch (accounts[transaction.accountId]) {
                // An account deleted or not yet synced: the category alone.
                null => category?.name ?? l10n.uncategorized,
                final Account account => l10n.captionPair(
                  account.name,
                  category?.name ?? l10n.uncategorized,
                ),
              },
              amount: transaction.amount,
              pending: transaction.pending,
              onTap: () => TransactionRoute(transaction.id).push<void>(context),
            );
        }
      },
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// The active filters as chips under the app bar, each removing its filter.
class _ActiveFilters extends ConsumerWidget {
  const _ActiveFilters(this.filters);

  final TransactionFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Map<String, Account> accounts = ref.watch(accountsByIdProvider);
    final Map<String, Category> categories = ref.watch(categoriesByIdProvider);
    final TransactionListController controller = ref.read(
      transactionListControllerProvider.notifier,
    );
    final List<Widget> chips = [
      for (final String id in filters.accountIds)
        _chip(
          l10n,
          accounts[id]?.name ?? l10n.accountNotFound,
          () => controller.setFilters(filters.withoutAccount(id)),
        ),
      for (final String id in filters.categoryIds)
        _chip(
          l10n,
          categories[id]?.name ?? l10n.uncategorized,
          () => controller.setFilters(filters.withoutCategory(id)),
        ),
      if (filters.date case final DateFilter date)
        _chip(
          l10n,
          dateFilterLabel(l10n, date),
          () => controller.setFilters(filters.withoutDate()),
        ),
      if (filters.minAmount != null || filters.maxAmount != null)
        _chip(
          l10n,
          amountFilterLabel(l10n, filters.minAmount, filters.maxAmount),
          () => controller.setFilters(filters.withoutAmount()),
        ),
      for (final String tag in filters.tags)
        _chip(
          l10n,
          l10n.tagLabel(tag),
          () => controller.setFilters(filters.withoutTag(tag)),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Wrap(spacing: 8, runSpacing: 4, children: chips),
      ),
    );
  }

  Widget _chip(AppLocalizations l10n, String label, VoidCallback onDeleted) =>
      InputChip(
        label: Text(label),
        onDeleted: onDeleted,
        deleteButtonTooltipMessage: l10n.filterRemove(label),
      );
}
