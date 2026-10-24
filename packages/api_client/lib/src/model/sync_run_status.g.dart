// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_run_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const SyncRunStatus _$started = const SyncRunStatus._('started');
const SyncRunStatus _$notReady = const SyncRunStatus._('notReady');
const SyncRunStatus _$completed = const SyncRunStatus._('completed');

SyncRunStatus _$valueOf(String name) {
  switch (name) {
    case 'started':
      return _$started;
    case 'notReady':
      return _$notReady;
    case 'completed':
      return _$completed;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<SyncRunStatus> _$values = BuiltSet<SyncRunStatus>(
  const <SyncRunStatus>[_$started, _$notReady, _$completed],
);

class _$SyncRunStatusMeta {
  const _$SyncRunStatusMeta();
  SyncRunStatus get started => _$started;
  SyncRunStatus get notReady => _$notReady;
  SyncRunStatus get completed => _$completed;
  SyncRunStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<SyncRunStatus> get values => _$values;
}

mixin _$SyncRunStatusMixin {
  // ignore: non_constant_identifier_names
  _$SyncRunStatusMeta get SyncRunStatus => const _$SyncRunStatusMeta();
}

Serializer<SyncRunStatus> _$syncRunStatusSerializer =
    _$SyncRunStatusSerializer();

class _$SyncRunStatusSerializer implements PrimitiveSerializer<SyncRunStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'started': 'started',
    'notReady': 'not_ready',
    'completed': 'completed',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'started': 'started',
    'not_ready': 'notReady',
    'completed': 'completed',
  };

  @override
  final Iterable<Type> types = const <Type>[SyncRunStatus];
  @override
  final String wireName = 'SyncRunStatus';

  @override
  Object serialize(
    Serializers serializers,
    SyncRunStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  SyncRunStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => SyncRunStatus.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
