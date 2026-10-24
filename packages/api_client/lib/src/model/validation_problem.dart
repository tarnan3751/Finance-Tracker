//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/field_error.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'validation_problem.g.dart';

/// A `Problem` with `status` 400, `code` `validation_failed` and the field errors.
///
/// Properties:
/// * [type]
/// * [title]
/// * [status]
/// * [detail]
/// * [instance]
/// * [code]
/// * [errors]
@BuiltValue()
abstract class ValidationProblem
    implements Built<ValidationProblem, ValidationProblemBuilder> {
  @BuiltValueField(wireName: r'type')
  String get type;

  @BuiltValueField(wireName: r'title')
  String get title;

  @BuiltValueField(wireName: r'status')
  ValidationProblemStatusEnum get status;
  // enum statusEnum {  400,  };

  @BuiltValueField(wireName: r'detail')
  String? get detail;

  @BuiltValueField(wireName: r'instance')
  String? get instance;

  @BuiltValueField(wireName: r'code')
  ValidationProblemCodeEnum get code;
  // enum codeEnum {  validation_failed,  };

  @BuiltValueField(wireName: r'errors')
  BuiltList<FieldError> get errors;

  ValidationProblem._();

  factory ValidationProblem([void updates(ValidationProblemBuilder b)]) =
      _$ValidationProblem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ValidationProblemBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ValidationProblem> get serializer =>
      _$ValidationProblemSerializer();
}

class _$ValidationProblemSerializer
    implements PrimitiveSerializer<ValidationProblem> {
  @override
  final Iterable<Type> types = const [ValidationProblem, _$ValidationProblem];

  @override
  final String wireName = r'ValidationProblem';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ValidationProblem object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(String),
    );
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(ValidationProblemStatusEnum),
    );
    if (object.detail != null) {
      yield r'detail';
      yield serializers.serialize(
        object.detail,
        specifiedType: const FullType(String),
      );
    }
    if (object.instance != null) {
      yield r'instance';
      yield serializers.serialize(
        object.instance,
        specifiedType: const FullType(String),
      );
    }
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(ValidationProblemCodeEnum),
    );
    yield r'errors';
    yield serializers.serialize(
      object.errors,
      specifiedType: const FullType(BuiltList, [FullType(FieldError)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ValidationProblem object, {
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
    required ValidationProblemBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.type = valueDes;
          break;
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ValidationProblemStatusEnum),
          ) as ValidationProblemStatusEnum;
          result.status = valueDes;
          break;
        case r'detail':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.detail = valueDes;
          break;
        case r'instance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.instance = valueDes;
          break;
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ValidationProblemCodeEnum),
          ) as ValidationProblemCodeEnum;
          result.code = valueDes;
          break;
        case r'errors':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(FieldError)]),
          ) as BuiltList<FieldError>;
          result.errors.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ValidationProblem deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ValidationProblemBuilder();
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

class ValidationProblemStatusEnum extends EnumClass {
  @BuiltValueEnumConst(wireNumber: 400)
  static const ValidationProblemStatusEnum number400 =
      _$validationProblemStatusEnum_number400;

  static Serializer<ValidationProblemStatusEnum> get serializer =>
      _$validationProblemStatusEnumSerializer;

  const ValidationProblemStatusEnum._(String name) : super(name);

  static BuiltSet<ValidationProblemStatusEnum> get values =>
      _$validationProblemStatusEnumValues;
  static ValidationProblemStatusEnum valueOf(String name) =>
      _$validationProblemStatusEnumValueOf(name);
}

class ValidationProblemCodeEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'validation_failed')
  static const ValidationProblemCodeEnum validationFailed =
      _$validationProblemCodeEnum_validationFailed;

  static Serializer<ValidationProblemCodeEnum> get serializer =>
      _$validationProblemCodeEnumSerializer;

  const ValidationProblemCodeEnum._(String name) : super(name);

  static BuiltSet<ValidationProblemCodeEnum> get values =>
      _$validationProblemCodeEnumValues;
  static ValidationProblemCodeEnum valueOf(String name) =>
      _$validationProblemCodeEnumValueOf(name);
}
