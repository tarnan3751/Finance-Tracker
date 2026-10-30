/// What the transaction screens show and do: the list under its search and filters, paged
/// fifty at a time and grouped by date; the lookup that gives each transaction its
/// effective category; what the editor and the filter sheet suggest (tags, recently used
/// categories and accounts); the saved filters and the one the list's filters are; a
/// receipt's photo; and the writes of the editor, of bulk edit (receipts included) and of
/// the saved filters.
library;

import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:finance_tracker/core/api/api_providers.dart';
import 'package:finance_tracker/core/db/receipt_store.dart';
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/core/time/today_provider.dart';
import 'package:finance_tracker/core/util/stream_current.dart';
import 'package:finance_tracker/features/categories/application/categories_providers.dart';
import 'package:finance_tracker/features/transactions/application/transaction_filters.dart';
import 'package:finance_tracker/features/transactions/domain/effective_category.dart';
import 'package:finance_tracker/features/transactions/domain/saved_filter.dart';
import 'package:finance_tracker/features/transactions/domain/saved_filter_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_usage.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:uuid/uuid.dart';

part 'transactions_providers.g.dart';

final Logger _log = Logger('transactions');

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

/// A saved filter with the filters it holds.
typedef DecodedSavedFilter = ({SavedFilter saved, TransactionFilters filters});

/// The saved filters, in their order, with their filters decoded. One whose JSON does not
/// decode (`TransactionFilters.fromJson`) is left out and logged by type, so it can never
/// take the list or the sheet down.
@riverpod
Stream<List<DecodedSavedFilter>> savedFilters(Ref ref) => ref
    .watch(savedFilterRepositoryProvider)
    .watchAll()
    .map(
      (all) => [
        for (final SavedFilter saved in all)
          if (_decoded(saved) case final TransactionFilters filters)
            (saved: saved, filters: filters),
      ],
    );

TransactionFilters? _decoded(SavedFilter saved) {
  try {
    return TransactionFilters.fromJson(saved.filters);
  } on FormatException catch (e) {
    _log.warning('a saved filter does not decode (${e.runtimeType}); skipped');
    return null;
  }
}

/// The saved filter the list's filters are, or null: the first, in order, whose filters
/// equal them. Derived, so renaming shows at once and any change of the filters drops it.
@riverpod
SavedFilter? appliedSavedFilter(Ref ref) {
  final TransactionFilters current = ref
      .watch(transactionListControllerProvider)
      .filters;
  if (current == TransactionFilters.none) return null;
  for (final DecodedSavedFilter f
      in ref.watch(savedFiltersProvider).value ??
          const <DecodedSavedFilter>[]) {
    if (f.filters == current) return f.saved;
  }
  return null;
}

/// The writes of the filter sheet's saved filters.
@riverpod
SavedFilterActions savedFilterActions(Ref ref) =>
    SavedFilterActions(ref.watch(savedFilterRepositoryProvider));

/// Saves, renames and deletes saved filters; names are trimmed.
final class SavedFilterActions {
  SavedFilterActions(this._repository);

  final SavedFilterRepository _repository;

  /// Saves [filters] under [name].
  Future<SavedFilter> save(String name, TransactionFilters filters) =>
      _repository.save(name.trim(), filters.toJson());

  /// Renames saved filter [id] to [name].
  Future<void> rename(String id, String name) =>
      _repository.rename(id, name.trim());

  /// Deletes saved filter [id].
  Future<void> delete(String id) => _repository.delete(id);
}

/// The receipt photo of transaction [transactionId] as this device has it: the file
/// when [sha256] is null or its bytes hash to it, else null (no file, or another photo's,
/// one replaced elsewhere). No fetch: the editor shows it at once, and the Conflicts
/// screen asks it whether a photo is still here.
@riverpod
Future<Uint8List?> localReceipt(
  Ref ref,
  String transactionId,
  String? sha256,
) async {
  final Uint8List? local = await ref
      .watch(receiptStoreProvider)
      .read(receiptPathFor(transactionId));
  if (sha256 == null || local == null) return local;
  return receiptHash(local) == sha256 ? local : null;
}

