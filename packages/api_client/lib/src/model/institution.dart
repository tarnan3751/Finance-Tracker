//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'institution.g.dart';

/// Mirrors `shared_models` `Institution`; `primary_color` is ARGB.
///
/// Properties:
/// * [id] - Plaid's institution id
/// * [name]
/// * [logoUrl] - The server's `GET /institutions/{institution_id}/logo` URL when it holds the institution's logo
/// * [primaryColor] - ARGB, converted from Plaid's `#rrggbb`
@BuiltValue()
abstract class Institution implements Built<Institution, InstitutionBuilder> {
  /// Plaid's institution id
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  /// The server's `GET /institutions/{institution_id}/logo` URL when it holds the institution's logo
  @BuiltValueField(wireName: r'logo_url')
  String? get logoUrl;

  /// ARGB, converted from Plaid's `#rrggbb`
  @BuiltValueField(wireName: r'primary_color')
  int? get primaryColor;

  Institution._();

  factory Institution([void updates(InstitutionBuilder b)]) = _$Institution;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(InstitutionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Institution> get serializer => _$InstitutionSerializer();
}

class _$InstitutionSerializer implements PrimitiveSerializer<Institution> {
  @override
  final Iterable<Type> types = const [Institution, _$Institution];

  @override
  final String wireName = r'Institution';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Institution object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'logo_url';
    yield object.logoUrl == null
        ? null
        : serializers.serialize(
            object.logoUrl,
            specifiedType: const FullType.nullable(String),
          );
    yield r'primary_color';
    yield object.primaryColor == null
        ? null
        : serializers.serialize(
            object.primaryColor,
            specifiedType: const FullType.nullable(int),
          );
  }

  @override
  Object serialize(
    Serializers serializers,
    Institution object, {
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
    required InstitutionBuilder result,
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
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'logo_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.logoUrl = valueDes;
          break;
        case r'primary_color':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.primaryColor = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Institution deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = InstitutionBuilder();
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
