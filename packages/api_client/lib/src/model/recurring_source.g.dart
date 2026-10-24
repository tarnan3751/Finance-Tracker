// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_source.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const RecurringSource _$plaid = const RecurringSource._('plaid');
const RecurringSource _$detected = const RecurringSource._('detected');
const RecurringSource _$user = const RecurringSource._('user');
const RecurringSource _$demo = const RecurringSource._('demo');

RecurringSource _$valueOf(String name) {
  switch (name) {
    case 'plaid':
      return _$plaid;
    case 'detected':
      return _$detected;
    case 'user':
      return _$user;
    case 'demo':
      return _$demo;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<RecurringSource> _$values = BuiltSet<RecurringSource>(
  const <RecurringSource>[_$plaid, _$detected, _$user, _$demo],
);

class _$RecurringSourceMeta {
  const _$RecurringSourceMeta();
  RecurringSource get plaid => _$plaid;
  RecurringSource get detected => _$detected;
  RecurringSource get user => _$user;
  RecurringSource get demo => _$demo;
  RecurringSource valueOf(String name) => _$valueOf(name);
  BuiltSet<RecurringSource> get values => _$values;
}

mixin _$RecurringSourceMixin {
  // ignore: non_constant_identifier_names
  _$RecurringSourceMeta get RecurringSource => const _$RecurringSourceMeta();
}

Serializer<RecurringSource> _$recurringSourceSerializer =
    _$RecurringSourceSerializer();

class _$RecurringSourceSerializer
    implements PrimitiveSerializer<RecurringSource> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'plaid': 'plaid',
    'detected': 'detected',
    'user': 'user',
    'demo': 'demo',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'plaid': 'plaid',
    'detected': 'detected',
    'user': 'user',
    'demo': 'demo',
  };

  @override
  final Iterable<Type> types = const <Type>[RecurringSource];
  @override
  final String wireName = 'RecurringSource';

  @override
  Object serialize(
    Serializers serializers,
    RecurringSource object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  RecurringSource deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => RecurringSource.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
