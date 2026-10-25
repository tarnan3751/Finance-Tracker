/// The Transactions tab: every account's transactions, newest first, under date headers,
/// loaded fifty at a time as the list scrolls. Search from the app bar; filter by account,
/// category, date range, amount and tag, and show hidden transactions, in a bottom sheet,
/// the active filters shown as removable chips; tap a row to open it; "Add transaction".
/// Long-press a row to select it: the app bar then counts the selection and edits it in
/// bulk (set the category, add a tag, hide or unhide, delete when no row is the bank's),
/// each action one recorded batch with a snack bar of the count. Outside selection, the
/// menu opens the duplicate review, its badge counting the likely duplicate pairs.
library;

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/router/routes.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/core/widgets/empty_state.dart';
import 'package:finance_tracker/features/accounts/application/accounts_providers.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/categories/presentation/category_picker.dart';
import 'package:finance_tracker/features/duplicates/application/duplicates_providers.dart';
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

  // The selected transactions' ids in selection mode; null outside it.
  Set<String>? _selection;

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

  void _select(String id) => setState(() => _selection = {...?_selection, id});

  void _toggle(String id) => setState(() {
    final Set<String> next = {...?_selection};
    if (!next.remove(id)) next.add(id);
    _selection = next.isEmpty ? null : next;
  });

  void _endSelection() => setState(() => _selection = null);

  // Runs a bulk [action] on [selected], ends selection and reports the count it changed
  // with [done]; a refused batch changes nothing and says so.
  Future<void> _bulk(
    Future<int> Function(TransactionActions actions) action,
    String Function(int count) done,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TransactionActions actions = ref.read(transactionActionsProvider);
    _endSelection();
    try {
      final int count = await action(actions);
      messenger.showSnackBar(SnackBar(content: Text(done(count))));
    } on TransactionBatchException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.cause is EntityDeletedException
                ? l10n.bulkFailedDeleted
                : l10n.bulkFailed,
          ),
        ),
      );
    }
  }

  Future<void> _setCategory(List<Transaction> selected) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final CategoryChoice? choice = await showCategoryPicker(context);
    if (choice == null || !mounted) return;
    await _bulk(
      (a) => a.setCategory(selected, choice.categoryId),
      l10n.bulkCategorySet,
    );
  }

  Future<void> _addTag(List<Transaction> selected) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? tag = await showDialog<String>(
      context: context,
      builder: (context) => const _TagDialog(),
    );
    if (tag == null || !mounted) return;
    await _bulk((a) => a.addTag(selected, tag), l10n.bulkTagAdded);
  }

  Future<void> _delete(List<Transaction> selected) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final int count = selected.length;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.bulkDeleteTitle(count)),
        content: Text(l10n.bulkDeleteBody),
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
    if (confirmed != true || !mounted) return;
    await _bulk((a) async {
      await a.deleteAll([for (final Transaction t in selected) t.id]);
      return count;
    }, l10n.bulkDeleted);
  }

  // The app bar of selection mode over [selected], the selected rows in the list, and
  // [loaded], every row in it.
  AppBar _selectionBar(
    AppLocalizations l10n,
    List<Transaction> selected,
    List<Transaction> loaded,
  ) {
    final bool allHidden = selected.every((t) => t.hidden);
    final bool anyBank = selected.any((t) => t.source == DataSource.plaid);
    final bool none = selected.isEmpty;
    return AppBar(
      leading: IconButton(
        tooltip: l10n.selectionCancel,
        icon: const Icon(Icons.close),
        onPressed: _endSelection,
      ),
      // The count alone fits beside the actions; screen readers hear "N selected".
      title: Text(
        '${selected.length}',
        semanticsLabel: l10n.transactionsSelected(selected.length),
      ),
      actions: [
        IconButton(
          tooltip: l10n.bulkSetCategory,
          icon: const Icon(Icons.category_outlined),
          onPressed: none ? null : () => _setCategory(selected),
        ),
        IconButton(
          tooltip: l10n.bulkAddTag,
          icon: const Icon(Icons.sell_outlined),
          onPressed: none ? null : () => _addTag(selected),
        ),
        IconButton(
          tooltip: allHidden && !none ? l10n.bulkUnhide : l10n.bulkHide,
          icon: Icon(
            allHidden && !none
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: none
              ? null
              : () => _bulk(
                  (a) => a.setHidden(selected, !allHidden),
                  allHidden ? l10n.bulkUnhidden : l10n.bulkHidden,
                ),
        ),
        IconButton(
          // Only the bank removes a Plaid transaction.
          tooltip: l10n.delete,
          icon: const Icon(Icons.delete_outline),
          onPressed: none || anyBank ? null : () => _delete(selected),
        ),
        PopupMenuButton<void>(
          tooltip: l10n.transactionMoreOptions,
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: () => setState(
                () => _selection = {
                  ...?_selection,
                  for (final Transaction t in loaded) t.id,
                },
              ),
              child: Text(l10n.selectAll),
            ),
          ],
        ),
      ],
    );
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
    final int duplicates =
        ref.watch(duplicateCandidatesProvider).value?.length ?? 0;
    // Rows that left the list (hidden, deleted, filtered out) leave the selection.
    final Set<String>? selection = _selection;
    final List<Transaction>? selected = selection == null
        ? null
        : [
            for (final Transaction t in transactions ?? const <Transaction>[])
              if (selection.contains(t.id)) t,
          ];
    return PopScope(
      canPop: selection == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _endSelection();
      },
      child: Scaffold(
        appBar: selected != null
            ? _selectionBar(l10n, selected, transactions ?? const [])
            : AppBar(
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
                  PopupMenuButton<void>(
                    tooltip: l10n.transactionsMoreOptions(duplicates),
                    icon: Badge(
                      isLabelVisible: duplicates > 0,
                      label: Text(l10n.duplicatesBadge(duplicates)),
                      child: const Icon(Icons.more_vert),
                    ),
                    itemBuilder: (_) => [
                      PopupMenuItem<void>(
                        onTap: () =>
                            const DuplicatesRoute().push<void>(context),
                        child: Text(l10n.duplicatesMenuItem(duplicates)),
                      ),
                    ],
                  ),
                ],
              ),
        floatingActionButton:
            selection != null ||
                transactions == null ||
                transactions.isEmpty && !filtered
            ? null
            : FloatingActionButton.extended(
                onPressed: () =>
                    const NewTransactionRoute().push<void>(context),
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
                      selection: selected == null
                          ? null
                          : {for (final Transaction t in selected) t.id},
                      onSelect: _select,
                      onToggle: _toggle,
                    ),
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for the tag to add to the selection; pops with it, trimmed, or null.
class _TagDialog extends StatefulWidget {
  const _TagDialog();

