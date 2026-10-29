// Goals for screen tests on testClock's today, 24 October 2026: an emergency fund on the
// test seed's checking account (a balance goal of 10,000.00 by 24 October 2027, created
// 24 April 2026), a holiday saved by six monthly contributions of 125.00 toward 1,800.00
// by 24 April 2027 (behind its plan by 152.46), a car fund with one contribution and no
// date, and an archived bike fund that reached its target.
//
//   await pumpApp(tester, overrides: [storeOverride(seededStore()), goalsOverride()]);
import 'package:finance_tracker/core/di/providers.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/goals/data/in_memory_goal_repository.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_models/shared_models.dart';

import 'pump_app.dart';
import 'seed.dart';

/// The goals of the header.
List<Goal> testGoals() => [
  Goal(
    id: 'goal-fund',
    name: 'Emergency fund',
    target: Money(1000000, 'USD'),
    kind: GoalKind.balance,
    linkedAccountIds: const [checkingId],
    targetDate: LocalDate(2027, 10, 24),
    createdOn: LocalDate(2026, 4, 24),
  ),
  Goal(
    id: 'goal-trip',
    name: 'Holiday',
    target: Money(180000, 'USD'),
    kind: GoalKind.contribution,
    targetDate: LocalDate(2027, 4, 24),
    createdOn: LocalDate(2026, 4, 24),
    note: 'Two weeks in Lisbon',
  ),
  Goal(
    id: 'goal-car',
    name: 'Car',
    target: Money(800000, 'USD'),
    kind: GoalKind.contribution,
    createdOn: LocalDate(2026, 9, 1),
  ),
  Goal(
    id: 'goal-bike',
    name: 'Bike',
    target: Money(60000, 'USD'),
    kind: GoalKind.contribution,
    createdOn: LocalDate(2026, 1, 10),
    archivedAt: DateTime.utc(2026, 6, 1),
  ),
];

/// The contributions of the header.
List<GoalContribution> testContributions() => [
  for (int m = 0; m < 6; m++)
    GoalContribution(
      id: 'trip-$m',
      goalId: 'goal-trip',
      date: LocalDate(2026, 5 + m, 1),
      amount: Money(12500, 'USD'),
      note: m == 0 ? 'First one' : null,
    ),
  GoalContribution(
    id: 'car-0',
    goalId: 'goal-car',
    date: LocalDate(2026, 9, 15),
    amount: Money(50000, 'USD'),
  ),
  GoalContribution(
    id: 'bike-0',
    goalId: 'goal-bike',
    date: LocalDate(2026, 5, 20),
    amount: Money(60000, 'USD'),
  ),
];

/// The repository holding [goals] and [contributions] (the header's by default).
InMemoryGoalRepository testGoalRepository({
  List<Goal>? goals,
  List<GoalContribution>? contributions,
}) => InMemoryGoalRepository(
  testClock,
  recorder: const NoChangeRecorder(),
  goals: goals ?? testGoals(),
  contributions: contributions ?? testContributions(),
);

/// The override that puts [repository] (the header's goals by default) in the app.
Override goalsOverride([InMemoryGoalRepository? repository]) =>
    goalRepositoryProvider.overrideWithValue(
      repository ?? testGoalRepository(),
    );
