/// The seam between the repositories and the sync engine's local edit path
/// (`docs/reference/sync-app.md`, **Recording**).
///
/// Every repository write to user-authored data calls [ChangeRecorder.record] once per
/// entity it changed (or [ChangeRecorder.recordAll] once for a batch), with the entity's record fields before and after
/// (`entity_codec.dart`), inside the write's own transaction. Which changes are
/// user-authored is decided here, by `source`, for both implementations
/// ([userAuthoredChange]); the engine never reads `source`.
///
/// Pure Dart, no Flutter import.
library;

import 'dart:convert';

import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

/// Records changes to entities for sync. An implementation extends this class to take
/// [recordAll]'s default, which records each change in turn.
abstract class ChangeRecorder {
  /// Const, so implementations can be.
  const ChangeRecorder();

  /// Records that entity [type] [id] changed from [before] (null for a new entity) to
  /// [after], both record fields, when the change is user-authored and changes anything.
  Future<void> record(
    EntityType type,
    String id,
    Map<String, Object?>? before,
    Map<String, Object?> after,
  );

  /// Records [changes] to distinct entities of [type], each as [record] would, in order.
  Future<void> recordAll(EntityType type, List<LocalChange> changes) async {
    for (final LocalChange c in changes) {
      await record(type, c.id, c.before, c.after);
    }
  }
}

/// The recorder of the demo flavor, which never syncs: records nothing.
final class NoChangeRecorder extends ChangeRecorder {
  /// The recorder.
  const NoChangeRecorder();

  @override
  Future<void> record(
    EntityType type,
    String id,
    Map<String, Object?>? before,
    Map<String, Object?> after,
  ) async {}

  @override
  Future<void> recordAll(EntityType type, List<LocalChange> changes) async {}
}

/// Records through the engine's [LocalEditor] over [store], stamping with the device's
/// clock as [clock] gives it (read inside the store's transaction, so a node change can
/// never interleave with an edit) at [nowWallMillis]. Inside a repository's transaction
/// on the same database, the record, its clocks and its outbox entry commit with the
/// repository's own write.
///
/// [recordAll] records a batch through one [LocalEditor.recordChanges], so the store
/// reads, writes and appends the batch in a few statements rather than several per entity.
final class EngineChangeRecorder extends ChangeRecorder {
  /// A recorder over [store].
  EngineChangeRecorder(this.store, this.clock, this.nowWallMillis);

  /// The device's sync store.
  final SyncStore store;

  /// The device's clock, shared with its sync sessions.
  final Future<HlcClock> Function() clock;

  /// The wall clock, UTC milliseconds.
  final int Function() nowWallMillis;

  @override
  Future<void> record(
    EntityType type,
    String id,
    Map<String, Object?>? before,
    Map<String, Object?> after,
  ) async {
    final ({Map<String, Object?>? before, Map<String, Object?> after})? change =
        userAuthoredChange(type, before, after);
    if (change == null) return;
    await store.transaction(
      () async => LocalEditor(
        store,
        await clock(),
      ).recordChange(type, id, change.before, change.after, nowWallMillis()),
    );
  }

  @override
  Future<void> recordAll(EntityType type, List<LocalChange> changes) async {
    final List<LocalChange> authored = [
      for (final LocalChange c in changes)
        if (userAuthoredChange(type, c.before, c.after) case final change?)
          (id: c.id, before: change.before, after: change.after),
    ];
    if (authored.isEmpty) return;
    await store.transaction(
      () async => LocalEditor(
        store,
        await clock(),
      ).recordChanges(type, authored, nowWallMillis),
    );
  }
}

/// Records, through [recorder], each entity of [after] (record fields by id) that differs
/// from [before]: one entry per entity a write changed, in one [ChangeRecorder.recordAll].
Future<void> recordEach(
  ChangeRecorder recorder,
  EntityType type,
  Map<String, Map<String, Object?>> before,
  Map<String, Map<String, Object?>> after,
) async {
  final List<LocalChange> changes = [
    for (final MapEntry<String, Map<String, Object?>> e in after.entries)
      if (before[e.key] case final Map<String, Object?>? old
          when old == null || jsonEncode(old) != jsonEncode(e.value))
        (id: e.key, before: old, after: e.value),
  ];
  if (changes.isNotEmpty) await recorder.recordAll(type, changes);
}

/// The part of a change that is user-authored, or null when none is (`PLAN.md` §6.4,
/// §7.1):
///
/// - a transaction with `source` `manual` or `import`: all of it;
/// - a Plaid transaction: only the seven fields the user owns ([plaidOverrideFields]), and
///   nothing for a new one, which only Plaid's own pipeline creates;
/// - a `derived` or `demo` transaction: nothing (derived values are recomputed on each
///   device; demo data never syncs);
/// - an account linked through an Item (`item_id` set): nothing until Phase 3 rules on
///   linked-account overrides;
/// - categories, rules, budgets and settings: all of it.
({Map<String, Object?>? before, Map<String, Object?> after})?
userAuthoredChange(
  EntityType type,
  Map<String, Object?>? before,
  Map<String, Object?> after,
) {
  switch (type) {
    case EntityType.transaction:
      switch (after['source']) {
        case 'manual' || 'import':
          return (before: before, after: after);
        case 'plaid':
          if (before == null) return null;
          Map<String, Object?> owned(Map<String, Object?> fields) => {
            for (final String f in plaidOverrideFields) f: fields[f],
          };
          return (before: owned(before), after: owned(after));
        default:
          return null;
      }
    case EntityType.account:
      return after['item_id'] == null ? (before: before, after: after) : null;
    case _:
      return (before: before, after: after);
  }
}
