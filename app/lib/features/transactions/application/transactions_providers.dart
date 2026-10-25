/// What the transaction screens show and do: the list under its search and filters, paged
/// fifty at a time and grouped by date; the lookup that gives each transaction its
/// effective category; what the editor and the filter sheet suggest (tags, recently used
/// categories and accounts); and the writes of the editor and of bulk edit.
library;

import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/core/util/stream_current.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/transactions/application/transaction_filters.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_usage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:uuid/uuid.dart';

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

/// The live categories by id and by Plaid code, from which the screens take each
/// transaction's effective category (`effectiveCategory`): its user category, else the
/// system category of its Plaid code.
@riverpod
CategoryLookup transactionCategoryLookup(Ref ref) =>
    categoryLookup(ref.watch(categoriesProvider).value ?? const []);

/// The list's transactions under its filters, newest first, as many pages as are loaded.
/// A category filter takes the categories under each chosen one along and matches the
/// effective category, through the Plaid codes of the categories included; date presets
/// are resolved against [todayProvider], so they move at midnight.
@riverpod
Stream<TransactionPage> transactionPage(Ref ref) {
  final TransactionListState state = ref.watch(
    transactionListControllerProvider,
  );
  final LocalDate today = ref.watch(todayProvider);
  final List<Category> categories =
      ref.watch(categoriesProvider).value ?? const [];
  final Map<String, Category> byId = ref
      .watch(transactionCategoryLookupProvider)
      .byId;
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
          plaidCodeOf: (id) => byId[id]?.plaidCategory,
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

/// The live transaction [id], or null when it does not exist or is deleted.
@riverpod
Stream<Transaction?> transaction(Ref ref, String id) =>
    ref.watch(transactionRepositoryProvider).watchById(id);

/// What the editor and the filter sheet suggest, from the live transactions: the tags in
/// use and the most recently used categories and accounts
/// (`TransactionRepository.watchUsage`).
@riverpod
Stream<TransactionUsage> transactionUsage(Ref ref) =>
    ref.watch(transactionRepositoryProvider).watchUsage();

/// The writes of the transaction editor and of bulk edit.
@riverpod
TransactionActions transactionActions(Ref ref) => TransactionActions(
  ref.watch(transactionRepositoryProvider),
  ref.watch(clockProvider),
  syncStore: ref.watch(recordingSyncStoreProvider),
);

/// What the editor enters: everything a user sets on a transaction.
typedef TransactionDraft = ({
  String accountId,
  Money amount,
  LocalDate date,
  String name,
  String? categoryId,
  String? notes,
  List<String> tags,
  bool hidden,
});

/// Creates, edits, deletes and restores transactions, one at a time or in bulk. The
/// repository's typed exceptions (`AccountNotFoundException`, `CurrencyMismatchException`,
/// `EntityDeletedException`, and for the bulk writes `TransactionBatchException`) reach
/// the caller, which explains them.
final class TransactionActions {
  TransactionActions(this._transactions, this._clock, {this._syncStore});

  final TransactionRepository _transactions;
  final Clock _clock;

  // The store the writes are recorded into, whose transaction is the database's in dev
  // and prod; null in the demo, which records nothing.
  final SyncStore? _syncStore;

  // Runs [body] in one store transaction, so a sync pull cannot land between a bulk
  // action's reads and its write; directly when there is no store.
  Future<T> _inTransaction<T>(Future<T> Function() body) {
    final SyncStore? store = _syncStore;
    return store == null ? body() : store.transaction(body);
  }

  static const Uuid _uuid = Uuid();

  /// Creates a `manual` transaction from [draft] and returns its id.
  Future<String> create(TransactionDraft draft) async {
    final DateTime now = _clock.nowUtc();
    final String id = _uuid.v4();
    await _transactions.upsert(
      Transaction(
        id: id,
        accountId: draft.accountId,
        amount: draft.amount,
        date: draft.date,
        pending: false,
        name: draft.name,
        userCategoryId: draft.categoryId,
        notes: draft.notes,
        tags: draft.tags,
        hidden: draft.hidden,
        source: DataSource.manual,
        createdAt: now,
        updatedAt: now,
        syncVersion: 0,
      ),
    );
    return id;
  }

  /// Saves [draft] over [existing]. Everything the editor does not show (the source, the
  /// merchant name, the splits, the Plaid fields, `createdAt`) is kept as it was.
  Future<void> update(Transaction existing, TransactionDraft draft) =>
      _transactions.upsert(
        existing.copyWith(
          accountId: draft.accountId,
          amount: draft.amount,
          date: draft.date,
          name: draft.name,
          userCategoryId: draft.categoryId,
          notes: draft.notes,
          tags: draft.tags,
          hidden: draft.hidden,
          updatedAt: _clock.nowUtc(),
        ),
      );

  /// Deletes transaction [id]; [restore] brings it back.
  Future<void> delete(String id) => _transactions.delete(id);

  /// Restores deleted transaction [id] (the undo of [delete]).
  Future<void> restore(String id) => _transactions.restore(id);

  /// Sets the user category of [selected] to [categoryId] (null clears it). Returns how
  /// many changed.
  Future<int> setCategory(List<Transaction> selected, String? categoryId) =>
      _bulk(selected, (t) => t.copyWith(userCategoryId: categoryId));

  /// Adds [tag] to those of [selected] that do not carry it. Returns how many changed.
  Future<int> addTag(List<Transaction> selected, String tag) => _bulk(
    selected,
    (t) => t.tags.contains(tag) ? t : t.copyWith(tags: [...t.tags, tag]),
  );

  /// Hides [selected], or unhides them when [hidden] is false. Returns how many changed.
  Future<int> setHidden(List<Transaction> selected, bool hidden) =>
      _bulk(selected, (t) => t.copyWith(hidden: hidden));

  /// Deletes [ids] in one write, all or none (none of them may be `plaid`).
  Future<void> deleteAll(List<String> ids) =>
      _inTransaction(() => _transactions.deleteAll(ids));

  // Applies [change] to each of [selected] as the repository holds it now (an edit
  // synced since the list last showed it is kept; a row deleted since is skipped) and
  // writes the rows it changes in one recorded batch, stamped now; returns how many.
  // The reads and the write share one transaction, so nothing synced in between is
  // written back.
  Future<int> _bulk(
    List<Transaction> selected,
    Transaction Function(Transaction) change,
  ) => _inTransaction(() async {
    final List<Transaction> changed = [];
    for (final Transaction t in selected) {
      final Transaction? current = await currentValue(
        _transactions.watchById(t.id),
      );
      if (current == null) continue;
      final Transaction next = change(current);
      if (next != current) changed.add(next);
    }
    final DateTime now = _clock.nowUtc();
    await _transactions.upsertAll([
      for (final Transaction t in changed) t.copyWith(updatedAt: now),
    ]);
    return changed.length;
  });
}
