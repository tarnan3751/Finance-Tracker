//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'provision_job_status.g.dart';

class ProvisionJobStatus extends EnumClass {
  @BuiltValueEnumConst(wireName: r'queued')
  static const ProvisionJobStatus queued = _$queued;
  @BuiltValueEnumConst(wireName: r'running')
  static const ProvisionJobStatus running = _$running;
  @BuiltValueEnumConst(wireName: r'completed')
  static const ProvisionJobStatus completed = _$completed;
  @BuiltValueEnumConst(wireName: r'failed')
  static const ProvisionJobStatus failed = _$failed;

  static Serializer<ProvisionJobStatus> get serializer =>
      _$provisionJobStatusSerializer;

  const ProvisionJobStatus._(String name) : super(name);

  static BuiltSet<ProvisionJobStatus> get values => _$values;
  static ProvisionJobStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ProvisionJobStatusMixin = Object with _$ProvisionJobStatusMixin;
