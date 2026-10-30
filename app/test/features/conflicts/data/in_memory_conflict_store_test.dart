// The in-memory ConflictStore against the shared contract, and its order.
import 'package:finance_tracker/features/conflicts/data/in_memory_conflict_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../contract/conflict_store_contract.dart';

void main() {
  late InMemoryConflictStore store;
  runConflictStoreContract(
    () async => store = InMemoryConflictStore(),
    add: (c) async => store.add(c),
    dispose: () => store.close(),
  );

  test('the most recently seen come first', () async {
    final InMemoryConflictStore store = InMemoryConflictStore();
    addTearDown(store.close);
    store
      ..add(testConflict('t1', 'notes', seenAt: DateTime.utc(2026, 10, 1)))
      ..add(testConflict('t2', 'notes', seenAt: DateTime.utc(2026, 10, 3)))
      ..add(testConflict('t3', 'notes', seenAt: DateTime.utc(2026, 10, 2)));
    expect((await store.watch().first).map((c) => c.entityId), [
      't2',
      't3',
      't1',
    ]);
  });
}
