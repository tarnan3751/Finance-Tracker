/// A [TransactionRepository] over an [InMemoryStore]: what tests use.
library;

import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_usage.dart';
import 'package:shared_models/shared_models.dart';

/// Transactions held in [store], shared with the store's account repository.
base class InMemoryTransactionRepository implements TransactionRepository {
  /// The repository over [store].
  InMemoryTransactionRepository(this.store);

  /// The state shared with the account and category repositories.
  final InMemoryStore store;

  @override
  Stream<List<Transaction>> watch(TransactionQuery query) =>
      store.watch(() => store.transactions(query), same: sameList);

  @override
  Stream<Transaction?> watchById(String id) =>
      store.watch(() => store.transaction(id));

  @override
  Future<void> upsert(Transaction transaction) async =>
      store.upsertTransaction(transaction);

  @override
  Future<void> delete(String id) async => store.deleteTransaction(id);

  @override
  Future<void> restore(String id) async => store.restoreTransaction(id);

  @override
  Future<int> count(TransactionQuery query) async => store.count(query);

  @override
  Stream<TransactionUsage> watchUsage({int recentLimit = 20}) {
    checkRecentLimit(recentLimit);
    return store.watch(() => store.usage(recentLimit));
  }
}
