/// A spending budget (`PLAN.md` §6.2).
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_models/src/entities/enums.dart';
import 'package:shared_models/src/money/money.dart';
import 'package:shared_models/src/time/local_date.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

/// A budget for a category (a parent category budgets its group) per period.
@freezed
abstract class Budget with _$Budget {
  /// A budget; each period starts on [periodStartDay], 1 to 28. [startDate] is the first
  /// day of the budget's first period (the period that contains it), from which rollover
  /// accumulates, so every device computes the same carry from the synced budget alone.
  /// The assertion checks constructed values in debug builds; JSON is checked in every
  /// build, because an assertion is compiled out of release builds.
  @Assert(
    'periodStartDay >= 1 && periodStartDay <= 28',
    'periodStartDay must be 1 to 28',
  )
  const factory Budget({
    required String id,
    required String categoryId,
    required BudgetPeriodKind period,
    @_PeriodStartDayConverter() required int periodStartDay,
    required Money amount,
    required bool rollover,
    required LocalDate startDate,
  }) = _Budget;

  /// Reads the snake_case JSON form.
  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);
}

/// Rejects a `period_start_day` outside 1 to 28 at the JSON boundary with a
/// [FormatException], which `checked` mode reports against the field.
final class _PeriodStartDayConverter implements JsonConverter<int, int> {
  const _PeriodStartDayConverter();

  @override
  int fromJson(int json) {
    if (json < 1 || json > 28) {
      throw FormatException('period_start_day must be 1 to 28', json);
    }
    return json;
  }

  @override
  int toJson(int object) => object;
}
