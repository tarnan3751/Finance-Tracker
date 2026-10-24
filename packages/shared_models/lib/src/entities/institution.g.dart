// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'institution.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Institution _$InstitutionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_Institution', json, ($checkedConvert) {
  final val = _Institution(
    id: $checkedConvert('id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    logoUrl: $checkedConvert(
      'logo_url',
      (v) => v == null ? null : Uri.parse(v as String),
    ),
    primaryColor: $checkedConvert('primary_color', (v) => (v as num?)?.toInt()),
  );
  return val;
}, fieldKeyMap: const {'logoUrl': 'logo_url', 'primaryColor': 'primary_color'});

Map<String, dynamic> _$InstitutionToJson(_Institution instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'logo_url': instance.logoUrl?.toString(),
      'primary_color': instance.primaryColor,
    };
