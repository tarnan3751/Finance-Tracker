// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Category _$CategoryFromJson(Map<String, dynamic> json) => $checkedCreate(
  '_Category',
  json,
  ($checkedConvert) {
    final val = _Category(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      parentId: $checkedConvert('parent_id', (v) => v as String?),
      isSystem: $checkedConvert('is_system', (v) => v as bool),
      icon: $checkedConvert('icon', (v) => v as String),
      color: $checkedConvert('color', (v) => (v as num).toInt()),
      plaidCategory: $checkedConvert('plaid_category', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'parentId': 'parent_id',
    'isSystem': 'is_system',
    'plaidCategory': 'plaid_category',
  },
);

Map<String, dynamic> _$CategoryToJson(_Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'parent_id': instance.parentId,
  'is_system': instance.isSystem,
  'icon': instance.icon,
  'color': instance.color,
  'plaid_category': instance.plaidCategory,
};
