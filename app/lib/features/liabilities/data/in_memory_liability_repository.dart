/// A [LiabilityRepository] held in memory: what tests use, and the base of the demo
/// flavor's.
library;

import 'dart:async';

import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/features/liabilities/domain/liability_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Liabilities kept in memory for the life of the object; they depend on no other
/// repository, so they keep their own state.
base class InMemoryLiabilityRepository implements LiabilityRepository {
  /// A repository holding [initial], which [applyPlaid]'s rules hold to.
  InMemoryLiabilityRepository({List<Liability> initial = const []}) {
    checkLiabilityBatch(initial);
    _liabilities.addAll(initial);
  }

  final List<Liability> _liabilities = [];
  final StreamController<void> _changes = StreamController<void>.broadcast();

  List<Liability> _sorted(bool Function(Liability) test) =>
      [
        for (final Liability l in _liabilities)
          if (test(l)) l,
      ]..sort((a, b) {
        final int byAccount = compareBinary(a.accountId, b.accountId);
        return byAccount != 0 ? byAccount : a.kind.index - b.kind.index;
      });

  Stream<List<Liability>> _watch(bool Function(Liability) test) =>
      Stream<List<Liability>>.multi((controller) {
        controller.add(_sorted(test));
        final StreamSubscription<void> subscription = _changes.stream.listen(
          (_) => controller.add(_sorted(test)),
          onDone: controller.close,
        );
        controller.onCancel = subscription.cancel;
      }).distinct(sameList);

  @override
  Stream<List<Liability>> watchAll() => _watch((_) => true);

  @override
  Stream<List<Liability>> watchByAccount(String accountId) =>
      _watch((l) => l.accountId == accountId);

  @override
  Future<void> applyPlaid(List<Liability> liabilities) async {
    checkLiabilityBatch(liabilities);
    _liabilities
      ..clear()
      ..addAll(liabilities);
    _changes.add(null);
  }

  /// Ends every watcher's stream.
  Future<void> close() => _changes.close();
}

/// Throws when [liabilities] break [LiabilityRepository.applyPlaid]'s rules: a source
/// other than `plaid` or `demo`, or a repeated account and kind ([ArgumentError]), or
/// amounts in two currencies (`CurrencyMismatchException`).
void checkLiabilityBatch(List<Liability> liabilities) {
  final Set<(String, LiabilityKind)> keys = {};
  for (final Liability l in liabilities) {
    if (l.source != DataSource.plaid && l.source != DataSource.demo) {
      throw ArgumentError.value(l.source, 'source', 'liability ${l.accountId}');
    }
    if (!keys.add((l.accountId, l.kind))) {
      throw ArgumentError.value(l.accountId, 'accountId', 'two ${l.kind.name}');
    }
    liabilityCurrency(l);
  }
}

/// The currency of [liability]'s amounts, or null when it has none. Throws
/// `CurrencyMismatchException` when they are in two.
String? liabilityCurrency(Liability liability) {
  String? currency;
  for (final Money? m in [
    liability.minimumPaymentAmount,
    liability.lastStatementBalance,
    liability.lastPaymentAmount,
    liability.originationPrincipal,
    liability.nextMonthlyPayment,
    liability.ytdInterestPaid,
    liability.ytdPrincipalPaid,
    for (final LiabilityApr a in liability.aprs) a.balanceSubjectToApr,
  ]) {
    if (m == null) continue;
    currency ??= m.currencyCode;
    if (m.currencyCode != currency) {
      throw CurrencyMismatchException(currency, m.currencyCode);
    }
  }
  return currency;
}
