/// The `bills` table: the user's bills (`docs/reference/bills.md`), schema 10.
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';

/// Bills. The expected amount is `amount_minor` in `currency`, both null or both set;
/// `reminder_offset_days` (ints) and `paid_occurrences` (ISO dates) are JSON arrays.
/// `cadence` has no CHECK: a cadence a later version adds needs no table rebuild.
@DataClassName('BillRow')
@TableIndex(name: 'bills_due_date', columns: {#dueDate})
class Bills extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  IntColumn get amountMinor => integer().nullable()();
  TextColumn get currency => text().nullable()();
  TextColumn get dueDate => text().map(const LocalDateColumnConverter())();
  TextColumn get cadence =>
      text().map(const RecurringCadenceColumnConverter()).nullable()();
  TextColumn get accountId => text().nullable()();
  TextColumn get streamId => text().nullable()();
  TextColumn get liabilityAccountId => text().nullable()();
  TextColumn get reminderOffsetDays => text()();
  IntColumn get reminderMinutes => integer()();
  BoolColumn get active => boolean()();
  BoolColumn get autopay => boolean()();
  TextColumn get paidOccurrences => text()();
  IntColumn get createdAt => integer().map(const UtcMillisColumnConverter())();
  IntColumn get updatedAt => integer().map(const UtcMillisColumnConverter())();
  IntColumn get deletedAt =>
      integer().map(const UtcMillisColumnConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK (reminder_minutes BETWEEN 0 AND 1439)',
    'CHECK ((amount_minor IS NULL) = (currency IS NULL))',
  ];
}
