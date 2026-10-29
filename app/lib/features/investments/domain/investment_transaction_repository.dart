/// The investment transactions of the user's linked investment accounts
/// (`docs/reference/investments.md`).
///
/// Implementations: Drift (dev and prod), in memory (tests), demo (the demo flavor, with
/// the persona's brokerage); all pass
/// `test/contract/investment_transaction_repository_contract.dart`.
library;

import 'package:shared_models/shared_models.dart';

/// Reads the investment transactions and applies the server's pages of them.
/// Server-authoritative: nothing here is recorded for sync. Every stream starts with the
/// current value and emits again only when that value changes.
abstract interface class InvestmentTransactionRepository {
  /// The live investment transactions of account [accountId], newest date first, then id
  /// descending.
  Stream<List<InvestmentTransaction>> watchByAccount(String accountId);

  /// Stores [page], one page of the server's changes, in one write: each row replaces the
  /// stored row with its id, a row with `deletedAt` set is kept as a tombstone (and leaves
  /// the watched lists), and a later live row with that id brings it back. A row that is
  /// not `plaid` or `demo`, or two with one id, is an [ArgumentError], and a row whose
  /// fees are in another currency than its amount a `CurrencyMismatchException`, before
  /// anything is written.
  Future<void> applyPage(List<InvestmentTransaction> page);
}
