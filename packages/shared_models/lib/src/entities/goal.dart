/// A savings goal (`PLAN.md` §6.2).
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_models/src/money/money.dart';
import 'package:shared_models/src/time/local_date.dart';

part 'goal.freezed.dart';
part 'goal.g.dart';

/// A goal to reach [target] by [targetDate], optionally tracked through linked accounts.
@freezed
abstract class Goal with _$Goal {
  /// A goal.
  const factory Goal({
    required String id,
    required String name,
    required Money target,
    required List<String> linkedAccountIds,
    LocalDate? targetDate,
    required List<GoalContribution> contributions,
  }) = _Goal;

  /// Reads the snake_case JSON form.
  factory Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);
}

/// An amount put toward a goal on a date.
@freezed
abstract class GoalContribution with _$GoalContribution {
  /// A contribution.
  const factory GoalContribution({
    required LocalDate date,
    required Money amount,
  }) = _GoalContribution;

  /// Reads the snake_case JSON form.
  factory GoalContribution.fromJson(Map<String, dynamic> json) =>
      _$GoalContributionFromJson(json);
}
