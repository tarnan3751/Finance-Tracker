// The contract every SavedFilterRepository implementation passes: the in-memory one (also
// the demo's) and the Drift one, each from its own test file under
// test/features/transactions/data/.
import 'package:finance_tracker/features/transactions/domain/saved_filter.dart';
import 'package:finance_tracker/features/transactions/domain/saved_filter_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registers the contract tests for the repositories [create] builds, empty.
void runSavedFilterRepositoryContract(
  Future<SavedFilterRepository> Function() create, {
  Future<void> Function()? dispose,
}) {
  group('SavedFilterRepository contract', () {
    late SavedFilterRepository filters;

    setUp(() async => filters = await create());
    if (dispose != null) tearDown(dispose);

    Future<List<SavedFilter>> all() => filters.watchAll().first;

    const Map<String, Object?> json = {
      'text': 'coffee',
      'date': {'preset': 'this_month'},
      'min_amount': {'minor_units': 10000, 'currency': 'USD'},
      'tags': ['work', 'trip'],
      'later_key': [1, null, true],
    };

    test('starts empty', () async => expect(await all(), isEmpty));

    test('saves the filters as given, each after the last', () async {
      final SavedFilter first = await filters.save('Coffee', json);
      final SavedFilter second = await filters.save('Coffee', const {});
      expect(first.id, isNot(second.id));
      expect([first.position, second.position], [0, 1]);
      expect(await all(), [first, second]);
      expect((await all()).first.filters, json);
    });

    test('a blank name is refused', () async {
      await expectLater(filters.save('  ', json), throwsArgumentError);
      final SavedFilter saved = await filters.save('Coffee', json);
      await expectLater(filters.rename(saved.id, ''), throwsArgumentError);
      expect(await all(), [saved]);
    });

    test('renames, keeping its place and filters', () async {
      final SavedFilter a = await filters.save('A', json);
      final SavedFilter b = await filters.save('B', const {});
      await filters.rename(a.id, 'Renamed');
      expect(await all(), [
        SavedFilter(id: a.id, name: 'Renamed', position: 0, filters: json),
        b,
      ]);
      await filters.rename('missing', 'Nothing');
      expect(await all(), hasLength(2));
    });

    test('deletes, and a later save still goes last', () async {
      final SavedFilter a = await filters.save('A', json);
      final SavedFilter b = await filters.save('B', json);
      await filters.delete(b.id);
      await filters.delete('missing');
      expect(await all(), [a]);
      final SavedFilter c = await filters.save('C', json);
      expect(c.position, 1);
      await filters.delete(a.id);
      expect(await all(), [c]);
    });

    test('the stream emits each change once', () async {
      final List<List<String>> seen = [];
      final sub = filters.watchAll().listen(
        (list) => seen.add([for (final f in list) f.name]),
      );
      await pumpEventQueue();
      final SavedFilter a = await filters.save('A', json);
      await pumpEventQueue();
      await filters.rename(a.id, 'B');
      await pumpEventQueue();
      await filters.rename(a.id, 'B');
      await pumpEventQueue();
      await filters.delete(a.id);
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, [
        <String>[],
        ['A'],
        ['B'],
        <String>[],
      ]);
    });
  });
}
