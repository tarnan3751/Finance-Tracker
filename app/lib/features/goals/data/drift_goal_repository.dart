/// The [GoalRepository] of the dev and prod flavors, over the `goals` and
/// `goal_contributions` tables (`docs/reference/data.md`).
library;

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:finance_tracker/core/db/database_exceptions.dart';
import 'package:finance_tracker/core/db/repository_support.dart';
import 'package:finance_tracker/core/sync/change_recorder.dart';
import 'package:finance_tracker/core/sync/entity_codec.dart';
import 'package:finance_tracker/core/time/clock.dart';
import 'package:finance_tracker/features/goals/data/goal_rows.dart';
import 'package:finance_tracker/features/goals/domain/goal_repository.dart';
import 'package:shared_models/shared_models.dart';

/// Goals and contributions in [AppDatabase]. Audit fields, archives and deletes are
/// stamped from the clock. Every write records the entity it changed through
/// [_recorder] in the same database transaction.
final class DriftGoalRepository implements GoalRepository {
  /// The repository over [_database], stamping writes from [_clock] and recording them
  /// through `recorder`.
  DriftGoalRepository(this._database, this._clock, {required this._recorder});

  final AppDatabase _database;
  final Clock _clock;
  final ChangeRecorder _recorder;

  $GoalsTable get _goals => _database.goals;
  $GoalContributionsTable get _contributions => _database.goalContributions;

  // Emits whenever either table changes, starting now.
  Stream<void> _changes() => _database
      .customSelect('SELECT 1', readsFrom: {_goals, _contributions})
      .watch();

  // The live goals ([id] only, when given) with their live contributions.
  Future<List<GoalEntry>> _read({String? id}) => _database.transaction(
    () async {
      final List<GoalRow> goals =
          await (_database.select(_goals)
                ..where(
                  (g) =>
                      g.deletedAt.isNull() &
                      (id == null ? const Constant(true) : g.id.equals(id)),
                )
                ..orderBy([
                  (g) => OrderingTerm.asc(g.createdOn),
                  (g) => OrderingTerm.asc(g.id),
                ]))
              .get();
      if (goals.isEmpty) return const [];
      final List<GoalContributionRow> contributions =
          await (_database.select(_contributions)
                ..where(
                  (c) =>
                      c.deletedAt.isNull() &
                      (id == null ? const Constant(true) : c.goalId.equals(id)),
                )
                ..orderBy([
                  (c) => OrderingTerm.asc(c.date),
                  (c) => OrderingTerm.asc(c.id),
                ]))
              .get();
      final Map<String, List<GoalContribution>> byGoal = {};
      for (final GoalContributionRow row in contributions) {
        (byGoal[row.goalId] ??= []).add(goalContributionFromRow(row));
      }
      return [
        for (final GoalRow row in goals)
          GoalEntry(goalFromRow(row), byGoal[row.id] ?? const []),
      ];
    },
  );

  @override
  Stream<List<GoalEntry>> watchAll() =>
      _changes().asyncMap((_) => _read()).distinct(sameList);

  @override
  Stream<GoalEntry?> watchById(String id) => _changes().asyncMap((_) async {
    final List<GoalEntry> entries = await _read(id: id);
    return entries.isEmpty ? null : entries.single;
  }).distinct();

  Future<void> _writeGoal(GoalRow? existing, Goal goal) async {
    final DateTime now = _clock.nowUtc();
    await _database
        .into(_goals)
        .insertOnConflictUpdate(
          goalCompanion(goal, createdAt: existing?.createdAt ?? now, now: now),
        );
    await _recorder.record(
      EntityType.goal,
      goal.id,
      existing == null ? null : goalRecordJson(goalFromRow(existing)),
      goalRecordJson(goal),
    );
  }

  Future<void> _writeContribution(
    GoalContributionRow? existing,
    GoalContribution contribution,
  ) async {
    final DateTime now = _clock.nowUtc();
    await _database
        .into(_contributions)
        .insertOnConflictUpdate(
          goalContributionCompanion(
            contribution,
            createdAt: existing?.createdAt ?? now,
            now: now,
          ),
        );
    await _recorder.record(
      EntityType.goalContribution,
      contribution.id,
      existing == null
          ? null
          : goalContributionRecordJson(goalContributionFromRow(existing)),
      goalContributionRecordJson(contribution),
    );
  }

  @override
  Future<void> create(Goal goal) => _database.transaction(() async {
    if (await _goalRow(goal.id) != null) {
      throw ArgumentError.value(goal.id, 'goal', 'already exists');
    }
    await _writeGoal(null, goal.copyWith(archivedAt: null, deletedAt: null));
  });

  @override
  Future<void> update(Goal goal) => _database.transaction(() async {
    final GoalRow? existing = await _goalRow(goal.id);
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
  });

  @override
  Future<void> setArchived(String id, {required bool archived}) =>
      _database.transaction(() async {
        final GoalRow? existing = await _goalRow(id);
        if (existing == null ||
            existing.deletedAt != null ||
            (existing.archivedAt != null) == archived) {
          return;
        }
        await _writeGoal(
          existing,
          goalFromRow(existing)
              .copyWith(archivedAt: archived ? _clock.nowUtc() : null),
        );
      });

  @override
  Future<void> delete(String id) => _database.transaction(() async {
    final GoalRow? existing = await _goalRow(id);
    if (existing == null || existing.deletedAt != null) return;
    await _writeGoal(
      existing,
      goalFromRow(existing).copyWith(deletedAt: _clock.nowUtc()),
    );
  });

  @override
  Future<void> restore(String id) => _database.transaction(() async {
    final GoalRow? existing = await _goalRow(id);
    if (existing == null || existing.deletedAt == null) return;
    await _writeGoal(existing, goalFromRow(existing).copyWith(deletedAt: null));
  });

  @override
  Future<void> addContribution(GoalContribution contribution) =>
      _database.transaction(() async {
        final GoalRow? goal = await _goalRow(contribution.goalId);
        if (goal == null) {
          throw ArgumentError.value(
            contribution.goalId,
            'goal',
            'does not exist',
          );
        }
        if (goal.deletedAt != null) {
          throw EntityDeletedException('goal', goal.id);
        }
        if (await _contributionRow(contribution.id) != null) {
          throw ArgumentError.value(contribution.id, 'contribution', 'exists');
        }
        if (contribution.amount.currencyCode != goal.currency) {
          throw CurrencyMismatchException(
            goal.currency,
            contribution.amount.currencyCode,
          );
        }
        await _writeContribution(null, contribution.copyWith(deletedAt: null));
      });

  @override
  Future<void> deleteContribution(String id) => _database.transaction(() async {
    final GoalContributionRow? existing = await _contributionRow(id);
    if (existing == null || existing.deletedAt != null) return;
    await _writeContribution(
      existing,
      goalContributionFromRow(existing).copyWith(deletedAt: _clock.nowUtc()),
    );
  });

  @override
  Future<void> restoreContribution(String id) =>
      _database.transaction(() async {
        final GoalContributionRow? existing = await _contributionRow(id);
        if (existing == null || existing.deletedAt == null) return;
        await _writeContribution(
          existing,
          goalContributionFromRow(existing).copyWith(deletedAt: null),
        );
      });

  Future<GoalRow?> _goalRow(String id) => (_database.select(
    _goals,
  )..where((g) => g.id.equals(id))).getSingleOrNull();

  Future<GoalContributionRow?> _contributionRow(String id) => (_database.select(
    _contributions,
  )..where((c) => c.id.equals(id))).getSingleOrNull();
}
