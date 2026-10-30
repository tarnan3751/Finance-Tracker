// The Drift ConflictStore against the shared contract, its conflicts arriving through the
// sync store as a session hands them over; and its order.
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:finance_tracker/features/conflicts/data/drift_conflict_store.dart';
import 'package:finance_tracker/features/conflicts/domain/sync_conflict.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_engine/sync_engine.dart';

import '../../../contract/conflict_store_contract.dart';
import '../../../contract/repository_fixture.dart';

FieldConflict _engine(SyncConflict c) => FieldConflict(
  entityType: c.entityType,
  entityId: c.entityId,
  field: c.field,
  localValue: c.localValue,
  localClock: c.localClock,
  remoteValue: c.remoteValue,
  remoteClock: c.remoteClock,
);

void main() {
  late AppDatabase database;
  late DriftSyncStore sync;
  runConflictStoreContract(
    () async {
      database = AppDatabase(NativeDatabase.memory());
      sync = DriftSyncStore(database, SteppingClock());
      return DriftConflictStore(database);
    },
    add: (c) => sync.recordConflicts([_engine(c)]),
    dispose: () => database.close(),
  );

  test('the most recently seen come first, and nothing is recorded', () async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final DriftSyncStore store = DriftSyncStore(db, SteppingClock());
    for (final String id in ['t1', 't2', 't3']) {
      await store.recordConflicts([_engine(testConflict(id, 'notes'))]);
    }
    expect(
      (await DriftConflictStore(db).watch().first).map((c) => c.entityId),
      ['t3', 't2', 't1'],
    );
    expect(await db.select(db.changeLog).get(), isEmpty);
  });
}
