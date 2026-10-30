// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'problem_code.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ProblemCode _$validationFailed = const ProblemCode._('validationFailed');
const ProblemCode _$invalidCredentials = const ProblemCode._(
  'invalidCredentials',
);
const ProblemCode _$emailTaken = const ProblemCode._('emailTaken');
const ProblemCode _$tokenExpired = const ProblemCode._('tokenExpired');
const ProblemCode _$tokenRevoked = const ProblemCode._('tokenRevoked');
const ProblemCode _$notFound = const ProblemCode._('notFound');
const ProblemCode _$conflict = const ProblemCode._('conflict');
const ProblemCode _$itemLoginRequired = const ProblemCode._(
  'itemLoginRequired',
);
const ProblemCode _$plaidError = const ProblemCode._('plaidError');
const ProblemCode _$rateLimited = const ProblemCode._('rateLimited');
const ProblemCode _$internal = const ProblemCode._('internal');
const ProblemCode _$syncCursorInvalid = const ProblemCode._(
  'syncCursorInvalid',
);
const ProblemCode _$webhookUnverified = const ProblemCode._(
  'webhookUnverified',
);
const ProblemCode _$payloadTooLarge = const ProblemCode._('payloadTooLarge');
const ProblemCode _$unsupportedMediaType = const ProblemCode._(
  'unsupportedMediaType',
);

ProblemCode _$valueOf(String name) {
  switch (name) {
    case 'validationFailed':
      return _$validationFailed;
    case 'invalidCredentials':
      return _$invalidCredentials;
    case 'emailTaken':
      return _$emailTaken;
    case 'tokenExpired':
      return _$tokenExpired;
    case 'tokenRevoked':
      return _$tokenRevoked;
    case 'notFound':
      return _$notFound;
    case 'conflict':
      return _$conflict;
    case 'itemLoginRequired':
      return _$itemLoginRequired;
    case 'plaidError':
      return _$plaidError;
    case 'rateLimited':
      return _$rateLimited;
    case 'internal':
      return _$internal;
    case 'syncCursorInvalid':
      return _$syncCursorInvalid;
    case 'webhookUnverified':
      return _$webhookUnverified;
    case 'payloadTooLarge':
      return _$payloadTooLarge;
    case 'unsupportedMediaType':
      return _$unsupportedMediaType;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ProblemCode> _$values = BuiltSet<ProblemCode>(
  const <ProblemCode>[
    _$validationFailed,
    _$invalidCredentials,
    _$emailTaken,
    _$tokenExpired,
    _$tokenRevoked,
    _$notFound,
    _$conflict,
    _$itemLoginRequired,
    _$plaidError,
    _$rateLimited,
    _$internal,
    _$syncCursorInvalid,
    _$webhookUnverified,
    _$payloadTooLarge,
    _$unsupportedMediaType,
  ],
);

class _$ProblemCodeMeta {
  const _$ProblemCodeMeta();
  ProblemCode get validationFailed => _$validationFailed;
  ProblemCode get invalidCredentials => _$invalidCredentials;
  ProblemCode get emailTaken => _$emailTaken;
  ProblemCode get tokenExpired => _$tokenExpired;
  ProblemCode get tokenRevoked => _$tokenRevoked;
  ProblemCode get notFound => _$notFound;
  ProblemCode get conflict => _$conflict;
  ProblemCode get itemLoginRequired => _$itemLoginRequired;
  ProblemCode get plaidError => _$plaidError;
  ProblemCode get rateLimited => _$rateLimited;
  ProblemCode get internal => _$internal;
  ProblemCode get syncCursorInvalid => _$syncCursorInvalid;
  ProblemCode get webhookUnverified => _$webhookUnverified;
  ProblemCode get payloadTooLarge => _$payloadTooLarge;
  ProblemCode get unsupportedMediaType => _$unsupportedMediaType;
  ProblemCode valueOf(String name) => _$valueOf(name);
  BuiltSet<ProblemCode> get values => _$values;
}

mixin _$ProblemCodeMixin {
  // ignore: non_constant_identifier_names
  _$ProblemCodeMeta get ProblemCode => const _$ProblemCodeMeta();
}

Serializer<ProblemCode> _$problemCodeSerializer = _$ProblemCodeSerializer();

class _$ProblemCodeSerializer implements PrimitiveSerializer<ProblemCode> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'validationFailed': 'validation_failed',
    'invalidCredentials': 'invalid_credentials',
    'emailTaken': 'email_taken',
    'tokenExpired': 'token_expired',
    'tokenRevoked': 'token_revoked',
    'notFound': 'not_found',
    'conflict': 'conflict',
    'itemLoginRequired': 'item_login_required',
    'plaidError': 'plaid_error',
    'rateLimited': 'rate_limited',
    'internal': 'internal',
    'syncCursorInvalid': 'sync_cursor_invalid',
    'webhookUnverified': 'webhook_unverified',
    'payloadTooLarge': 'payload_too_large',
    'unsupportedMediaType': 'unsupported_media_type',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'validation_failed': 'validationFailed',
    'invalid_credentials': 'invalidCredentials',
    'email_taken': 'emailTaken',
    'token_expired': 'tokenExpired',
    'token_revoked': 'tokenRevoked',
    'not_found': 'notFound',
    'conflict': 'conflict',
    'item_login_required': 'itemLoginRequired',
    'plaid_error': 'plaidError',
    'rate_limited': 'rateLimited',
    'internal': 'internal',
    'sync_cursor_invalid': 'syncCursorInvalid',
    'webhook_unverified': 'webhookUnverified',
    'payload_too_large': 'payloadTooLarge',
    'unsupported_media_type': 'unsupportedMediaType',
  };

  @override
  final Iterable<Type> types = const <Type>[ProblemCode];
  @override
  final String wireName = 'ProblemCode';

  @override
  Object serialize(
    Serializers serializers,
    ProblemCode object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ProblemCode deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ProblemCode.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
