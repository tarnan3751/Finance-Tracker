/// The transactions the app shows, filtered and paged by [TransactionQuery].
///
/// Implementations: Drift (dev and prod), in memory (tests), demo (the demo flavor); all
/// pass `test/contract/transaction_repository_contract.dart`.
library;

import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:shared_models/shared_models.dart';

/// Reads and writes transactions with their tags and splits. Every stream starts with the
/// current value and emits again only when that value changes.
///
/// A delete is soft: the transaction is hidden from every read and comes back with
/// [restore]. Writes to a deleted transaction throw `EntityDeletedException`
/// (`core/db/database_exceptions.dart`).
abstract interface class TransactionRepository {
  /// The live transactions matching [query], newest first: by date, then `createdAt`,
  /// then id, all descending; paged by the query's limit and offset.
  Stream<List<Transaction>> watch(TransactionQuery query);

  /// The live transaction [id], or null when there is none or it is deleted.
  Stream<Transaction?> watchById(String id);

  /// Inserts or replaces [transaction] with its tags and splits, in one write. Its audit
  /// fields are stored as given, except `deletedAt`, which only [delete] sets.
  ///
  /// Throws [ArgumentError] when `createdAt` or `updatedAt` is not a UTC instant with
  /// millisecond precision; `AccountNotFoundException` when its account does not exist or
  /// is deleted;
  /// `CurrencyMismatchException` when its amount or a split is in another currency than
  /// the account's; `EntityDeletedException` when the transaction is deleted.
  Future<void> upsert(Transaction transaction);

  /// Soft-deletes transaction [id], stamping its `updatedAt` from the clock. Does nothing
  /// when there is no such live transaction.
  Future<void> delete(String id);

  /// Restores deleted transaction [id], stamping its `updatedAt` from the clock. Throws
  /// `AccountNotFoundException` when its account is deleted (restore the account instead).
  /// Does nothing when it is not deleted.
  Future<void> restore(String id);

  /// The number of live transactions matching [query], ignoring its limit and offset.
  Future<int> count(TransactionQuery query);
}
