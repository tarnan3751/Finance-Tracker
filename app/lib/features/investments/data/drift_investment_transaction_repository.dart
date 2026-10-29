/// The [InvestmentTransactionRepository] of the dev and prod flavors, over the
/// `investment_transactions` table (`docs/reference/data.md`).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/investments/data/in_memory_investment_transaction_repository.dart'
    show checkInvestmentTransactionPage;
import 'package:finance_tracker/features/investments/domain/investment_transaction_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Investment transactions in [AppDatabase], stamped `pulled_at` from the clock; nothing
/// recorded.
final class DriftInvestmentTransactionRepository
    implements InvestmentTransactionRepository {
  /// The repository over [_database], stamping writes from [_clock].
  DriftInvestmentTransactionRepository(this._database, this._clock);

  final AppDatabase _database;
  final Clock _clock;

  @override
  Stream<List<InvestmentTransaction>> watchByAccount(String accountId) =>
      (_database.select(_database.investmentTransactions)
            ..where((t) => t.accountId.equals(accountId) & t.deletedAt.isNull())
            ..orderBy([
              (t) => OrderingTerm.desc(t.date),
              (t) => OrderingTerm.desc(t.id),
            ]))
          .watch()
          .map((rows) => rows.map(investmentTransactionFromRow).toList())
          .distinct(sameList);

  @override
  Future<void> applyPage(List<InvestmentTransaction> page) async {
    checkInvestmentTransactionPage(page);
    final DateTime now = _clock.nowUtc();
    await _database.batch(
      (batch) =>
          batch.insertAllOnConflictUpdate(_database.investmentTransactions, [
            for (final InvestmentTransaction t in page)
              InvestmentTransactionsCompanion.insert(
                id: t.id,
                accountId: t.accountId,
                securityId: Value(t.securityId),
                date: t.date,
                name: t.name,
                type: t.type,
                subtype: Value(t.subtype),
                quantity: t.quantity,
                price: t.price,
                amountMinor: t.amount.minorUnits,
                feesMinor: Value(minorUnitsIn(t.fees, t.amount.currencyCode)),
                currency: t.amount.currencyCode,
                deletedAt: Value(t.deletedAt),
                syncVersion: t.syncVersion,
                source: t.source,
                pulledAt: now,
              ),
          ]),
    );
  }
}

/// The [InvestmentTransaction] a row holds.
InvestmentTransaction investmentTransactionFromRow(
  InvestmentTransactionRow row,
) => InvestmentTransaction(
  id: row.id,
  accountId: row.accountId,
  securityId: row.securityId,
  date: row.date,
  name: row.name,
  type: row.type,
  subtype: row.subtype,
  quantity: row.quantity,
  price: row.price,
  amount: Money(row.amountMinor, row.currency),
  fees: moneyOrNull(row.feesMinor, row.currency),
  deletedAt: row.deletedAt,
  syncVersion: row.syncVersion,
  source: row.source,
);
