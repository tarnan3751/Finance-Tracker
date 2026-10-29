// The goal screens on the goal seed (goal_seed.dart) and the test seed, as of 24 October
// 2026: the list's cards with their status and suggestion and the folded Archived
// section; a new goal through the editor; the detail of a contribution goal with a
// contribution added, deleted and restored by Undo; a balance goal's counted accounts;
// archive and delete from the editor with their undo; the progress read as one
// sentence; the empty state; and every screen at twice the text size.
import 'package:finance_tracker/core/db/in_memory_store.dart';
import 'package:finance_tracker/features/goals/data/in_memory_goal_repository.dart';
import 'package:finance_tracker/features/goals/domain/goal_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_models/shared_models.dart';

import '../../../helpers/goal_seed.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/seed.dart';

Future<InMemoryGoalRepository> pumpGoals(
  WidgetTester tester, {
  String location = '/goals',
  double textScale = 1,
  InMemoryGoalRepository? repository,
}) async {
  final InMemoryGoalRepository goals = repository ?? testGoalRepository();
  await pumpApp(
    tester,
    initialLocation: location,
    textScale: textScale,
    overrides: [storeOverride(seededStore()), goalsOverride(goals)],
  );
  return goals;
}

/// Goal [id] with its contributions as [goals] holds it, read outside the fake clock.
Future<GoalEntry?> entry(
  WidgetTester tester,
  InMemoryGoalRepository goals,
  String id,
) async => tester.runAsync<GoalEntry?>(() => goals.watchById(id).first);

Future<Goal?> stored(
  WidgetTester tester,
  InMemoryGoalRepository goals,
  String id,
) async => (await entry(tester, goals, id))?.goal;

