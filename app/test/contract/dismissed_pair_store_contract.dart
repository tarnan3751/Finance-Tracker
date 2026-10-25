// The contract every DismissedPairStore implementation passes: the in-memory and Drift
// ones, each from its own test file under test/features/duplicates/data/.
import 'package:finance_tracker/features/duplicates/domain/dismissed_pair_store.dart';
import 'package:finance_tracker/features/duplicates/domain/duplicate_detector.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registers the contract tests for the stores [create] builds.
void runDismissedPairStoreContract(
  Future<DismissedPairStore> Function() create, {
  Future<void> Function()? dispose,
}) {
  group('DismissedPairStore contract', () {
    late DismissedPairStore store;

    setUp(() async => store = await create());
    if (dispose != null) tearDown(dispose);

    test('starts empty', () async {
      expect(await store.watch().first, isEmpty);
    });

    test('remembers a pair whichever way round it is named', () async {
      await store.dismiss(PairKey('t2', 't1'));
      await store.dismiss(PairKey('t1', 't2'));
      await store.dismiss(PairKey('t3', 't4'));
      expect(await store.watch().first, {
        PairKey('t1', 't2'),
        PairKey('t3', 't4'),
      });
    });

    test(
      'restore forgets a pair; restoring an unknown one does nothing',
      () async {
        await store.dismiss(PairKey('t1', 't2'));
        await store.restore(PairKey('t2', 't1'));
        await store.restore(PairKey('t8', 't9'));
        expect(await store.watch().first, isEmpty);
      },
    );

    test('a watcher sees each change', () async {
      final List<Set<PairKey>> seen = [];
      final sub = store.watch().listen(seen.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();
      await store.dismiss(PairKey('t1', 't2'));
      await pumpEventQueue();
      await store.restore(PairKey('t1', 't2'));
      await pumpEventQueue();
      expect(seen.first, isEmpty);
      expect(seen, contains(equals({PairKey('t1', 't2')})));
      expect(seen.last, isEmpty);
    });
  });
}
