/// The `stream_overrides` table: the user's choices about each recurring stream, schema 9
/// (`docs/reference/recurring.md`).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/converters.dart';

/// One row per stream the user has made a choice about, keyed by the stream's id (no
/// foreign key: a stream the server stops reporting leaves its override behind, and an
/// override may arrive through sync before its stream). `is_subscription` and
/// `display_name` null leave the stream's own value standing. User data: synced as the
/// `recurring_stream` record; `deleted_at` is its tombstone (the override cleared).
@DataClassName('StreamOverrideRow')
class StreamOverrides extends Table {
  TextColumn get streamId => text()();
  BoolColumn get muted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSubscription => boolean().nullable()();
  TextColumn get displayName => text().nullable()();
  IntColumn get createdAt => integer().map(const UtcMillisColumnConverter())();
  IntColumn get updatedAt => integer().map(const UtcMillisColumnConverter())();
  IntColumn get deletedAt =>
      integer().map(const UtcMillisColumnConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {streamId};
}
