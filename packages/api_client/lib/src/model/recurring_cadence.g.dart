// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_cadence.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const RecurringCadence _$weekly = const RecurringCadence._('weekly');
const RecurringCadence _$biweekly = const RecurringCadence._('biweekly');
const RecurringCadence _$semiMonthly = const RecurringCadence._('semiMonthly');
const RecurringCadence _$monthly = const RecurringCadence._('monthly');
const RecurringCadence _$annually = const RecurringCadence._('annually');
const RecurringCadence _$unknown = const RecurringCadence._('unknown');

RecurringCadence _$valueOf(String name) {
  switch (name) {
    case 'weekly':
      return _$weekly;
    case 'biweekly':
      return _$biweekly;
    case 'semiMonthly':
      return _$semiMonthly;
    case 'monthly':
      return _$monthly;
    case 'annually':
      return _$annually;
    case 'unknown':
      return _$unknown;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<RecurringCadence> _$values = BuiltSet<RecurringCadence>(
  const <RecurringCadence>[
    _$weekly,
    _$biweekly,
    _$semiMonthly,
    _$monthly,
    _$annually,
    _$unknown,
  ],
);

class _$RecurringCadenceMeta {
  const _$RecurringCadenceMeta();
  RecurringCadence get weekly => _$weekly;
  RecurringCadence get biweekly => _$biweekly;
  RecurringCadence get semiMonthly => _$semiMonthly;
  RecurringCadence get monthly => _$monthly;
  RecurringCadence get annually => _$annually;
  RecurringCadence get unknown => _$unknown;
  RecurringCadence valueOf(String name) => _$valueOf(name);
  BuiltSet<RecurringCadence> get values => _$values;
}

mixin _$RecurringCadenceMixin {
  // ignore: non_constant_identifier_names
  _$RecurringCadenceMeta get RecurringCadence => const _$RecurringCadenceMeta();
}

Serializer<RecurringCadence> _$recurringCadenceSerializer =
    _$RecurringCadenceSerializer();

class _$RecurringCadenceSerializer
    implements PrimitiveSerializer<RecurringCadence> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'weekly': 'weekly',
    'biweekly': 'biweekly',
    'semiMonthly': 'semi_monthly',
    'monthly': 'monthly',
    'annually': 'annually',
    'unknown': 'unknown',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'weekly': 'weekly',
    'biweekly': 'biweekly',
    'semi_monthly': 'semiMonthly',
    'monthly': 'monthly',
    'annually': 'annually',
    'unknown': 'unknown',
  };

  @override
  final Iterable<Type> types = const <Type>[RecurringCadence];
  @override
  final String wireName = 'RecurringCadence';

  @override
  Object serialize(
    Serializers serializers,
    RecurringCadence object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  RecurringCadence deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => RecurringCadence.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
