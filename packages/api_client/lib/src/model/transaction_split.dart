//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/money.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'transaction_split.g.dart';

/// Mirrors `shared_models` `TransactionSplit`.
///
/// Properties:
/// * [categoryId]
/// * [amount]
/// * [note]
@BuiltValue()
abstract class TransactionSplit
    implements Built<TransactionSplit, TransactionSplitBuilder> {
  @BuiltValueField(wireName: r'category_id')
  String get categoryId;

  @BuiltValueField(wireName: r'amount')
  Money get amount;

  @BuiltValueField(wireName: r'note')
  String? get note;

  TransactionSplit._();

  factory TransactionSplit([void updates(TransactionSplitBuilder b)]) =
      _$TransactionSplit;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TransactionSplitBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TransactionSplit> get serializer =>
      _$TransactionSplitSerializer();
}

class _$TransactionSplitSerializer
    implements PrimitiveSerializer<TransactionSplit> {
  @override
  final Iterable<Type> types = const [TransactionSplit, _$TransactionSplit];

  @override
  final String wireName = r'TransactionSplit';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TransactionSplit object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'category_id';
    yield serializers.serialize(
      object.categoryId,
      specifiedType: const FullType(String),
    );
    yield r'amount';
    yield serializers.serialize(
      object.amount,
      specifiedType: const FullType(Money),
    );
    yield r'note';
    yield object.note == null
        ? null
        : serializers.serialize(
            object.note,
            specifiedType: const FullType.nullable(String),
          );
  }

  @override
  Object serialize(
    Serializers serializers,
    TransactionSplit object, {
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
    required TransactionSplitBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'category_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.categoryId = valueDes;
          break;
        case r'amount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Money),
          ) as Money;
          result.amount.replace(valueDes);
          break;
        case r'note':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.note = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TransactionSplit deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TransactionSplitBuilder();
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
