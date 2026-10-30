/// One sync of a device against the relay: push the outbox, then pull and merge
/// (`docs/reference/sync.md`, **The session**).
library;

import 'package:meta/meta.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/src/entity_record.dart';
import 'package:sync_engine/src/hlc_clock.dart';
import 'package:sync_engine/src/merge.dart';
import 'package:sync_engine/src/sync_relay.dart';
import 'package:sync_engine/src/sync_store.dart';

/// What a [SyncSession.run] did.
@immutable
final class SyncReport {
  /// A report.
  const SyncReport({
    required this.pushed,
    required this.rejected,
    required this.pulled,
    required this.applied,
    required this.changed,
    required this.clamped,
    required this.conflicts,
    required this.deferred,
  });

  /// Outbox entries the relay accepted.
  final int pushed;

  /// Outbox entries the relay refused. Each has one of two fates: a
  /// [PushRejectionReason.clockDrift] entry stays unsynced and is offered again next run
  /// (it heals once real time catches up); an [PushRejectionReason.invalid] or
  /// [PushRejectionReason.conflictingDuplicate] entry is permanent and leaves the outbox
  /// through [SyncStore.markRejected], kept by the store for the host to inspect. The
  /// third fate, acceptance, is counted in [pushed].
  final List<PushRejection> rejected;

  /// Entries pulled and merged, those of types this build does not know (held by the
  /// store) included.
  final int pulled;

  /// Pulled entries that changed a record.
  final int applied;

  /// The entities whose records changed, for the host to react to.
  final Set<EntityKey> changed;

  /// Pulled entries whose clock was more than the bound ahead of this device's physical
  /// clock: they were merged, but the device's clock clamped instead of adopting their
  /// wall time ([HlcClock.receive]). Only a device whose clock is behind the relay's can
  /// see one, since the relay refuses entries more than the bound ahead of its own.
  final int clamped;

  /// Overwrites of this device's own values that were conflicts ([MergeOutcome.losers]
  /// whose old value this device wrote), handed to [SyncStore.recordConflicts].
  final int conflicts;

  /// Outbox entries [SyncSession.beforePush] held back: still unsynced, offered again on
  /// the next run.
  final int deferred;
}

/// Syncs one device. Safe to rerun after any failure: a failed push leaves its entries
/// unsynced (the relay accepts a resent entry idempotently), and a failed pull keeps the
/// last saved cursor (a re-pulled page merges idempotently).
final class SyncSession {
  /// A session for the device whose records are in [store] and whose clock is [clock]
  /// (the instance its `LocalEditor` uses). [nowWallMillis] is the device's physical
  /// clock in UTC milliseconds.
  SyncSession(
    this.store,
    this.relay,
    this.clock, {
    required this.nowWallMillis,
    this.pushBatchSize = 200,
    this.pullPageSize = 200,
    this.beforePush,
  });

  /// The device's store.
  final SyncStore store;

  /// The relay.
  final SyncRelay relay;

  /// The device's clock; its node id is the device id.
  final HlcClock clock;

  /// The device's physical clock.
  final int Function() nowWallMillis;

  /// Entries per push.
  final int pushBatchSize;

  /// Entries per pull page.
  final int pullPageSize;

  /// Called with each batch before it is pushed; returns the entries of the batch that
  /// may be pushed now, in the batch's order (the host's work that must come first, such
  /// as uploading the bytes an entry names). The entries it leaves out stay unsynced,
  /// are not offered again in this run, so they never hold up the entries behind them,
  /// and are offered first on the next run. Null pushes every entry.
  final Future<List<ChangeLogEntry>> Function(List<ChangeLogEntry> batch)?
  beforePush;

  Future<SyncReport>? _running;

