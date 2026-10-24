//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'rejected_entry.g.dart';

/// RejectedEntry
///
/// Properties:
/// * [hlc] - A hybrid logical clock timestamp in its packed form `<wall>-<counter>-<node>`: wall milliseconds zero-padded to 15 digits, the counter to 5, then the node id. Packed strings sort in logical order.
/// * [reason] - Why the entry was not stored, for logs
@BuiltValue()
abstract class RejectedEntry
    implements Built<RejectedEntry, RejectedEntryBuilder> {
  /// A hybrid logical clock timestamp in its packed form `<wall>-<counter>-<node>`: wall milliseconds zero-padded to 15 digits, the counter to 5, then the node id. Packed strings sort in logical order.
  @BuiltValueField(wireName: r'hlc')
  String get hlc;

  /// Why the entry was not stored, for logs
  @BuiltValueField(wireName: r'reason')
  String get reason;

  RejectedEntry._();

  factory RejectedEntry([void updates(RejectedEntryBuilder b)]) =
      _$RejectedEntry;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RejectedEntryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RejectedEntry> get serializer =>
      _$RejectedEntrySerializer();
}

class _$RejectedEntrySerializer implements PrimitiveSerializer<RejectedEntry> {
  @override
  final Iterable<Type> types = const [RejectedEntry, _$RejectedEntry];

  @override
  final String wireName = r'RejectedEntry';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RejectedEntry object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'hlc';
    yield serializers.serialize(
      object.hlc,
      specifiedType: const FullType(String),
    );
    yield r'reason';
    yield serializers.serialize(
      object.reason,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RejectedEntry object, {
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
    required RejectedEntryBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'hlc':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.hlc = valueDes;
          break;
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reason = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RejectedEntry deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RejectedEntryBuilder();
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
