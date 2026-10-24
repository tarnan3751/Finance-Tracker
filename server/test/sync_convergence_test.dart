// Two SyncSessions from packages/sync_engine converge through the server's relay (called
// through the shelf handler), and the same script run against InMemorySyncRelay ends in
// the same records with the same session reports: the server's relay is equivalent to the
// engine's reference relay.
import 'dart:math';

import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

import 'support/shelf_sync_relay.dart';
import 'support/test_server.dart';

/// One device of a run.
final class _Device {
  _Device(this.id, SyncRelay relay, this.now) {
    clock = HlcClock(id);
    editor = LocalEditor(store, clock);
    session = SyncSession(
      store,
      relay,
      clock,
      nowWallMillis: now,
      pushBatchSize: 3,
      pullPageSize: 3,
    );
  }

  final String id;
  final int Function() now;
  final store = InMemorySyncStore();
  late final HlcClock clock;
  late final LocalEditor editor;
  late final SyncSession session;

  String state() => ([
    for (final r in store.records.values) r.toCanonicalJson(),
  ]..sort()).join('\n');
}

/// One step of a script: device [device] does [op] on entity [id].
typedef _Step = ({int device, String op, String id, String value});

/// Runs [script] on two devices named [ids] against [relayFor] and returns the final
/// states and a trace of every session report.
Future<({List<String> states, List<String> trace})> _run(
  List<_Step> script,
  List<String> ids,
  SyncRelay Function(int device) relayFor,
  TestClock clock,
) async {
  int now() => clock.value.millisecondsSinceEpoch;
  final devices = [
    for (var i = 0; i < 2; i++) _Device(ids[i], relayFor(i), now),
  ];
  final trace = <String>[];
  Future<void> sync(_Device d) async {
    final r = await d.session.run();
    trace.add(
      '${d.id}: pushed ${r.pushed} pulled ${r.pulled} applied ${r.applied} '
      'rejected ${r.rejected.length} changed ${r.changed.length}',
    );
  }

  for (final step in script) {
    clock.advance(const Duration(milliseconds: 7));
    final d = devices[step.device];
    const type = EntityType.category;
    final before = (await d.store.read(type, step.id))?.fields;
    switch (step.op) {
      case 'sync':
        await sync(d);
      case 'edit':
        await d.editor.recordChange(type, step.id, before, {
          ...?before,
          'id': step.id,
          'name': step.value,
          if (before == null) 'deleted_at': null,
        }, now());
      case 'tags':
        await d.editor.recordChange(type, step.id, before, {
          ...?before,
          'id': step.id,
          'tags': [step.value, 'x'],
          if (before == null) 'deleted_at': null,
        }, now());
      case 'delete' when before != null && before['deleted_at'] == null:
        await d.editor.recordChange(type, step.id, before, {
          ...before,
          'deleted_at': 'deleted',
        }, now());
      case 'restore' when before != null && before['deleted_at'] != null:
        await d.editor.recordChange(type, step.id, before, {
          ...before,
          'deleted_at': null,
        }, now());
      default:
        break;
    }
  }
  // A final round without edits, twice so every device sees everything.
  for (var round = 0; round < 2; round++) {
    for (final d in devices) {
      clock.advance(const Duration(milliseconds: 7));
      await sync(d);
    }
  }
  return (states: [for (final d in devices) d.state()], trace: trace);
}

Future<void> _check(List<_Step> script) async {
  final server = await TestServer.start();
  final sessions = [await server.register(), await server.login()];
  final ids = [for (final s in sessions) s.deviceId];
  final start = server.clock.value;

  final viaServer = await _run(
    script,
    ids,
    (i) => ShelfSyncRelay(server, sessions[i].access),
    server.clock,
  );

  final referenceClock = TestClock(start);
  final reference = InMemorySyncRelay(
    nowWallMillis: () => referenceClock.value.millisecondsSinceEpoch,
  );
  final viaReference = await _run(
    script,
    ids,
    (_) => reference,
    referenceClock,
  );

  expect(viaServer.states[0], viaServer.states[1], reason: 'devices diverged');
  expect(viaServer.states[0], isNotEmpty);
  expect(viaServer.trace.where((t) => !t.contains('pulled 0 ')), isNotEmpty);
  expect(viaServer.states, viaReference.states);
  expect(viaServer.trace, viaReference.trace);
}

void main() {
  test(
    'a scripted scenario converges as through the reference relay',
    () async {
      final script = <_Step>[
        (device: 0, op: 'edit', id: 'food', value: 'Food'),
        (device: 0, op: 'edit', id: 'rent', value: 'Rent'),
        (device: 0, op: 'edit', id: 'fun', value: 'Fun'),
        (device: 0, op: 'edit', id: 'pets', value: 'Pets'),
        (device: 0, op: 'sync', id: '', value: ''),
        (device: 1, op: 'sync', id: '', value: ''),
        // Concurrent edits of different fields and of the same field.
        (device: 0, op: 'edit', id: 'food', value: 'Groceries'),
        (device: 1, op: 'tags', id: 'food', value: 'weekly'),
        (device: 1, op: 'edit', id: 'rent', value: 'Housing'),
        (device: 0, op: 'edit', id: 'rent', value: 'Home'),
        // A delete against a concurrent edit: the tombstone wins.
        (device: 0, op: 'delete', id: 'fun', value: ''),
        (device: 1, op: 'edit', id: 'fun', value: 'Leisure'),
        // Both devices exchange everything.
        (device: 1, op: 'sync', id: '', value: ''),
        (device: 0, op: 'sync', id: '', value: ''),
        (device: 1, op: 'sync', id: '', value: ''),
        // A restore after the delete.
        (device: 1, op: 'restore', id: 'fun', value: ''),
        (device: 1, op: 'sync', id: '', value: ''),
      ];
      await _check(script);
    },
  );

  test(
    'a short random scenario converges as through the reference relay',
    () async {
      final random = Random(20261024);
      const ops = ['edit', 'edit', 'tags', 'delete', 'restore', 'sync', 'sync'];
      final script = [
        for (var i = 0; i < 60; i++)
          (
            device: random.nextInt(2),
            op: ops[random.nextInt(ops.length)],
            id: 'c${random.nextInt(6)}',
            value: 'v${random.nextInt(4)}',
          ),
      ];
      await _check(script);
    },
  );
}
