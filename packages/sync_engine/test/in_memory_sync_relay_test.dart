// The in-memory relay, the reference for the SyncRelay contract: seq order and paging,
// idempotent resends, the rejection reasons, the JSON round trip, and pulls that skip
// the caller's own entries while their cursor passes them.
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

const hour = 3600 * 1000;

ChangeLogEntry entry(
  String device,
  int wall, {
  ChangeOperation op = ChangeOperation.update,
  Map<String, Object?> payload = const {'name': 'x'},
  String? nodeId,
}) => ChangeLogEntry(
  entityType: EntityType.recurringStream,
  entityId: 's1',
  operation: op,
  payload: payload,
  hlc: Hlc(wall, 0, nodeId ?? device),
  deviceId: device,
  synced: false,
);

void main() {
  late InMemorySyncRelay relay;
  setUp(() => relay = InMemorySyncRelay(nowWallMillis: () => 1000));

  test('accepted entries are stored once each, in push order', () async {
    final r = await relay.push([entry('a', 1), entry('b', 2), entry('a', 3)]);
    expect(r.accepted, [Hlc(1, 0, 'a'), Hlc(2, 0, 'b'), Hlc(3, 0, 'a')]);
    expect(r.rejected, isEmpty);
    expect(relay.entries.map((e) => e.hlc.wallMillis), [1, 2, 3]);
    expect(relay.entries.every((e) => e.synced), isTrue);
  });

  test('a resent entry is accepted again without a new seq', () async {
    await relay.push([entry('a', 1)]);
    final r = await relay.push([
      entry('a', 1),
      entry('a', 1).copyWith(synced: true),
    ]);
    expect(r.accepted, [Hlc(1, 0, 'a'), Hlc(1, 0, 'a')]);
    expect(relay.entries, hasLength(1));
  });

  test(
    'another payload under a stored clock is a conflicting duplicate',
    () async {
      await relay.push([entry('a', 1)]);
      final r = await relay.push([
        entry('a', 1, payload: const {'name': 'other'}),
      ]);
      expect(r.accepted, isEmpty);
      expect(
        r.rejected.single.reason,
        PushRejectionReason.conflictingDuplicate,
      );
      expect(relay.entries.single.payload, {'name': 'x'});
    },
  );

  test('malformed entries are invalid', () async {
    final r = await relay.push([
      entry('a', 1, nodeId: 'b'),
      entry('a', 2, payload: const {}),
      entry('a', 3, op: ChangeOperation.delete, payload: const {'notes': 'x'}),
      entry(
        'a',
        4,
        op: ChangeOperation.delete,
        payload: const {'deleted_at': '2026-10-24'},
      ),
      entry(
        'a',
        5,
        op: ChangeOperation.delete,
        payload: const {'deleted_at': '2026-10-24T00:00:00.000Z'},
      ),
    ]);
    expect(
      r.rejected.map((x) => x.reason),
      List.filled(4, PushRejectionReason.invalid),
    );
    expect(r.accepted, [Hlc(5, 0, 'a')]);
  });

  test('an entry more than maxDrift ahead of the relay is rejected', () async {
    final r = await relay.push([
      entry('a', 1000 + hour + 1),
      entry('a', 1000 + hour),
    ]);
    expect(r.rejected.single.reason, PushRejectionReason.clockDrift);
    expect(r.rejected.single.hlc, Hlc(1000 + hour + 1, 0, 'a'));
    expect(r.accepted, [Hlc(1000 + hour, 0, 'a')]);
  });

  test('pull pages by seq and round-trips entries through JSON', () async {
    final payload = {
      'amount': {'minor_units': -5, 'currency': 'USD'},
      'tags': ['a', 'b'],
    };
    await relay.push([
      for (var w = 1; w <= 5; w++) entry('a', w, payload: payload),
    ]);
    var page = await relay.pull(since: 0, limit: 2, deviceId: 'z');
    expect(page.entries.map((e) => e.hlc.wallMillis), [1, 2]);
    expect((page.nextSince, page.hasMore), (2, true));
    expect(page.entries.first.payload, payload);
    page = await relay.pull(since: 2, limit: 2, deviceId: 'z');
    expect((page.entries.length, page.nextSince, page.hasMore), (2, 4, true));
    page = await relay.pull(since: 4, limit: 2, deviceId: 'z');
    expect((page.entries.length, page.nextSince, page.hasMore), (1, 5, false));
    page = await relay.pull(since: 5, limit: 2, deviceId: 'z');
    expect((page.entries.length, page.nextSince, page.hasMore), (0, 5, false));
  });

  test(
    "pull skips the caller's own entries and its cursor passes them",
    () async {
      await relay.push([
        entry('a', 1),
        entry('b', 2),
        entry('a', 3),
        entry('b', 4),
        entry('a', 5),
      ]);
      var page = await relay.pull(since: 0, limit: 1, deviceId: 'a');
      expect(page.entries.map((e) => e.hlc), [Hlc(2, 0, 'b')]);
      expect((page.nextSince, page.hasMore), (3, true));
      page = await relay.pull(since: page.nextSince, limit: 1, deviceId: 'a');
      expect(page.entries.map((e) => e.hlc), [Hlc(4, 0, 'b')]);
      expect(
        (page.nextSince, page.hasMore),
        (5, false),
        reason: 'passes the trailing own entry',
      );
      page = await relay.pull(since: 0, limit: 10, deviceId: 'b');
      expect(page.entries.map((e) => e.hlc.wallMillis), [1, 3, 5]);
    },
  );

  test('a device that pushed everything pulls nothing but advances', () async {
    await relay.push([entry('a', 1), entry('a', 2)]);
    final page = await relay.pull(since: 0, deviceId: 'a');
    expect(page.entries, isEmpty);
    expect((page.nextSince, page.hasMore), (2, false));
  });

  test('fold merges every stored entry', () async {
    await relay.push([
      entry(
        'a',
        1,
        op: ChangeOperation.create,
        payload: const {'name': 'one', 'notes': null},
      ),
      entry('b', 2, payload: const {'notes': 'n'}),
    ]);
    final rec = relay.fold()[(type: EntityType.recurringStream, id: 's1')]!;
    expect(rec.fields, {'name': 'one', 'notes': 'n'});
  });

  test('a cursor past the end of the log is invalid', () async {
    await relay.push([entry('a', 1), entry('a', 2)]);
    expect((await relay.pull(since: 2, deviceId: 'z')).entries, isEmpty);
    await expectLater(
      relay.pull(since: 3, deviceId: 'z'),
      throwsA(
        isA<SyncCursorInvalidException>()
            .having((e) => e.since, 'since', 3)
            .having((e) => e.lastSeq, 'lastSeq', 2),
      ),
    );
  });
}
