// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provision_persona.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ProvisionPersona _$renter = const ProvisionPersona._('renter');
const ProvisionPersona _$family = const ProvisionPersona._('family');
const ProvisionPersona _$student = const ProvisionPersona._('student');
const ProvisionPersona _$smallBusiness = const ProvisionPersona._(
  'smallBusiness',
);

ProvisionPersona _$valueOf(String name) {
  switch (name) {
    case 'renter':
      return _$renter;
    case 'family':
      return _$family;
    case 'student':
      return _$student;
    case 'smallBusiness':
      return _$smallBusiness;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ProvisionPersona> _$values = BuiltSet<ProvisionPersona>(
  const <ProvisionPersona>[_$renter, _$family, _$student, _$smallBusiness],
);

class _$ProvisionPersonaMeta {
  const _$ProvisionPersonaMeta();
  ProvisionPersona get renter => _$renter;
  ProvisionPersona get family => _$family;
  ProvisionPersona get student => _$student;
  ProvisionPersona get smallBusiness => _$smallBusiness;
  ProvisionPersona valueOf(String name) => _$valueOf(name);
  BuiltSet<ProvisionPersona> get values => _$values;
}

mixin _$ProvisionPersonaMixin {
  // ignore: non_constant_identifier_names
  _$ProvisionPersonaMeta get ProvisionPersona => const _$ProvisionPersonaMeta();
}

Serializer<ProvisionPersona> _$provisionPersonaSerializer =
    _$ProvisionPersonaSerializer();

class _$ProvisionPersonaSerializer
    implements PrimitiveSerializer<ProvisionPersona> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'renter': 'renter',
    'family': 'family',
    'student': 'student',
    'smallBusiness': 'small_business',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'renter': 'renter',
    'family': 'family',
    'student': 'student',
    'small_business': 'smallBusiness',
  };

  @override
  final Iterable<Type> types = const <Type>[ProvisionPersona];
  @override
  final String wireName = 'ProvisionPersona';

  @override
  Object serialize(
    Serializers serializers,
    ProvisionPersona object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ProvisionPersona deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ProvisionPersona.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
