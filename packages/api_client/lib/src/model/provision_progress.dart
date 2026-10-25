//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'provision_progress.g.dart';

/// ProvisionProgress
///
/// Properties:
/// * [itemsTotal]
/// * [itemsLinked]
/// * [batchesTotal] - Always 0; the job injects no batches
/// * [batchesSent] - Always 0; the job injects no batches
/// * [skipped] - Transactions left out of a custom user because their shifted date fell outside Plaid's window (from the UTC date minus 729 days to Plaid's today at UTC−12) when its Item was linked, as when a job links a 730-day persona's oldest day before 12:00 UTC
@BuiltValue()
abstract class ProvisionProgress
    implements Built<ProvisionProgress, ProvisionProgressBuilder> {
  @BuiltValueField(wireName: r'items_total')
  int get itemsTotal;

  @BuiltValueField(wireName: r'items_linked')
  int get itemsLinked;

  /// Always 0; the job injects no batches
  @BuiltValueField(wireName: r'batches_total')
  int get batchesTotal;

  /// Always 0; the job injects no batches
  @BuiltValueField(wireName: r'batches_sent')
  int get batchesSent;

  /// Transactions left out of a custom user because their shifted date fell outside Plaid's window (from the UTC date minus 729 days to Plaid's today at UTC−12) when its Item was linked, as when a job links a 730-day persona's oldest day before 12:00 UTC
  @BuiltValueField(wireName: r'skipped')
  int get skipped;

  ProvisionProgress._();

  factory ProvisionProgress([void updates(ProvisionProgressBuilder b)]) =
      _$ProvisionProgress;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProvisionProgressBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProvisionProgress> get serializer =>
      _$ProvisionProgressSerializer();
}

class _$ProvisionProgressSerializer
    implements PrimitiveSerializer<ProvisionProgress> {
  @override
  final Iterable<Type> types = const [ProvisionProgress, _$ProvisionProgress];

  @override
  final String wireName = r'ProvisionProgress';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProvisionProgress object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items_total';
    yield serializers.serialize(
      object.itemsTotal,
      specifiedType: const FullType(int),
    );
    yield r'items_linked';
    yield serializers.serialize(
      object.itemsLinked,
      specifiedType: const FullType(int),
    );
    yield r'batches_total';
    yield serializers.serialize(
      object.batchesTotal,
      specifiedType: const FullType(int),
    );
    yield r'batches_sent';
    yield serializers.serialize(
      object.batchesSent,
      specifiedType: const FullType(int),
    );
    yield r'skipped';
    yield serializers.serialize(
      object.skipped,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ProvisionProgress object, {
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
    required ProvisionProgressBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items_total':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.itemsTotal = valueDes;
          break;
        case r'items_linked':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.itemsLinked = valueDes;
          break;
        case r'batches_total':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.batchesTotal = valueDes;
          break;
        case r'batches_sent':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.batchesSent = valueDes;
          break;
        case r'skipped':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.skipped = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProvisionProgress deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProvisionProgressBuilder();
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
