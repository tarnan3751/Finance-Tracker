// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'money.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Money extends Money {
  @override
  final int minorUnits;
  @override
  final String currency;

  factory _$Money([void Function(MoneyBuilder)? updates]) =>
      (MoneyBuilder()..update(updates))._build();

  _$Money._({required this.minorUnits, required this.currency}) : super._();
  @override
  Money rebuild(void Function(MoneyBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MoneyBuilder toBuilder() => MoneyBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Money &&
        minorUnits == other.minorUnits &&
        currency == other.currency;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, minorUnits.hashCode);
    _$hash = $jc(_$hash, currency.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Money')
          ..add('minorUnits', minorUnits)
          ..add('currency', currency))
        .toString();
  }
}

class MoneyBuilder implements Builder<Money, MoneyBuilder> {
  _$Money? _$v;

  int? _minorUnits;
  int? get minorUnits => _$this._minorUnits;
  set minorUnits(int? minorUnits) => _$this._minorUnits = minorUnits;

  String? _currency;
  String? get currency => _$this._currency;
  set currency(String? currency) => _$this._currency = currency;

  MoneyBuilder() {
    Money._defaults(this);
  }

  MoneyBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _minorUnits = $v.minorUnits;
      _currency = $v.currency;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Money other) {
    _$v = other as _$Money;
  }

  @override
  void update(void Function(MoneyBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Money build() => _build();

  _$Money _build() {
    final _$result =
        _$v ??
        _$Money._(
          minorUnits: BuiltValueNullFieldError.checkNotNull(
            minorUnits,
            r'Money',
            'minorUnits',
          ),
          currency: BuiltValueNullFieldError.checkNotNull(
            currency,
            r'Money',
            'currency',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
