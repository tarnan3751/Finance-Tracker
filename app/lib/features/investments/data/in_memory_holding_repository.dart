/// A [HoldingRepository] held in memory: what tests use, and the base of the demo
/// flavor's.
library;

import 'dart:async';

import 'package:finance_tracker/core/db/converters.dart' show minorUnitsIn;
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/features/investments/domain/holding_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Holdings and securities kept in memory for the life of the object; they depend on no
/// other repository, so they keep their own state.
base class InMemoryHoldingRepository implements HoldingRepository {
  /// A repository holding [holdings] and [securities], which [applyPlaid]'s rules hold
  /// to.
  InMemoryHoldingRepository({
    List<Holding> holdings = const [],
    List<Security> securities = const [],
  }) {
    checkHoldingBatch(holdings, securities);
    _holdings.addAll(holdings);
    _securities.addAll(securities);
  }

  final List<Holding> _holdings = [];
  final List<Security> _securities = [];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  List<HoldingView> _views(bool Function(Holding) test) {
    final Map<String, Security> byId = {
      for (final Security s in _securities) s.id: s,
    };
    return [
      for (final Holding h in _holdings)
        if (test(h)) (holding: h, security: byId[h.securityId]),
    ]..sort(compareHoldingViews);
  }

  Stream<List<HoldingView>> _watch(bool Function(Holding) test) =>
      Stream<List<HoldingView>>.multi((controller) {
        controller.add(_views(test));
        final StreamSubscription<void> subscription = _changes.stream.listen(
          (_) => controller.add(_views(test)),
          onDone: controller.close,
        );
        controller.onCancel = subscription.cancel;
      }).distinct(sameList);

  @override
  Stream<List<HoldingView>> watchAll() => _watch((_) => true);

  @override
  Stream<List<HoldingView>> watchByAccount(String accountId) =>
      _watch((h) => h.accountId == accountId);

  @override
  Future<void> applyPlaid(
    List<Holding> holdings,
    List<Security> securities,
  ) async {
    checkHoldingBatch(holdings, securities);
    _holdings
      ..clear()
      ..addAll(holdings);
    _securities
      ..clear()
      ..addAll(securities);
    _changes.add(null);
  }

  /// Ends every watcher's stream.
  Future<void> close() => _changes.close();
}

/// [HoldingRepository.watchAll]'s order: account id, then the security's name (its
/// ticker, else the security id, when it has none) ignoring ASCII case, then security id.
int compareHoldingViews(HoldingView a, HoldingView b) {
  final int byAccount = compareBinary(a.holding.accountId, b.holding.accountId);
  if (byAccount != 0) return byAccount;
  String label(HoldingView v) =>
      v.security?.name ?? v.security?.tickerSymbol ?? v.holding.securityId;
  final int byName = compareNoCase(label(a), label(b));
  return byName != 0
      ? byName
      : compareBinary(a.holding.securityId, b.holding.securityId);
}

/// Throws when [holdings] and [securities] break [HoldingRepository.applyPlaid]'s rules:
/// a source other than `plaid` or `demo`, a repeated account and security, or a repeated
/// security id ([ArgumentError]), or a holding's value and cost basis in two currencies
/// (`CurrencyMismatchException`).
void checkHoldingBatch(List<Holding> holdings, List<Security> securities) {
  void provenance(DataSource source, String what) {
    if (source != DataSource.plaid && source != DataSource.demo) {
      throw ArgumentError.value(source, 'source', what);
    }
  }

  final Set<(String, String)> keys = {};
  for (final Holding h in holdings) {
    provenance(h.source, 'holding ${h.securityId} of ${h.accountId}');
    if (!keys.add((h.accountId, h.securityId))) {
      throw ArgumentError.value(h.securityId, 'securityId', 'held twice');
    }
    minorUnitsIn(h.costBasis, h.institutionValue.currencyCode);
  }
  final Set<String> ids = {};
  for (final Security s in securities) {
    provenance(s.source, 'security ${s.id}');
    if (!ids.add(s.id)) {
      throw ArgumentError.value(s.id, 'id', 'listed twice');
    }
  }
}
