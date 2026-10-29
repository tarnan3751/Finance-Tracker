/// The [HoldingRepository] of the dev and prod flavors, over the `holdings` and
/// `securities` tables (`docs/reference/data.md`).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/investments/data/in_memory_holding_repository.dart'
    show checkHoldingBatch, compareHoldingViews;
import 'package:finance_tracker/features/investments/domain/holding_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Holdings and securities in [AppDatabase], stamped `pulled_at` from the clock; nothing
/// recorded.
final class DriftHoldingRepository implements HoldingRepository {
  /// The repository over [_database], stamping writes from [_clock].
  DriftHoldingRepository(this._database, this._clock);

  final AppDatabase _database;
  final Clock _clock;

  Stream<List<HoldingView>> _watch(
    Expression<bool> Function($HoldingsTable) w,
  ) {
    final $HoldingsTable holdings = _database.holdings;
    final $SecuritiesTable securities = _database.securities;
    return (_database.select(holdings)..where(w))
        .join([
          leftOuterJoin(
            securities,
            securities.id.equalsExp(holdings.securityId),
          ),
        ])
        .watch()
        .map(
          (rows) => [
            for (final TypedResult row in rows)
              (
                holding: holdingFromRow(row.readTable(holdings)),
                security: switch (row.readTableOrNull(securities)) {
                  null => null,
                  final SecurityRow s => securityFromRow(s),
                },
              ),
          ]..sort(compareHoldingViews),
        )
        .distinct(sameList);
  }

  @override
  Stream<List<HoldingView>> watchAll() => _watch((_) => const Constant(true));

  @override
  Stream<List<HoldingView>> watchByAccount(String accountId) =>
      _watch((h) => h.accountId.equals(accountId));

  @override
  Future<void> applyPlaid(
    List<Holding> holdings,
    List<Security> securities,
  ) async {
    checkHoldingBatch(holdings, securities);
    final DateTime now = _clock.nowUtc();
    await _database.transaction(() async {
      await _database.delete(_database.holdings).go();
      await _database.delete(_database.securities).go();
      await _database.batch((batch) {
        batch
          ..insertAll(_database.securities, [
            for (final Security s in securities)
              SecuritiesCompanion.insert(
                id: s.id,
                name: Value(s.name),
                tickerSymbol: Value(s.tickerSymbol),
                type: Value(s.type),
                isCashEquivalent: Value(s.isCashEquivalent),
                closePrice: Value(s.closePrice),
                closePriceAsOf: Value(s.closePriceAsOf),
                currencyCode: s.currencyCode,
                source: s.source,
                pulledAt: now,
              ),
          ])
          ..insertAll(_database.holdings, [
            for (final Holding h in holdings)
              HoldingsCompanion.insert(
                accountId: h.accountId,
                securityId: h.securityId,
                quantity: h.quantity,
                institutionPrice: h.institutionPrice,
                institutionPriceAsOf: Value(h.institutionPriceAsOf),
                institutionValueMinor: h.institutionValue.minorUnits,
                costBasisMinor: Value(
                  minorUnitsIn(h.costBasis, h.institutionValue.currencyCode),
                ),
                currency: h.institutionValue.currencyCode,
                source: h.source,
                pulledAt: now,
              ),
          ]);
      });
    });
  }
}

/// The [Holding] a row holds.
Holding holdingFromRow(HoldingRow row) => Holding(
  accountId: row.accountId,
  securityId: row.securityId,
  quantity: row.quantity,
  institutionPrice: row.institutionPrice,
  institutionPriceAsOf: row.institutionPriceAsOf,
  institutionValue: Money(row.institutionValueMinor, row.currency),
  costBasis: moneyOrNull(row.costBasisMinor, row.currency),
  source: row.source,
);

/// The [Security] a row holds.
Security securityFromRow(SecurityRow row) => Security(
  id: row.id,
  name: row.name,
  tickerSymbol: row.tickerSymbol,
  type: row.type,
  isCashEquivalent: row.isCashEquivalent,
  closePrice: row.closePrice,
  closePriceAsOf: row.closePriceAsOf,
  currencyCode: row.currencyCode,
  source: row.source,
);
