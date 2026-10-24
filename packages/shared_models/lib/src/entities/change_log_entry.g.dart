// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_log_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChangeLogEntry _$ChangeLogEntryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      '_ChangeLogEntry',
      json,
      ($checkedConvert) {
        final val = _ChangeLogEntry(
          entityType: $checkedConvert(
            'entity_type',
            (v) => $enumDecode(_$EntityTypeEnumMap, v),
          ),
          entityId: $checkedConvert('entity_id', (v) => v as String),
          operation: $checkedConvert(
            'operation',
            (v) => $enumDecode(_$ChangeOperationEnumMap, v),
          ),
          payload: $checkedConvert('payload', (v) => v as Map<String, dynamic>),
          hlc: $checkedConvert(
            'hlc',
            (v) => const HlcConverter().fromJson(v as String),
          ),
          deviceId: $checkedConvert('device_id', (v) => v as String),
          synced: $checkedConvert('synced', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'entityType': 'entity_type',
        'entityId': 'entity_id',
        'deviceId': 'device_id',
      },
    );

Map<String, dynamic> _$ChangeLogEntryToJson(_ChangeLogEntry instance) =>
    <String, dynamic>{
      'entity_type': _$EntityTypeEnumMap[instance.entityType]!,
      'entity_id': instance.entityId,
      'operation': _$ChangeOperationEnumMap[instance.operation]!,
      'payload': instance.payload,
      'hlc': const HlcConverter().toJson(instance.hlc),
      'device_id': instance.deviceId,
      'synced': instance.synced,
    };

const _$EntityTypeEnumMap = {
  EntityType.account: 'account',
  EntityType.transaction: 'transaction',
  EntityType.category: 'category',
  EntityType.rule: 'rule',
  EntityType.budget: 'budget',
  EntityType.recurringStream: 'recurring_stream',
  EntityType.billReminder: 'bill_reminder',
  EntityType.goal: 'goal',
  EntityType.settings: 'settings',
};

const _$ChangeOperationEnumMap = {
  ChangeOperation.create: 'create',
  ChangeOperation.update: 'update',
  ChangeOperation.delete: 'delete',
};
