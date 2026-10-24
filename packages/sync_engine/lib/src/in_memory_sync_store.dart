/// The in-memory [SyncStore]: the reference for the store contract, used by the tests and
/// the simulation.
library;

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/src/entity_record.dart';
import 'package:sync_engine/src/sync_relay.dart';
import 'package:sync_engine/src/sync_store.dart';

/// A [SyncStore] held in memory. A transaction snapshots the state and restores it when
/// its body throws; transactions and standalone calls take one lock in turn.
final class InMemorySyncStore implements SyncStore {
  Map<EntityKey, EntityRecord> _records = {};
  List<ChangeLogEntry> _outbox = [];
  List<(ChangeLogEntry, PushRejectionReason)> _rejected = [];
  int? _cursor;
  Hlc? _clock;

  Future<void> _tail = Future.value();
  static final Object _inTransaction = Object();

  /// Called with the operation's name (`read`, `write`, `savePullCursor`, ...) before each
  /// operation; a throw from it fails that operation, as a crash or an IO error would.
  @visibleForTesting
  void Function(String operation)? failBefore;

  /// Every record, by key.
  Map<EntityKey, EntityRecord> get records => Map.unmodifiable(_records);

  /// Every outbox entry appended and not rejected, synced or not, in append order.
  List<ChangeLogEntry> get outbox => List.unmodifiable(_outbox);

  /// The entries taken out of the outbox by [markRejected], with their reasons.
  List<(ChangeLogEntry, PushRejectionReason)> get rejected =>
      List.unmodifiable(_rejected);

  @override
  Future<T> transaction<T>(Future<T> Function() body) {
    if (Zone.current[_inTransaction] == true) return body();
    return _locked(() async {
      final records = _records;
      final outbox = _outbox;
      final rejected = _rejected;
      final cursor = _cursor;
      final clock = _clock;
      _records = {...records};
      _outbox = [...outbox];
      try {
        return await runZoned(body, zoneValues: {_inTransaction: true});
      } catch (_) {
        _records = records;
        _outbox = outbox;
        _rejected = rejected;
        _cursor = cursor;
        _clock = clock;
        rethrow;
      }
    });
  }

  Future<T> _locked<T>(Future<T> Function() body) {
    final result = _tail.then((_) => body());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<T> _op<T>(String name, T Function() body) {
    Future<T> run() async {
      failBefore?.call(name);
      return body();
    }

    return Zone.current[_inTransaction] == true ? run() : _locked(run);
  }

  @override
  Future<EntityRecord?> read(EntityType type, String id) =>
      _op('read', () => _records[(type: type, id: id)]);

  @override
  Future<void> write(EntityRecord record) =>
      _op('write', () => _records[record.key] = record);

  @override
  Future<List<ChangeLogEntry>> unsynced({int limit = 200}) => _op(
    'unsynced',
    () =>
        (_outbox.where((e) => !e.synced).toList()
              ..sort((a, b) => a.hlc.compareTo(b.hlc)))
            .take(limit)
            .toList(),
  );

  @override
  Future<void> markSynced(Iterable<Hlc> hlcs) => _op('markSynced', () {
    final set = hlcs.toSet();
    _outbox = [
      for (final e in _outbox)
        set.contains(e.hlc) ? e.copyWith(synced: true) : e,
    ];
  });

  @override
  Future<void> markRejected(Iterable<Hlc> hlcs, PushRejectionReason reason) =>
      _op('markRejected', () {
        final set = hlcs.toSet();
        _rejected = [
          ..._rejected,
          for (final e in _outbox)
            if (set.contains(e.hlc)) (e, reason),
        ];
        _outbox = [
          for (final e in _outbox)
            if (!set.contains(e.hlc)) e,
        ];
      });

  @override
  Future<void> append(ChangeLogEntry entry) => _op(
    'append',
    () => _outbox = [..._outbox, entry.copyWith(synced: false)],
  );

  @override
  Future<int?> pullCursor() => _op('pullCursor', () => _cursor);

  @override
  Future<void> savePullCursor(int seq) =>
      _op('savePullCursor', () => _cursor = seq);

  @override
  Future<Hlc?> lastClock() => _op('lastClock', () => _clock);

  @override
  Future<void> saveClock(Hlc clock) => _op('saveClock', () => _clock = clock);
}
