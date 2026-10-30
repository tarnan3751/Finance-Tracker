/// The transactions the app shows, filtered and paged by [TransactionQuery].
///
/// Implementations: Drift (dev and prod), in memory (tests), demo (the demo flavor); all
/// pass `test/contract/transaction_repository_contract.dart`.
library;

import 'package:finance_tracker/features/transactions/domain/transaction_query.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_usage.dart';
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
  /// Throws `AuditInstantError` (an [ArgumentError]) when `createdAt` or `updatedAt` is
  /// not a UTC instant with millisecond precision; `AccountNotFoundException` when its
  /// account does not exist or is deleted; `CurrencyMismatchException` when its amount or
  /// a split is in another currency than the account's; `EntityDeletedException` when
  /// the transaction is deleted.
  Future<void> upsert(Transaction transaction);

  /// Upserts every transaction of [batch] in one write, all or nothing: each goes through
  /// [upsert]'s checks and is recorded as [upsert] records it (one change-log entry per
  /// transaction that changes, none for one written unchanged), in list order. A `plaid`
  /// transaction may change only the fields the user owns (`userCategoryId`, `notes`,
  /// `tags`, `splits`, `receiptPath`, `receiptSha256`, `hidden`) and `updatedAt`, and
  /// must already be
  /// stored. An empty batch does nothing.
  ///
  /// Throws [ArgumentError] when an id is repeated, before anything is read; and
  /// `TransactionBatchException` naming the first transaction refused, with the failure
  /// [upsert] would have raised for it as the cause (or a `PlaidOverridesOnlyError`
  /// naming the Plaid field a `plaid` transaction changes); then nothing is written or
  /// recorded. Any other error propagates as itself.
  Future<void> upsertAll(List<Transaction> batch);

  /// Applies [page], a page of the server's Plaid-sourced transactions (`GET
  /// /transactions`), in one write that records nothing and skips the checks of a local
  /// edit: each transaction is stored as the server sent it, `source`, audit fields,
  /// `deletedAt` and `syncVersion` included, keeping the seven fields the user owns
  /// (`userCategoryId`, `notes`, `tags`, `splits`, `receiptPath`, `receiptSha256`,
  /// `hidden`) from a
  /// stored row. A
  /// tombstone for a transaction the device never had is skipped. Returns the
  /// transactions it inserted, live ones only, as stored.
  Future<List<Transaction>> applyPlaid(List<Transaction> page);

  /// Soft-deletes transaction [id], stamping its `updatedAt` from the clock. Does nothing
  /// when there is no such live transaction. Throws `BankDataNotDeletableException` for
  /// a `plaid` transaction: only the bank removes one.
  Future<void> delete(String id);

  /// Deletes every transaction of [ids] as [delete] does, in one write, all or nothing.
  /// Throws `TransactionBatchException` naming the first `plaid` transaction, with its
  /// `BankDataNotDeletableException` as the cause, and then deletes nothing.
  Future<void> deleteAll(List<String> ids);

  /// Restores deleted transaction [id], stamping its `updatedAt` from the clock. Throws
  /// `AccountNotFoundException` when its account is deleted (restore the account instead).
  /// Does nothing when it is not deleted.
  Future<void> restore(String id);

  /// The number of live transactions matching [query], ignoring its limit and offset.
  Future<int> count(TransactionQuery query);

  /// The live transactions with a `receiptPath` and no `receiptSha256` (photos attached
  /// before receipt hashes existed), from a query that reads only those rows: empty once
  /// every one has its hash.
  Future<List<Transaction>> unhashedReceipts();

  /// The distinct tags of the live transactions and their [recentLimit] most recently
  /// used categories and accounts ([TransactionUsage] documents the order), from queries
  /// that read only those columns. A [recentLimit] below 1 is an [ArgumentError].
  Stream<TransactionUsage> watchUsage({int recentLimit = 20});
}
