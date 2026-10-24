// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_source.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DataSource _$plaid = const DataSource._('plaid');
const DataSource _$manual = const DataSource._('manual');
const DataSource _$import_ = const DataSource._('import_');
const DataSource _$derived = const DataSource._('derived');
const DataSource _$demo = const DataSource._('demo');

DataSource _$valueOf(String name) {
  switch (name) {
    case 'plaid':
      return _$plaid;
    case 'manual':
      return _$manual;
    case 'import_':
      return _$import_;
    case 'derived':
      return _$derived;
    case 'demo':
      return _$demo;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DataSource> _$values = BuiltSet<DataSource>(const <DataSource>[
  _$plaid,
  _$manual,
  _$import_,
  _$derived,
  _$demo,
]);

class _$DataSourceMeta {
  const _$DataSourceMeta();
  DataSource get plaid => _$plaid;
  DataSource get manual => _$manual;
  DataSource get import_ => _$import_;
  DataSource get derived => _$derived;
  DataSource get demo => _$demo;
  DataSource valueOf(String name) => _$valueOf(name);
  BuiltSet<DataSource> get values => _$values;
}

mixin _$DataSourceMixin {
  // ignore: non_constant_identifier_names
  _$DataSourceMeta get DataSource => const _$DataSourceMeta();
}

Serializer<DataSource> _$dataSourceSerializer = _$DataSourceSerializer();

class _$DataSourceSerializer implements PrimitiveSerializer<DataSource> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'plaid': 'plaid',
    'manual': 'manual',
    'import_': 'import',
    'derived': 'derived',
    'demo': 'demo',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'plaid': 'plaid',
    'manual': 'manual',
    'import': 'import_',
    'derived': 'derived',
    'demo': 'demo',
  };

  @override
  final Iterable<Type> types = const <Type>[DataSource];
  @override
  final String wireName = 'DataSource';

  @override
  Object serialize(
    Serializers serializers,
    DataSource object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DataSource deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DataSource.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
