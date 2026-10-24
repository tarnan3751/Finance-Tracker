/// Rules applied to transactions on arrival (`PLAN.md` §6.2).
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_models/src/entities/enums.dart';
import 'package:shared_models/src/money/money.dart';

part 'rule.freezed.dart';
part 'rule.g.dart';

/// A rule: when every condition matches a transaction, the actions apply. Rules run in
/// [position] order.
@freezed
abstract class Rule with _$Rule {
  /// A rule.
  const factory Rule({
    required String id,
    required String name,
    required int position,
    required List<RuleCondition> conditions,
    required List<RuleAction> actions,
  }) = _Rule;

  /// Reads the snake_case JSON form.
  factory Rule.fromJson(Map<String, dynamic> json) => _$RuleFromJson(json);
}

/// One test a rule makes. [text] is the merchant substring, the account id or the Plaid
/// category code, by [kind]; [minAmount] and [maxAmount] bound `amountBetween`.
@freezed
abstract class RuleCondition with _$RuleCondition {
  /// A condition.
  const factory RuleCondition({
    required RuleConditionKind kind,
    String? text,
    Money? minAmount,
    Money? maxAmount,
  }) = _RuleCondition;

  /// Reads the snake_case JSON form.
  factory RuleCondition.fromJson(Map<String, dynamic> json) =>
      _$RuleConditionFromJson(json);
}

/// One change a rule makes. [value] is the category id, the tag or the new name, by
/// [kind]; null for `hide`.
@freezed
abstract class RuleAction with _$RuleAction {
  /// An action.
  const factory RuleAction({required RuleActionKind kind, String? value}) =
      _RuleAction;

  /// Reads the snake_case JSON form.
  factory RuleAction.fromJson(Map<String, dynamic> json) =>
      _$RuleActionFromJson(json);
}
