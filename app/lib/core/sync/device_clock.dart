/// The device's hybrid logical clock and its node (`docs/reference/sync-app.md`, **The
/// device's node**).
///
/// One [HlcClock] is shared by every local edit and every sync session of the device.
/// Its node starts as a provisional `local-<uuid v4>`, so changes made before the first
/// sign-in are stamped and recorded; when the session's device id is known, [adopt]
/// substitutes it into the unsynced outbox and the clock. Pure Dart, no Flutter import.
library;

import 'package:finance_tracker/core/db/app_database.dart'
    show provisionalNodeId;
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/db/tables/sync_meta.dart';
import 'package:sync_engine/sync_engine.dart';

/// The device's clock over [_store].
final class DeviceClock {
  /// The clock of the device whose state is [_store]; `newNodeId` names a new device's
  /// provisional node.
  DeviceClock(this._store, {this._newNodeId = provisionalNodeId});

  final DriftSyncStore _store;
  final String Function() _newNodeId;
  HlcClock? _clock;

  /// The clock, resumed from the store on first use (a new device gets a provisional
  /// node). Call it inside a store transaction, so it is never read half-way through
  /// [adopt].
  Future<HlcClock> current() async {
    final HlcClock? clock = _clock;
    if (clock != null) return clock;
    String? node = await _store.meta(SyncMetaKeys.deviceId);
    if (node == null) {
      node = _newNodeId();
      await _store.saveMeta(SyncMetaKeys.deviceId, node);
    }
    return _clock = HlcClock(node, last: await _store.lastClock());
  }

  /// Makes [deviceId] (the server's id for this device) the clock's node: the unsynced
  /// outbox, the field clocks it set and the persisted clock move to it, wall and counter
  /// kept (`DriftSyncStore.substituteNode`). Does nothing when it already is the node.
  Future<void> adopt(String deviceId) => _store.transaction(() async {
    final HlcClock clock = await current();
    if (clock.nodeId == deviceId) return;
    _clock = HlcClock(deviceId, last: await _store.substituteNode(deviceId));
  });
}
