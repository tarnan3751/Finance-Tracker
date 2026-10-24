//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'recurring_source.g.dart';

/// Who found the stream: Plaid, the app's own detector or the user; `demo` for a stream from the demo flavor or the dev server's fake Plaid client (PLAN.md §7.1)
class RecurringSource extends EnumClass {
  @BuiltValueEnumConst(wireName: r'plaid')
  static const RecurringSource plaid = _$plaid;
  @BuiltValueEnumConst(wireName: r'detected')
  static const RecurringSource detected = _$detected;
  @BuiltValueEnumConst(wireName: r'user')
  static const RecurringSource user = _$user;
  @BuiltValueEnumConst(wireName: r'demo')
  static const RecurringSource demo = _$demo;

  static Serializer<RecurringSource> get serializer =>
      _$recurringSourceSerializer;

  const RecurringSource._(String name) : super(name);

  static BuiltSet<RecurringSource> get values => _$values;
  static RecurringSource valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class RecurringSourceMixin = Object with _$RecurringSourceMixin;
