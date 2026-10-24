//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/webhook_code.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'fire_webhook_request.g.dart';

/// FireWebhookRequest
///
/// Properties:
/// * [webhookCode]
@BuiltValue()
abstract class FireWebhookRequest
    implements Built<FireWebhookRequest, FireWebhookRequestBuilder> {
  @BuiltValueField(wireName: r'webhook_code')
  WebhookCode get webhookCode;
  // enum webhookCodeEnum {  SYNC_UPDATES_AVAILABLE,  DEFAULT_UPDATE,  RECURRING_TRANSACTIONS_UPDATE,  NEW_ACCOUNTS_AVAILABLE,  PENDING_DISCONNECT,  USER_PERMISSION_REVOKED,  LOGIN_REPAIRED,  ERROR,  };

  FireWebhookRequest._();

  factory FireWebhookRequest([void updates(FireWebhookRequestBuilder b)]) =
      _$FireWebhookRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FireWebhookRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FireWebhookRequest> get serializer =>
      _$FireWebhookRequestSerializer();
}

class _$FireWebhookRequestSerializer
    implements PrimitiveSerializer<FireWebhookRequest> {
  @override
  final Iterable<Type> types = const [FireWebhookRequest, _$FireWebhookRequest];

  @override
  final String wireName = r'FireWebhookRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FireWebhookRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'webhook_code';
    yield serializers.serialize(
      object.webhookCode,
      specifiedType: const FullType(WebhookCode),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FireWebhookRequest object, {
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
    required FireWebhookRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'webhook_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(WebhookCode),
          ) as WebhookCode;
          result.webhookCode = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FireWebhookRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FireWebhookRequestBuilder();
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
