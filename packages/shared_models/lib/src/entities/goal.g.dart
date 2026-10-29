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
      kind: $checkedConvert('kind', (v) => $enumDecode(_$GoalKindEnumMap, v)),
      linkedAccountIds: $checkedConvert(
        'linked_account_ids',
        (v) =>
            (v as List<dynamic>?)?.map((e) => e as String).toList() ??
            const <String>[],
      ),
      targetDate: $checkedConvert(
        'target_date',
        (v) => v == null ? null : LocalDate.fromJson(v as String),
      ),
      createdOn: $checkedConvert(
        'created_on',
        (v) => LocalDate.fromJson(v as String),
      ),
      note: $checkedConvert('note', (v) => v as String?),
      archivedAt: $checkedConvert(
        'archived_at',
        (v) => _$JsonConverterFromJson<String, DateTime>(
          v,
          const UtcInstantConverter().fromJson,
        ),
      ),
      deletedAt: $checkedConvert(
        'deleted_at',
        (v) => _$JsonConverterFromJson<String, DateTime>(
          v,
          const UtcInstantConverter().fromJson,
        ),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'linkedAccountIds': 'linked_account_ids',
    'targetDate': 'target_date',
    'createdOn': 'created_on',
    'archivedAt': 'archived_at',
    'deletedAt': 'deleted_at',
  },
);

Map<String, dynamic> _$GoalToJson(_Goal instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'target': instance.target.toJson(),
  'kind': _$GoalKindEnumMap[instance.kind]!,
  'linked_account_ids': instance.linkedAccountIds,
  'target_date': instance.targetDate?.toJson(),
  'created_on': instance.createdOn.toJson(),
  'note': instance.note,
  'archived_at': _$JsonConverterToJson<String, DateTime>(
    instance.archivedAt,
    const UtcInstantConverter().toJson,
  ),
  'deleted_at': _$JsonConverterToJson<String, DateTime>(
    instance.deletedAt,
    const UtcInstantConverter().toJson,
  ),
};

const _$GoalKindEnumMap = {
  GoalKind.balance: 'balance',
  GoalKind.contribution: 'contribution',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

_GoalContribution _$GoalContributionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_GoalContribution', json, ($checkedConvert) {
      final val = _GoalContribution(
        id: $checkedConvert('id', (v) => v as String),
        goalId: $checkedConvert('goal_id', (v) => v as String),
        date: $checkedConvert('date', (v) => LocalDate.fromJson(v as String)),
        amount: $checkedConvert(
          'amount',
          (v) => Money.fromJson(v as Map<String, dynamic>),
        ),
        note: $checkedConvert('note', (v) => v as String?),
        deletedAt: $checkedConvert(
          'deleted_at',
          (v) => _$JsonConverterFromJson<String, DateTime>(
            v,
            const UtcInstantConverter().fromJson,
          ),
        ),
      );
      return val;
    }, fieldKeyMap: const {'goalId': 'goal_id', 'deletedAt': 'deleted_at'});

Map<String, dynamic> _$GoalContributionToJson(_GoalContribution instance) =>
    <String, dynamic>{
      'id': instance.id,
      'goal_id': instance.goalId,
      'date': instance.date.toJson(),
      'amount': instance.amount.toJson(),
      'note': instance.note,
      'deleted_at': _$JsonConverterToJson<String, DateTime>(
        instance.deletedAt,
        const UtcInstantConverter().toJson,
      ),
    };
