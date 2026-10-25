// The Drift DismissedPairStore against the shared contract, and its rows: the ids in
// order, stamped with the clock, recording nothing for sync.
import 'package:drift/native.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/features/duplicates/data/drift_dismissed_pair_store.dart';
import 'package:finance_tracker/features/duplicates/domain/duplicate_detector.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../contract/dismissed_pair_store_contract.dart';
import '../../../contract/repository_fixture.dart';

void main() {
  late AppDatabase database;
  runDismissedPairStoreContract(() async {
    database = AppDatabase(NativeDatabase.memory());
    return DriftDismissedPairStore(database, SteppingClock()..frozen = true);
  }, dispose: () => database.close());

  test(
    'a row holds the ids in order and when, and nothing is recorded',
    () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final SteppingClock clock = SteppingClock()..frozen = true;
      await DriftDismissedPairStore(db, clock).dismiss(PairKey('t9', 't1'));
      final DismissedPairRow row = await db
          .select(db.dismissedPairs)
          .getSingle();
      expect((row.idA, row.idB), ('t1', 't9'));
      expect(row.dismissedAt, clock.nowUtc());
      expect(row.dismissedAt.isUtc, isTrue);
      expect(await db.select(db.changeLog).get(), isEmpty);
    },
  );
}
