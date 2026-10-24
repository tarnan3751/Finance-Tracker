//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api_client/src/model/provision_job_status.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api_client/src/model/provision_persona.dart';
import 'package:api_client/src/model/provision_progress.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'provision_job.g.dart';

/// A persona provisioning run. Kept in the server's memory: a restart forgets every job, and the Items it linked stay.
///
/// Properties:
/// * [id]
/// * [persona]
/// * [seed]
/// * [status]
/// * [createdAt]
/// * [finishedAt]
/// * [progress]
/// * [error] - Why the job failed (the step and Plaid's error code); null unless `failed`; never a token
/// * [itemIds] - The Items linked so far, in link order
@BuiltValue()
abstract class ProvisionJob
    implements Built<ProvisionJob, ProvisionJobBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'persona')
  ProvisionPersona get persona;
  // enum personaEnum {  renter,  family,  student,  small_business,  };

  @BuiltValueField(wireName: r'seed')
  int get seed;

  @BuiltValueField(wireName: r'status')
  ProvisionJobStatus get status;
  // enum statusEnum {  queued,  running,  completed,  failed,  };

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'finished_at')
  DateTime? get finishedAt;

  @BuiltValueField(wireName: r'progress')
  ProvisionProgress get progress;

  /// Why the job failed (the step and Plaid's error code); null unless `failed`; never a token
  @BuiltValueField(wireName: r'error')
  String? get error;

  /// The Items linked so far, in link order
  @BuiltValueField(wireName: r'item_ids')
  BuiltList<String> get itemIds;

  ProvisionJob._();

  factory ProvisionJob([void updates(ProvisionJobBuilder b)]) = _$ProvisionJob;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProvisionJobBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProvisionJob> get serializer => _$ProvisionJobSerializer();
}

class _$ProvisionJobSerializer implements PrimitiveSerializer<ProvisionJob> {
  @override
  final Iterable<Type> types = const [ProvisionJob, _$ProvisionJob];

  @override
  final String wireName = r'ProvisionJob';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProvisionJob object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'persona';
    yield serializers.serialize(
      object.persona,
      specifiedType: const FullType(ProvisionPersona),
    );
    yield r'seed';
    yield serializers.serialize(
      object.seed,
      specifiedType: const FullType(int),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(ProvisionJobStatus),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'finished_at';
    yield object.finishedAt == null
        ? null
        : serializers.serialize(
            object.finishedAt,
            specifiedType: const FullType.nullable(DateTime),
          );
    yield r'progress';
    yield serializers.serialize(
      object.progress,
      specifiedType: const FullType(ProvisionProgress),
    );
    yield r'error';
    yield object.error == null
        ? null
        : serializers.serialize(
            object.error,
            specifiedType: const FullType.nullable(String),
          );
    yield r'item_ids';
    yield serializers.serialize(
      object.itemIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ProvisionJob object, {
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
    required ProvisionJobBuilder result,
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
        case r'persona':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ProvisionPersona),
          ) as ProvisionPersona;
          result.persona = valueDes;
          break;
        case r'seed':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.seed = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ProvisionJobStatus),
          ) as ProvisionJobStatus;
          result.status = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'finished_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.finishedAt = valueDes;
          break;
        case r'progress':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ProvisionProgress),
          ) as ProvisionProgress;
          result.progress.replace(valueDes);
          break;
        case r'error':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.error = valueDes;
          break;
        case r'item_ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.itemIds.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProvisionJob deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProvisionJobBuilder();
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
