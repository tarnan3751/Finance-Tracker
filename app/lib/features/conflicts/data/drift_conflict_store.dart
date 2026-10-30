/// The [ConflictStore] of the dev and prod flavors, over the `conflicts` table
/// (`docs/reference/data.md`, schema 13). Nothing here is recorded for sync.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/features/conflicts/domain/conflict_store.dart';
import 'package:finance_tracker/features/conflicts/domain/sync_conflict.dart';
import 'package:shared_models/shared_models.dart';

/// Conflicts in [AppDatabase].
final class DriftConflictStore implements ConflictStore {
  /// The store over [_database].
  DriftConflictStore(this._database);

  final AppDatabase _database;

  static final Map<String, EntityType> _types = {
    for (final EntityType t in EntityType.values) snakeName(t): t,
  };

  @override
  Stream<List<SyncConflict>> watch() =>
      (_database.select(_database.conflicts)..orderBy([
            (c) => OrderingTerm.desc(c.seenAt),
            (c) => OrderingTerm.asc(c.entityType),
            (c) => OrderingTerm.asc(c.entityId),
            (c) => OrderingTerm.asc(c.field),
          ]))
          .watch()
          .map(
            (rows) => [
              for (final ConflictRow r in rows)
                if (_types[r.entityType] case final EntityType type)
                  SyncConflict(
                    entityType: type,
                    entityId: r.entityId,
                    field: r.field,
                    localValue: jsonDecode(r.localValue),
                    localClock: Hlc.parse(r.localHlc),
                    remoteValue: jsonDecode(r.remoteValue),
                    remoteClock: Hlc.parse(r.remoteHlc),
                    entityLabel: r.entityLabel,
                    seenAt: r.seenAt,
                  ),
            ],
          );

  @override
  Future<void> dismiss(SyncConflict conflict) =>
      (_database.delete(_database.conflicts)..where(
            (c) =>
                c.entityType.equals(snakeName(conflict.entityType)) &
                c.entityId.equals(conflict.entityId) &
                c.field.equals(conflict.field),
          ))
          .go();
}
