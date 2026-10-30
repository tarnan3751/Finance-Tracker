//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'receipt.g.dart';

/// A stored receipt photo.
///
/// Properties:
/// * [sha256]
/// * [size] - Its length in bytes
@BuiltValue()
abstract class Receipt implements Built<Receipt, ReceiptBuilder> {
  @BuiltValueField(wireName: r'sha256')
  String get sha256;

  /// Its length in bytes
  @BuiltValueField(wireName: r'size')
  int get size;

  Receipt._();

  factory Receipt([void updates(ReceiptBuilder b)]) = _$Receipt;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ReceiptBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Receipt> get serializer => _$ReceiptSerializer();
}

class _$ReceiptSerializer implements PrimitiveSerializer<Receipt> {
  @override
  final Iterable<Type> types = const [Receipt, _$Receipt];

  @override
  final String wireName = r'Receipt';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Receipt object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'sha256';
    yield serializers.serialize(
      object.sha256,
      specifiedType: const FullType(String),
    );
    yield r'size';
    yield serializers.serialize(
      object.size,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Receipt object, {
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
    required ReceiptBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'sha256':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.sha256 = valueDes;
          break;
        case r'size':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.size = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Receipt deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ReceiptBuilder();
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
