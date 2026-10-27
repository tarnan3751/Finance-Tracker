/// The liabilities of the user's linked accounts (`docs/reference/liabilities.md`).
///
/// Implementations: Drift (dev and prod), in memory (tests), demo (the demo flavor, with
/// the persona's liabilities); all pass
/// `test/contract/liability_repository_contract.dart`.
library;

import 'package:shared_models/shared_models.dart';

/// Reads the liabilities and replaces them with the server's. Server-authoritative:
/// nothing here is recorded for sync. Every stream starts with the current value and
/// emits again only when that value changes.
abstract interface class LiabilityRepository {
  /// Every liability, by account id, then kind (credit, mortgage, student).
  Stream<List<Liability>> watchAll();

  /// The liabilities of account [accountId], by kind.
  Stream<List<Liability>> watchByAccount(String accountId);

  /// Replaces every liability with [liabilities], the server's whole list, in one
  /// write. A liability that is not `plaid` or `demo`, or two of one account and kind,
  /// is an [ArgumentError], and one whose amounts are in two currencies a
  /// `CurrencyMismatchException`, before anything is written.
  Future<void> applyPlaid(List<Liability> liabilities);
}
