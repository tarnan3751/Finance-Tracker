//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'recurring_status.g.dart';

class RecurringStatus extends EnumClass {
  @BuiltValueEnumConst(wireName: r'active')
  static const RecurringStatus active = _$active;
  @BuiltValueEnumConst(wireName: r'ended')
  static const RecurringStatus ended = _$ended;

  static Serializer<RecurringStatus> get serializer =>
      _$recurringStatusSerializer;

  const RecurringStatus._(String name) : super(name);

  static BuiltSet<RecurringStatus> get values => _$values;
  static RecurringStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class RecurringStatusMixin = Object with _$RecurringStatusMixin;
