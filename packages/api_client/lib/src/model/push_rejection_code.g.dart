// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_rejection_code.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PushRejectionCode _$clockDrift = const PushRejectionCode._('clockDrift');
const PushRejectionCode _$invalid = const PushRejectionCode._('invalid');
const PushRejectionCode _$conflictingDuplicate = const PushRejectionCode._(
  'conflictingDuplicate',
);

PushRejectionCode _$valueOf(String name) {
  switch (name) {
    case 'clockDrift':
      return _$clockDrift;
    case 'invalid':
      return _$invalid;
    case 'conflictingDuplicate':
      return _$conflictingDuplicate;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<PushRejectionCode> _$values = BuiltSet<PushRejectionCode>(
  const <PushRejectionCode>[_$clockDrift, _$invalid, _$conflictingDuplicate],
);

class _$PushRejectionCodeMeta {
  const _$PushRejectionCodeMeta();
  PushRejectionCode get clockDrift => _$clockDrift;
  PushRejectionCode get invalid => _$invalid;
  PushRejectionCode get conflictingDuplicate => _$conflictingDuplicate;
  PushRejectionCode valueOf(String name) => _$valueOf(name);
  BuiltSet<PushRejectionCode> get values => _$values;
}

mixin _$PushRejectionCodeMixin {
  // ignore: non_constant_identifier_names
  _$PushRejectionCodeMeta get PushRejectionCode =>
      const _$PushRejectionCodeMeta();
}

Serializer<PushRejectionCode> _$pushRejectionCodeSerializer =
    _$PushRejectionCodeSerializer();

class _$PushRejectionCodeSerializer
    implements PrimitiveSerializer<PushRejectionCode> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'clockDrift': 'clock_drift',
    'invalid': 'invalid',
    'conflictingDuplicate': 'conflicting_duplicate',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'clock_drift': 'clockDrift',
    'invalid': 'invalid',
    'conflicting_duplicate': 'conflictingDuplicate',
  };

  @override
  final Iterable<Type> types = const <Type>[PushRejectionCode];
  @override
  final String wireName = 'PushRejectionCode';

  @override
  Object serialize(
    Serializers serializers,
    PushRejectionCode object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  PushRejectionCode deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => PushRejectionCode.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
