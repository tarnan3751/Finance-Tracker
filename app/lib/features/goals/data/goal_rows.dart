/// The `goals` and `goal_contributions` rows and the entities they hold: shared by the
/// Drift repository and the Drift sync store, which materializes `goal` and
/// `goal_contribution` records.
library;

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:finance_tracker/core/db/app_database.dart';
import 'package:shared_models/shared_models.dart';

/// The row of [goal], its tombstone and archive instant included, stamped [createdAt]
/// and [now]. The linked accounts are a JSON array.
GoalsCompanion goalCompanion(
  Goal goal, {
  required DateTime createdAt,
  required DateTime now,
}) => GoalsCompanion(
  id: Value(goal.id),
  name: Value(goal.name),
  targetMinor: Value(goal.target.minorUnits),
  currency: Value(goal.target.currencyCode),
  kind: Value(goal.kind),
  linkedAccountIds: Value(jsonEncode(goal.linkedAccountIds)),
  targetDate: Value(goal.targetDate),
  createdOn: Value(goal.createdOn),
  note: Value(goal.note),
  archivedAt: Value(goal.archivedAt),
  createdAt: Value(createdAt),
  updatedAt: Value(now),
  deletedAt: Value(goal.deletedAt),
);

/// The [Goal] a row holds.
Goal goalFromRow(GoalRow row) => Goal(
  id: row.id,
  name: row.name,
  target: Money(row.targetMinor, row.currency),
  kind: row.kind,
  linkedAccountIds: [
    for (final Object? id in jsonDecode(row.linkedAccountIds) as List<Object?>)
      id! as String,
  ],
  targetDate: row.targetDate,
  createdOn: row.createdOn,
  note: row.note,
  archivedAt: row.archivedAt,
  deletedAt: row.deletedAt,
);

/// The row of [contribution], its tombstone included, stamped [createdAt] and [now].
GoalContributionsCompanion goalContributionCompanion(
  GoalContribution contribution, {
  required DateTime createdAt,
  required DateTime now,
}) => GoalContributionsCompanion(
  id: Value(contribution.id),
  goalId: Value(contribution.goalId),
  date: Value(contribution.date),
  amountMinor: Value(contribution.amount.minorUnits),
  currency: Value(contribution.amount.currencyCode),
  note: Value(contribution.note),
  createdAt: Value(createdAt),
  updatedAt: Value(now),
  deletedAt: Value(contribution.deletedAt),
);

/// The [GoalContribution] a row holds.
GoalContribution goalContributionFromRow(GoalContributionRow row) =>
    GoalContribution(
      id: row.id,
      goalId: row.goalId,
      date: row.date,
      amount: Money(row.amountMinor, row.currency),
      note: row.note,
      deletedAt: row.deletedAt,
    );
