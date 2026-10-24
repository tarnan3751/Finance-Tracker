// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Device _$DeviceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_Device', json, ($checkedConvert) {
      final val = _Device(
        id: $checkedConvert('id', (v) => v as String),
        userId: $checkedConvert('user_id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        lastSyncAt: $checkedConvert(
          'last_sync_at',
          (v) => _$JsonConverterFromJson<String, DateTime>(
            v,
            const UtcInstantConverter().fromJson,
          ),
        ),
      );
      return val;
    }, fieldKeyMap: const {'userId': 'user_id', 'lastSyncAt': 'last_sync_at'});

Map<String, dynamic> _$DeviceToJson(_Device instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'name': instance.name,
  'last_sync_at': _$JsonConverterToJson<String, DateTime>(
    instance.lastSyncAt,
    const UtcInstantConverter().toJson,
  ),
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