  @override
  State<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<_TagDialog> {
  final TextEditingController _tag = TextEditingController();

  @override
  void dispose() {
    _tag.dispose();
    super.dispose();
  }

  void _submit() {
    final String tag = _tag.text.trim();
    if (tag.isNotEmpty) Navigator.of(context).pop(tag);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.bulkAddTag),
      content: TextField(
        controller: _tag,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.bulkTagLabel),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _tag.text.trim().isEmpty ? null : _submit,
          child: Text(l10n.bulkTagAdd),
        ),
      ],
    );
  }
}

class _TransactionList extends ConsumerWidget {
  const _TransactionList({
    required this.items,
    required this.hasMore,
    required this.selection,
    required this.onSelect,
    required this.onToggle,
  });

  final List<TransactionListItem> items;
  final bool hasMore;

  /// The selected ids in selection mode; null outside it.
  final Set<String>? selection;

  /// Enters selection mode with a row (a long press).
  final void Function(String id) onSelect;

  /// Selects or deselects a row in selection mode (a tap).
  final void Function(String id) onToggle;

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
              hidden: transaction.hidden,
              selected: selection?.contains(transaction.id),
              onTap: selection == null
                  ? () => TransactionRoute(transaction.id).push<void>(context)
                  : () => onToggle(transaction.id),
              onLongPress: selection == null
                  ? () => onSelect(transaction.id)
                  : null,
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
      if (filters.showHidden)
        _chip(
          l10n,
          l10n.filterIncludingHidden,
          () => controller.setFilters(filters.withoutHidden()),
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
