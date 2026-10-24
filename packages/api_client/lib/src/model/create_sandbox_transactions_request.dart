//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/sandbox_transaction.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_sandbox_transactions_request.g.dart';

/// CreateSandboxTransactionsRequest
///
/// Properties:
/// * [transactions]
@BuiltValue()
abstract class CreateSandboxTransactionsRequest
    implements
        Built<
          CreateSandboxTransactionsRequest,
          CreateSandboxTransactionsRequestBuilder
        > {
  @BuiltValueField(wireName: r'transactions')
  BuiltList<SandboxTransaction> get transactions;

  CreateSandboxTransactionsRequest._();

  factory CreateSandboxTransactionsRequest([
    void updates(CreateSandboxTransactionsRequestBuilder b),
  ]) = _$CreateSandboxTransactionsRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateSandboxTransactionsRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateSandboxTransactionsRequest> get serializer =>
      _$CreateSandboxTransactionsRequestSerializer();
}

class _$CreateSandboxTransactionsRequestSerializer
    implements PrimitiveSerializer<CreateSandboxTransactionsRequest> {
  @override
  final Iterable<Type> types = const [
    CreateSandboxTransactionsRequest,
    _$CreateSandboxTransactionsRequest,
  ];

  @override
  final String wireName = r'CreateSandboxTransactionsRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateSandboxTransactionsRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'transactions';
    yield serializers.serialize(
      object.transactions,
      specifiedType: const FullType(BuiltList, [FullType(SandboxTransaction)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateSandboxTransactionsRequest object, {
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
    required CreateSandboxTransactionsRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'transactions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [
              FullType(SandboxTransaction),
            ]),
          ) as BuiltList<SandboxTransaction>;
          result.transactions.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateSandboxTransactionsRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateSandboxTransactionsRequestBuilder();
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
