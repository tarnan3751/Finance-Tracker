// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const RecurringStatus _$active = const RecurringStatus._('active');
const RecurringStatus _$ended = const RecurringStatus._('ended');

RecurringStatus _$valueOf(String name) {
  switch (name) {
    case 'active':
      return _$active;
    case 'ended':
      return _$ended;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<RecurringStatus> _$values = BuiltSet<RecurringStatus>(
  const <RecurringStatus>[_$active, _$ended],
);

class _$RecurringStatusMeta {
  const _$RecurringStatusMeta();
  RecurringStatus get active => _$active;
  RecurringStatus get ended => _$ended;
  RecurringStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<RecurringStatus> get values => _$values;
}

mixin _$RecurringStatusMixin {
  // ignore: non_constant_identifier_names
  _$RecurringStatusMeta get RecurringStatus => const _$RecurringStatusMeta();
}

Serializer<RecurringStatus> _$recurringStatusSerializer =
    _$RecurringStatusSerializer();

class _$RecurringStatusSerializer
    implements PrimitiveSerializer<RecurringStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'active': 'active',
    'ended': 'ended',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'active': 'active',
    'ended': 'ended',
  };

  @override
  final Iterable<Type> types = const <Type>[RecurringStatus];
  @override
  final String wireName = 'RecurringStatus';

  @override
  Object serialize(
    Serializers serializers,
    RecurringStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  RecurringStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => RecurringStatus.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
