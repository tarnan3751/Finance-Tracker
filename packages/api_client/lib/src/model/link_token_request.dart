//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'link_token_request.g.dart';

/// LinkTokenRequest
///
/// Properties:
/// * [androidPackageName] - The app's registered package name; Plaid derives the redirect from it
/// * [updateItemId] - An Item to open Link in update mode for
@BuiltValue()
abstract class LinkTokenRequest
    implements Built<LinkTokenRequest, LinkTokenRequestBuilder> {
  /// The app's registered package name; Plaid derives the redirect from it
  @BuiltValueField(wireName: r'android_package_name')
  String get androidPackageName;

  /// An Item to open Link in update mode for
  @BuiltValueField(wireName: r'update_item_id')
  String? get updateItemId;

  LinkTokenRequest._();

  factory LinkTokenRequest([void updates(LinkTokenRequestBuilder b)]) =
      _$LinkTokenRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LinkTokenRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<LinkTokenRequest> get serializer =>
      _$LinkTokenRequestSerializer();
}

class _$LinkTokenRequestSerializer
    implements PrimitiveSerializer<LinkTokenRequest> {
  @override
  final Iterable<Type> types = const [LinkTokenRequest, _$LinkTokenRequest];

  @override
  final String wireName = r'LinkTokenRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    LinkTokenRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'android_package_name';
    yield serializers.serialize(
      object.androidPackageName,
      specifiedType: const FullType(String),
    );
    if (object.updateItemId != null) {
      yield r'update_item_id';
      yield serializers.serialize(
        object.updateItemId,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    LinkTokenRequest object, {
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
    required LinkTokenRequestBuilder result,
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
        case r'update_item_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.updateItemId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  LinkTokenRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LinkTokenRequestBuilder();
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
