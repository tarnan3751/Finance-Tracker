/// The demo flavor's [GoalRepository]: the in-memory one, holding the two goals of the
/// persona the demo shows and their contributions (`demo_goals.dart`, through
/// `goalRepositoryProvider`).
library;

import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/features/goals/data/in_memory_goal_repository.dart';
import 'package:finance_tracker/features/goals/domain/goal_repository.dart';

/// The demo's goals; changes last until the app closes (or another persona is chosen)
/// and are never recorded for sync.
final class DemoGoalRepository extends InMemoryGoalRepository {
  /// The repository holding `goals` and `contributions`, stamping from `clock`.
  DemoGoalRepository(super.clock, {super.goals, super.contributions})
    : super(recorder: const NoChangeRecorder());
}
