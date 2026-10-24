// The HTTP relay over stub endpoints: push and pull pass through in the engine's types,
// a pull for another device is refused, and the API's sync_cursor_invalid becomes the
// engine's exception; and a session runs through it.
import 'package:finance_tracker/core/api/problems.dart';
import 'package:finance_tracker/core/sync/http_sync_relay.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

/// Endpoints over an in-memory relay as device [device], counting calls.
final class StubEndpoints implements SyncEndpoints {
  StubEndpoints(this.relay, this.device);

  final InMemorySyncRelay relay;
  final String device;
  final List<int> pulls = [];
  Object? failNextPull;

  @override
  Future<PushResult> pushChanges(List<ChangeLogEntry> entries) =>
      relay.push(entries);

  @override
  Future<PullPage> pullChanges({required int since, required int limit}) async {
    pulls.add(since);
    final Object? failure = failNextPull;
    if (failure != null) {
      failNextPull = null;
      throw failure;
    }
    return relay.pull(since: since, limit: limit, deviceId: device);
  }
}

ChangeLogEntry entry(String device, int wall) => ChangeLogEntry(
  entityType: EntityType.category,
  entityId: 'c1',
  operation: ChangeOperation.create,
  payload: const {'name': 'Hobbies'},
  hlc: Hlc(wall, 0, device),
  deviceId: device,
  synced: false,
);

void main() {
  late InMemorySyncRelay server;

  setUp(() => server = InMemorySyncRelay(nowWallMillis: () => 1000000));

  test('push and pull pass through', () async {
    final HttpSyncRelay a = HttpSyncRelay(
      StubEndpoints(server, 'dev-a'),
      deviceId: 'dev-a',
    );
    final HttpSyncRelay b = HttpSyncRelay(
      StubEndpoints(server, 'dev-b'),
      deviceId: 'dev-b',
    );
    final PushResult pushed = await a.push([entry('dev-a', 10)]);
    expect(pushed.accepted, [Hlc(10, 0, 'dev-a')]);
    final PullPage page = await b.pull(since: 0, deviceId: 'dev-b');
    expect(page.entries.single.hlc, Hlc(10, 0, 'dev-a'));
    expect(page.nextSince, 1);
    expect(page.hasMore, isFalse);
  });

  test('a pull for another device is refused', () {
    final HttpSyncRelay a = HttpSyncRelay(
      StubEndpoints(server, 'dev-a'),
      deviceId: 'dev-a',
    );
    expect(() => a.pull(since: 0, deviceId: 'dev-b'), throwsArgumentError);
  });

  test("the API's sync_cursor_invalid is the engine's exception", () async {
    final StubEndpoints endpoints = StubEndpoints(server, 'dev-a')
      ..failNextPull = const SyncCursorInvalid(since: 12);
    final HttpSyncRelay a = HttpSyncRelay(endpoints, deviceId: 'dev-a');
    await expectLater(
      a.pull(since: 12, deviceId: 'dev-a'),
      throwsA(
        isA<SyncCursorInvalidException>()
            .having((e) => e.since, 'since', 12)
            .having((e) => e.lastSeq, 'lastSeq', 0),
      ),
    );
    endpoints.failNextPull = const NetworkError(NetworkErrorKind.timeout);
    await expectLater(
      a.pull(since: 0, deviceId: 'dev-a'),
      throwsA(isA<NetworkError>()),
    );
  });

  test('a session runs through it and recovers from a reset server', () async {
    final InMemorySyncStore store = InMemorySyncStore();
    final HlcClock clock = HlcClock('dev-a');
    final StubEndpoints endpoints = StubEndpoints(server, 'dev-a');
    final HttpSyncRelay relay = HttpSyncRelay(endpoints, deviceId: 'dev-a');
    await LocalEditor(store, clock).recordChange(
      EntityType.category,
      'c1',
      null,
      const {'name': 'Hobbies'},
      1000,
    );
    final SyncReport report = await SyncSession(
      store,
      relay,
      clock,
      nowWallMillis: () => 1000,
    ).run();
    expect(report.pushed, 1);
    await store.savePullCursor(40);
    endpoints.failNextPull = const SyncCursorInvalid(since: 40);
    await expectLater(
      SyncSession(store, relay, clock, nowWallMillis: () => 1001).run(),
      throwsA(isA<SyncCursorInvalidException>()),
    );
  });
}
