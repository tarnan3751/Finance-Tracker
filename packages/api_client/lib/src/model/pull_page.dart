//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/pulled_change_log_entry.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'pull_page.g.dart';

/// PullPage
///
/// Properties:
/// * [entries]
/// * [nextSince] - The largest `seq` this page covered, entries of the calling device included, or `since` when nothing new
/// * [hasMore]
@BuiltValue()
abstract class PullPage implements Built<PullPage, PullPageBuilder> {
  @BuiltValueField(wireName: r'entries')
  BuiltList<PulledChangeLogEntry> get entries;

  /// The largest `seq` this page covered, entries of the calling device included, or `since` when nothing new
  @BuiltValueField(wireName: r'next_since')
  int get nextSince;

  @BuiltValueField(wireName: r'has_more')
  bool get hasMore;

  PullPage._();

  factory PullPage([void updates(PullPageBuilder b)]) = _$PullPage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PullPageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PullPage> get serializer => _$PullPageSerializer();
}

class _$PullPageSerializer implements PrimitiveSerializer<PullPage> {
  @override
  final Iterable<Type> types = const [PullPage, _$PullPage];

  @override
  final String wireName = r'PullPage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PullPage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'entries';
    yield serializers.serialize(
      object.entries,
      specifiedType: const FullType(BuiltList, [
        FullType(PulledChangeLogEntry),
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
    PullPage object, {
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
    required PullPageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'entries':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [
              FullType(PulledChangeLogEntry),
            ]),
          ) as BuiltList<PulledChangeLogEntry>;
          result.entries.replace(valueDes);
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
  PullPage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PullPageBuilder();
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