/// The receipt photo of transaction [transactionId], whose bytes hash to [sha256]
/// (`docs/reference/transactions.md`, **Receipts**): the file on this device when it is
/// that photo; else, when the hash is known, fetched from the server on this first view,
/// checked against the hash and stored under the usual path, so the next view is local.
/// Null when there is no file and no hash (a receipt attached on another device before
/// hashes existed, not hashed there yet). A failed fetch is an error (`NotFound` while
/// the photo has not reached the server); invalidating retries.
@riverpod
Future<Uint8List?> receipt(
  Ref ref,
  String transactionId,
  String? sha256,
) async {
  final ReceiptStore store = ref.watch(receiptStoreProvider);
  final Uint8List? local = await store.read(receiptPathFor(transactionId));
  if (sha256 == null) return local;
  if (local != null && receiptHash(local) == sha256) return local;
  final Uint8List fetched = await ref
      .read(financeApiProvider)
      .getReceipt(sha256);
  if (receiptHash(fetched) != sha256) throw const ReceiptHashMismatch();
  await store.commit(await store.stage(transactionId, fetched));
  // The file changed: whatever showed it (another photo's check on the Conflicts screen
  // included) reads it again.
  ref.invalidate(localReceiptProvider);
  return fetched;
}

/// The SHA-256 of receipt photo [bytes], lower-case hex: its `receiptSha256`.
String receiptHash(List<int> bytes) => crypto.sha256.convert(bytes).toString();

/// A fetched receipt photo whose bytes do not hash to the transaction's `receiptSha256`.
final class ReceiptHashMismatch implements Exception {
  const ReceiptHashMismatch();

  @override
  String toString() => 'ReceiptHashMismatch';
}

/// The writes of the transaction editor and of bulk edit.
@riverpod
TransactionActions transactionActions(Ref ref) => TransactionActions(
  ref.watch(transactionRepositoryProvider),
  ref.watch(receiptStoreProvider),
  ref.watch(clockProvider),
  syncStore: ref.watch(recordingSyncStoreProvider),
);

/// What the editor does to a transaction's receipt.
sealed class ReceiptChange {
  const ReceiptChange();
}

/// The receipt stays as it is (none, or the one it has).
final class KeepReceipt extends ReceiptChange {
  const KeepReceipt();
}

/// [bytes] become the receipt, a new one or in place of the one it has.
final class AttachReceipt extends ReceiptChange {
  const AttachReceipt(this.bytes);

  final Uint8List bytes;
}

/// The receipt is removed.
final class RemoveReceipt extends ReceiptChange {
  const RemoveReceipt();
}

/// What the editor enters: everything a user sets on a transaction. [splits] are signed
/// like [amount] and sum to it; with splits, [categoryId] is null, the splits being the
/// transaction's categorization.
typedef TransactionDraft = ({
  String accountId,
  Money amount,
  LocalDate date,
  String name,
  String? categoryId,
  String? notes,
  List<String> tags,
  List<TransactionSplit> splits,
  bool hidden,
  ReceiptChange receipt,
});

/// Creates, edits, deletes and restores transactions, one at a time or in bulk, with
/// their receipt photos. The repository's typed exceptions (`AccountNotFoundException`,
/// `CurrencyMismatchException`, `EntityDeletedException`, and for the bulk writes
/// `TransactionBatchException`) reach the caller, which explains them, as does a
/// `FileSystemException` from staging a photo.
///
/// A new photo is staged, the transaction written, and the photo committed over the old
/// one only then; a failed write discards it, so the receipt stays as it was. A removed
/// receipt's file goes after the write. The repositories hold no files: a deleted
/// transaction's photo goes when its delete is final ([discardReceiptOf], after the
/// undo is no longer offered; [deleteAll], which has no undo, at once), and
/// [sweepReceipts] removes whatever else no live transaction references.
final class TransactionActions {
  TransactionActions(
    this._transactions,
    this._receipts,
    this._clock, {
    this._syncStore,
  });

  final TransactionRepository _transactions;
  final ReceiptStore _receipts;
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

  /// Creates a `manual` transaction from [draft] and returns it.
  Future<Transaction> create(TransactionDraft draft) async {
    final DateTime now = _clock.nowUtc();
    final String id = _uuid.v4();
    final Transaction created = Transaction(
      id: id,
      accountId: draft.accountId,
      amount: draft.amount,
      date: draft.date,
      pending: false,
      name: draft.name,
      userCategoryId: draft.categoryId,
      notes: draft.notes,
      tags: draft.tags,
      splits: draft.splits,
      receiptPath: draft.receipt is AttachReceipt ? receiptPathFor(id) : null,
      receiptSha256: switch (draft.receipt) {
        AttachReceipt(:final Uint8List bytes) => receiptHash(bytes),
        _ => null,
      },
      hidden: draft.hidden,
      source: DataSource.manual,
      createdAt: now,
      updatedAt: now,
      syncVersion: 0,
    );
    await _withReceipt(id, draft.receipt, () => _transactions.upsert(created));
    return created;
  }

