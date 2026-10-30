/// A [TransactionRepository] over an [InMemoryStore]: what tests use.
library;

import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_usage.dart';
import 'package:shared_models/shared_models.dart';

/// Transactions held in [store], shared with the store's account repository. Every
/// write records the transaction through [recorder] after the store's synchronous write.
base class InMemoryTransactionRepository implements TransactionRepository {
  /// The repository over [store], recording through [recorder].
  InMemoryTransactionRepository(this.store, {required this.recorder});

  /// The state shared with the account and category repositories.
  final InMemoryStore store;

  /// Where the writes are recorded.
  final ChangeRecorder recorder;

  @override
  Stream<List<Transaction>> watch(TransactionQuery query) =>
      store.watch(() => store.transactions(query), same: sameList);

  @override
  Stream<Transaction?> watchById(String id) =>
      store.watch(() => store.transaction(id));

  @override
  Future<void> upsert(Transaction transaction) =>
      _recorded(transaction.id, () => store.upsertTransaction(transaction));

  @override
  Future<void> upsertAll(List<Transaction> batch) => _recordedAll([
    for (final Transaction t in batch) t.id,
  ], () => store.upsertTransactions(batch));

  @override
  Future<void> deleteAll(List<String> ids) =>
      _recordedAll(ids, () => store.deleteTransactions(ids));

  @override
  Future<List<Transaction>> applyPlaid(List<Transaction> page) async =>
      store.applyPlaidTransactions(page);

  @override
  Future<void> delete(String id) =>
      _recorded(id, () => store.deleteTransaction(id));

  @override
  Future<void> restore(String id) =>
      _recorded(id, () => store.restoreTransaction(id));

  // Runs [write] on transaction [id] and records the change it made.
  Future<void> _recorded(String id, void Function() write) async {
    final Map<String, Object?>? before = store.transactionRecord(id);
    write();
    await recordEach(
      recorder,
      EntityType.transaction,
      {id: ?before},
      {id: ?store.transactionRecord(id)},
    );
  }

  // Runs [write] on transactions [ids] and records the change it made to each, in order.
  Future<void> _recordedAll(List<String> ids, void Function() write) async {
    final Map<String, Map<String, Object?>> before = {
      for (final String id in ids) id: ?store.transactionRecord(id),
    };
    write();
    await recordEach(recorder, EntityType.transaction, before, {
      for (final String id in ids) id: ?store.transactionRecord(id),
    });
  }

  @override
  Future<int> count(TransactionQuery query) async => store.count(query);

  @override
  Future<List<Transaction>> unhashedReceipts() async => [
    for (final Transaction t in store.transactions(TransactionQuery.all))
      if (t.receiptPath != null && t.receiptSha256 == null) t,
  ];

  @override
  Stream<TransactionUsage> watchUsage({int recentLimit = 20}) {
    checkRecentLimit(recentLimit);
    return store.watch(() => store.usage(recentLimit));
  }
}
