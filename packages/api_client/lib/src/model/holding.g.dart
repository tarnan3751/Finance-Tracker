// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holding.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Holding extends Holding {
  @override
  final String accountId;
  @override
  final String securityId;
  @override
  final String quantity;
  @override
  final String institutionPrice;
  @override
  final Date? institutionPriceAsOf;
  @override
  final Money institutionValue;
  @override
  final Money? costBasis;
  @override
  final String currencyCode;
  @override
  final DataSource source_;

  factory _$Holding([void Function(HoldingBuilder)? updates]) =>
      (HoldingBuilder()..update(updates))._build();

  _$Holding._({
    required this.accountId,
    required this.securityId,
    required this.quantity,
    required this.institutionPrice,
    this.institutionPriceAsOf,
    required this.institutionValue,
    this.costBasis,
    required this.currencyCode,
    required this.source_,
  }) : super._();
  @override
  Holding rebuild(void Function(HoldingBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  HoldingBuilder toBuilder() => HoldingBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Holding &&
        accountId == other.accountId &&
        securityId == other.securityId &&
        quantity == other.quantity &&
        institutionPrice == other.institutionPrice &&
        institutionPriceAsOf == other.institutionPriceAsOf &&
        institutionValue == other.institutionValue &&
        costBasis == other.costBasis &&
        currencyCode == other.currencyCode &&
        source_ == other.source_;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accountId.hashCode);
    _$hash = $jc(_$hash, securityId.hashCode);
    _$hash = $jc(_$hash, quantity.hashCode);
    _$hash = $jc(_$hash, institutionPrice.hashCode);
    _$hash = $jc(_$hash, institutionPriceAsOf.hashCode);
    _$hash = $jc(_$hash, institutionValue.hashCode);
    _$hash = $jc(_$hash, costBasis.hashCode);
    _$hash = $jc(_$hash, currencyCode.hashCode);
    _$hash = $jc(_$hash, source_.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Holding')
          ..add('accountId', accountId)
          ..add('securityId', securityId)
          ..add('quantity', quantity)
          ..add('institutionPrice', institutionPrice)
          ..add('institutionPriceAsOf', institutionPriceAsOf)
          ..add('institutionValue', institutionValue)
          ..add('costBasis', costBasis)
          ..add('currencyCode', currencyCode)
          ..add('source_', source_))
        .toString();
  }
}

class HoldingBuilder implements Builder<Holding, HoldingBuilder> {
  _$Holding? _$v;

  String? _accountId;
  String? get accountId => _$this._accountId;
  set accountId(String? accountId) => _$this._accountId = accountId;

  String? _securityId;
  String? get securityId => _$this._securityId;
  set securityId(String? securityId) => _$this._securityId = securityId;

  String? _quantity;
  String? get quantity => _$this._quantity;
  set quantity(String? quantity) => _$this._quantity = quantity;

  String? _institutionPrice;
  String? get institutionPrice => _$this._institutionPrice;
  set institutionPrice(String? institutionPrice) =>
      _$this._institutionPrice = institutionPrice;

  Date? _institutionPriceAsOf;
  Date? get institutionPriceAsOf => _$this._institutionPriceAsOf;
  set institutionPriceAsOf(Date? institutionPriceAsOf) =>
      _$this._institutionPriceAsOf = institutionPriceAsOf;

  MoneyBuilder? _institutionValue;
  MoneyBuilder get institutionValue =>
      _$this._institutionValue ??= MoneyBuilder();
  set institutionValue(MoneyBuilder? institutionValue) =>
      _$this._institutionValue = institutionValue;

  MoneyBuilder? _costBasis;
  MoneyBuilder get costBasis => _$this._costBasis ??= MoneyBuilder();
  set costBasis(MoneyBuilder? costBasis) => _$this._costBasis = costBasis;

  String? _currencyCode;
  String? get currencyCode => _$this._currencyCode;
  set currencyCode(String? currencyCode) => _$this._currencyCode = currencyCode;

  DataSource? _source_;
  DataSource? get source_ => _$this._source_;
  set source_(DataSource? source_) => _$this._source_ = source_;

  HoldingBuilder() {
    Holding._defaults(this);
  }

  HoldingBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accountId = $v.accountId;
      _securityId = $v.securityId;
      _quantity = $v.quantity;
      _institutionPrice = $v.institutionPrice;
      _institutionPriceAsOf = $v.institutionPriceAsOf;
      _institutionValue = $v.institutionValue.toBuilder();
      _costBasis = $v.costBasis?.toBuilder();
      _currencyCode = $v.currencyCode;
      _source_ = $v.source_;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Holding other) {
    _$v = other as _$Holding;
  }

  @override
  void update(void Function(HoldingBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Holding build() => _build();

  _$Holding _build() {
    _$Holding _$result;
    try {
      _$result =
          _$v ??
          _$Holding._(
            accountId: BuiltValueNullFieldError.checkNotNull(
              accountId,
              r'Holding',
              'accountId',
            ),
            securityId: BuiltValueNullFieldError.checkNotNull(
              securityId,
              r'Holding',
              'securityId',
            ),
            quantity: BuiltValueNullFieldError.checkNotNull(
              quantity,
              r'Holding',
              'quantity',
            ),
            institutionPrice: BuiltValueNullFieldError.checkNotNull(
              institutionPrice,
              r'Holding',
              'institutionPrice',
            ),
            institutionPriceAsOf: institutionPriceAsOf,
            institutionValue: institutionValue.build(),
            costBasis: _costBasis?.build(),
            currencyCode: BuiltValueNullFieldError.checkNotNull(
              currencyCode,
              r'Holding',
              'currencyCode',
            ),
            source_: BuiltValueNullFieldError.checkNotNull(
              source_,
              r'Holding',
              'source_',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'institutionValue';
        institutionValue.build();
        _$failedField = 'costBasis';
        _costBasis?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'Holding',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
