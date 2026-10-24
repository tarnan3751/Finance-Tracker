// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apr.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Apr extends Apr {
  @override
  final String aprPercentage;
  @override
  final String aprType;
  @override
  final Money? balanceSubjectToApr;
  @override
  final Money? interestChargeAmount;

  factory _$Apr([void Function(AprBuilder)? updates]) =>
      (AprBuilder()..update(updates))._build();

  _$Apr._({
    required this.aprPercentage,
    required this.aprType,
    this.balanceSubjectToApr,
    this.interestChargeAmount,
  }) : super._();
  @override
  Apr rebuild(void Function(AprBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AprBuilder toBuilder() => AprBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Apr &&
        aprPercentage == other.aprPercentage &&
        aprType == other.aprType &&
        balanceSubjectToApr == other.balanceSubjectToApr &&
        interestChargeAmount == other.interestChargeAmount;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, aprPercentage.hashCode);
    _$hash = $jc(_$hash, aprType.hashCode);
    _$hash = $jc(_$hash, balanceSubjectToApr.hashCode);
    _$hash = $jc(_$hash, interestChargeAmount.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Apr')
          ..add('aprPercentage', aprPercentage)
          ..add('aprType', aprType)
          ..add('balanceSubjectToApr', balanceSubjectToApr)
          ..add('interestChargeAmount', interestChargeAmount))
        .toString();
  }
}

class AprBuilder implements Builder<Apr, AprBuilder> {
  _$Apr? _$v;

  String? _aprPercentage;
  String? get aprPercentage => _$this._aprPercentage;
  set aprPercentage(String? aprPercentage) =>
      _$this._aprPercentage = aprPercentage;

  String? _aprType;
  String? get aprType => _$this._aprType;
  set aprType(String? aprType) => _$this._aprType = aprType;

  MoneyBuilder? _balanceSubjectToApr;
  MoneyBuilder get balanceSubjectToApr =>
      _$this._balanceSubjectToApr ??= MoneyBuilder();
  set balanceSubjectToApr(MoneyBuilder? balanceSubjectToApr) =>
      _$this._balanceSubjectToApr = balanceSubjectToApr;

  MoneyBuilder? _interestChargeAmount;
  MoneyBuilder get interestChargeAmount =>
      _$this._interestChargeAmount ??= MoneyBuilder();
  set interestChargeAmount(MoneyBuilder? interestChargeAmount) =>
      _$this._interestChargeAmount = interestChargeAmount;

  AprBuilder() {
    Apr._defaults(this);
  }

  AprBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _aprPercentage = $v.aprPercentage;
      _aprType = $v.aprType;
      _balanceSubjectToApr = $v.balanceSubjectToApr?.toBuilder();
      _interestChargeAmount = $v.interestChargeAmount?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Apr other) {
    _$v = other as _$Apr;
  }

  @override
  void update(void Function(AprBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Apr build() => _build();

  _$Apr _build() {
    _$Apr _$result;
    try {
      _$result =
          _$v ??
          _$Apr._(
            aprPercentage: BuiltValueNullFieldError.checkNotNull(
              aprPercentage,
              r'Apr',
              'aprPercentage',
            ),
            aprType: BuiltValueNullFieldError.checkNotNull(
              aprType,
              r'Apr',
              'aprType',
            ),
            balanceSubjectToApr: _balanceSubjectToApr?.build(),
            interestChargeAmount: _interestChargeAmount?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'balanceSubjectToApr';
        _balanceSubjectToApr?.build();
        _$failedField = 'interestChargeAmount';
        _interestChargeAmount?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'Apr', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
