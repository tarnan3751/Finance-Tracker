// LocalEditor.recordChanges is recordChange in a batch: over a random history of local
// edits and merged remote entries (clocks behind, ahead and beyond the bound among them),
// a random batch of creates, edits, deletes, restores and no-ops on distinct entities
// recorded with one recordChanges leaves the same records, outbox, clock and entries as
// the same changes recorded one recordChange at a time, on the in-memory store and on a
// store that reads values from the host's rows as the app's does (RowStore); and a batch
// that fails part-way leaves nothing. Deterministic: `Random(seed)` with the default seed
// 20261101; set SYNC_ENGINE_SEED to explore. A failure names the seed and the case.
import 'dart:io';
import 'dart:math';

import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

import 'local_editor_test.dart' show RowStore;

final int seed =
    int.tryParse(Platform.environment['SYNC_ENGINE_SEED'] ?? '') ?? 20261101;
const int cases = 400;

const EntityType _type = EntityType.budget;
const List<String> _ids = ['b0', 'b1', 'b2', 'b3', 'b4', 'b5'];
const int _start = 1761318000000; // 2026-10-24 15:00 UTC

Map<String, Object?> _fields(Random r, String id) => {
  'id': id,
  'name': r.nextInt(5) == 0 ? null : 'name${r.nextInt(4)}',
  'amount': {'minor_units': r.nextInt(3) * 1000, 'currency': 'USD'},
  'tags': [for (var i = 0; i < r.nextInt(3); i++) 't${r.nextInt(3)}'],
  'deleted_at': null,
};

/// One device: a store, the host's view of each entity (what its row holds), its clock.
final class _Device {
  _Device({required this.rows})
    : store = rows ? RowStore() : InMemorySyncStore(),
      clock = HlcClock('dev-a');

  final bool rows;
  final SyncStore store;
  final HlcClock clock;
  final Map<String, Map<String, Object?>> host = {};
  int wall = _start;

  LocalEditor get editor => LocalEditor(store, clock);

  int now() => wall += 7;

  // What the host writes before recording, as the app's repositories do.
  void writeRow(String id, Map<String, Object?> after) {
    host[id] = after;
    if (store case final RowStore s) {
      s.rows[(type: _type, id: id)] = {
        ...?s.rows[(type: _type, id: id)],
        ...after,
      };
    }
  }

  Future<void> local(
    String id,
    Map<String, Object?>? b,
    Map<String, Object?> a,
  ) {
    writeRow(id, a);
    return editor.recordChange(_type, id, b, a, now());
  }

  Future<void> remote(ChangeLogEntry e) => store.transaction(() async {
    clock.receive(e.hlc, now());
    final out = merge(await store.read(_type, e.entityId), e);
    if (out.applied) await store.write(out.record);
    host[e.entityId] = {...?host[e.entityId], ...out.record.fields};
  });

  Future<Map<String, EntityRecord>> records() => store.readAll(_type, _ids);
}

// The same history on both devices: local edits and remote entries.
Future<void> _history(Random r, List<_Device> devices) async {
  final steps = r.nextInt(12);
  var remoteCounter = 0;
  for (var s = 0; s < steps; s++) {
    final id = _ids[r.nextInt(_ids.length)];
    final known = devices.first.host[id];
    if (r.nextBool()) {
      final after = _fields(r, id);
      for (final d in devices) {
        await d.local(id, known, after);
      }
    } else {
      // Behind, near, ahead of and beyond the bound from the device's time.
      final offset = [-60000, 0, 120000, 2 * 3600 * 1000][r.nextInt(4)];
      final hlc = Hlc(
        devices.first.wall + offset,
        remoteCounter++,
        r.nextBool() ? 'dev-b' : 'dev-c',
      );
      final create = known == null || r.nextInt(4) == 0;
      final payload = {..._fields(r, id)};
      if (create) {
        payload.remove('deleted_at');
      } else if (r.nextInt(3) == 0) {
        payload['deleted_at'] = '2026-10-24T15:00:00.000Z';
      }
      final e = ChangeLogEntry(
        entityType: _type,
        entityId: id,
        operation: create
            ? ChangeOperation.create
            : (payload['deleted_at'] != null
                  ? ChangeOperation.delete
                  : ChangeOperation.update),
        payload: payload,
        hlc: hlc,
        deviceId: hlc.nodeId,
        synced: true,
      );
      for (final d in devices) {
        await d.remote(e);
      }
    }
  }
}

