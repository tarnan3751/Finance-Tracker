// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webhook_code.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const WebhookCode _$syncUpdatesAvailable = const WebhookCode._(
  'syncUpdatesAvailable',
);
const WebhookCode _$defaultUpdate = const WebhookCode._('defaultUpdate');
const WebhookCode _$recurringTransactionsUpdate = const WebhookCode._(
  'recurringTransactionsUpdate',
);
const WebhookCode _$newAccountsAvailable = const WebhookCode._(
  'newAccountsAvailable',
);
const WebhookCode _$pendingDisconnect = const WebhookCode._(
  'pendingDisconnect',
);
const WebhookCode _$userPermissionRevoked = const WebhookCode._(
  'userPermissionRevoked',
);
const WebhookCode _$loginRepaired = const WebhookCode._('loginRepaired');
const WebhookCode _$error = const WebhookCode._('error');

WebhookCode _$valueOf(String name) {
  switch (name) {
    case 'syncUpdatesAvailable':
      return _$syncUpdatesAvailable;
    case 'defaultUpdate':
      return _$defaultUpdate;
    case 'recurringTransactionsUpdate':
      return _$recurringTransactionsUpdate;
    case 'newAccountsAvailable':
      return _$newAccountsAvailable;
    case 'pendingDisconnect':
      return _$pendingDisconnect;
    case 'userPermissionRevoked':
      return _$userPermissionRevoked;
    case 'loginRepaired':
      return _$loginRepaired;
    case 'error':
      return _$error;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<WebhookCode> _$values = BuiltSet<WebhookCode>(
  const <WebhookCode>[
    _$syncUpdatesAvailable,
    _$defaultUpdate,
    _$recurringTransactionsUpdate,
    _$newAccountsAvailable,
    _$pendingDisconnect,
    _$userPermissionRevoked,
    _$loginRepaired,
    _$error,
  ],
);

class _$WebhookCodeMeta {
  const _$WebhookCodeMeta();
  WebhookCode get syncUpdatesAvailable => _$syncUpdatesAvailable;
  WebhookCode get defaultUpdate => _$defaultUpdate;
  WebhookCode get recurringTransactionsUpdate => _$recurringTransactionsUpdate;
  WebhookCode get newAccountsAvailable => _$newAccountsAvailable;
  WebhookCode get pendingDisconnect => _$pendingDisconnect;
  WebhookCode get userPermissionRevoked => _$userPermissionRevoked;
  WebhookCode get loginRepaired => _$loginRepaired;
  WebhookCode get error => _$error;
  WebhookCode valueOf(String name) => _$valueOf(name);
  BuiltSet<WebhookCode> get values => _$values;
}

mixin _$WebhookCodeMixin {
  // ignore: non_constant_identifier_names
  _$WebhookCodeMeta get WebhookCode => const _$WebhookCodeMeta();
}

Serializer<WebhookCode> _$webhookCodeSerializer = _$WebhookCodeSerializer();

class _$WebhookCodeSerializer implements PrimitiveSerializer<WebhookCode> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'syncUpdatesAvailable': 'SYNC_UPDATES_AVAILABLE',
    'defaultUpdate': 'DEFAULT_UPDATE',
    'recurringTransactionsUpdate': 'RECURRING_TRANSACTIONS_UPDATE',
    'newAccountsAvailable': 'NEW_ACCOUNTS_AVAILABLE',
    'pendingDisconnect': 'PENDING_DISCONNECT',
    'userPermissionRevoked': 'USER_PERMISSION_REVOKED',
    'loginRepaired': 'LOGIN_REPAIRED',
    'error': 'ERROR',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'SYNC_UPDATES_AVAILABLE': 'syncUpdatesAvailable',
    'DEFAULT_UPDATE': 'defaultUpdate',
    'RECURRING_TRANSACTIONS_UPDATE': 'recurringTransactionsUpdate',
    'NEW_ACCOUNTS_AVAILABLE': 'newAccountsAvailable',
    'PENDING_DISCONNECT': 'pendingDisconnect',
    'USER_PERMISSION_REVOKED': 'userPermissionRevoked',
    'LOGIN_REPAIRED': 'loginRepaired',
    'ERROR': 'error',
  };

  @override
  final Iterable<Type> types = const <Type>[WebhookCode];
  @override
  final String wireName = 'WebhookCode';

  @override
  Object serialize(
    Serializers serializers,
    WebhookCode object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  WebhookCode deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => WebhookCode.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
