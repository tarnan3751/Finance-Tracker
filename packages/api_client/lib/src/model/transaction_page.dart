//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/transaction.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'transaction_page.g.dart';

/// TransactionPage
///
/// Properties:
/// * [transactions]
/// * [nextSince] - The largest `sync_version` in this page, or `since` when it is empty
/// * [hasMore]
@BuiltValue()
abstract class TransactionPage
    implements Built<TransactionPage, TransactionPageBuilder> {
  @BuiltValueField(wireName: r'transactions')
  BuiltList<Transaction> get transactions;

  /// The largest `sync_version` in this page, or `since` when it is empty
  @BuiltValueField(wireName: r'next_since')
  int get nextSince;

  @BuiltValueField(wireName: r'has_more')
  bool get hasMore;

  TransactionPage._();

  factory TransactionPage([void updates(TransactionPageBuilder b)]) =
      _$TransactionPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TransactionPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TransactionPage> get serializer =>
      _$TransactionPageSerializer();
}

class _$TransactionPageSerializer
    implements PrimitiveSerializer<TransactionPage> {
  @override
  final Iterable<Type> types = const [TransactionPage, _$TransactionPage];

  @override
  final String wireName = r'TransactionPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TransactionPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'transactions';
    yield serializers.serialize(
      object.transactions,
      specifiedType: const FullType(BuiltList, [FullType(Transaction)]),
    );
    yield r'next_since';
    yield serializers.serialize(
      object.nextSince,
      specifiedType: const FullType(int),
    );
    yield r'has_more';
    yield serializers.serialize(
      object.hasMore,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TransactionPage object, {
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
    required TransactionPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'transactions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Transaction)]),
          ) as BuiltList<Transaction>;
          result.transactions.replace(valueDes);
          break;
        case r'next_since':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.nextSince = valueDes;
          break;
        case r'has_more':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.hasMore = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TransactionPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TransactionPageBuilder();
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
