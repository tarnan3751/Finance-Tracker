// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_type.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AccountType _$depository = const AccountType._('depository');
const AccountType _$credit = const AccountType._('credit');
const AccountType _$loan = const AccountType._('loan');
const AccountType _$investment = const AccountType._('investment');
const AccountType _$other = const AccountType._('other');

AccountType _$valueOf(String name) {
  switch (name) {
    case 'depository':
      return _$depository;
    case 'credit':
      return _$credit;
    case 'loan':
      return _$loan;
    case 'investment':
      return _$investment;
    case 'other':
      return _$other;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AccountType> _$values = BuiltSet<AccountType>(
  const <AccountType>[_$depository, _$credit, _$loan, _$investment, _$other],
);

class _$AccountTypeMeta {
  const _$AccountTypeMeta();
  AccountType get depository => _$depository;
  AccountType get credit => _$credit;
  AccountType get loan => _$loan;
  AccountType get investment => _$investment;
  AccountType get other => _$other;
  AccountType valueOf(String name) => _$valueOf(name);
  BuiltSet<AccountType> get values => _$values;
}

mixin _$AccountTypeMixin {
  // ignore: non_constant_identifier_names
  _$AccountTypeMeta get AccountType => const _$AccountTypeMeta();
}

Serializer<AccountType> _$accountTypeSerializer = _$AccountTypeSerializer();

class _$AccountTypeSerializer implements PrimitiveSerializer<AccountType> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'depository': 'depository',
    'credit': 'credit',
    'loan': 'loan',
    'investment': 'investment',
    'other': 'other',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'depository': 'depository',
    'credit': 'credit',
    'loan': 'loan',
    'investment': 'investment',
    'other': 'other',
  };

  @override
  final Iterable<Type> types = const <Type>[AccountType];
  @override
  final String wireName = 'AccountType';

  @override
  Object serialize(
    Serializers serializers,
    AccountType object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  AccountType deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => AccountType.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
