/// The sync engine's store over the local database (`docs/reference/sync-app.md`, **The
/// store**): the outbox in `change_log`, the field clocks in `record_clocks`, the cursor,
/// clock and node in `sync_meta`, and the records themselves materialized in the entity
/// tables, or held in `held_records` when a table cannot hold them yet.
///
/// A record's fields are read back from its entity's row (`entity_codec.dart`), restricted
/// to the fields that have a clock, so a field the record never set (`deleted_at` before
/// the first delete) is absent. Writing a record writes its clocks and then:
///
/// - a complete record (its create merged) of an account, transaction or category replaces
///   the row, children included, as the record says, without the repositories' checks:
///   those are preconditions of a local edit, and applying them to merged state would make
///   it depend on arrival order. A transaction's currency is its amount's, even when that
///   is no longer its account's; a transaction may be written before its account;
/// - an incomplete record (only updates merged: a Plaid transaction's overrides, a system
///   category's icon) whose row exists is laid over the row; settings always exist;
/// - a record the table cannot hold exactly is also kept whole in `held_records`, and
///   reads come from there while it is: `unknown_fields` (fields this version does not
///   know; the known ones land in the row), `unrepresentable` (splits the table cannot
///   store, in another currency than the amount or not decoding: every other field lands
///   and the row has no splits, so devices with the same record show the same row; or
///   fields that do not decode at all, when the row stays as it was), `incomplete` (only
///   updates, and no row yet), `unsupported_type` (an entity the app does not store yet).
///   A later write the table can hold exactly deletes the held row.
///
/// Pure Dart, no Flutter import.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/tables/record_clocks.dart';
import 'package:finance_tracker/core/db/tables/sync_meta.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/accounts/data/drift_account_repository.dart';
import 'package:finance_tracker/features/categories/data/drift_category_repository.dart';
import 'package:finance_tracker/features/settings/data/drift_settings_repository.dart';
import 'package:finance_tracker/features/transactions/data/drift_transaction_repository.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

/// Why a record is held rather than materialized.
enum HeldReason { incomplete, unrepresentable, unknownFields, unsupportedType }

/// What the outbox and the held records hold, for the sync status.
typedef SyncLedger = ({int pending, int rejected, Hlc? lastRejected, int held});

/// The [SyncStore] of the dev and prod flavors, over [AppDatabase]. Accounts and
/// categories carry no audit fields in their records, so materializing one stamps its
/// `updated_at` (and `created_at` on insert) from [_clock].
final class DriftSyncStore implements SyncStore {
  /// The store over [_database], stamping from [_clock].
  DriftSyncStore(this._database, this._clock);

  final AppDatabase _database;
  final Clock _clock;

  @override
  Future<T> transaction<T>(Future<T> Function() body) =>
      _database.transaction(body);

  // Records -----------------------------------------------------------------------------

  @override
  Future<EntityRecord?> read(
    EntityType type,
    String id,
  ) => _database.transaction(() async {
    final String name = snakeName(type);
    final List<RecordClockRow> clocks = await (_database.select(
      _database.recordClocks,
    )..where((c) => c.entityType.equals(name) & c.entityId.equals(id))).get();
    if (clocks.isEmpty) return null;
    Hlc? createdAt;
    final Map<String, Hlc> fieldClocks = {};
    for (final RecordClockRow row in clocks) {
      if (row.field == createClockField) {
        createdAt = Hlc.parse(row.hlc);
      } else {
        fieldClocks[row.field] = Hlc.parse(row.hlc);
      }
    }
    final HeldRecordRow? held = await _held(name, id);
    final Map<String, Object?>? values = held != null
        ? jsonDecode(held.fields) as Map<String, Object?>
        : await _entityFields(type, id);
    if (values == null) {
      throw StateError('$name $id has clocks but no row and is not held');
    }
    return EntityRecord(
      type: type,
      id: id,
      fields: {for (final String f in fieldClocks.keys) f: values[f]},
      fieldClocks: fieldClocks,
      createdAt: createdAt,
    );
  });

