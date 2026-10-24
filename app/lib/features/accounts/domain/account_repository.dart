/// The accounts the app shows, and their balances derived from transactions.
///
/// Implementations: Drift (dev and prod), in memory (tests), demo (the demo flavor); all
/// pass `test/contract/account_repository_contract.dart`.
library;

import 'package:shared_models/shared_models.dart';

/// Reads and writes accounts. Every stream starts with the current value and emits again
/// only when that value changes.
///
/// A delete is soft: the account and its transactions are hidden from every read and come
/// back with [restore]. Writes to a deleted account throw `EntityDeletedException`
/// (`core/db/database_exceptions.dart`).
abstract interface class AccountRepository {
  /// The live accounts: visible ones first, then hidden ones, each by `displayOrder`, then
  /// by id.
  Stream<List<Account>> watchAll();

  /// The live account [id], or null when there is none or it is deleted.
  Stream<Account?> watchById(String id);

  /// Inserts or replaces [account].
  ///
  /// Throws `CurrencyMismatchException` when a balance is in another currency than
  /// `account.currencyCode`, or when the currency of an account that has transactions
  /// would change; `EntityDeletedException` when the account is deleted.
  Future<void> upsert(Account account);

  /// Writes [account] as [upsert] does and, when given, its [openingBalance] transaction
  /// as `TransactionRepository.upsert` does, in one write: both are stored or neither.
  /// Throws what either throws, and [ArgumentError] when [openingBalance] is on another
  /// account.
  Future<void> create(Account account, {Transaction? openingBalance});

  /// Soft-deletes account [id] and, with it, its live transactions (stamping their
  /// `updatedAt`). Does nothing when there is no such live account.
  Future<void> delete(String id);

  /// Restores deleted account [id] and exactly the transactions its delete removed
  /// (stamping their `updatedAt`); transactions deleted on their own stay deleted. Does
  /// nothing when the account is not deleted.
  Future<void> restore(String id);

  /// The sum of the live transactions of account [id] in its currency; null when the
  /// account has none, or does not exist, or is deleted. Pending transactions count.
  Stream<Money?> watchDerivedBalance(String id);

  /// [watchDerivedBalance] for every live account, keyed by account id.
  Stream<Map<String, Money?>> watchDerivedBalances();
}
