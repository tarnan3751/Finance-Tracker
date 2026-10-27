/// The `recurring_streams` table: the recurring streams the app knows, schema 9
/// (`docs/reference/recurring.md`).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';
import 'package:shared_models/shared_models.dart';

/// Recurring streams: the server's (`plaid`, or `demo` from a fake), replaced whole by
/// each Plaid pull, and the app detector's (`detected`), replaced whole by each run of
/// it; neither is ever recorded in the change log (the user's choices about a stream are
/// `stream_overrides`). `average_amount_minor` is in `currency`, in the app's sign;
/// `transaction_ids` is a JSON array of the member transactions' ids; `pulled_at` is when
/// the row was written. `cadence` has no CHECK, so a cadence a newer version adds needs
/// no schema step.
@DataClassName('RecurringStreamRow')
@TableIndex(name: 'recurring_streams_account', columns: {#accountId})
class RecurringStreams extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  TextColumn get merchantName => text()();
  TextColumn get cadence =>
      text().map(const RecurringCadenceColumnConverter())();
  IntColumn get averageAmountMinor => integer()();
  TextColumn get currency => text()();
  TextColumn get lastExpected =>
      text().map(const LocalDateColumnConverter()).nullable()();
  TextColumn get nextExpected =>
      text().map(const LocalDateColumnConverter()).nullable()();
  TextColumn get status => textEnum<RecurringStatus>()();
  BoolColumn get isSubscription => boolean()();
  TextColumn get source => textEnum<RecurringSource>()();
  TextColumn get transactionIds => text()();
  IntColumn get pulledAt => integer().map(const UtcMillisColumnConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK (status IN ('active', 'ended'))",
    "CHECK (source IN ('plaid', 'detected', 'user', 'demo'))",
  ];
}
