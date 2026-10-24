// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BalanceSnapshot _$BalanceSnapshotFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_BalanceSnapshot', json, ($checkedConvert) {
      final val = _BalanceSnapshot(
        accountId: $checkedConvert('account_id', (v) => v as String),
        date: $checkedConvert('date', (v) => LocalDate.fromJson(v as String)),
        current: $checkedConvert(
          'current',
          (v) => Money.fromJson(v as Map<String, dynamic>),
        ),
        available: $checkedConvert(
          'available',
          (v) => v == null ? null : Money.fromJson(v as Map<String, dynamic>),
        ),
        limit: $checkedConvert(
          'limit',
          (v) => v == null ? null : Money.fromJson(v as Map<String, dynamic>),
        ),
        source: $checkedConvert(
          'source',
          (v) => $enumDecode(_$DataSourceEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'accountId': 'account_id'});

Map<String, dynamic> _$BalanceSnapshotToJson(_BalanceSnapshot instance) =>
    <String, dynamic>{
      'account_id': instance.accountId,
      'date': instance.date.toJson(),
      'current': instance.current.toJson(),
      'available': instance.available?.toJson(),
      'limit': instance.limit?.toJson(),
      'source': _$DataSourceEnumMap[instance.source]!,
    };

const _$DataSourceEnumMap = {
  DataSource.plaid: 'plaid',
  DataSource.manual: 'manual',
  DataSource.import: 'import',
  DataSource.derived: 'derived',
  DataSource.demo: 'demo',
};
