/// The Plaid pull's store over the local database (`core/plaid/plaid_pull.dart`): its
/// cursors in `sync_meta`, its writes in one database transaction, and the held sync
/// records of new rows materialized through the sync store, then those rows read back
/// for the arrival processor.
library;

import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/db/tables/sync_meta.dart';
import 'package:finance_tracker/core/plaid/plaid_pull.dart';
import 'package:finance_tracker/features/transactions/data/drift_transaction_repository.dart';
import 'package:shared_models/shared_models.dart';

/// The [PlaidPullStore] of the dev and prod flavors.
final class DriftPlaidPullStore implements PlaidPullStore {
  /// The store over [_database] and its [_syncStore].
  DriftPlaidPullStore(this._database, this._syncStore);

  final AppDatabase _database;
  final DriftSyncStore _syncStore;

  @override
  Future<T> transaction<T>(Future<T> Function() body) =>
      _database.transaction(body);

  @override
  Future<int?> transactionsSince() async {
    final String? value = await _syncStore.meta(
      SyncMetaKeys.plaidTransactionsSince,
    );
    return value == null ? null : int.parse(value);
  }

  @override
  Future<void> saveTransactionsSince(int since) =>
      _syncStore.saveMeta(SyncMetaKeys.plaidTransactionsSince, '$since');

  @override
  Future<int?> investmentTransactionsSince() async {
    final String? value = await _syncStore.meta(
      SyncMetaKeys.plaidInvestmentTransactionsSince,
    );
    return value == null ? null : int.parse(value);
  }

  @override
  Future<void> saveInvestmentTransactionsSince(int since) => _syncStore
      .saveMeta(SyncMetaKeys.plaidInvestmentTransactionsSince, '$since');

  @override
  Future<void> savePulledListsAt(DateTime at) async {
    await _syncStore.saveMeta(
      SyncMetaKeys.plaidAccountsPulledAt,
      '${at.millisecondsSinceEpoch}',
    );
    await _syncStore.saveMeta(
      SyncMetaKeys.plaidItemsPulledAt,
      '${at.millisecondsSinceEpoch}',
    );
  }

  @override
  Future<DateTime?> pulledAt() async {
    final String? value = await _syncStore.meta(SyncMetaKeys.plaidPulledAt);
    return value == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(int.parse(value), isUtc: true);
  }

  @override
  Future<void> savePulledAt(DateTime at) => _syncStore.saveMeta(
    SyncMetaKeys.plaidPulledAt,
    '${at.millisecondsSinceEpoch}',
  );

  @override
  Future<List<Transaction>> materializeHeld(List<Transaction> inserted) async {
    final List<String> ids = [for (final Transaction t in inserted) t.id];
    await _syncStore.materializeHeld(EntityType.transaction, ids);
    final Map<String, Transaction> stored = {};
    for (int start = 0; start < ids.length; start += 500) {
      final List<String> chunk = ids.sublist(
        start,
        start + 500 > ids.length ? ids.length : start + 500,
      );
      final List<TransactionRow> rows = await (_database.select(
        _database.transactions,
      )..where((t) => t.id.isIn(chunk))).get();
      for (final Transaction t in await transactionsWithChildren(
        _database,
        rows,
      )) {
        stored[t.id] = t;
      }
    }
    return [for (final String id in ids) stored[id]!];
  }
}