  @override
  Future<void> write(EntityRecord record) => _database.transaction(() async {
    final String name = snakeName(record.type);
    await (_database.delete(_database.recordClocks)..where(
          (c) => c.entityType.equals(name) & c.entityId.equals(record.id),
        ))
        .go();
    await _database.batch(
      (batch) => batch.insertAll(_database.recordClocks, [
        for (final MapEntry<String, Hlc> e in record.fieldClocks.entries)
          RecordClocksCompanion.insert(
            entityType: name,
            entityId: record.id,
            field: e.key,
            hlc: e.value.pack(),
          ),
        if (record.createdAt case final Hlc created)
          RecordClocksCompanion.insert(
            entityType: name,
            entityId: record.id,
            field: createClockField,
            hlc: created.pack(),
          ),
      ]),
    );
    final HeldReason? reason = await _materialize(record);
    if (reason == null) {
      await (_database.delete(_database.heldRecords)..where(
            (h) => h.entityType.equals(name) & h.entityId.equals(record.id),
          ))
          .go();
    } else {
      await _database
          .into(_database.heldRecords)
          .insertOnConflictUpdate(
            HeldRecordsCompanion.insert(
              entityType: name,
              entityId: record.id,
              fields: jsonEncode(record.fields),
              reason: snakeName(reason),
            ),
          );
    }
  });

  Future<HeldRecordRow?> _held(String type, String id) =>
      (_database.select(_database.heldRecords)
            ..where((h) => h.entityType.equals(type) & h.entityId.equals(id)))
          .getSingleOrNull();

