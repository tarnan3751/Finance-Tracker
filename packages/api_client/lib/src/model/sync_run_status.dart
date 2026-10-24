//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'sync_run_status.g.dart';

class SyncRunStatus extends EnumClass {
  @BuiltValueEnumConst(wireName: r'started')
  static const SyncRunStatus started = _$started;
  @BuiltValueEnumConst(wireName: r'not_ready')
  static const SyncRunStatus notReady = _$notReady;
  @BuiltValueEnumConst(wireName: r'completed')
  static const SyncRunStatus completed = _$completed;

  static Serializer<SyncRunStatus> get serializer => _$syncRunStatusSerializer;

  const SyncRunStatus._(String name) : super(name);

  static BuiltSet<SyncRunStatus> get values => _$values;
  static SyncRunStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class SyncRunStatusMixin = Object with _$SyncRunStatusMixin;
