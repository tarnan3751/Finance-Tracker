/// What the transaction screens show: the list under its search and filters, paged fifty
/// at a time and grouped by date, and what the filter sheet and the category picker
/// suggest (tags, recently used categories and accounts).
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/transactions/application/transaction_filters.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_usage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';

part 'transactions_providers.g.dart';

/// How many transactions the list loads at a time.
const int transactionPageSize = 50;

/// The list's filters and how many pages of it are loaded.
typedef TransactionListState = ({TransactionFilters filters, int pages});

/// The transaction list's search, filters and paging. Any change to the filters goes back
/// to the first page.
@riverpod
class TransactionListController extends _$TransactionListController {
  @override
  TransactionListState build() => (filters: TransactionFilters.none, pages: 1);

  /// Replaces the filters with [filters].
  void setFilters(TransactionFilters filters) {
    if (filters != state.filters) state = (filters: filters, pages: 1);
  }

  /// Sets the search text to [text], keeping the other filters.
  void setText(String text) => setFilters(state.filters.withText(text));

  /// Loads one more page when the [loaded] transactions fill every page asked for so far.
  /// Until the next page arrives, [loaded] stays below that, so the many scroll events
  /// of one fling ask for one page.
  void loadMore({required int loaded}) {
    if (loaded < state.pages * transactionPageSize) return;
    state = (filters: state.filters, pages: state.pages + 1);
  }
}

/// The loaded transactions of the list and whether more match.
typedef TransactionPage = ({List<Transaction> transactions, bool hasMore});

/// The list's transactions under its filters, newest first, as many pages as are loaded.
/// A category filter takes the categories under each chosen one along; date presets are
/// resolved against [todayProvider], so they move at midnight.
@riverpod
Stream<TransactionPage> transactionPage(Ref ref) {
  final TransactionListState state = ref.watch(
    transactionListControllerProvider,
  );
  final LocalDate today = ref.watch(todayProvider);
  final List<Category> categories =
      ref.watch(categoriesProvider).value ?? const [];
  final int limit = state.pages * transactionPageSize;
  return ref
      .watch(transactionRepositoryProvider)
      .watch(
        state.filters.toQuery(
          today,
          limit: limit,
          childrenOf: (id) => [
            for (final Category c in categories)
              if (c.parentId == id) c.id,
          ],
        ),
      )
      .map(
        (transactions) =>
            (transactions: transactions, hasMore: transactions.length == limit),
      );
}

/// A row of the grouped transaction list.
sealed class TransactionListItem {
  const TransactionListItem();
}

/// The header above the transactions of [date].
final class DateHeaderItem extends TransactionListItem {
  const DateHeaderItem(this.date);

  final LocalDate date;
}

/// A transaction row.
final class TransactionItem extends TransactionListItem {
  const TransactionItem(this.transaction);

  final Transaction transaction;
}

/// [newestFirst] with a [DateHeaderItem] before the first transaction of each date.
List<TransactionListItem> groupByDate(List<Transaction> newestFirst) {
  final List<TransactionListItem> items = [];
  LocalDate? current;
  for (final Transaction transaction in newestFirst) {
    if (transaction.date != current) {
      current = transaction.date;
      items.add(DateHeaderItem(transaction.date));
    }
    items.add(TransactionItem(transaction));
  }
  return items;
}

/// What the editor and the filter sheet suggest, from the live transactions: the tags in
/// use and the most recently used categories and accounts
/// (`TransactionRepository.watchUsage`).
@riverpod
Stream<TransactionUsage> transactionUsage(Ref ref) =>
    ref.watch(transactionRepositoryProvider).watchUsage();
