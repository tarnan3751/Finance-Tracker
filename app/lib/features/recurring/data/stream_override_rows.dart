/// The `stream_overrides` rows and the [StreamOverride] they hold: shared by the Drift
/// repository and the Drift sync store, which materializes `recurring_stream` records.
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/features/recurring/domain/stream_override.dart';

/// The override a row holds (whether or not it is cleared).
StreamOverride streamOverrideFromRow(StreamOverrideRow row) => StreamOverride(
  muted: row.muted,
  isSubscription: row.isSubscription,
  displayName: row.displayName,
);

/// The row of [override] for stream [streamId], stamped [createdAt] and [now];
/// `deleted_at` is written only when given.
StreamOverridesCompanion streamOverrideCompanion(
  String streamId,
  StreamOverride override, {
  required DateTime createdAt,
  required DateTime now,
  Value<DateTime?> deletedAt = const Value.absent(),
}) => StreamOverridesCompanion(
  streamId: Value(streamId),
  muted: Value(override.muted),
  isSubscription: Value(override.isSubscription),
  displayName: Value(override.displayName),
  createdAt: Value(createdAt),
  updatedAt: Value(now),
  deletedAt: deletedAt,
);
