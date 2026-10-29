/// The user's savings goals and their contributions (`docs/reference/goals.md`).
///
/// Implementations: Drift (dev and prod), in memory (tests), demo (the demo flavor, with
/// the two goals of the persona it shows); all pass
/// `test/contract/goal_repository_contract.dart`.
library;

import 'package:shared_models/shared_models.dart';

/// A live goal and its live contributions, by date, then by id.
final class GoalEntry {
  /// The [goal] with its [contributions].
  GoalEntry(this.goal, List<GoalContribution> contributions)
    : contributions = List.unmodifiable(contributions);

  /// The goal.
  final Goal goal;

  /// Its live contributions, by date, then by id.
  final List<GoalContribution> contributions;

  @override
  bool operator ==(Object other) {
    if (other is! GoalEntry ||
        other.goal != goal ||
        other.contributions.length != contributions.length) {
      return false;
    }
    for (int i = 0; i < contributions.length; i++) {
      if (other.contributions[i] != contributions[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(goal, Object.hashAll(contributions));

  @override
  String toString() => 'GoalEntry($goal, $contributions)';
}

/// Reads and writes goals and their contributions. Every stream starts with the current
/// value and emits again only when that value changes. Deletes are soft; the restores are
/// the only way back. A deleted goal's contributions stay as they are and show again when
/// it is restored; a contribution whose goal this device has not received (another
/// device's, synced first) is not shown until the goal arrives.
abstract interface class GoalRepository {
  /// The live goals, archived ones included, by creation day, then by id, each with its
  /// live contributions.
  Stream<List<GoalEntry>> watchAll();

  /// Goal [id] with its live contributions, or null when there is no such live goal.
  Stream<GoalEntry?> watchById(String id);

  /// Stores new [goal], live and not archived whatever its `archivedAt` and
  /// `deletedAt` say. Throws [ArgumentError] when a goal [goal]'s id already exists.
  Future<void> create(Goal goal);

  /// Replaces live goal [goal]'s fields, keeping its stored archive state (changed only
  /// by [setArchived]). Throws `EntityDeletedException`
  /// (`core/db/database_exceptions.dart`) when the goal is deleted, [ArgumentError] when
  /// there is no such goal.
  Future<void> update(Goal goal);

  /// Archives live goal [id] now, or brings it back from the archive; does nothing when
  /// it already is so, or there is no such live goal.
  Future<void> setArchived(String id, {required bool archived});

  /// Soft-deletes goal [id]; does nothing when there is no such live goal.
  Future<void> delete(String id);

  /// Restores deleted goal [id]; does nothing when there is no such deleted goal.
  Future<void> restore(String id);

  /// Stores new [contribution], live whatever its `deletedAt` says. Throws
  /// `EntityDeletedException` when its goal is deleted, [ArgumentError] when there is
  /// no such goal or a contribution with its id exists, and `CurrencyMismatchException`
  /// when its amount is in another currency than the goal's target.
  Future<void> addContribution(GoalContribution contribution);

  /// Soft-deletes contribution [id]; does nothing when there is no such live one.
  Future<void> deleteContribution(String id);

  /// Restores deleted contribution [id]; does nothing when there is no such deleted one.
  Future<void> restoreContribution(String id);
}
