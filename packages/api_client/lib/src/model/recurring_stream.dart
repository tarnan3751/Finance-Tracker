//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/money.dart';
import 'package:api_client/src/model/recurring_status.dart';
import 'package:api_client/src/model/recurring_cadence.dart';
import 'package:api_client/src/model/date.dart';
import 'package:api_client/src/model/recurring_source.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'recurring_stream.g.dart';

/// Mirrors `shared_models` `RecurringStream`.
///
/// Properties:
/// * [id]
/// * [accountId]
/// * [merchantName]
/// * [cadence]
/// * [averageAmount]
/// * [lastExpected]
/// * [nextExpected]
/// * [status]
/// * [isSubscription]
/// * [source_]
@BuiltValue()
abstract class RecurringStream
    implements Built<RecurringStream, RecurringStreamBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'account_id')
  String get accountId;

  @BuiltValueField(wireName: r'merchant_name')
  String get merchantName;

  @BuiltValueField(wireName: r'cadence')
  RecurringCadence get cadence;
  // enum cadenceEnum {  weekly,  biweekly,  semi_monthly,  monthly,  annually,  unknown,  };

  @BuiltValueField(wireName: r'average_amount')
  Money get averageAmount;

  @BuiltValueField(wireName: r'last_expected')
  Date? get lastExpected;

  @BuiltValueField(wireName: r'next_expected')
  Date? get nextExpected;

  @BuiltValueField(wireName: r'status')
  RecurringStatus get status;
  // enum statusEnum {  active,  ended,  };

  @BuiltValueField(wireName: r'is_subscription')
  bool get isSubscription;

  @BuiltValueField(wireName: r'source')
  RecurringSource get source_;
  // enum source_Enum {  plaid,  detected,  user,  };

  RecurringStream._();

  factory RecurringStream([void updates(RecurringStreamBuilder b)]) =
      _$RecurringStream;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RecurringStreamBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RecurringStream> get serializer =>
      _$RecurringStreamSerializer();
}

class _$RecurringStreamSerializer
    implements PrimitiveSerializer<RecurringStream> {
  @override
  final Iterable<Type> types = const [RecurringStream, _$RecurringStream];

  @override
  final String wireName = r'RecurringStream';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RecurringStream object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'account_id';
    yield serializers.serialize(
      object.accountId,
      specifiedType: const FullType(String),
    );
    yield r'merchant_name';
    yield serializers.serialize(
      object.merchantName,
      specifiedType: const FullType(String),
    );
    yield r'cadence';
    yield serializers.serialize(
      object.cadence,
      specifiedType: const FullType(RecurringCadence),
    );
    yield r'average_amount';
    yield serializers.serialize(
      object.averageAmount,
      specifiedType: const FullType(Money),
    );
    yield r'last_expected';
    yield object.lastExpected == null
        ? null
        : serializers.serialize(
            object.lastExpected,
            specifiedType: const FullType.nullable(Date),
          );
    yield r'next_expected';
    yield object.nextExpected == null
        ? null
        : serializers.serialize(
            object.nextExpected,
            specifiedType: const FullType.nullable(Date),
          );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(RecurringStatus),
    );
    yield r'is_subscription';
    yield serializers.serialize(
      object.isSubscription,
      specifiedType: const FullType(bool),
    );
    yield r'source';
    yield serializers.serialize(
      object.source_,
      specifiedType: const FullType(RecurringSource),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RecurringStream object, {
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
    required RecurringStreamBuilder result,
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
        case r'account_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.accountId = valueDes;
          break;
        case r'merchant_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.merchantName = valueDes;
          break;
        case r'cadence':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(RecurringCadence),
          ) as RecurringCadence;
          result.cadence = valueDes;
          break;
        case r'average_amount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Money),
          ) as Money;
          result.averageAmount.replace(valueDes);
          break;
        case r'last_expected':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.lastExpected = valueDes;
          break;
        case r'next_expected':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(Date),
          ) as Date?;
          if (valueDes == null) continue;
          result.nextExpected = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(RecurringStatus),
          ) as RecurringStatus;
          result.status = valueDes;
          break;
        case r'is_subscription':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isSubscription = valueDes;
          break;
        case r'source':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(RecurringSource),
          ) as RecurringSource;
          result.source_ = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RecurringStream deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RecurringStreamBuilder();
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
