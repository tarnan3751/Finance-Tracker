// Two SyncSessions from packages/sync_engine converge through the server's relay (called
// through the shelf handler), and the same script run against InMemorySyncRelay ends in
// the same records with the same session reports: the server's relay is equivalent to the
// engine's reference relay, clocks hours apart included (a device ahead refused for drift
// until its entries fall within the bound, a device behind clamping what it receives and
// stamping an edit past the value it changes).
import 'dart:math';

import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

import 'support/shelf_sync_relay.dart';
import 'support/test_server.dart';

/// One device of a run.
final class _Device {
  _Device(this.id, SyncRelay relay, int Function() trueNow) {
    now = () => trueNow() + skew;
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

  /// How far this device's wall clock is from true time, in milliseconds.
  int skew = 0;
  late final int Function() now;
  final store = InMemorySyncStore();
  late final HlcClock clock;
  late final LocalEditor editor;
  late final SyncSession session;

  String state() => ([
    for (final r in store.records.values) r.toCanonicalJson(),
  ]..sort()).join('\n');
}

/// One step of a script: device [device] does [op] on entity [id]; `skew` sets the
/// device's clock [value] hours from true time, `wait` lets [value] hours pass.
typedef _Step = ({int device, String op, String id, String value});

/// Runs [script] on two devices named [ids] against [relayFor] and returns the final
/// states and a trace of every session report.
Future<({List<String> states, List<String> trace})> _run(
  List<_Step> script,
  List<String> ids,
  SyncRelay Function(int device) relayFor,
  TestClock clock, {
  Future<void> Function()? afterWait,
}) async {
  int now() => clock.value.millisecondsSinceEpoch;
  final devices = [
    for (var i = 0; i < 2; i++) _Device(ids[i], relayFor(i), now),
  ];
  final trace = <String>[];
  Future<void> sync(_Device d) async {
    final r = await d.session.run();
    trace.add(
      '${d.id}: pushed ${r.pushed} pulled ${r.pulled} applied ${r.applied} '
      'rejected ${r.rejected.length} changed ${r.changed.length} '
      'clamped ${r.clamped}',
    );
  }

  for (final step in script) {
    clock.advance(const Duration(milliseconds: 7));
    final d = devices[step.device];
    const type = EntityType.category;
    final before = (await d.store.read(type, step.id))?.fields;
    switch (step.op) {
      case 'skew':
        d.skew = int.parse(step.value) * _hour;
      case 'wait':
        clock.advance(Duration(hours: int.parse(step.value)));
        await afterWait?.call();
      case 'sync':
        await sync(d);
      case 'edit':
        await d.editor.recordChange(type, step.id, before, {
          ...?before,
          'id': step.id,
          'name': step.value,
          if (before == null) 'deleted_at': null,
        }, d.now());
      case 'tags':
        await d.editor.recordChange(type, step.id, before, {
          ...?before,
          'id': step.id,
          'tags': [step.value, 'x'],
          if (before == null) 'deleted_at': null,
        }, d.now());
      case 'delete' when before != null && before['deleted_at'] == null:
        await d.editor.recordChange(type, step.id, before, {
          ...before,
          'deleted_at': 'deleted',
        }, d.now());
      case 'restore' when before != null && before['deleted_at'] != null:
        await d.editor.recordChange(type, step.id, before, {
          ...before,
          'deleted_at': null,
        }, d.now());
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

const _hour = 3600 * 1000;

Future<({List<String> states, List<String> trace})> _check(
  List<_Step> script,
) async {
  final server = await TestServer.start();
  final sessions = [await server.register(), await server.login()];
  final ids = [for (final s in sessions) s.deviceId];
  final start = server.clock.value;

  final relays = [for (final s in sessions) ShelfSyncRelay(server, s.access)];
  final viaServer = await _run(
    script,
    ids,
    (i) => relays[i],
    server.clock,
    // Hours passing expire the access tokens; the devices refresh them as the app does.
    afterWait: () async {
      for (var i = 0; i < sessions.length; i++) {
        final r = await server.call(
          'post',
          '/auth/refresh',
          body: {'refresh_token': sessions[i].refresh},
        );
        expect(r.status, 200);
        sessions[i] = Session(r.json);
        relays[i].accessToken = sessions[i].access;
      }
    },
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
  return viaServer;
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

  test('a device three hours ahead is refused for drift, keeps its change '
      'queued, and wins once it falls within the bound', () async {
    final run = await _check(const [
      (device: 0, op: 'skew', id: '', value: '3'),
      (device: 0, op: 'edit', id: 'food', value: 'Ahead'),
      (device: 0, op: 'sync', id: '', value: ''),
      (device: 1, op: 'edit', id: 'food', value: 'Now'),
      (device: 1, op: 'sync', id: '', value: ''),
      (device: 0, op: 'sync', id: '', value: ''),
      // The clock is set right; its entry, stamped three hours ahead, waits until it
      // is within an hour of the relay's time.
      (device: 0, op: 'skew', id: '', value: '0'),
      (device: 0, op: 'sync', id: '', value: ''),
      (device: 0, op: 'wait', id: '', value: '3'),
      (device: 0, op: 'sync', id: '', value: ''),
    ]);
    expect(
      run.trace.first,
      contains(': pushed 0 pulled 0 applied 0 rejected 1 '),
      reason: 'refused for drift, nothing else to do',
    );
    expect(run.trace.where((t) => t.contains('rejected 1')), hasLength(3));
    expect(run.states[0], contains('"Ahead"'));
    expect(run.states[0], isNot(contains('"Now"')));
  });

  test('a device three hours behind clamps what it receives, and its later '
      'edit of that value wins without being refused', () async {
    final run = await _check(const [
      (device: 1, op: 'skew', id: '', value: '-3'),
      (device: 0, op: 'edit', id: 'food', value: 'Seen'),
      (device: 0, op: 'sync', id: '', value: ''),
      (device: 1, op: 'sync', id: '', value: ''),
      (device: 1, op: 'edit', id: 'food', value: 'Edited after'),
      (device: 1, op: 'sync', id: '', value: ''),
      (device: 0, op: 'sync', id: '', value: ''),
    ]);
    expect(run.trace[1], contains('pulled 1 applied 1 rejected 0'));
    expect(run.trace[1], endsWith('clamped 1'));
    expect(run.trace[2], contains('pushed 1 pulled 0 applied 0 rejected 0'));
    expect(run.states[0], contains('"Edited after"'));
    expect(run.states[0], isNot(contains('"Seen"')));
  });

  test('a random scenario with clocks hours apart and long partitions '
      'converges as through the reference relay', () async {
    final random = Random(20261030);
    const ops = ['edit', 'edit', 'tags', 'delete', 'restore', 'sync', 'skew'];
    final script = <_Step>[(device: 1, op: 'skew', id: '', value: '-5')];
    for (var i = 0; i < 80; i++) {
      final device = random.nextInt(2);
      // One device at a time is cut off for a long stretch: it edits but never syncs.
      final cut = i ~/ 20 % 2 == 0 ? 0 : 1;
      var op = ops[random.nextInt(ops.length)];
      if (op == 'sync' && device == cut && i % 20 < 15) op = 'edit';
      script.add((
        device: device,
        op: op,
        id: 'c${random.nextInt(4)}',
        // Device 0's clock is right or up to five hours ahead, device 1's three to
        // six hours behind.
        value: op == 'skew'
            ? '${device == 0 ? random.nextInt(6) : -3 - random.nextInt(4)}'
            : 'v${random.nextInt(4)}',
      ));
      if (random.nextInt(20) == 0) {
        script.add((device: 0, op: 'wait', id: '', value: '1'));
      }
    }
    // Every clock set right and time past every entry stamped ahead.
    script.addAll(const [
      (device: 0, op: 'skew', id: '', value: '0'),
      (device: 1, op: 'skew', id: '', value: '0'),
      (device: 0, op: 'wait', id: '', value: '7'),
    ]);
    final run = await _check(script);
    expect(run.trace.where((t) => !t.contains('clamped 0')), isNotEmpty);
    expect(run.trace.where((t) => !t.contains('rejected 0')), isNotEmpty);
  });
}
