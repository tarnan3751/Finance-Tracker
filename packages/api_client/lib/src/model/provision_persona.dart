//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'provision_persona.g.dart';

/// The persona engine's personas (docs/reference/persona.md)
class ProvisionPersona extends EnumClass {
  @BuiltValueEnumConst(wireName: r'renter')
  static const ProvisionPersona renter = _$renter;
  @BuiltValueEnumConst(wireName: r'family')
  static const ProvisionPersona family = _$family;
  @BuiltValueEnumConst(wireName: r'student')
  static const ProvisionPersona student = _$student;
  @BuiltValueEnumConst(wireName: r'small_business')
  static const ProvisionPersona smallBusiness = _$smallBusiness;

  static Serializer<ProvisionPersona> get serializer =>
      _$provisionPersonaSerializer;

  const ProvisionPersona._(String name) : super(name);

  static BuiltSet<ProvisionPersona> get values => _$values;
  static ProvisionPersona valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ProvisionPersonaMixin = Object with _$ProvisionPersonaMixin;
