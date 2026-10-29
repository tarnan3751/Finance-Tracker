/// A [GoalRepository] held in memory: what tests use, and the base of the demo flavor's.
library;

import 'dart:async';

import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/goals/domain/goal_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Goals and contributions kept in memory for the life of the object; archives and
/// deletes are stamped from the clock. Every write records the entity it changed through
/// [recorder].
base class InMemoryGoalRepository implements GoalRepository {
  /// A repository holding [goals] and [contributions], stamping from [_clock] and
  /// recording through [recorder].
  InMemoryGoalRepository(
    this._clock, {
    required this.recorder,
    List<Goal> goals = const [],
    List<GoalContribution> contributions = const [],
  }) {
    for (final Goal goal in goals) {
      _goals[goal.id] = goal;
    }
    for (final GoalContribution contribution in contributions) {
      _contributions[contribution.id] = contribution;
    }
  }

  /// Where the writes are recorded.
  final ChangeRecorder recorder;

  final Clock _clock;
  final Map<String, Goal> _goals = {};
  final Map<String, GoalContribution> _contributions = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  GoalEntry _entry(Goal goal) => GoalEntry(
    goal,
    [
      for (final GoalContribution c in _contributions.values)
        if (c.goalId == goal.id && c.deletedAt == null) c,
    ]..sort((a, b) {
      final int byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : compareBinary(a.id, b.id);
    }),
  );

  List<GoalEntry> _live() => [
    for (final Goal goal
        in [
          for (final Goal g in _goals.values)
            if (g.deletedAt == null) g,
        ]..sort((a, b) {
          final int byDay = a.createdOn.compareTo(b.createdOn);
          return byDay != 0 ? byDay : compareBinary(a.id, b.id);
        }))
      _entry(goal),
  ];

  Stream<T> _watch<T>(T Function() read, bool Function(T, T) same) =>
      Stream<T>.multi((controller) {
        controller.add(read());
        final StreamSubscription<void> subscription = _changes.stream.listen(
          (_) => controller.add(read()),
          onDone: controller.close,
        );
        controller.onCancel = subscription.cancel;
      }).distinct(same);

  @override
  Stream<List<GoalEntry>> watchAll() => _watch(_live, sameList);

  @override
  Stream<GoalEntry?> watchById(String id) => _watch(() {
    final Goal? goal = _goals[id];
    return goal == null || goal.deletedAt != null ? null : _entry(goal);
  }, (a, b) => a == b);

  Future<void> _writeGoal(Goal? before, Goal after) async {
    _goals[after.id] = after;
    _changes.add(null);
    await recorder.record(
      EntityType.goal,
      after.id,
      before == null ? null : goalRecordJson(before),
      goalRecordJson(after),
    );
  }

  Future<void> _writeContribution(
    GoalContribution? before,
    GoalContribution after,
  ) async {
    _contributions[after.id] = after;
    _changes.add(null);
    await recorder.record(
      EntityType.goalContribution,
      after.id,
      before == null ? null : goalContributionRecordJson(before),
      goalContributionRecordJson(after),
    );
  }

  @override
  Future<void> create(Goal goal) async {
    if (_goals.containsKey(goal.id)) {
      throw ArgumentError.value(goal.id, 'goal', 'already exists');
    }
    await _writeGoal(null, goal.copyWith(archivedAt: null, deletedAt: null));
  }

  @override
  Future<void> update(Goal goal) async {
    final Goal? existing = _goals[goal.id];
    if (existing == null) {
      throw ArgumentError.value(goal.id, 'goal', 'does not exist');
    }
    if (existing.deletedAt != null) {
      throw EntityDeletedException('goal', goal.id);
    }
    await _writeGoal(
      existing,
      goal.copyWith(archivedAt: existing.archivedAt, deletedAt: null),
    );
  }

  @override
  Future<void> setArchived(String id, {required bool archived}) async {
    final Goal? existing = _goals[id];
    if (existing == null ||
        existing.deletedAt != null ||
        (existing.archivedAt != null) == archived) {
      return;
    }
    await _writeGoal(
      existing,
      existing.copyWith(archivedAt: archived ? _clock.nowUtc() : null),
    );
  }

  @override
  Future<void> delete(String id) async {
    final Goal? existing = _goals[id];
    if (existing == null || existing.deletedAt != null) return;
    await _writeGoal(existing, existing.copyWith(deletedAt: _clock.nowUtc()));
  }

  @override
  Future<void> restore(String id) async {
    final Goal? existing = _goals[id];
    if (existing == null || existing.deletedAt == null) return;
    await _writeGoal(existing, existing.copyWith(deletedAt: null));
  }

  @override
  Future<void> addContribution(GoalContribution contribution) async {
    final Goal? goal = _goals[contribution.goalId];
    if (goal == null) {
      throw ArgumentError.value(contribution.goalId, 'goal', 'does not exist');
    }
    if (goal.deletedAt != null) {
      throw EntityDeletedException('goal', goal.id);
    }
    if (_contributions.containsKey(contribution.id)) {
      throw ArgumentError.value(contribution.id, 'contribution', 'exists');
    }
    if (contribution.amount.currencyCode != goal.target.currencyCode) {
      throw CurrencyMismatchException(
        goal.target.currencyCode,
        contribution.amount.currencyCode,
      );
    }
    await _writeContribution(null, contribution.copyWith(deletedAt: null));
  }

  @override
  Future<void> deleteContribution(String id) async {
    final GoalContribution? existing = _contributions[id];
    if (existing == null || existing.deletedAt != null) return;
    await _writeContribution(
      existing,
      existing.copyWith(deletedAt: _clock.nowUtc()),
    );
  }

  @override
  Future<void> restoreContribution(String id) async {
    final GoalContribution? existing = _contributions[id];
    if (existing == null || existing.deletedAt == null) return;
    await _writeContribution(existing, existing.copyWith(deletedAt: null));
  }

  /// Ends every watcher's stream.
  Future<void> close() => _changes.close();
}
