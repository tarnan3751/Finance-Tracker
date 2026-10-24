//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/investment_transaction.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'investment_transaction_page.g.dart';

/// InvestmentTransactionPage
///
/// Properties:
/// * [investmentTransactions]
/// * [nextSince] - The largest `sync_version` in this page, or `since` when it is empty
/// * [hasMore]
@BuiltValue()
abstract class InvestmentTransactionPage
    implements
        Built<InvestmentTransactionPage, InvestmentTransactionPageBuilder> {
  @BuiltValueField(wireName: r'investment_transactions')
  BuiltList<InvestmentTransaction> get investmentTransactions;

  /// The largest `sync_version` in this page, or `since` when it is empty
  @BuiltValueField(wireName: r'next_since')
  int get nextSince;

  @BuiltValueField(wireName: r'has_more')
  bool get hasMore;

  InvestmentTransactionPage._();

  factory InvestmentTransactionPage([
    void updates(InvestmentTransactionPageBuilder b),
  ]) = _$InvestmentTransactionPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(InvestmentTransactionPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<InvestmentTransactionPage> get serializer =>
      _$InvestmentTransactionPageSerializer();
}

class _$InvestmentTransactionPageSerializer
    implements PrimitiveSerializer<InvestmentTransactionPage> {
  @override
  final Iterable<Type> types = const [
    InvestmentTransactionPage,
    _$InvestmentTransactionPage,
  ];

  @override
  final String wireName = r'InvestmentTransactionPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    InvestmentTransactionPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'investment_transactions';
    yield serializers.serialize(
      object.investmentTransactions,
      specifiedType: const FullType(BuiltList, [
        FullType(InvestmentTransaction),
      ]),
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
    InvestmentTransactionPage object, {
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
    required InvestmentTransactionPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'investment_transactions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [
              FullType(InvestmentTransaction),
            ]),
          ) as BuiltList<InvestmentTransaction>;
          result.investmentTransactions.replace(valueDes);
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
  InvestmentTransactionPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = InvestmentTransactionPageBuilder();
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
