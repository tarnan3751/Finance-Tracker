//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'recurring_cadence.g.dart';

/// Plaid's `frequency` in our naming; `quarterly` is never Plaid's (its frequencies have none) and comes from the app's own detector
class RecurringCadence extends EnumClass {
  @BuiltValueEnumConst(wireName: r'weekly')
  static const RecurringCadence weekly = _$weekly;
  @BuiltValueEnumConst(wireName: r'biweekly')
  static const RecurringCadence biweekly = _$biweekly;
  @BuiltValueEnumConst(wireName: r'semi_monthly')
  static const RecurringCadence semiMonthly = _$semiMonthly;
  @BuiltValueEnumConst(wireName: r'quarterly')
  static const RecurringCadence quarterly = _$quarterly;
  @BuiltValueEnumConst(wireName: r'monthly')
  static const RecurringCadence monthly = _$monthly;
  @BuiltValueEnumConst(wireName: r'annually')
  static const RecurringCadence annually = _$annually;
  @BuiltValueEnumConst(wireName: r'unknown')
  static const RecurringCadence unknown = _$unknown;

  static Serializer<RecurringCadence> get serializer =>
      _$recurringCadenceSerializer;

  const RecurringCadence._(String name) : super(name);

  static BuiltSet<RecurringCadence> get values => _$values;
  static RecurringCadence valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class RecurringCadenceMixin = Object with _$RecurringCadenceMixin;
