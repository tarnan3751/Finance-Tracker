// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entity_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const EntityType _$account = const EntityType._('account');
const EntityType _$transaction = const EntityType._('transaction');
const EntityType _$category = const EntityType._('category');
const EntityType _$rule = const EntityType._('rule');
const EntityType _$budget = const EntityType._('budget');
const EntityType _$recurringStream = const EntityType._('recurringStream');
const EntityType _$billReminder = const EntityType._('billReminder');
const EntityType _$goal = const EntityType._('goal');
const EntityType _$settings = const EntityType._('settings');

EntityType _$valueOf(String name) {
  switch (name) {
    case 'account':
      return _$account;
    case 'transaction':
      return _$transaction;
    case 'category':
      return _$category;
    case 'rule':
      return _$rule;
    case 'budget':
      return _$budget;
    case 'recurringStream':
      return _$recurringStream;
    case 'billReminder':
      return _$billReminder;
    case 'goal':
      return _$goal;
    case 'settings':
      return _$settings;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<EntityType> _$values = BuiltSet<EntityType>(const <EntityType>[
  _$account,
  _$transaction,
  _$category,
  _$rule,
  _$budget,
  _$recurringStream,
  _$billReminder,
  _$goal,
  _$settings,
]);

class _$EntityTypeMeta {
  const _$EntityTypeMeta();
  EntityType get account => _$account;
  EntityType get transaction => _$transaction;
  EntityType get category => _$category;
  EntityType get rule => _$rule;
  EntityType get budget => _$budget;
  EntityType get recurringStream => _$recurringStream;
  EntityType get billReminder => _$billReminder;
  EntityType get goal => _$goal;
  EntityType get settings => _$settings;
  EntityType valueOf(String name) => _$valueOf(name);
  BuiltSet<EntityType> get values => _$values;
}

mixin _$EntityTypeMixin {
  // ignore: non_constant_identifier_names
  _$EntityTypeMeta get EntityType => const _$EntityTypeMeta();
}

Serializer<EntityType> _$entityTypeSerializer = _$EntityTypeSerializer();

class _$EntityTypeSerializer implements PrimitiveSerializer<EntityType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'account': 'account',
    'transaction': 'transaction',
    'category': 'category',
    'rule': 'rule',
    'budget': 'budget',
    'recurringStream': 'recurring_stream',
    'billReminder': 'bill_reminder',
    'goal': 'goal',
    'settings': 'settings',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'account': 'account',
    'transaction': 'transaction',
    'category': 'category',
    'rule': 'rule',
    'budget': 'budget',
    'recurring_stream': 'recurringStream',
    'bill_reminder': 'billReminder',
    'goal': 'goal',
    'settings': 'settings',
  };

  @override
  final Iterable<Type> types = const <Type>[EntityType];
  @override
  final String wireName = 'EntityType';

  @override
  Object serialize(
    Serializers serializers,
    EntityType object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  EntityType deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => EntityType.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
