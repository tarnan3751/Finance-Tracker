// A session on the app's Drift store through the HTTP relay, pulling a page that holds an
// entry of a type this build does not know: the rest of the page lands, the cursor
// advances past it, the entry is held under its raw type, and the next page applies.
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/core/sync/http_sync_relay.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';
import 'package:sync_engine/sync_engine.dart';

import '../../contract/repository_fixture.dart';

/// Endpoints serving [pages] by cursor.
final class _PageEndpoints implements SyncEndpoints {
  _PageEndpoints(this.pages);

  final Map<int, PullPage> pages;

  @override
  Future<PushResult> pushChanges(List<ChangeLogEntry> entries) async =>
      const PushResult(accepted: [], rejected: []);

  @override
  Future<PullPage> pullChanges({
    required int since,
    required int limit,
  }) async => pages[since]!;
}

ChangeLogEntry _category(String id, int wall) => ChangeLogEntry(
  entityType: EntityType.category,
  entityId: id,
  operation: ChangeOperation.create,
  payload: {
    'id': id,
    'name': 'Hobbies',
    'parent_id': null,
    'is_system': false,
    'icon': 'star',
    'color': 0xFF0000FF,
    'plaid_category': null,
  },
  hlc: Hlc(wall, 0, 'dev-b'),
  deviceId: 'dev-b',
  synced: true,
);

void main() {
  test('a page with an unknown type applies the rest and advances', () async {
    final AppDatabase database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final DriftSyncStore store = DriftSyncStore(database, SteppingClock());
    final SyncReport report = await SyncSession(
      store,
      HttpSyncRelay(
        _PageEndpoints({
          0: PullPage(
            entries: [_category('c1', 100)],
            unknownTypes: [
              UnknownTypeEntry(
                entityType: 'future_type',
                entityId: 'f1',
                operation: ChangeOperation.create,
                payload: const {'id': 'f1', 'shape': 'new'},
                hlc: Hlc(150, 0, 'dev-b'),
                deviceId: 'dev-b',
              ),
            ],
            nextSince: 2,
            hasMore: true,
          ),
          2: PullPage(
            entries: [_category('c2', 200)],
            nextSince: 3,
            hasMore: false,
          ),
        }),
        deviceId: 'dev-a',
      ),
      HlcClock('dev-a'),
      nowWallMillis: () => 1000,
    ).run();

    expect(report.pulled, 3);
    expect(report.pullBlockedBy, isNull);
    expect(await store.pullCursor(), 3);
    expect(
      (await database.select(database.categories).get()).map((c) => c.id),
      unorderedEquals(['c1', 'c2']),
    );
    final HeldRecordRow held = await database
        .select(database.heldRecords)
        .getSingle();
    expect(
      (held.entityType, held.entityId, held.reason),
      ('future_type', 'f1', 'unsupported_type'),
    );
    expect((await store.watchLedger().first).held, 1);
  });
}
