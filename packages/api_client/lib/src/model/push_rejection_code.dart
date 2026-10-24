//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'push_rejection_code.g.dart';

/// The sync engine's `PushRejectionReason` names in snake_case
class PushRejectionCode extends EnumClass {
  @BuiltValueEnumConst(wireName: r'clock_drift')
  static const PushRejectionCode clockDrift = _$clockDrift;
  @BuiltValueEnumConst(wireName: r'invalid')
  static const PushRejectionCode invalid = _$invalid;
  @BuiltValueEnumConst(wireName: r'conflicting_duplicate')
  static const PushRejectionCode conflictingDuplicate = _$conflictingDuplicate;

  static Serializer<PushRejectionCode> get serializer =>
      _$pushRejectionCodeSerializer;

  const PushRejectionCode._(String name) : super(name);

  static BuiltSet<PushRejectionCode> get values => _$values;
  static PushRejectionCode valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class PushRejectionCodeMixin = Object with _$PushRejectionCodeMixin;
