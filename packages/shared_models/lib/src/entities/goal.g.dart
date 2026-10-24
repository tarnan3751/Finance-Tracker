// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Goal _$GoalFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_Goal',
  json,
  ($checkedConvert) {
    final val = _Goal(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      target: $checkedConvert(
        'target',
        (v) => Money.fromJson(v as Map<String, dynamic>),
      ),
      linkedAccountIds: $checkedConvert(
        'linked_account_ids',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      targetDate: $checkedConvert(
        'target_date',
        (v) => v == null ? null : LocalDate.fromJson(v as String),
      ),
      contributions: $checkedConvert(
        'contributions',
        (v) => (v as List<dynamic>)
            .map((e) => GoalContribution.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'linkedAccountIds': 'linked_account_ids',
    'targetDate': 'target_date',
  },
);

Map<String, dynamic> _$GoalToJson(_Goal instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'target': instance.target.toJson(),
  'linked_account_ids': instance.linkedAccountIds,
  'target_date': instance.targetDate?.toJson(),
  'contributions': instance.contributions.map((e) => e.toJson()).toList(),
};

_GoalContribution _$GoalContributionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_GoalContribution', json, ($checkedConvert) {
      final val = _GoalContribution(
        date: $checkedConvert('date', (v) => LocalDate.fromJson(v as String)),
        amount: $checkedConvert(
          'amount',
          (v) => Money.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GoalContributionToJson(_GoalContribution instance) =>
    <String, dynamic>{
      'date': instance.date.toJson(),
      'amount': instance.amount.toJson(),
    };
