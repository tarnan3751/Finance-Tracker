/// The holdings of the user's linked investment accounts and the securities they hold
/// (`docs/reference/investments.md`).
///
/// Implementations: Drift (dev and prod), in memory (tests), demo (the demo flavor, with
/// the persona's brokerage); all pass `test/contract/holding_repository_contract.dart`.
library;

import 'package:shared_models/shared_models.dart';

/// A holding with the security it is in, null when the server did not list that
/// security.
typedef HoldingView = ({Holding holding, Security? security});

/// Reads the holdings and replaces them, with their securities, by the server's.
/// Server-authoritative: nothing here is recorded for sync. Every stream starts with the
/// current value and emits again only when that value changes.
abstract interface class HoldingRepository {
  /// Every holding with its security, by account id, then the security's name (its
  /// ticker, else its id, when it has none) ignoring ASCII case, then security id.
  Stream<List<HoldingView>> watchAll();

  /// The holdings of account [accountId], in [watchAll]'s order.
  Stream<List<HoldingView>> watchByAccount(String accountId);

  /// Replaces every holding with [holdings] and every security with [securities], the
  /// server's whole lists, in one write. A holding or security that is not `plaid` or
  /// `demo`, two holdings of one account and security, or two securities with one id, is
  /// an [ArgumentError], and a holding whose value and cost basis are in two currencies
  /// a `CurrencyMismatchException`, before anything is written.
  Future<void> applyPlaid(List<Holding> holdings, List<Security> securities);
}
