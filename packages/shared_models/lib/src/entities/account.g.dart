// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Account _$AccountFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_Account',
  json,
  ($checkedConvert) {
    final val = _Account(
      id: $checkedConvert('id', (v) => v as String),
      itemId: $checkedConvert('item_id', (v) => v as String?),
      type: $checkedConvert(
        'type',
        (v) => $enumDecode(
          _$AccountTypeEnumMap,
          v,
          unknownValue: AccountType.other,
        ),
      ),
      subtype: $checkedConvert('subtype', (v) => v as String?),
      name: $checkedConvert('name', (v) => v as String),
      officialName: $checkedConvert('official_name', (v) => v as String?),
      mask: $checkedConvert('mask', (v) => v as String?),
      currencyCode: $checkedConvert('currency_code', (v) => v as String),
      currentBalance: $checkedConvert(
        'current_balance',
        (v) => v == null ? null : Money.fromJson(v as Map<String, dynamic>),
      ),
      availableBalance: $checkedConvert(
        'available_balance',
        (v) => v == null ? null : Money.fromJson(v as Map<String, dynamic>),
      ),
      creditLimit: $checkedConvert(
        'credit_limit',
        (v) => v == null ? null : Money.fromJson(v as Map<String, dynamic>),
      ),
      balancesAsOf: $checkedConvert(
        'balances_as_of',
        (v) => _$JsonConverterFromJson<String, DateTime>(
          v,
          const UtcInstantConverter().fromJson,
        ),
      ),
      isHidden: $checkedConvert('is_hidden', (v) => v as bool),
      displayOrder: $checkedConvert('display_order', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'itemId': 'item_id',
    'officialName': 'official_name',
    'currencyCode': 'currency_code',
    'currentBalance': 'current_balance',
    'availableBalance': 'available_balance',
    'creditLimit': 'credit_limit',
    'balancesAsOf': 'balances_as_of',
    'isHidden': 'is_hidden',
    'displayOrder': 'display_order',
  },
);

Map<String, dynamic> _$AccountToJson(_Account instance) => <String, dynamic>{
  'id': instance.id,
  'item_id': instance.itemId,
  'type': _$AccountTypeEnumMap[instance.type]!,
  'subtype': instance.subtype,
  'name': instance.name,
  'official_name': instance.officialName,
  'mask': instance.mask,
  'currency_code': instance.currencyCode,
  'current_balance': instance.currentBalance?.toJson(),
  'available_balance': instance.availableBalance?.toJson(),
  'credit_limit': instance.creditLimit?.toJson(),
  'balances_as_of': _$JsonConverterToJson<String, DateTime>(
    instance.balancesAsOf,
    const UtcInstantConverter().toJson,
  ),
  'is_hidden': instance.isHidden,
  'display_order': instance.displayOrder,
};

const _$AccountTypeEnumMap = {
  AccountType.depository: 'depository',
  AccountType.credit: 'credit',
  AccountType.loan: 'loan',
  AccountType.investment: 'investment',
  AccountType.other: 'other',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
