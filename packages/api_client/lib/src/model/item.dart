//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/item_status.dart';
import 'package:api_client/src/model/institution.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'item.g.dart';

/// Mirrors `shared_models` `Item`, with its institution embedded (`shared_models` keeps the institution separately, by `institution_id`). The transactions cursor is server-only state and is not here.
///
/// Properties:
/// * [id]
/// * [institutionId]
/// * [status]
/// * [lastSuccessfulSyncAt]
/// * [errorCode] - Plaid's error code (`ITEM_LOGIN_REQUIRED`, ...) when `status` is `login_required` or `error`; null otherwise
/// * [institution]
@BuiltValue()
abstract class Item implements Built<Item, ItemBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'institution_id')
  String get institutionId;

  @BuiltValueField(wireName: r'status')
  ItemStatus get status;
  // enum statusEnum {  healthy,  login_required,  error,  pending_expiration,  removed,  unknown,  };

  @BuiltValueField(wireName: r'last_successful_sync_at')
  DateTime? get lastSuccessfulSyncAt;

  /// Plaid's error code (`ITEM_LOGIN_REQUIRED`, ...) when `status` is `login_required` or `error`; null otherwise
  @BuiltValueField(wireName: r'error_code')
  String? get errorCode;

  @BuiltValueField(wireName: r'institution')
  Institution get institution;

  Item._();

  factory Item([void updates(ItemBuilder b)]) = _$Item;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ItemBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Item> get serializer => _$ItemSerializer();
}

class _$ItemSerializer implements PrimitiveSerializer<Item> {
  @override
  final Iterable<Type> types = const [Item, _$Item];

  @override
  final String wireName = r'Item';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Item object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'institution_id';
    yield serializers.serialize(
      object.institutionId,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(ItemStatus),
    );
    yield r'last_successful_sync_at';
    yield object.lastSuccessfulSyncAt == null
        ? null
        : serializers.serialize(
            object.lastSuccessfulSyncAt,
            specifiedType: const FullType.nullable(DateTime),
          );
    yield r'error_code';
    yield object.errorCode == null
        ? null
        : serializers.serialize(
            object.errorCode,
            specifiedType: const FullType.nullable(String),
          );
    yield r'institution';
    yield serializers.serialize(
      object.institution,
      specifiedType: const FullType(Institution),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Item object, {
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
    required ItemBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'institution_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.institutionId = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ItemStatus),
          ) as ItemStatus;
          result.status = valueDes;
          break;
        case r'last_successful_sync_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.lastSuccessfulSyncAt = valueDes;
          break;
        case r'error_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.errorCode = valueDes;
          break;
        case r'institution':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Institution),
          ) as Institution;
          result.institution.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Item deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ItemBuilder();
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
