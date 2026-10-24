// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ItemStatus _$healthy = const ItemStatus._('healthy');
const ItemStatus _$loginRequired = const ItemStatus._('loginRequired');
const ItemStatus _$error = const ItemStatus._('error');
const ItemStatus _$pendingExpiration = const ItemStatus._('pendingExpiration');
const ItemStatus _$unknown = const ItemStatus._('unknown');

ItemStatus _$valueOf(String name) {
  switch (name) {
    case 'healthy':
      return _$healthy;
    case 'loginRequired':
      return _$loginRequired;
    case 'error':
      return _$error;
    case 'pendingExpiration':
      return _$pendingExpiration;
    case 'unknown':
      return _$unknown;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ItemStatus> _$values = BuiltSet<ItemStatus>(const <ItemStatus>[
  _$healthy,
  _$loginRequired,
  _$error,
  _$pendingExpiration,
  _$unknown,
]);

class _$ItemStatusMeta {
  const _$ItemStatusMeta();
  ItemStatus get healthy => _$healthy;
  ItemStatus get loginRequired => _$loginRequired;
  ItemStatus get error => _$error;
  ItemStatus get pendingExpiration => _$pendingExpiration;
  ItemStatus get unknown => _$unknown;
  ItemStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<ItemStatus> get values => _$values;
}

mixin _$ItemStatusMixin {
  // ignore: non_constant_identifier_names
  _$ItemStatusMeta get ItemStatus => const _$ItemStatusMeta();
}

Serializer<ItemStatus> _$itemStatusSerializer = _$ItemStatusSerializer();

class _$ItemStatusSerializer implements PrimitiveSerializer<ItemStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'healthy': 'healthy',
    'loginRequired': 'login_required',
    'error': 'error',
    'pendingExpiration': 'pending_expiration',
    'unknown': 'unknown',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'healthy': 'healthy',
    'login_required': 'loginRequired',
    'error': 'error',
    'pending_expiration': 'pendingExpiration',
    'unknown': 'unknown',
  };

  @override
  final Iterable<Type> types = const <Type>[ItemStatus];
  @override
  final String wireName = 'ItemStatus';

  @override
  Object serialize(
    Serializers serializers,
    ItemStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ItemStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ItemStatus.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
