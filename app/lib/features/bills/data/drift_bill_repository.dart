/// The [BillRepository] of the dev and prod flavors, over the `bills` table
/// (`docs/reference/data.md`).
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/bills/domain/bill_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Bills in [AppDatabase]. Audit fields are stamped from the clock. Every write records
/// the bill it changed through [_recorder] in the same database transaction.
final class DriftBillRepository implements BillRepository {
  /// The repository over [_database], stamping writes from [_clock] and recording them
  /// through `recorder`.
  DriftBillRepository(this._database, this._clock, {required this._recorder});

  final AppDatabase _database;
  final Clock _clock;
  final ChangeRecorder _recorder;

  $BillsTable get _bills => _database.bills;

  @override
  Stream<List<BillReminder>> watchAll() =>
      (_database.select(_bills)
            ..where((b) => b.deletedAt.isNull())
            ..orderBy([
              (b) => OrderingTerm.asc(b.dueDate),
              (b) => OrderingTerm.asc(b.id),
            ]))
          .watch()
          .map((rows) => rows.map(billFromRow).toList())
          .distinct(sameList);

  @override
  Stream<BillReminder?> watchById(String id) =>
      (_database.select(_bills)
            ..where((b) => b.id.equals(id) & b.deletedAt.isNull()))
          .watchSingleOrNull()
          .map((row) => row == null ? null : billFromRow(row))
          .distinct();

  @override
  Future<void> upsert(BillReminder bill) => _database.transaction(() async {
    final BillRow? existing = await _row(bill.id);
    if (existing != null && existing.deletedAt != null) {
      throw EntityDeletedException('bill', bill.id);
    }
    final DateTime now = _clock.nowUtc();
    await _database
        .into(_bills)
        .insertOnConflictUpdate(
          billCompanion(bill, createdAt: existing?.createdAt ?? now, now: now),
        );
    await _recorder.record(
      EntityType.billReminder,
      bill.id,
      existing == null ? null : billRecordJson(billFromRow(existing)),
      billRecordJson(bill),
    );
  });

  @override
  Future<void> delete(String id) => _database.transaction(() async {
    final BillRow? row = await _row(id);
    if (row == null || row.deletedAt != null) return;
    final DateTime now = _clock.nowUtc();
    await (_database.update(_bills)..where((b) => b.id.equals(id))).write(
      BillsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
    final BillReminder bill = billFromRow(row);
    await _recorder.record(
      EntityType.billReminder,
      id,
      billRecordJson(bill),
      billRecordJson(bill, deletedAt: now),
    );
  });

  @override
  Future<void> restore(String id) => _database.transaction(() async {
    final BillRow? row = await _row(id);
    final DateTime? deletedAt = row?.deletedAt;
    if (row == null || deletedAt == null) return;
    await (_database.update(_bills)..where((b) => b.id.equals(id))).write(
      BillsCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(_clock.nowUtc()),
      ),
    );
    final BillReminder bill = billFromRow(row);
    await _recorder.record(
      EntityType.billReminder,
      id,
      billRecordJson(bill, deletedAt: deletedAt),
      billRecordJson(bill),
    );
  });

  Future<BillRow?> _row(String id) => (_database.select(
    _bills,
  )..where((b) => b.id.equals(id))).getSingleOrNull();
}

/// The row of [bill], stamped [createdAt] and [now]; `deleted_at` is written only when
/// given. The offsets and the paid occurrences are JSON arrays.
BillsCompanion billCompanion(
  BillReminder bill, {
  required DateTime createdAt,
  required DateTime now,
  Value<DateTime?> deletedAt = const Value.absent(),
}) => BillsCompanion(
  id: Value(bill.id),
  name: Value(bill.name),
  amountMinor: Value(bill.amount?.minorUnits),
  currency: Value(bill.amount?.currencyCode),
  dueDate: Value(bill.dueDate),
  cadence: Value(bill.cadence),
  accountId: Value(bill.accountId),
  streamId: Value(bill.streamId),
  liabilityAccountId: Value(bill.liabilityAccountId),
  reminderOffsetDays: Value(jsonEncode(bill.reminderOffsetDays)),
  reminderMinutes: Value(bill.reminderMinutes),
  active: Value(bill.active),
  autopay: Value(bill.autopay),
  paidOccurrences: Value(
    jsonEncode([for (final LocalDate d in bill.paidOccurrences) d.toIso()]),
  ),
  createdAt: Value(createdAt),
  updatedAt: Value(now),
  deletedAt: deletedAt,
);

/// The [BillReminder] a row holds.
BillReminder billFromRow(BillRow row) => BillReminder(
  id: row.id,
  name: row.name,
  amount: switch ((row.amountMinor, row.currency)) {
    (final int minor, final String currency) => Money(minor, currency),
    _ => null,
  },
  dueDate: row.dueDate,
  cadence: row.cadence,
  accountId: row.accountId,
  streamId: row.streamId,
  liabilityAccountId: row.liabilityAccountId,
  reminderOffsetDays: [
    for (final Object? d in jsonDecode(row.reminderOffsetDays) as List<Object?>)
      d! as int,
  ],
  reminderMinutes: row.reminderMinutes,
  active: row.active,
  autopay: row.autopay,
  paidOccurrences: [
    for (final Object? d in jsonDecode(row.paidOccurrences) as List<Object?>)
      LocalDate.parse(d! as String),
  ],
);
