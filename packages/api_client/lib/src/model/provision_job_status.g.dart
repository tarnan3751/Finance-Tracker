// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provision_job_status.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ProvisionJobStatus _$queued = const ProvisionJobStatus._('queued');
const ProvisionJobStatus _$running = const ProvisionJobStatus._('running');
const ProvisionJobStatus _$completed = const ProvisionJobStatus._('completed');
const ProvisionJobStatus _$failed = const ProvisionJobStatus._('failed');

ProvisionJobStatus _$valueOf(String name) {
  switch (name) {
    case 'queued':
      return _$queued;
    case 'running':
      return _$running;
    case 'completed':
      return _$completed;
    case 'failed':
      return _$failed;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ProvisionJobStatus> _$values = BuiltSet<ProvisionJobStatus>(
  const <ProvisionJobStatus>[_$queued, _$running, _$completed, _$failed],
);

class _$ProvisionJobStatusMeta {
  const _$ProvisionJobStatusMeta();
  ProvisionJobStatus get queued => _$queued;
  ProvisionJobStatus get running => _$running;
  ProvisionJobStatus get completed => _$completed;
  ProvisionJobStatus get failed => _$failed;
  ProvisionJobStatus valueOf(String name) => _$valueOf(name);
  BuiltSet<ProvisionJobStatus> get values => _$values;
}

mixin _$ProvisionJobStatusMixin {
  // ignore: non_constant_identifier_names
  _$ProvisionJobStatusMeta get ProvisionJobStatus =>
      const _$ProvisionJobStatusMeta();
}

Serializer<ProvisionJobStatus> _$provisionJobStatusSerializer =
    _$ProvisionJobStatusSerializer();

class _$ProvisionJobStatusSerializer
    implements PrimitiveSerializer<ProvisionJobStatus> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'queued': 'queued',
    'running': 'running',
    'completed': 'completed',
    'failed': 'failed',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'queued': 'queued',
    'running': 'running',
    'completed': 'completed',
    'failed': 'failed',
  };

  @override
  final Iterable<Type> types = const <Type>[ProvisionJobStatus];
  @override
  final String wireName = 'ProvisionJobStatus';

  @override
  Object serialize(
    Serializers serializers,
    ProvisionJobStatus object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ProvisionJobStatus deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ProvisionJobStatus.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
