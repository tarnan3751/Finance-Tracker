//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/device.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'auth_tokens.g.dart';

/// AuthTokens
///
/// Properties:
/// * [accessToken]
/// * [refreshToken]
/// * [accessExpiresIn] - Seconds until the access token expires
/// * [device]
@BuiltValue()
abstract class AuthTokens implements Built<AuthTokens, AuthTokensBuilder> {
  @BuiltValueField(wireName: r'access_token')
  String get accessToken;

  @BuiltValueField(wireName: r'refresh_token')
  String get refreshToken;

  /// Seconds until the access token expires
  @BuiltValueField(wireName: r'access_expires_in')
  int get accessExpiresIn;

  @BuiltValueField(wireName: r'device')
  Device get device;

  AuthTokens._();

  factory AuthTokens([void updates(AuthTokensBuilder b)]) = _$AuthTokens;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AuthTokensBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AuthTokens> get serializer => _$AuthTokensSerializer();
}

class _$AuthTokensSerializer implements PrimitiveSerializer<AuthTokens> {
  @override
  final Iterable<Type> types = const [AuthTokens, _$AuthTokens];

  @override
  final String wireName = r'AuthTokens';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AuthTokens object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'access_token';
    yield serializers.serialize(
      object.accessToken,
      specifiedType: const FullType(String),
    );
    yield r'refresh_token';
    yield serializers.serialize(
      object.refreshToken,
      specifiedType: const FullType(String),
    );
    yield r'access_expires_in';
    yield serializers.serialize(
      object.accessExpiresIn,
      specifiedType: const FullType(int),
    );
    yield r'device';
    yield serializers.serialize(
      object.device,
      specifiedType: const FullType(Device),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AuthTokens object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(
      serializers,
      object,
      specifiedType: specifiedType,
    ).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AuthTokensBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'access_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.accessToken = valueDes;
          break;
        case r'refresh_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.refreshToken = valueDes;
          break;
        case r'access_expires_in':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.accessExpiresIn = valueDes;
          break;
        case r'device':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Device),
          ) as Device;
          result.device.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AuthTokens deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AuthTokensBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}
