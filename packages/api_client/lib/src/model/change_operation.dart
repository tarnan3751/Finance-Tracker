//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'change_operation.g.dart';

class ChangeOperation extends EnumClass {
  @BuiltValueEnumConst(wireName: r'create')
  static const ChangeOperation create = _$create;
  @BuiltValueEnumConst(wireName: r'update')
  static const ChangeOperation update = _$update;
  @BuiltValueEnumConst(wireName: r'delete')
  static const ChangeOperation delete = _$delete;

  static Serializer<ChangeOperation> get serializer =>
      _$changeOperationSerializer;

  const ChangeOperation._(String name) : super(name);

  static BuiltSet<ChangeOperation> get values => _$values;
  static ChangeOperation valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ChangeOperationMixin = Object with _$ChangeOperationMixin;
