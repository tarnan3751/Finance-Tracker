/// An [InvestmentTransactionRepository] held in memory: what tests use, and the base of
/// the demo flavor's.
library;

import 'dart:async';

import 'package:finance_tracker/core/db/converters.dart' show minorUnitsIn;
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/features/investments/domain/investment_transaction_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Investment transactions kept in memory for the life of the object, by id; they
/// depend on no other repository, so they keep their own state.
base class InMemoryInvestmentTransactionRepository
    implements InvestmentTransactionRepository {
  /// A repository holding [initial], which [applyPage]'s rules hold to.
  InMemoryInvestmentTransactionRepository({
    List<InvestmentTransaction> initial = const [],
  }) {
    checkInvestmentTransactionPage(initial);
    for (final InvestmentTransaction t in initial) {
      _rows[t.id] = t;
    }
  }

  final Map<String, InvestmentTransaction> _rows = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  List<InvestmentTransaction> _live(String accountId) => [
    for (final InvestmentTransaction t in _rows.values)
      if (t.accountId == accountId && t.deletedAt == null) t,
  ]..sort(compareInvestmentTransactionsNewestFirst);

  @override
  Stream<List<InvestmentTransaction>> watchByAccount(String accountId) =>
      Stream<List<InvestmentTransaction>>.multi((controller) {
        controller.add(_live(accountId));
        final StreamSubscription<void> subscription = _changes.stream.listen(
          (_) => controller.add(_live(accountId)),
          onDone: controller.close,
        );
        controller.onCancel = subscription.cancel;
      }).distinct(sameList);

  @override
  Future<void> applyPage(List<InvestmentTransaction> page) async {
    checkInvestmentTransactionPage(page);
    for (final InvestmentTransaction t in page) {
      _rows[t.id] = t;
    }
    _changes.add(null);
  }

  /// Ends every watcher's stream.
  Future<void> close() => _changes.close();
}

/// [InvestmentTransactionRepository.watchByAccount]'s order: date, then id (in SQLite's
/// `BINARY` order), both descending.
int compareInvestmentTransactionsNewestFirst(
  InvestmentTransaction a,
  InvestmentTransaction b,
) {
  final int byDate = b.date.compareTo(a.date);
  return byDate != 0 ? byDate : compareBinary(b.id, a.id);
}

/// Throws when [page] breaks [InvestmentTransactionRepository.applyPage]'s rules: a
/// source other than `plaid` or `demo`, or a repeated id ([ArgumentError]), or fees in
/// another currency than the amount (`CurrencyMismatchException`).
void checkInvestmentTransactionPage(List<InvestmentTransaction> page) {
  for (final InvestmentTransaction t in page) {
    if (t.source != DataSource.plaid && t.source != DataSource.demo) {
      throw ArgumentError.value(t.source, 'source', 'investment ${t.id}');
    }
    minorUnitsIn(t.fees, t.amount.currencyCode);
  }
  checkDistinctIds([for (final InvestmentTransaction t in page) t.id]);
}
