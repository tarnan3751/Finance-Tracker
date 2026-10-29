/// A savings goal and the contributions toward it (`PLAN.md` §6.2, §12 "Goals";
/// `docs/reference/goals.md`).
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_models/src/entities/enums.dart';
import 'package:shared_models/src/money/money.dart';
import 'package:shared_models/src/time/local_date.dart';
import 'package:shared_models/src/time/utc_instant_converter.dart';

part 'goal.freezed.dart';
part 'goal.g.dart';

/// A goal to reach [target] by [targetDate] (none: no date), created on [createdOn],
/// which starts its plan. A [GoalKind.balance] goal tracks [linkedAccountIds]; a
/// [GoalKind.contribution] goal its [GoalContribution]s, which are records of their own so
/// that contributions made on two devices both survive. [archivedAt] and [deletedAt] are
/// UTC instants.
@freezed
abstract class Goal with _$Goal {
  /// A goal.
  const factory Goal({
    required String id,
    required String name,
    required Money target,
    required GoalKind kind,
    @Default(<String>[]) List<String> linkedAccountIds,
    LocalDate? targetDate,
    required LocalDate createdOn,
    String? note,
    @UtcInstantConverter() DateTime? archivedAt,
    @UtcInstantConverter() DateTime? deletedAt,
  }) = _Goal;

  /// Reads the snake_case JSON form.
  factory Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);
}

/// An amount put toward goal [goalId] on [date]: positive adds, negative withdraws.
/// [deletedAt] is the tombstone, a UTC instant.
@freezed
abstract class GoalContribution with _$GoalContribution {
  /// A contribution.
  const factory GoalContribution({
    required String id,
    required String goalId,
    required LocalDate date,
    required Money amount,
    String? note,
    @UtcInstantConverter() DateTime? deletedAt,
  }) = _GoalContribution;

  /// Reads the snake_case JSON form.
  factory GoalContribution.fromJson(Map<String, dynamic> json) =>
      _$GoalContributionFromJson(json);
}
