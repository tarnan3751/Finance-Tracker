// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'net_worth_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NetWorthSnapshot _$NetWorthSnapshotFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_NetWorthSnapshot', json, ($checkedConvert) {
      final val = _NetWorthSnapshot(
        date: $checkedConvert('date', (v) => LocalDate.fromJson(v as String)),
        assets: $checkedConvert(
          'assets',
          (v) => Money.fromJson(v as Map<String, dynamic>),
        ),
        liabilities: $checkedConvert(
          'liabilities',
          (v) => Money.fromJson(v as Map<String, dynamic>),
        ),
        byAccount: $checkedConvert(
          'by_account',
          (v) => (v as Map<String, dynamic>).map(
            (k, e) => MapEntry(k, Money.fromJson(e as Map<String, dynamic>)),
          ),
        ),
        source: $checkedConvert(
          'source',
          (v) => $enumDecode(_$DataSourceEnumMap, v),
        ),
      );
      return val;
    }, fieldKeyMap: const {'byAccount': 'by_account'});

Map<String, dynamic> _$NetWorthSnapshotToJson(_NetWorthSnapshot instance) =>
    <String, dynamic>{
      'date': instance.date.toJson(),
      'assets': instance.assets.toJson(),
      'liabilities': instance.liabilities.toJson(),
      'by_account': instance.byAccount.map((k, e) => MapEntry(k, e.toJson())),
      'source': _$DataSourceEnumMap[instance.source]!,
    };

const _$DataSourceEnumMap = {
  DataSource.plaid: 'plaid',
  DataSource.manual: 'manual',
  DataSource.import: 'import',
  DataSource.derived: 'derived',
  DataSource.demo: 'demo',
};