  /// Pushes every unsynced entry in clock order, in batches, less those [beforePush]
  /// holds back: accepted entries are marked
  /// synced, permanently rejected ones (`invalid`, `conflictingDuplicate`) are marked
  /// rejected and leave the outbox, and the push continues with the next batch; a
  /// `clockDrift` rejection stays unsynced and ends the push phase for this run. Then
  /// pulls from the saved cursor until the relay has no more, each page in one store
  /// transaction that receives every entry's clock (clamping one beyond the bound),
  /// merges it (an entry of a type this build does not know is held by the store under
  /// its raw type, `SyncStore.holdUnknownType`), hands the conflicts the merge reports
  /// about this device's own values to [SyncStore.recordConflicts], and saves the clock
  /// and the cursor.
  ///
  /// A call while a run is in flight returns that run. A store or relay error propagates;
  /// what was saved before it stays saved. That includes [SyncCursorInvalidException]
  /// from a reset relay, which propagates unchanged: the host resets the cursor with
  /// `store.savePullCursor(0)` and runs again.
  Future<SyncReport> run() => _running ??= _run().whenComplete(() {
    _running = null;
  });

  Future<SyncReport> _run() async {
    var pushed = 0;
    final rejected = <PushRejection>[];
    final held = <Hlc>{};
    while (true) {
      final batch = [
        for (final e in await store.unsynced(
          limit: pushBatchSize + held.length,
        ))
          if (!held.contains(e.hlc)) e,
      ].take(pushBatchSize).toList();
      if (batch.isEmpty) break;
      final ready = beforePush == null ? batch : await beforePush!(batch);
      final readyClocks = {for (final e in ready) e.hlc};
      for (final e in batch) {
        if (!readyClocks.contains(e.hlc)) held.add(e.hlc);
      }
      if (ready.isEmpty) continue;
      final result = await relay.push(ready);
      if (result.accepted.isNotEmpty) await store.markSynced(result.accepted);
      pushed += result.accepted.length;
      rejected.addAll(result.rejected);
      var permanent = 0;
      for (final reason in [
        PushRejectionReason.invalid,
        PushRejectionReason.conflictingDuplicate,
      ]) {
        final hlcs = [
          for (final x in result.rejected)
            if (x.reason == reason) x.hlc,
        ];
        if (hlcs.isEmpty) continue;
        await store.markRejected(hlcs, reason);
        permanent += hlcs.length;
      }
      final drifted = result.rejected.length > permanent;
      if (drifted || result.accepted.length + permanent == 0) break;
    }

    var pulled = 0;
    var applied = 0;
    final changed = <EntityKey>{};
    var clamped = 0;
    var conflicts = 0;
    var cursor = await store.pullCursor() ?? 0;
    while (true) {
      final page = await relay.pull(
        since: cursor,
        limit: pullPageSize,
        deviceId: clock.nodeId,
      );
      final now = nowWallMillis();
      if (page.entries.isNotEmpty ||
          page.unknownTypes.isNotEmpty ||
          page.nextSince != cursor) {
        final pageClamped = [
          for (final e in page.entries) e.hlc,
          for (final e in page.unknownTypes) e.hlc,
        ].where((hlc) => clock.beyondBound(hlc, now)).length;
        final (pageApplied, pageConflicts) = await store.transaction(() async {
          var n = 0;
          var lost = 0;
          for (final e in page.entries) {
            clock.receive(e.hlc, now);
            final out = merge(await store.read(e.entityType, e.entityId), e);
            if (!out.applied) continue;
            await store.write(out.record);
            // Only this device's own values: the device whose edit lost is the one to
            // ask, and the others would show a dispute they took no part in.
            final mine = [
              for (final c in out.losers)
                if (c.localDevice == clock.nodeId) c,
            ];
            if (mine.isNotEmpty) {
              await store.recordConflicts(mine);
              lost += mine.length;
            }
            changed.add(out.record.key);
            n++;
          }
          for (final e in page.unknownTypes) {
            clock.receive(e.hlc, now);
            await store.holdUnknownType(e);
          }
          await store.saveClock(clock.last);
          await store.savePullCursor(page.nextSince);
          return (n, lost);
        });
        applied += pageApplied;
        conflicts += pageConflicts;
        clamped += pageClamped;
      }
      pulled += page.entries.length + page.unknownTypes.length;
      cursor = page.nextSince;
      if (!page.hasMore) break;
    }
    return SyncReport(
      pushed: pushed,
      rejected: rejected,
      pulled: pulled,
      applied: applied,
      changed: changed,
      clamped: clamped,
      conflicts: conflicts,
      deferred: held.length,
    );
  }
}
