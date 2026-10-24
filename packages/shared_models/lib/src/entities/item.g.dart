// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Item _$ItemFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_Item',
  json,
  ($checkedConvert) {
    final val = _Item(
      id: $checkedConvert('id', (v) => v as String),
      institutionId: $checkedConvert('institution_id', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(
          _$ItemStatusEnumMap,
          v,
          unknownValue: ItemStatus.unknown,
        ),
      ),
      lastSuccessfulSyncAt: $checkedConvert(
        'last_successful_sync_at',
        (v) => _$JsonConverterFromJson<String, DateTime>(
          v,
          const UtcInstantConverter().fromJson,
        ),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'institutionId': 'institution_id',
    'lastSuccessfulSyncAt': 'last_successful_sync_at',
  },
);

Map<String, dynamic> _$ItemToJson(_Item instance) => <String, dynamic>{
  'id': instance.id,
  'institution_id': instance.institutionId,
  'status': _$ItemStatusEnumMap[instance.status]!,
  'last_successful_sync_at': _$JsonConverterToJson<String, DateTime>(
    instance.lastSuccessfulSyncAt,
    const UtcInstantConverter().toJson,
  ),
};

const _$ItemStatusEnumMap = {
  ItemStatus.healthy: 'healthy',
  ItemStatus.loginRequired: 'login_required',
  ItemStatus.error: 'error',
  ItemStatus.pendingExpiration: 'pending_expiration',
  ItemStatus.unknown: 'unknown',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
