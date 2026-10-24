// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Rule _$RuleFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_Rule', json, ($checkedConvert) {
      final val = _Rule(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        position: $checkedConvert('position', (v) => (v as num).toInt()),
        conditions: $checkedConvert(
          'conditions',
          (v) => (v as List<dynamic>)
              .map((e) => RuleCondition.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        actions: $checkedConvert(
          'actions',
          (v) => (v as List<dynamic>)
              .map((e) => RuleAction.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$RuleToJson(_Rule instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'position': instance.position,
  'conditions': instance.conditions.map((e) => e.toJson()).toList(),
  'actions': instance.actions.map((e) => e.toJson()).toList(),
};

_RuleCondition _$RuleConditionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_RuleCondition',
      json,
      ($checkedConvert) {
        final val = _RuleCondition(
          kind: $checkedConvert(
            'kind',
            (v) => $enumDecode(_$RuleConditionKindEnumMap, v),
          ),
          text: $checkedConvert('text', (v) => v as String?),
          minAmount: $checkedConvert(
            'min_amount',
            (v) => v == null ? null : Money.fromJson(v as Map<String, dynamic>),
          ),
          maxAmount: $checkedConvert(
            'max_amount',
            (v) => v == null ? null : Money.fromJson(v as Map<String, dynamic>),
          ),
        );
        return val;
      },
      fieldKeyMap: const {'minAmount': 'min_amount', 'maxAmount': 'max_amount'},
    );

Map<String, dynamic> _$RuleConditionToJson(_RuleCondition instance) =>
    <String, dynamic>{
      'kind': _$RuleConditionKindEnumMap[instance.kind]!,
      'text': instance.text,
      'min_amount': instance.minAmount?.toJson(),
      'max_amount': instance.maxAmount?.toJson(),
    };

const _$RuleConditionKindEnumMap = {
  RuleConditionKind.merchantContains: 'merchant_contains',
  RuleConditionKind.amountBetween: 'amount_between',
  RuleConditionKind.account: 'account',
  RuleConditionKind.plaidCategory: 'plaid_category',
};

_RuleAction _$RuleActionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_RuleAction', json, ($checkedConvert) {
      final val = _RuleAction(
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$RuleActionKindEnumMap, v),
        ),
        value: $checkedConvert('value', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$RuleActionToJson(_RuleAction instance) =>
    <String, dynamic>{
      'kind': _$RuleActionKindEnumMap[instance.kind]!,
      'value': instance.value,
    };

const _$RuleActionKindEnumMap = {
  RuleActionKind.setCategory: 'set_category',
  RuleActionKind.addTag: 'add_tag',
  RuleActionKind.rename: 'rename',
  RuleActionKind.hide: 'hide',
};
