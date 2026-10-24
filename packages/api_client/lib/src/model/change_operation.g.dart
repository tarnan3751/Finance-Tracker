// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_operation.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ChangeOperation _$create = const ChangeOperation._('create');
const ChangeOperation _$update = const ChangeOperation._('update');
const ChangeOperation _$delete = const ChangeOperation._('delete');

ChangeOperation _$valueOf(String name) {
  switch (name) {
    case 'create':
      return _$create;
    case 'update':
      return _$update;
    case 'delete':
      return _$delete;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ChangeOperation> _$values = BuiltSet<ChangeOperation>(
  const <ChangeOperation>[_$create, _$update, _$delete],
);

class _$ChangeOperationMeta {
  const _$ChangeOperationMeta();
  ChangeOperation get create => _$create;
  ChangeOperation get update => _$update;
  ChangeOperation get delete => _$delete;
  ChangeOperation valueOf(String name) => _$valueOf(name);
  BuiltSet<ChangeOperation> get values => _$values;
}

mixin _$ChangeOperationMixin {
  // ignore: non_constant_identifier_names
  _$ChangeOperationMeta get ChangeOperation => const _$ChangeOperationMeta();
}

Serializer<ChangeOperation> _$changeOperationSerializer =
    _$ChangeOperationSerializer();

class _$ChangeOperationSerializer
    implements PrimitiveSerializer<ChangeOperation> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'create': 'create',
    'update': 'update',
    'delete': 'delete',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'create': 'create',
    'update': 'update',
    'delete': 'delete',
  };

  @override
  final Iterable<Type> types = const <Type>[ChangeOperation];
  @override
  final String wireName = 'ChangeOperation';

  @override
  Object serialize(
    Serializers serializers,
    ChangeOperation object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ChangeOperation deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ChangeOperation.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
