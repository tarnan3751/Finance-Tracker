// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Budget _$BudgetFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_Budget',
  json,
  ($checkedConvert) {
    final val = _Budget(
      id: $checkedConvert('id', (v) => v as String),
      categoryId: $checkedConvert('category_id', (v) => v as String),
      period: $checkedConvert(
        'period',
        (v) => $enumDecode(_$BudgetPeriodKindEnumMap, v),
      ),
      periodStartDay: $checkedConvert(
        'period_start_day',
        (v) => const _PeriodStartDayConverter().fromJson((v as num).toInt()),
      ),
      amount: $checkedConvert(
        'amount',
        (v) => Money.fromJson(v as Map<String, dynamic>),
      ),
      rollover: $checkedConvert('rollover', (v) => v as bool),
    );
    return val;
  },
  fieldKeyMap: const {
    'categoryId': 'category_id',
    'periodStartDay': 'period_start_day',
  },
);

Map<String, dynamic> _$BudgetToJson(_Budget instance) => <String, dynamic>{
  'id': instance.id,
  'category_id': instance.categoryId,
  'period': _$BudgetPeriodKindEnumMap[instance.period]!,
  'period_start_day': const _PeriodStartDayConverter().toJson(
    instance.periodStartDay,
  ),
  'amount': instance.amount.toJson(),
  'rollover': instance.rollover,
};

const _$BudgetPeriodKindEnumMap = {BudgetPeriodKind.monthly: 'monthly'};
