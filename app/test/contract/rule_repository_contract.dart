// The contract every RuleRepository implementation passes: the in-memory, demo and Drift
// ones, each from its own test file under test/features/rules/data/.
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/features/rules/domain/rule_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import 'repository_fixture.dart';

/// A rule [id] at [position].
Rule testRule(String id, {int position = 0, String name = 'Coffee'}) => Rule(
  id: id,
  name: name,
  position: position,
  conditions: [
    const RuleCondition(
      kind: RuleConditionKind.merchantContains,
      text: 'Starbucks',
    ),
    RuleCondition(
      kind: RuleConditionKind.amountBetween,
      minAmount: Money(100, 'USD'),
      maxAmount: Money(2000, 'USD'),
    ),
  ],
  actions: const [
    RuleAction(kind: RuleActionKind.setCategory, value: 'c1'),
    RuleAction(kind: RuleActionKind.addTag, value: 'coffee'),
  ],
);

/// Registers the contract tests for the fixtures [create] builds.
void runRuleRepositoryContract(
  Future<RepositoryFixture> Function() create, {
  Future<void> Function()? dispose,
}) {
  group('RuleRepository contract', () {
    late RuleRepository rules;

    setUp(() async => rules = (await create()).rules);
    if (dispose != null) tearDown(dispose);

    List<String> ids(List<Rule> list) => [for (final Rule r in list) r.id];

    test('a fresh repository has no rules', () async {
      expect(await rules.watchAll().first, isEmpty);
    });

    test('upsert stores the rule as given, and replaces it', () async {
      await rules.upsert(testRule('r1'));
      expect(await rules.watchAll().first, [testRule('r1')]);
      await rules.upsert(testRule('r1', name: 'Coffee shops'));
      expect(await rules.watchAll().first, [
        testRule('r1', name: 'Coffee shops'),
      ]);
    });

    test('rules are ordered by position, then by id', () async {
      await rules.upsert(testRule('r3', position: 1));
      await rules.upsert(testRule('r2', position: 0));
      await rules.upsert(testRule('r1', position: 1));
      expect(ids(await rules.watchAll().first), ['r2', 'r1', 'r3']);
    });

    test('a watcher gets the current rules, then each change', () async {
      final Future<List<List<String>>> seen = rules
          .watchAll()
          .map(ids)
          .take(3)
          .toList();
      await pumpEventQueue();
      await rules.upsert(testRule('r1'));
      await pumpEventQueue();
      await rules.upsert(testRule('r2', position: 1));
      expect(await seen, [
        <String>[],
        ['r1'],
        ['r1', 'r2'],
      ]);
    });

    test('delete hides the rule; restore brings it back as it was', () async {
      await rules.upsert(testRule('r1'));
      await rules.upsert(testRule('r2', position: 1));
      await rules.delete('r1');
      expect(ids(await rules.watchAll().first), ['r2']);
      await rules.restore('r1');
      expect(await rules.watchAll().first, [
        testRule('r1'),
        testRule('r2', position: 1),
      ]);
    });

    test('deleting or restoring what is not there does nothing', () async {
      await rules.delete('missing');
      await rules.restore('missing');
      await rules.upsert(testRule('r1'));
      await rules.restore('r1');
      await rules.delete('r1');
      await rules.delete('r1');
      expect(await rules.watchAll().first, isEmpty);
    });

    test('an upsert of a deleted rule throws and changes nothing', () async {
      await rules.upsert(testRule('r1'));
      await rules.delete('r1');
      await expectLater(
        rules.upsert(testRule('r1', name: 'Edited')),
        throwsA(isA<EntityDeletedException>()),
      );
      await rules.restore('r1');
      expect(await rules.watchAll().first, [testRule('r1')]);
    });

    test('reorder numbers the listed rules from 0, the rest after', () async {
      for (final (int i, String id) in ['r1', 'r2', 'r3', 'r4'].indexed) {
        await rules.upsert(testRule(id, position: i * 10));
      }
      await rules.reorder(['r3', 'r1']);
      final List<Rule> live = await rules.watchAll().first;
      expect(ids(live), ['r3', 'r1', 'r2', 'r4']);
      expect([for (final Rule r in live) r.position], [0, 1, 2, 3]);
    });

    test(
      'reorder ignores unknown, deleted and repeated ids, and keeps the rest',
      () async {
        await rules.upsert(testRule('r1'));
        await rules.upsert(testRule('r2', position: 1));
        await rules.upsert(testRule('r3', position: 2));
        await rules.delete('r2');
        await rules.reorder(['missing', 'r3', 'r2', 'r3']);
        expect(ids(await rules.watchAll().first), ['r3', 'r1']);
        await rules.restore('r2');
        expect(ids(await rules.watchAll().first), ['r3', 'r1', 'r2']);
      },
    );
  });
}