  // The record fields of the stored entity, or null when there is no row.
  Future<Map<String, Object?>?> _entityFields(
    EntityType type,
    String id,
  ) async {
    switch (type) {
      case EntityType.account:
        final AccountRow? row = await _accountRow(id);
        return row == null
            ? null
            : accountRecordJson(accountFromRow(row), deletedAt: row.deletedAt);
      case EntityType.transaction:
        final TransactionRow? row = await (_database.select(
          _database.transactions,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        if (row == null) return null;
        return transactionRecordJson(
          (await transactionsWithChildren(_database, [row])).single,
          deletedWithAccount: row.deletedWithAccount,
        );
      case EntityType.category:
        final CategoryRow? row = await _categoryRow(id);
        return row == null
            ? null
            : categoryRecordJson(
                categoryFromRow(row),
                deletedAt: row.deletedAt,
              );
      case EntityType.settings:
        return id == settingsRecordId
            ? settingsRecordJson(
                settingsFromRows(
                  await _database.select(_database.appSettings).get(),
                ),
              )
            : null;
      case EntityType.rule ||
          EntityType.budget ||
          EntityType.recurringStream ||
          EntityType.billReminder ||
          EntityType.goal:
        return null;
    }
  }

  Future<AccountRow?> _accountRow(String id) => (_database.select(
    _database.accounts,
  )..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<CategoryRow?> _categoryRow(String id) => (_database.select(
    _database.categories,
  )..where((c) => c.id.equals(id))).getSingleOrNull();

  // Writes [record] into its entity's table, or returns why it is held.
  Future<HeldReason?> _materialize(EntityRecord record) async {
    final EntityType type = record.type;
    final HeldReason? unknown =
        record.fields.keys.every(knownRecordFields(type).contains)
        ? null
        : HeldReason.unknownFields;
    if (type == EntityType.settings) {
      if (record.id != settingsRecordId) return HeldReason.unsupportedType;
      final Set<String> known = knownRecordFields(type);
      await _database.batch(
        (batch) => batch.insertAllOnConflictUpdate(_database.appSettings, [
          for (final MapEntry<String, Object?> e in record.fields.entries)
            if (known.contains(e.key))
              AppSettingsCompanion.insert(
                key: e.key,
                value: jsonEncode(e.value),
              ),
        ]),
      );
      return unknown;
    }
    if (type != EntityType.account &&
        type != EntityType.transaction &&
        type != EntityType.category) {
      return HeldReason.unsupportedType;
    }
    final Map<String, Object?> fields;
    if (record.isComplete) {
      fields = record.fields;
    } else {
      final Map<String, Object?>? stored = await _entityFields(type, record.id);
      if (stored == null) return HeldReason.incomplete;
      fields = {...stored, ...record.fields};
    }
    final DateTime? createdAt = switch (type) {
      EntityType.account => (await _accountRow(record.id))?.createdAt,
      EntityType.category => (await _categoryRow(record.id))?.createdAt,
      _ => null,
    };
    try {
      await _rowWriter(type, record.id, fields, createdAt)();
      return unknown;
    } on _Unrepresentable {
      if (type != EntityType.transaction) return HeldReason.unrepresentable;
    }
    // Splits the table cannot store (another currency than the amount's, or splits that
    // do not decode): every other field still lands, deterministically, with no splits,
    // so devices holding the same record show the same row.
    try {
      await _rowWriter(type, record.id, {
        ...fields,
        'splits': const <Object?>[],
      }, createdAt)();
    } on _Unrepresentable {
      // Nothing decodes: the row stays as it was.
    }
    return HeldReason.unrepresentable;
  }

  // Decodes [fields] and checks they fit the table; returns the write. Throws when they
  // do not. [createdAt] is the stored row's (accounts and categories), null for a new one.
  Future<void> Function() _rowWriter(
    EntityType type,
    String id,
    Map<String, Object?> fields,
    DateTime? createdAt,
  ) {
    try {
      return _decodedRowWriter(type, id, fields, createdAt);
    } on Object catch (e) {
      // The fields do not decode into the entity, or not into its table.
      throw _Unrepresentable(e);
    }
  }

  Future<void> Function() _decodedRowWriter(
    EntityType type,
    String id,
    Map<String, Object?> fields,
    DateTime? createdAt,
  ) {
    final DateTime now = _clock.nowUtc();
    switch (type) {
      case EntityType.account:
        final Account account = Account.fromJson(fields);
        if (account.id != id) throw FormatException('id mismatch', account.id);
        final AccountsCompanion row = accountCompanion(
          account,
          createdAt: createdAt ?? now,
          updatedAt: now,
          deletedAt: Value(deletedAtOf(fields)),
        );
        return () =>
            _database.into(_database.accounts).insertOnConflictUpdate(row);
      case EntityType.transaction:
        final Transaction transaction = Transaction.fromJson(fields);
        if (transaction.id != id) {
          throw FormatException('id mismatch', transaction.id);
        }
        final String currency = transaction.amount.currencyCode;
        for (final TransactionSplit split in transaction.splits) {
          if (split.amount.currencyCode != currency) {
            throw CurrencyMismatchException(
              currency,
              split.amount.currencyCode,
            );
          }
        }
        final bool cascaded = deletedWithAccountOf(fields);
        return () => writeTransactionRow(
          _database,
          transaction,
          currency: currency,
          deletedAt: Value(transaction.deletedAt),
          deletedWithAccount: Value(cascaded),
        );
      case EntityType.category:
        final Category category = Category.fromJson(fields);
        if (category.id != id) {
          throw FormatException('id mismatch', category.id);
        }
        final CategoriesCompanion row = categoryCompanion(
          category,
          createdAt: createdAt ?? now,
          now: now,
          deletedAt: Value(deletedAtOf(fields)),
        );
        return () =>
            _database.into(_database.categories).insertOnConflictUpdate(row);
      case _:
        throw ArgumentError.value(type, 'type', 'not materialized');
    }
  }

  // The outbox --------------------------------------------------------------------------

  @override
  Future<void> append(ChangeLogEntry entry) => _database
      .into(_database.changeLog)
      .insert(
        ChangeLogCompanion.insert(
          entityType: snakeName(entry.entityType),
          entityId: entry.entityId,
          operation: snakeName(entry.operation),
          payload: jsonEncode(entry.payload),
          hlc: entry.hlc.pack(),
          deviceId: entry.deviceId,
        ),
      );

  @override
  Future<List<ChangeLogEntry>> unsynced({int limit = 200}) async => [
    for (final ChangeLogRow row
        in await (_database.select(_database.changeLog)
              ..where((c) => c.synced.equals(false) & c.rejectedReason.isNull())
              ..orderBy([(c) => OrderingTerm.asc(c.hlc)])
              ..limit(limit))
            .get())
      ChangeLogEntry(
        entityType: enumFromSnakeName(EntityType.values, row.entityType),
        entityId: row.entityId,
        operation: enumFromSnakeName(ChangeOperation.values, row.operation),
        payload: jsonDecode(row.payload) as Map<String, dynamic>,
        hlc: Hlc.parse(row.hlc),
        deviceId: row.deviceId,
        synced: false,
      ),
  ];

  @override
  Future<void> markSynced(Iterable<Hlc> hlcs) =>
      _updateEntries(hlcs, const ChangeLogCompanion(synced: Value(true)));

  @override
  Future<void> markRejected(Iterable<Hlc> hlcs, PushRejectionReason reason) =>
      _updateEntries(
        hlcs,
        ChangeLogCompanion(rejectedReason: Value(snakeName(reason))),
      );

  Future<void> _updateEntries(Iterable<Hlc> hlcs, ChangeLogCompanion change) =>
      _database.transaction(() async {
        final List<String> packed = [for (final Hlc h in hlcs) h.pack()];
        for (int start = 0; start < packed.length; start += 500) {
          final List<String> chunk = packed.sublist(
            start,
            start + 500 > packed.length ? packed.length : start + 500,
          );
          await (_database.update(
            _database.changeLog,
          )..where((c) => c.hlc.isIn(chunk))).write(change);
        }
      });

  /// The outbox's and the held records' counts, now and after every change: the entries
  /// waiting to be pushed, those refused for good (and the clock of the newest), and the
  /// records held out of the entity tables.
  Stream<SyncLedger> watchLedger() => _database
      .customSelect(
        'SELECT '
        '(SELECT COUNT(*) FROM change_log '
        'WHERE synced = 0 AND rejected_reason IS NULL) AS pending, '
        '(SELECT COUNT(*) FROM change_log '
        'WHERE rejected_reason IS NOT NULL) AS rejected, '
        '(SELECT MAX(hlc) FROM change_log '
        'WHERE rejected_reason IS NOT NULL) AS last_rejected, '
        '(SELECT COUNT(*) FROM held_records) AS held',
        readsFrom: {_database.changeLog, _database.heldRecords},
      )
      .watchSingle()
      .map((row) {
        final String? last = row.read<String?>('last_rejected');
        return (
          pending: row.read<int>('pending'),
          rejected: row.read<int>('rejected'),
          lastRejected: last == null ? null : Hlc.parse(last),
          held: row.read<int>('held'),
        );
      })
      .distinct();

  // Cursor, clock, node -----------------------------------------------------------------

  @override
  Future<int?> pullCursor() async {
    final String? value = await meta(SyncMetaKeys.pullCursor);
    return value == null ? null : int.parse(value);
  }

  @override
  Future<void> savePullCursor(int seq) =>
      saveMeta(SyncMetaKeys.pullCursor, '$seq');

  @override
  Future<Hlc?> lastClock() async {
    final String? value = await meta(SyncMetaKeys.lastClock);
    return value == null ? null : Hlc.parse(value);
  }

  @override
  Future<void> saveClock(Hlc clock) =>
      saveMeta(SyncMetaKeys.lastClock, clock.pack());

  /// The `sync_meta` value of [key], or null.
  Future<String?> meta(String key) async => (await (_database.select(
    _database.syncMeta,
  )..where((m) => m.key.equals(key))).getSingleOrNull())?.value;

  /// Sets the `sync_meta` value of [key].
  Future<void> saveMeta(String key, String value) => _database
      .into(_database.syncMeta)
      .insertOnConflictUpdate(SyncMetaCompanion.insert(key: key, value: value));

  /// Moves the unsynced, unrejected outbox to node [nodeId] by substituting the node of
  /// each entry's clock, wall and counter kept (an edit keeps its time under
  /// last-writer-wins), together with every field clock an entry set, the persisted clock
  /// and the stored node, in one transaction. Synced and rejected entries, and the clocks
  /// they set, keep their node. Returns the persisted clock under the new node, or null on
  /// a device that has none.
  ///
  /// Clocks stay unique: every substituted clock shares the substitution, and [nodeId] is
  /// a node this device has not used. A packed clock is a 22-character
  /// `<wall>-<counter>-` prefix, then the node.
  Future<Hlc?> substituteNode(String nodeId) => _database.transaction(() async {
    Hlc(0, 0, nodeId); // Throws on a node id the packed form cannot hold.
    const String outbox =
        'SELECT hlc FROM change_log WHERE synced = 0 AND rejected_reason IS NULL';
    await _database.customUpdate(
      'UPDATE record_clocks SET hlc = substr(hlc, 1, 22) || ? '
      'WHERE hlc IN ($outbox)',
      variables: [Variable.withString(nodeId)],
      updates: {_database.recordClocks},
    );
    await _database.customUpdate(
      'UPDATE change_log SET hlc = substr(hlc, 1, 22) || ?1, device_id = ?1 '
      'WHERE synced = 0 AND rejected_reason IS NULL',
      variables: [Variable.withString(nodeId)],
      updates: {_database.changeLog},
    );
    await saveMeta(SyncMetaKeys.deviceId, nodeId);
    final Hlc? last = await lastClock();
    if (last == null) return null;
    final Hlc moved = Hlc(last.wallMillis, last.counter, nodeId);
    await saveClock(moved);
    return moved;
  });
}

/// Fields that do not decode into an entity, or not into its table.
final class _Unrepresentable implements Exception {
  const _Unrepresentable(this.cause);

  final Object cause;

  @override
  String toString() => '_Unrepresentable(${cause.runtimeType})';
}
