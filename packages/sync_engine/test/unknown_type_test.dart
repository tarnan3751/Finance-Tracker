// Entries of a type this build does not know: merged under their raw type by the rules
// of merge (whatever the order, a create's deleted_at ignored), and a pulled page holding
// one applies the rest, holds it, receives its clock and advances the cursor; a page
// whose unknown entry is too far ahead is blocked like any other.
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';
import 'package:test/test.dart';

UnknownTypeEntry unknown(
  int wall,
  ChangeOperation operation,
  Map<String, dynamic> payload, {
  String id = 'p1',
  String node = 'dev-b',
}) => UnknownTypeEntry(
  entityType: 'future_type',
  entityId: id,
  operation: operation,
  payload: payload,
  hlc: Hlc(wall, 0, node),
  deviceId: node,
);

ChangeLogEntry known(int wall, String id) => ChangeLogEntry(
  entityType: EntityType.category,
  entityId: id,
  operation: ChangeOperation.create,
  payload: {'id': id, 'name': 'Food'},
  hlc: Hlc(wall, 0, 'dev-b'),
  deviceId: 'dev-b',
  synced: true,
);

/// A relay that serves [pages] in turn, from cursor 0.
final class _PagedRelay implements SyncRelay {
  _PagedRelay(this.pages);

  final List<PullPage> pages;

  @override
  Future<PushResult> push(List<ChangeLogEntry> entries) async =>
      const PushResult(accepted: [], rejected: []);

  @override
  Future<PullPage> pull({
    required int since,
    int limit = 200,
    required String deviceId,
  }) async => pages[since];
}

void main() {
  group('mergeUnknownType', () {
    final List<UnknownTypeEntry> entries = [
      unknown(10, ChangeOperation.create, {
        'id': 'p1',
        'name': 'a',
        'deleted_at': '2026-10-01T00:00:00.000Z',
      }),
      unknown(20, ChangeOperation.update, {'name': 'b'}),
      unknown(15, ChangeOperation.update, {'note': 'n'}),
      unknown(30, ChangeOperation.delete, {
        'deleted_at': '2026-10-02T00:00:00.000Z',
      }),
    ];

    UnknownTypeRecord fold(Iterable<UnknownTypeEntry> order) {
      UnknownTypeRecord? r;
      for (final UnknownTypeEntry e in order) {
        r = mergeUnknownType(r, e);
      }
      return r!;
    }

    test('folds as merge does, in any order, idempotently', () {
      final UnknownTypeRecord forward = fold(entries);
      expect(forward.fields, {
        'id': 'p1',
        'name': 'b',
        'note': 'n',
        'deleted_at': '2026-10-02T00:00:00.000Z',
      });
      expect(forward.createdAt, Hlc(10, 0, 'dev-b'));
      expect(forward.fieldClocks['name'], Hlc(20, 0, 'dev-b'));
      for (final List<UnknownTypeEntry> order in [
        entries.reversed.toList(),
        [...entries, ...entries],
        [entries[2], entries[0], entries[3], entries[1]],
      ]) {
        final UnknownTypeRecord other = fold(order);
        expect(other.fields, forward.fields);
        expect(other.fieldClocks, forward.fieldClocks);
        expect(other.createdAt, forward.createdAt);
      }
    });

    test('folds to what merge gives once the type is known', () {
      EntityRecord? record;
      for (final UnknownTypeEntry e in entries) {
        record = merge(
          record,
          ChangeLogEntry(
            entityType: EntityType.category,
            entityId: e.entityId,
            operation: e.operation,
            payload: e.payload,
            hlc: e.hlc,
            deviceId: e.deviceId,
            synced: true,
          ),
        ).record;
      }
      final UnknownTypeRecord held = fold(entries);
      expect(held.fields, record!.fields);
      expect(held.fieldClocks, record.fieldClocks);
      expect(held.createdAt, record.createdAt);
    });

    test('refuses another entity', () {
      expect(
        () => mergeUnknownType(
          fold(entries),
          unknown(40, ChangeOperation.update, {'name': 'x'}, id: 'p2'),
        ),
        throwsArgumentError,
      );
    });
  });

  group('a pulled page', () {
    test('applies the known entries, holds the unknown one, receives its clock '
        'and advances the cursor', () async {
      final InMemorySyncStore store = InMemorySyncStore();
      final HlcClock clock = HlcClock('dev-a');
      final SyncReport report = await SyncSession(
        store,
        _PagedRelay([
          PullPage(
            entries: [known(100, 'c1')],
            unknownTypes: [
              unknown(500, ChangeOperation.create, {'id': 'p1', 'name': 'a'}),
            ],
            nextSince: 1,
            hasMore: true,
          ),
          PullPage(
            entries: [known(200, 'c2')],
            unknownTypes: [
              unknown(300, ChangeOperation.update, {'name': 'b'}),
            ],
            nextSince: 2,
            hasMore: false,
          ),
        ]),
        clock,
        nowWallMillis: () => 1000,
      ).run();
      expect(report.pulled, 4);
      expect(report.applied, 2);
      expect(await store.pullCursor(), 2);
      expect(
        store.records.keys.map((k) => k.id),
        unorderedEquals(['c1', 'c2']),
      );
      final UnknownTypeRecord held =
          store.unknownTypeRecords[('future_type', 'p1')]!;
      // The second page's update is older than the create: last writer wins.
      expect(held.fields, {'id': 'p1', 'name': 'a'});
      expect(held.createdAt, Hlc(500, 0, 'dev-b'));
      expect(clock.last.wallMillis, greaterThanOrEqualTo(1000));
      expect((await store.lastClock())!.compareTo(Hlc(500, 0, 'dev-b')), 1);
    });

    test('an unknown entry far ahead blocks its page like any other', () async {
      final InMemorySyncStore store = InMemorySyncStore();
      final SyncReport report = await SyncSession(
        store,
        _PagedRelay([
          PullPage(
            entries: [known(100, 'c1')],
            unknownTypes: [
              unknown(10 * 3600 * 1000, ChangeOperation.create, {'id': 'p1'}),
            ],
            nextSince: 1,
            hasMore: false,
          ),
        ]),
        HlcClock('dev-a'),
        nowWallMillis: () => 1000,
      ).run();
      expect(report.pullBlockedBy, isNotNull);
      expect(await store.pullCursor(), isNull);
      expect(store.records, isEmpty);
      expect(store.unknownTypeRecords, isEmpty);
    });
  });
}