// A batch on distinct entities: creates, edits from the host's view or a stale one,
// deletes, restores and no-ops.
List<LocalChange> _batch(Random r, _Device d) {
  final ids = [..._ids]..shuffle(r);
  return [
    for (final id in ids.take(r.nextInt(_ids.length) + 1))
      () {
        final known = d.host[id];
        if (known == null || r.nextInt(6) == 0) {
          return (id: id, before: null, after: _fields(r, id));
        }
        final before = r.nextInt(5) == 0 ? _fields(r, id) : known;
        final after = switch (r.nextInt(5)) {
          0 => {...before}, // a no-op
          1 => {...before, 'deleted_at': '2026-10-24T16:00:00.000Z'},
          2 => {...before, 'deleted_at': null},
          _ => {..._fields(r, id), 'deleted_at': before['deleted_at']},
        };
        return (id: id, before: before, after: after);
      }(),
  ];
}

void main() {
  for (final rows in [false, true]) {
    final name = rows ? 'a store reading the host rows' : 'the in-memory store';
    test('recordChanges equals recordChange one at a time, on $name', () async {
      for (var c = 0; c < cases; c++) {
        final r = Random(seed * 31 + c);
        final one = _Device(rows: rows);
        final batch = _Device(rows: rows);
        await _history(r, [one, batch]);
        final changes = _batch(r, one);
        final reason = 'seed $seed, case $c';

        final single = <ChangeLogEntry?>[];
        for (final ch in changes) {
          one.writeRow(ch.id, ch.after);
          single.add(
            await one.editor.recordChange(
              _type,
              ch.id,
              ch.before,
              ch.after,
              one.now(),
            ),
          );
        }
        for (final ch in changes) {
          batch.writeRow(ch.id, ch.after);
        }
        final batched = await batch.editor.recordChanges(
          _type,
          changes,
          batch.now,
        );

        expect(batched, single, reason: reason);
        expect(await batch.records(), await one.records(), reason: reason);
        expect(
          await batch.store.unsynced(limit: 1000),
          await one.store.unsynced(limit: 1000),
          reason: reason,
        );
        expect(
          await batch.store.lastClock(),
          await one.store.lastClock(),
          reason: reason,
        );
        expect(batch.clock.last, one.clock.last, reason: reason);
      }
    });
  }

  test('a batch that fails part-way leaves nothing', () async {
    for (var c = 0; c < 50; c++) {
      final r = Random(seed * 17 + c);
      final d = _Device(rows: false);
      await _history(r, [d]);
      final store = d.store as InMemorySyncStore;
      final records = await d.records();
      final outbox = await store.unsynced(limit: 1000);
      final clock = await store.lastClock();
      final changes = _batch(r, d);
      var writes = 0;
      store.failBefore = (op) {
        if (op == 'append' && ++writes == 1) throw StateError('io');
      };
      final List<ChangeLogEntry?>? entries = await d.editor
          .recordChanges(_type, changes, d.now)
          .then<List<ChangeLogEntry?>?>((e) => e, onError: (Object _) => null);
      store.failBefore = null;
      if (entries != null) {
        // Nothing to append: every change was a no-op.
        expect(entries.nonNulls, isEmpty, reason: 'seed $seed, case $c');
        continue;
      }
      expect(await d.records(), records, reason: 'seed $seed, case $c');
      expect(await store.unsynced(limit: 1000), outbox);
      expect(await store.lastClock(), clock);
    }
  });

  test('two changes to one entity are refused, in the future', () async {
    final d = _Device(rows: false);
    final change = (id: 'b0', before: null, after: _fields(Random(1), 'b0'));
    final Future<List<ChangeLogEntry?>> refused = d.editor.recordChanges(
      _type,
      [change, change],
      d.now,
    );
    await expectLater(refused, throwsArgumentError);
    expect(await d.store.unsynced(), isEmpty);
  });
}
