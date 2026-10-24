// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_stream.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecurringStream _$RecurringStreamFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_RecurringStream',
      json,
      ($checkedConvert) {
        final val = _RecurringStream(
          id: $checkedConvert('id', (v) => v as String),
          accountId: $checkedConvert('account_id', (v) => v as String),
          merchantName: $checkedConvert('merchant_name', (v) => v as String),
          cadence: $checkedConvert(
            'cadence',
            (v) => $enumDecode(
              _$RecurringCadenceEnumMap,
              v,
              unknownValue: RecurringCadence.unknown,
            ),
          ),
          averageAmount: $checkedConvert(
            'average_amount',
            (v) => Money.fromJson(v as Map<String, dynamic>),
          ),
          lastExpected: $checkedConvert(
            'last_expected',
            (v) => v == null ? null : LocalDate.fromJson(v as String),
          ),
          nextExpected: $checkedConvert(
            'next_expected',
            (v) => v == null ? null : LocalDate.fromJson(v as String),
          ),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$RecurringStatusEnumMap, v),
          ),
          isSubscription: $checkedConvert('is_subscription', (v) => v as bool),
          source: $checkedConvert(
            'source',
            (v) => $enumDecode(_$RecurringSourceEnumMap, v),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'accountId': 'account_id',
        'merchantName': 'merchant_name',
        'averageAmount': 'average_amount',
        'lastExpected': 'last_expected',
        'nextExpected': 'next_expected',
        'isSubscription': 'is_subscription',
      },
    );

Map<String, dynamic> _$RecurringStreamToJson(_RecurringStream instance) =>
    <String, dynamic>{
      'id': instance.id,
      'account_id': instance.accountId,
      'merchant_name': instance.merchantName,
      'cadence': _$RecurringCadenceEnumMap[instance.cadence]!,
      'average_amount': instance.averageAmount.toJson(),
      'last_expected': instance.lastExpected?.toJson(),
      'next_expected': instance.nextExpected?.toJson(),
      'status': _$RecurringStatusEnumMap[instance.status]!,
      'is_subscription': instance.isSubscription,
      'source': _$RecurringSourceEnumMap[instance.source]!,
    };

const _$RecurringCadenceEnumMap = {
  RecurringCadence.weekly: 'weekly',
  RecurringCadence.biweekly: 'biweekly',
  RecurringCadence.semiMonthly: 'semi_monthly',
  RecurringCadence.monthly: 'monthly',
  RecurringCadence.annually: 'annually',
  RecurringCadence.unknown: 'unknown',
};

const _$RecurringStatusEnumMap = {
  RecurringStatus.active: 'active',
  RecurringStatus.ended: 'ended',
};

const _$RecurringSourceEnumMap = {
  RecurringSource.plaid: 'plaid',
  RecurringSource.detected: 'detected',
  RecurringSource.user: 'user',
};
