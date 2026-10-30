/// The in-memory [SyncRelay]: the reference for the relay contract, used by the tests and
/// the simulation. The dev server's relay (lane 2d) follows the same rules.
library;

import 'dart:convert';

import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/src/entity_record.dart';
import 'package:sync_engine/src/merge.dart';
import 'package:sync_engine/src/sync_relay.dart';

/// A [SyncRelay] held in memory. Entries are kept as JSON text and decoded on pull, so
/// every entry crosses the same wire form the server's would.
final class InMemorySyncRelay implements SyncRelay {
  /// A relay whose clock is [nowWallMillis]; an entry whose wall time is more than
  /// [maxDrift] ahead of it is rejected as [PushRejectionReason.clockDrift].
  InMemorySyncRelay({
    required this.nowWallMillis,
    this.maxDrift = Hlc.maxDrift,
  });

  /// The relay's clock, UTC milliseconds.
  final int Function() nowWallMillis;

  /// How far ahead of [nowWallMillis] an entry's wall time may be.
  final Duration maxDrift;

  /// The log; entry `i` has `seq` `i + 1`.
  final List<String> _log = [];
  final List<String> _deviceOf = [];
  final Map<String, int> _seqByKey = {};

  /// Every stored entry, in `seq` order.
  List<ChangeLogEntry> get entries => [for (final s in _log) _decode(s)];

  /// The records the stored entries determine: every entry merged, in `seq` order.
  Map<EntityKey, EntityRecord> fold() {
    final state = <EntityKey, EntityRecord>{};
    for (final e in entries) {
      final key = (type: e.entityType, id: e.entityId);
      state[key] = merge(state[key], e).record;
    }
    return state;
  }

  @override
  Future<PushResult> push(List<ChangeLogEntry> entries) async {
    final now = nowWallMillis();
    final accepted = <Hlc>[];
    final rejected = <PushRejection>[];
    for (final entry in entries) {
      final problem = _validate(entry);
      if (problem != null) {
        rejected.add(
          PushRejection(entry.hlc, PushRejectionReason.invalid, problem),
        );
        continue;
      }
      if (entry.hlc.wallMillis - now > maxDrift.inMilliseconds) {
        rejected.add(
          PushRejection(
            entry.hlc,
            PushRejectionReason.clockDrift,
            '${entry.hlc.wallMillis - now} ms ahead of the relay',
          ),
        );
        continue;
      }
      final json = jsonEncode(entry.copyWith(synced: true).toJson());
      final key = '${entry.deviceId}|${entry.hlc.pack()}';
      final seq = _seqByKey[key];
      if (seq == null) {
        _log.add(json);
        _deviceOf.add(entry.deviceId);
        _seqByKey[key] = _log.length;
      } else if (!jsonEquality.equals(
        jsonDecode(_log[seq - 1]),
        jsonDecode(json),
      )) {
        rejected.add(
          PushRejection(
            entry.hlc,
            PushRejectionReason.conflictingDuplicate,
            'another payload is stored as seq $seq',
          ),
        );
        continue;
      }
      accepted.add(entry.hlc);
    }
    return PushResult(accepted: accepted, rejected: rejected);
  }

  @override
  Future<PullPage> pull({
    required int since,
    int limit = 200,
    required String deviceId,
  }) async {
    if (since < 0) throw ArgumentError.value(since, 'since', 'negative');
    if (since > _log.length) {
      throw SyncCursorInvalidException(since, _log.length);
    }
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'must be positive');
    }
    final page = <ChangeLogEntry>[];
    var seq = since;
    while (seq < _log.length) {
      if (_deviceOf[seq] != deviceId) {
        if (page.length == limit) {
          return PullPage(entries: page, nextSince: seq, hasMore: true);
        }
        page.add(_decode(_log[seq]));
      }
      seq++;
    }
    return PullPage(
      entries: page,
      nextSince: _log.length > since ? _log.length : since,
      hasMore: false,
    );
  }

  static String? _validate(ChangeLogEntry e) {
    if (e.hlc.nodeId != e.deviceId) return 'clock node is not the device';
    if (e.payload.isEmpty) return 'empty payload';
    if (e.operation == ChangeOperation.delete) {
      final at = e.payload['deleted_at'];
      if (at is! String) return 'delete without deleted_at';
      try {
        const UtcInstantConverter().fromJson(at);
      } on FormatException {
        return 'deleted_at is not an instant';
      }
    }
    return null;
  }

  static ChangeLogEntry _decode(String json) =>
      ChangeLogEntry.fromJson(jsonDecode(json) as Map<String, dynamic>);
}
