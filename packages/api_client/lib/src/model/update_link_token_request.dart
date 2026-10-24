//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_link_token_request.g.dart';

/// UpdateLinkTokenRequest
///
/// Properties:
/// * [androidPackageName]
@BuiltValue()
abstract class UpdateLinkTokenRequest
    implements Built<UpdateLinkTokenRequest, UpdateLinkTokenRequestBuilder> {
  @BuiltValueField(wireName: r'android_package_name')
  String get androidPackageName;

  UpdateLinkTokenRequest._();

  factory UpdateLinkTokenRequest([
    void updates(UpdateLinkTokenRequestBuilder b),
  ]) = _$UpdateLinkTokenRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateLinkTokenRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateLinkTokenRequest> get serializer =>
      _$UpdateLinkTokenRequestSerializer();
}

class _$UpdateLinkTokenRequestSerializer
    implements PrimitiveSerializer<UpdateLinkTokenRequest> {
  @override
  final Iterable<Type> types = const [
    UpdateLinkTokenRequest,
    _$UpdateLinkTokenRequest,
  ];

  @override
  final String wireName = r'UpdateLinkTokenRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateLinkTokenRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'android_package_name';
    yield serializers.serialize(
      object.androidPackageName,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateLinkTokenRequest object, {
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
    required UpdateLinkTokenRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'android_package_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.androidPackageName = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateLinkTokenRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateLinkTokenRequestBuilder();
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