void main() {
  testWidgets('the list shows each goal with its status and suggestion, the '
      'archived ones folded', (tester) async {
    await pumpGoals(tester);
    expect(find.text('Emergency fund'), findsOneWidget);
    expect(find.text('By Oct 24, 2027'), findsOneWidget);
    expect(find.text('Holiday'), findsOneWidget);
    expect(find.text(r'$750.00 of $1,800.00'), findsOneWidget);
    expect(find.text(r'Behind by $152.46'), findsOneWidget);
    // 1,050.00 over the 6 whole months to April 24.
    expect(find.text(r'Set aside $175.00 a month'), findsOneWidget);
    // No date: no status, no suggestion.
    expect(find.text(r'$500.00 of $8,000.00'), findsOneWidget);
    expect(find.text('Bike'), findsNothing);
    await tester.tap(find.text('Archived (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Bike'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('a card reads as one sentence, each part once', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpGoals(tester);
    final String label = tester.getSemantics(find.text('Holiday')).label;
    expect(RegExp('Holiday').allMatches(label), hasLength(1));
    expect(RegExp(r'\$750\.00').allMatches(label), hasLength(1));
    expect(label, contains('41 percent of the target'));
    expect(label, contains(r'Behind by $152.46'));
    semantics.dispose();
  });

  testWidgets('with no goals, the empty state opens a new goal', (
    tester,
  ) async {
    await pumpGoals(
      tester,
      repository: testGoalRepository(goals: const [], contributions: const []),
    );
    expect(find.text('No savings goals yet'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'New goal'));
    await tester.pumpAndSettle();
    expect(find.text('New goal'), findsWidgets);
  });

  testWidgets('a new contribution goal is saved from the editor', (
    tester,
  ) async {
    final InMemoryGoalRepository goals = await pumpGoals(tester);
    await tester.tap(find.byTooltip('New goal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Choose at least one account'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Laptop',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Target amount'),
      '1200',
    );
    await tester.tap(find.text('Contributions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Laptop'), findsOneWidget);
    final Goal laptop = (await tester.runAsync(() => goals.watchAll().first))!
        .map((e) => e.goal)
        .singleWhere((g) => g.name == 'Laptop');
    expect(laptop.target, Money(120000, 'USD'));
    expect(laptop.kind, GoalKind.contribution);
    expect(laptop.linkedAccountIds, isEmpty);
    expect(laptop.targetDate, isNull);
    expect(laptop.createdOn, LocalDate(2026, 10, 24));
  });

  testWidgets('a contribution is added on the detail, deleted and restored', (
    tester,
  ) async {
    final InMemoryGoalRepository goals = await pumpGoals(tester);
    await tester.tap(find.text('Holiday'));
    await tester.pumpAndSettle();
    expect(find.text('Two weeks in Lisbon'), findsOneWidget);
    expect(find.text('Oct 1, 2026'), findsOneWidget);
    expect(find.text('May 1, 2026 · First one'), findsOneWidget);
    await tester.tap(find.text('Add contribution'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '200');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Note'),
      'Birthday',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text(r'$950.00 of $1,800.00'), findsOneWidget);
    expect(find.text('On track'), findsOneWidget);
    expect(find.text('Oct 24, 2026 · Birthday'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete contribution').first);
    await tester.pumpAndSettle();
    expect(find.text(r'$750.00 of $1,800.00'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text(r'$950.00 of $1,800.00'), findsOneWidget);
    expect(
      (await entry(tester, goals, 'goal-trip'))!.contributions,
      hasLength(7),
    );
  });

  testWidgets('a withdrawal is saved as a negative contribution', (
    tester,
  ) async {
    final InMemoryGoalRepository goals = await pumpGoals(
      tester,
      location: '/goals/goal-car/contribute',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '50');
    await tester.tap(find.text('Withdrawal'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      (await entry(
        tester,
        goals,
        'goal-car',
      ))!.contributions.map((c) => c.amount).last,
      Money(-5000, 'USD'),
    );
  });

  testWidgets('a balance goal lists the accounts it counts', (tester) async {
    await pumpGoals(tester, location: '/goals/goal-fund');
    expect(find.text('Counted accounts'), findsOneWidget);
    expect(find.text('Everyday Checking'), findsOneWidget);
    expect(find.text('from transactions'), findsOneWidget);
    expect(find.text('Add contribution'), findsNothing);
  });

  testWidgets('archiving from the editor folds the goal away, with an undo', (
    tester,
  ) async {
    final InMemoryGoalRepository goals = await pumpGoals(
      tester,
      location: '/goals/goal-car/edit',
    );
    await tester.tap(find.byTooltip('Archive'));
    await tester.pumpAndSettle();
    expect(find.text('Goal archived'), findsOneWidget);
    expect(find.text('Archived (2)'), findsOneWidget);
    expect((await stored(tester, goals, 'goal-car'))!.archivedAt, isNotNull);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect((await stored(tester, goals, 'goal-car'))!.archivedAt, isNull);
    expect(find.text('Archived (1)'), findsOneWidget);
  });

  testWidgets('deleting from the editor removes the goal, with an undo', (
    tester,
  ) async {
    final InMemoryGoalRepository goals = await pumpGoals(
      tester,
      location: '/goals/goal-trip/edit',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Unsaved',
    );
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Goal deleted'), findsOneWidget);
    expect(find.text('Holiday'), findsNothing);
    expect(await stored(tester, goals, 'goal-trip'), isNull);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Holiday'), findsOneWidget);
  });

  testWidgets('an edit keeps the creation day and the contributions', (
    tester,
  ) async {
    final InMemoryGoalRepository goals = await pumpGoals(
      tester,
      location: '/goals/goal-trip/edit',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Lisbon',
    );
    await tester.tap(find.text('Clear date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final Goal goal = (await stored(tester, goals, 'goal-trip'))!;
    expect(goal.name, 'Lisbon');
    expect(goal.targetDate, isNull);
    expect(goal.createdOn, LocalDate(2026, 4, 24));
    expect(goal.note, 'Two weeks in Lisbon');
  });

  for (final String location in [
    '/goals',
    '/goals/goal-trip',
    '/goals/goal-fund',
    '/goals/new',
    '/goals/goal-fund/edit',
    '/goals/goal-trip/contribute',
  ]) {
    testWidgets('$location lays out at twice the text size', (tester) async {
      await pumpGoals(tester, location: location, textScale: 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a new goal\'s target date starts today', (tester) async {
    await pumpGoals(tester, location: '/goals/new');
    await tester.tap(find.text('No date'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<DatePickerDialog>(find.byType(DatePickerDialog)).firstDate,
      DateTime(2026, 10, 24),
    );
  });

  testWidgets('an existing goal keeps a past target date', (tester) async {
    final InMemoryGoalRepository goals = testGoalRepository(
      goals: [
        ...testGoals(),
        Goal(
          id: 'goal-late',
          name: 'Late',
          target: Money(10000, 'USD'),
          kind: GoalKind.contribution,
          targetDate: LocalDate(2026, 9, 1),
          createdOn: LocalDate(2026, 1, 1),
        ),
      ],
    );
    await pumpGoals(
      tester,
      location: '/goals/goal-late/edit',
      repository: goals,
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Later');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final Goal late = (await stored(tester, goals, 'goal-late'))!;
    expect((late.name, late.targetDate), ('Later', LocalDate(2026, 9, 1)));
  });

  InMemoryStore euroStore() => seededStore()
    ..upsertAccount(
      const Account(
        id: 'euro',
        type: AccountType.depository,
        name: 'Euro savings',
        currencyCode: 'EUR',
        isHidden: false,
        displayOrder: 9,
      ),
    );

  testWidgets('the currency is fixed once a goal has contributions', (
    tester,
  ) async {
    await pumpApp(
      tester,
      initialLocation: '/goals/goal-trip/edit',
      overrides: [storeOverride(euroStore()), goalsOverride()],
    );
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'EUR'))
          .onSelected,
      isNull,
    );
    expect(
      find.text(
        'The currency stays as it is once the goal has contributions or accounts.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a new goal chooses its currency', (tester) async {
    await pumpApp(
      tester,
      initialLocation: '/goals/new',
      overrides: [storeOverride(euroStore()), goalsOverride()],
    );
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'EUR'))
          .onSelected,
      isNotNull,
    );
  });

  testWidgets('a contribution in another currency is marked as not counted', (
    tester,
  ) async {
    await pumpGoals(
      tester,
      location: '/goals/goal-trip',
      repository: testGoalRepository(
        contributions: [
          ...testContributions(),
          GoalContribution(
            id: 'trip-eur',
            goalId: 'goal-trip',
            date: LocalDate(2026, 10, 20),
            amount: Money(5000, 'EUR'),
          ),
        ],
      ),
    );
    expect(find.text('Oct 20, 2026 · Not counted, in EUR'), findsOneWidget);
    expect(find.text(r'$750.00 of $1,800.00'), findsOneWidget);
  });

  testWidgets('a contribution\'s date picker ends today', (tester) async {
    await pumpGoals(tester, location: '/goals/goal-trip/contribute');
    await tester.tap(find.text('Oct 24, 2026'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<DatePickerDialog>(find.byType(DatePickerDialog)).lastDate,
      DateTime(2026, 10, 24),
    );
  });
}
