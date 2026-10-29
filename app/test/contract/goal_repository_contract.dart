// The contract every GoalRepository implementation passes: the in-memory, demo and Drift
// ones, each from its own test file under test/features/goals/data/.
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/features/goals/domain/goal_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import 'repository_fixture.dart';

/// A goal [id] created on [createdOn], every field set.
Goal testGoal(
  String id, {
  LocalDate? createdOn,
  String name = 'Emergency fund',
  int target = 500000,
  String currency = 'USD',
  GoalKind kind = GoalKind.balance,
}) => Goal(
  id: id,
  name: name,
  target: Money(target, currency),
  kind: kind,
  linkedAccountIds: const ['savings', 'checking'],
  targetDate: LocalDate(2027, 10, 1),
  createdOn: createdOn ?? LocalDate(2026, 10, 1),
  note: 'Six months of rent',
);

/// A contribution [id] to goal [goalId] on [date].
GoalContribution testContribution(
  String id, {
  String goalId = 'g1',
  LocalDate? date,
  int amount = 12500,
  String currency = 'USD',
}) => GoalContribution(
  id: id,
  goalId: goalId,
  date: date ?? LocalDate(2026, 10, 5),
  amount: Money(amount, currency),
  note: 'Pay day',
);

/// Registers the contract tests for the fixtures [create] builds.
void runGoalRepositoryContract(
  Future<RepositoryFixture> Function() create, {
  Future<void> Function()? dispose,
}) {
  group('GoalRepository contract', () {
    late GoalRepository goals;
    late SteppingClock clock;

    setUp(() async {
      final RepositoryFixture f = await create();
      goals = f.goals;
      clock = f.clock;
    });
    if (dispose != null) tearDown(dispose);

    List<String> ids(List<GoalEntry> list) => [
      for (final GoalEntry e in list) e.goal.id,
    ];

    List<String> contributionIds(GoalEntry? entry) => [
      for (final GoalContribution c in entry!.contributions) c.id,
    ];

    test('a fresh repository has no goals', () async {
      expect(await goals.watchAll().first, isEmpty);
      expect(await goals.watchById('g1').first, isNull);
    });

    test('create stores the goal as given, live and not archived', () async {
      await goals.create(
        testGoal('g1').copyWith(
          archivedAt: DateTime.utc(2026, 10, 2),
          deletedAt: DateTime.utc(2026, 10, 3),
        ),
      );
      expect(await goals.watchAll().first, [GoalEntry(testGoal('g1'), [])]);
      expect(await goals.watchById('g1').first, GoalEntry(testGoal('g1'), []));
      final Goal bare = Goal(
        id: 'g2',
        name: 'Trip',
        target: Money(1, 'EUR'),
        kind: GoalKind.contribution,
        createdOn: LocalDate(2024, 2, 29),
      );
      await goals.create(bare);
      expect((await goals.watchById('g2').first)!.goal, bare);
    });

    test('create of an existing id throws and changes nothing', () async {
      await goals.create(testGoal('g1'));
      await expectLater(
        goals.create(testGoal('g1', name: 'Other')),
        throwsArgumentError,
      );
      expect((await goals.watchById('g1').first)!.goal, testGoal('g1'));
    });

    test('update replaces the fields and keeps the archive state', () async {
      await goals.create(testGoal('g1'));
      await goals.setArchived('g1', archived: true);
      final DateTime archivedAt =
          (await goals.watchById('g1').first)!.goal.archivedAt!;
      final Goal edited = testGoal(
        'g1',
        name: 'Rainy day',
        target: 100,
        kind: GoalKind.contribution,
      ).copyWith(linkedAccountIds: const [], targetDate: null, note: null);
      await goals.update(edited);
      expect(
        (await goals.watchById('g1').first)!.goal,
        edited.copyWith(archivedAt: archivedAt),
      );
      await expectLater(goals.update(testGoal('missing')), throwsArgumentError);
    });

    test('goals are ordered by creation day, then by id', () async {
      await goals.create(testGoal('g3', createdOn: LocalDate(2026, 10, 2)));
      await goals.create(testGoal('g2'));
      await goals.create(testGoal('g1', createdOn: LocalDate(2026, 10, 2)));
      await goals.create(testGoal('g0', createdOn: LocalDate(2027, 1, 1)));
      expect(ids(await goals.watchAll().first), ['g2', 'g1', 'g3', 'g0']);
    });

    test('archive stamps the instant and unarchive clears it; archived goals '
        'stay listed', () async {
      await goals.create(testGoal('g1'));
      clock.frozen = true;
      final DateTime now = clock.nowUtc();
      await goals.setArchived('g1', archived: true);
      expect((await goals.watchById('g1').first)!.goal.archivedAt, now);
      expect(ids(await goals.watchAll().first), ['g1']);
      await goals.setArchived('g1', archived: true);
      expect((await goals.watchById('g1').first)!.goal.archivedAt, now);
      await goals.setArchived('g1', archived: false);
      expect((await goals.watchById('g1').first)!.goal.archivedAt, isNull);
      await goals.setArchived('missing', archived: true);
    });

    test(
      'contributions are listed with their goal, by date, then id',
      () async {
        await goals.create(testGoal('g1'));
        await goals.create(testGoal('g2'));
        await goals.addContribution(
          testContribution('c3', date: LocalDate(2026, 10, 6)),
        );
        await goals.addContribution(testContribution('c2', amount: -500));
        await goals.addContribution(testContribution('c1'));
        await goals.addContribution(testContribution('c9', goalId: 'g2'));
        final GoalEntry? one = await goals.watchById('g1').first;
        expect(contributionIds(one), ['c1', 'c2', 'c3']);
        expect(one!.contributions[1], testContribution('c2', amount: -500));
        final List<GoalEntry> all = await goals.watchAll().first;
        expect(contributionIds(all[1]), ['c9']);
      },
    );

    test('a contribution is refused for a missing or deleted goal, an existing '
        'id or another currency', () async {
      await expectLater(
        goals.addContribution(testContribution('c1')),
        throwsArgumentError,
      );
      await goals.create(testGoal('g1'));
      await goals.addContribution(testContribution('c1'));
      await expectLater(
        goals.addContribution(testContribution('c1', amount: 1)),
        throwsArgumentError,
      );
      await expectLater(
        goals.addContribution(testContribution('c2', currency: 'EUR')),
        throwsA(isA<CurrencyMismatchException>()),
      );
      await goals.delete('g1');
      await expectLater(
        goals.addContribution(testContribution('c3')),
        throwsA(isA<EntityDeletedException>()),
      );
      await goals.restore('g1');
      expect(contributionIds(await goals.watchById('g1').first), ['c1']);
    });

    test(
      'deleting a contribution hides it; restoring brings it back',
      () async {
        await goals.create(testGoal('g1'));
        await goals.addContribution(testContribution('c1'));
        await goals.addContribution(testContribution('c2'));
        await goals.deleteContribution('c1');
        expect(contributionIds(await goals.watchById('g1').first), ['c2']);
        await goals.restoreContribution('c1');
        expect(contributionIds(await goals.watchById('g1').first), [
          'c1',
          'c2',
        ]);
        await goals.deleteContribution('missing');
        await goals.restoreContribution('c1');
      },
    );

    test('delete hides the goal with its contributions; restore brings both '
        'back as they were', () async {
      await goals.create(testGoal('g1'));
      await goals.create(testGoal('g2'));
      await goals.addContribution(testContribution('c1'));
      await goals.delete('g1');
      expect(ids(await goals.watchAll().first), ['g2']);
      expect(await goals.watchById('g1').first, isNull);
      await expectLater(
        goals.update(testGoal('g1', name: 'Other')),
        throwsA(isA<EntityDeletedException>()),
      );
      await goals.restore('g1');
      expect(
        await goals.watchById('g1').first,
        GoalEntry(testGoal('g1'), [testContribution('c1')]),
      );
      await goals.delete('missing');
      await goals.restore('g2');
      await goals.setArchived('g1', archived: true);
      await goals.delete('g1');
      await goals.setArchived('g1', archived: false);
      await goals.restore('g1');
      expect((await goals.watchById('g1').first)!.goal.archivedAt, isNotNull);
    });

    test('a watcher gets the current goals, then each change', () async {
      final Future<List<List<String>>> seen = goals
          .watchAll()
          .map(ids)
          .take(3)
          .toList();
      final Future<List<List<String>?>> one = goals
          .watchById('g1')
          .map((e) => e == null ? null : contributionIds(e))
          .take(4)
          .toList();
      await pumpEventQueue();
      await goals.create(testGoal('g1'));
      await pumpEventQueue();
      await goals.create(testGoal('g2'));
      await pumpEventQueue();
      await goals.addContribution(testContribution('c1'));
      await pumpEventQueue();
      await goals.delete('g1');
      expect(await seen, [
        <String>[],
        ['g1'],
        ['g1', 'g2'],
      ]);
      expect(await one, [
        null,
        <String>[],
        ['c1'],
        null,
      ]);
    });
  });
}
