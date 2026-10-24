/// The schema 2 backfill: the user-authored rows of a schema 1 database enter the change
/// log, so data made before sync existed syncs like any other (`docs/reference/data.md`,
/// **Schema 2**).
///
/// Pure Dart, no Flutter import: the migration runs it, and the schema dump runs the
/// database file in the Dart VM.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/tables/record_clocks.dart';
import 'package:finance_tracker/core/db/tables/sync_meta.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/features/accounts/data/drift_account_repository.dart';
import 'package:finance_tracker/features/categories/data/drift_category_repository.dart';
import 'package:finance_tracker/features/settings/data/drift_settings_repository.dart';
import 'package:finance_tracker/features/transactions/data/drift_transaction_repository.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

/// Records every user-authored row of [database] as a `create` entry, each at a fresh
/// clock of node [nodeId] stamped at [wallMillis], with field clocks for every field; a
/// row already soft-deleted also gets a `delete` entry, and its `deleted_at` becomes that
/// entry's instant, as merging the entries anywhere gives. Saves the node and the clock.
///
/// User-authored: accounts with no Item, user categories, transactions whose source is
/// `manual` or `import`, and the settings when any are stored. In a fixed order: accounts,
/// categories, transactions (each by id), settings.
Future<void> backfillChangeLog(
  AppDatabase database, {
  required String nodeId,
  required int Function() wallMillis,
}) async {
  final HlcClock clock = HlcClock(nodeId);

  // Appends the entries that take a new record to [live] (and then to [deleted]), writes
  // its clocks, and returns the record.
  Future<EntityRecord> backfill(
    EntityType type,
    String id,
    Map<String, Object?> live, [
    Map<String, Object?>? deleted,
  ]) async {
    EntityRecord? record;
    for (final (Map<String, Object?>? before, Map<String, Object?> after) in [
      (null, live),
      if (deleted != null) (live, deleted),
    ]) {
      final ChangeLogEntry entry = diff(
        type,
        id,
        before,
        after,
        clock.send(wallMillis()),
      )!;
      record = merge(record, entry).record;
      await database
          .into(database.changeLog)
          .insert(
            ChangeLogCompanion.insert(
              entityType: snakeName(type),
              entityId: id,
              operation: snakeName(entry.operation),
              payload: jsonEncode(entry.payload),
              hlc: entry.hlc.pack(),
              deviceId: entry.deviceId,
            ),
          );
    }
    await database.batch(
      (batch) => batch.insertAll(database.recordClocks, [
        for (final MapEntry<String, Hlc> e in record!.fieldClocks.entries)
          RecordClocksCompanion.insert(
            entityType: snakeName(type),
            entityId: id,
            field: e.key,
            hlc: e.value.pack(),
          ),
        RecordClocksCompanion.insert(
          entityType: snakeName(type),
          entityId: id,
          field: createClockField,
          hlc: record.createdAt!.pack(),
        ),
      ]),
    );
    return record!;
  }

  for (final AccountRow row
      in await (database.select(database.accounts)
            ..where((a) => a.itemId.isNull())
            ..orderBy([(a) => OrderingTerm.asc(a.id)]))
          .get()) {
    final Account account = accountFromRow(row);
    final DateTime? deletedAt = row.deletedAt;
    final EntityRecord record = await backfill(
      EntityType.account,
      row.id,
      accountRecordJson(account),
      deletedAt == null
          ? null
          : accountRecordJson(account, deletedAt: deletedAt),
    );
    if (deletedAt != null) {
      await (database.update(
        database.accounts,
      )..where((a) => a.id.equals(row.id))).write(
        AccountsCompanion(deletedAt: Value(deletedAtOf(record.fields))),
      );
    }
  }

  for (final CategoryRow row
      in await (database.select(database.categories)
            ..where((c) => c.isSystem.equals(false))
            ..orderBy([(c) => OrderingTerm.asc(c.id)]))
          .get()) {
    final Category category = categoryFromRow(row);
    final DateTime? deletedAt = row.deletedAt;
    final EntityRecord record = await backfill(
      EntityType.category,
      row.id,
      categoryRecordJson(category),
      deletedAt == null
          ? null
          : categoryRecordJson(category, deletedAt: deletedAt),
    );
    if (deletedAt != null) {
      await (database.update(
        database.categories,
      )..where((c) => c.id.equals(row.id))).write(
        CategoriesCompanion(deletedAt: Value(deletedAtOf(record.fields))),
      );
    }
  }

  final List<TransactionRow> rows =
      await (database.select(database.transactions)
            ..where(
              (t) =>
                  t.source.isInValues([DataSource.manual, DataSource.import]),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();
  final List<Transaction> transactions = await transactionsWithChildren(
    database,
    rows,
  );
  for (int i = 0; i < rows.length; i++) {
    final TransactionRow row = rows[i];
    final Transaction transaction = transactions[i];
    final EntityRecord record = await backfill(
      EntityType.transaction,
      row.id,
      transactionRecordJson(transaction.copyWith(deletedAt: null)),
      row.deletedAt == null
          ? null
          : transactionRecordJson(
              transaction,
              deletedWithAccount: row.deletedWithAccount,
            ),
    );
    if (row.deletedAt != null) {
      await (database.update(
        database.transactions,
      )..where((t) => t.id.equals(row.id))).write(
        TransactionsCompanion(deletedAt: Value(deletedAtOf(record.fields))),
      );
    }
  }

  final List<AppSettingRow> settings = await database
      .select(database.appSettings)
      .get();
  if (settings.isNotEmpty) {
    await backfill(
      EntityType.settings,
      settingsRecordId,
      settingsRecordJson(settingsFromRows(settings)),
    );
  }

  await database.batch(
    (batch) => batch.insertAllOnConflictUpdate(database.syncMeta, [
      SyncMetaCompanion.insert(key: SyncMetaKeys.deviceId, value: nodeId),
      SyncMetaCompanion.insert(
        key: SyncMetaKeys.lastClock,
        value: clock.last.pack(),
      ),
    ]),
  );
}