  /// Saves [draft] over [existing] and returns the saved transaction. Everything the
  /// editor does not show (the source, the merchant name, the Plaid fields, `createdAt`)
  /// is kept as it was.
  Future<Transaction> update(
    Transaction existing,
    TransactionDraft draft,
  ) async {
    final ReceiptChange receipt = draft.receipt;
    final Transaction updated = existing.copyWith(
      accountId: draft.accountId,
      amount: draft.amount,
      date: draft.date,
      name: draft.name,
      userCategoryId: draft.categoryId,
      notes: draft.notes,
      tags: draft.tags,
      splits: draft.splits,
      receiptPath: switch (receipt) {
        KeepReceipt() => existing.receiptPath,
        AttachReceipt() => receiptPathFor(existing.id),
        RemoveReceipt() => null,
      },
      receiptSha256: switch (receipt) {
        KeepReceipt() => existing.receiptSha256,
        AttachReceipt(:final Uint8List bytes) => receiptHash(bytes),
        RemoveReceipt() => null,
      },
      hidden: draft.hidden,
      updatedAt: _clock.nowUtc(),
    );
    await _withReceipt(
      existing.id,
      receipt,
      () => _transactions.upsert(updated),
    );
    final String? removed = existing.receiptPath;
    if (receipt is RemoveReceipt && removed != null) await _deleteFile(removed);
    return updated;
  }

  // Runs [write], the transaction [id]'s write, with [receipt]'s photo staged before it
  // and committed only once it has succeeded.
  Future<void> _withReceipt(
    String id,
    ReceiptChange receipt,
    Future<void> Function() write,
  ) async {
    if (receipt is! AttachReceipt) return write();
    final StagedReceipt staged = await _receipts.stage(id, receipt.bytes);
    try {
      await write();
    } catch (_) {
      await _receipts.discard(staged);
      rethrow;
    }
    await _receipts.commit(staged);
  }

  /// Deletes the receipt photo of deleted transaction [id], once its delete is final.
  Future<void> discardReceiptOf(String id) => _deleteFile(receiptPathFor(id));

  /// Gives each live transaction with a receipt photo on this device but no
  /// `receiptSha256` (attached before hashes existed) the hash of its file, as a recorded
  /// change, so the photo is uploaded and other devices can fetch it. The rest of the
  /// row is kept as it is, `updatedAt` included. A photo whose file is not here (it was
  /// attached on another device) is left for that device. Runs once per launch after the
  /// first frame (`bootstrap.dart`): one query for the rows with a path and no hash
  /// (`TransactionRepository.unhashedReceipts`), which finds nothing once every row has
  /// one, and a file read for each it finds. Returns how many it filled.
  Future<int> fillReceiptHashes() async {
    int filled = 0;
    for (final Transaction t in await _transactions.unhashedReceipts()) {
      final String path = t.receiptPath!;
      final Uint8List? bytes = await _receipts.read(path);
      if (bytes == null) continue;
      final bool wrote = await _inTransaction(() async {
        final Transaction? current = await currentValue(
          _transactions.watchById(t.id),
        );
        if (current == null ||
            current.receiptPath != path ||
            current.receiptSha256 != null) {
          return false;
        }
        await _transactions.upsert(
          current.copyWith(receiptSha256: receiptHash(bytes)),
        );
        return true;
      });
      if (wrote) filled++;
    }
    return filled;
  }

  /// Deletes the receipt files no live transaction references (a delete final while the
  /// app was not watching: killed during an undo, synced from another device, an account's
  /// delete, a pending transaction its posted one replaced). Files written since it began
  /// stay. Returns how many it deleted.
  Future<int> sweepReceipts() async {
    final DateTime started = DateTime.now();
    final List<Transaction> live = await currentValue(
      _transactions.watch(TransactionQuery.all),
    );
    return _receipts.sweep({
      for (final Transaction t in live)
        if (t.receiptPath case final String path) path,
    }, olderThan: started);
  }

  // Deletes the photo at [path]; a failure is logged by type only and left to the sweep,
  // since the transaction's write has already happened.
  Future<void> _deleteFile(String path) async {
    try {
      await _receipts.delete(path);
    } on Exception catch (e) {
      _log.warning('a receipt file was not deleted: ${e.runtimeType}');
    }
  }

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

  /// Deletes [ids] in one write, all or none (none of them may be `plaid`), then their
  /// receipt photos, since a bulk delete has no undo.
  Future<void> deleteAll(List<String> ids) async {
    await _inTransaction(() => _transactions.deleteAll(ids));
    for (final String id in ids) {
      await discardReceiptOf(id);
    }
  }

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
