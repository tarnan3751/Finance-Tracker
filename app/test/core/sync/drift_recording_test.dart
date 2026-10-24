// The Drift repositories against the recording contract, and the atomicity of a write and
// its entry.
import 'package:finance_tracker/core/db/drift_sync_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contract/drift_fixtures.dart';
import '../../contract/memory_fixtures.dart';
import '../../contract/recording_contract.dart';
import '../../contract/repository_fixture.dart';

void main() {
  final FixtureFactory fixtures = driftFixtures();
  runRecordingContract(fixtures.create, dispose: fixtures.dispose);

  test('a write and its entry roll back together', () async {
    final FixtureFactory own = driftFixtures();
    final RepositoryFixture f = await own.create();
    addTearDown(own.dispose);
    final DriftSyncStore sync = f.syncStore! as DriftSyncStore;
    await expectLater(
      sync.transaction(() async {
        await f.accounts.upsert(testAccount('a1'));
        expect(await sync.unsynced(), hasLength(1));
        throw StateError('crash');
      }),
      throwsStateError,
    );
    expect(await f.accounts.watchAll().first, isEmpty);
    expect(await sync.unsynced(), isEmpty);
  });
}
