// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Security extends Security {
  @override
  final String id;
  @override
  final String? name;
  @override
  final String? tickerSymbol;
  @override
  final String? type;
  @override
  final bool? isCashEquivalent;
  @override
  final String? closePrice;
  @override
  final Date? closePriceAsOf;
  @override
  final String currencyCode;
  @override
  final DataSource source_;

  factory _$Security([void Function(SecurityBuilder)? updates]) =>
      (SecurityBuilder()..update(updates))._build();

  _$Security._({
    required this.id,
    this.name,
    this.tickerSymbol,
    this.type,
    this.isCashEquivalent,
    this.closePrice,
    this.closePriceAsOf,
    required this.currencyCode,
    required this.source_,
  }) : super._();
  @override
  Security rebuild(void Function(SecurityBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SecurityBuilder toBuilder() => SecurityBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Security &&
        id == other.id &&
        name == other.name &&
        tickerSymbol == other.tickerSymbol &&
        type == other.type &&
        isCashEquivalent == other.isCashEquivalent &&
        closePrice == other.closePrice &&
        closePriceAsOf == other.closePriceAsOf &&
        currencyCode == other.currencyCode &&
        source_ == other.source_;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, tickerSymbol.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, isCashEquivalent.hashCode);
    _$hash = $jc(_$hash, closePrice.hashCode);
    _$hash = $jc(_$hash, closePriceAsOf.hashCode);
    _$hash = $jc(_$hash, currencyCode.hashCode);
    _$hash = $jc(_$hash, source_.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Security')
          ..add('id', id)
          ..add('name', name)
          ..add('tickerSymbol', tickerSymbol)
          ..add('type', type)
          ..add('isCashEquivalent', isCashEquivalent)
          ..add('closePrice', closePrice)
          ..add('closePriceAsOf', closePriceAsOf)
          ..add('currencyCode', currencyCode)
          ..add('source_', source_))
        .toString();
  }
}

class SecurityBuilder implements Builder<Security, SecurityBuilder> {
  _$Security? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _tickerSymbol;
  String? get tickerSymbol => _$this._tickerSymbol;
  set tickerSymbol(String? tickerSymbol) => _$this._tickerSymbol = tickerSymbol;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  bool? _isCashEquivalent;
  bool? get isCashEquivalent => _$this._isCashEquivalent;
  set isCashEquivalent(bool? isCashEquivalent) =>
      _$this._isCashEquivalent = isCashEquivalent;

  String? _closePrice;
  String? get closePrice => _$this._closePrice;
  set closePrice(String? closePrice) => _$this._closePrice = closePrice;

  Date? _closePriceAsOf;
  Date? get closePriceAsOf => _$this._closePriceAsOf;
  set closePriceAsOf(Date? closePriceAsOf) =>
      _$this._closePriceAsOf = closePriceAsOf;

  String? _currencyCode;
  String? get currencyCode => _$this._currencyCode;
  set currencyCode(String? currencyCode) => _$this._currencyCode = currencyCode;

  DataSource? _source_;
  DataSource? get source_ => _$this._source_;
  set source_(DataSource? source_) => _$this._source_ = source_;

  SecurityBuilder() {
    Security._defaults(this);
  }

  SecurityBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _tickerSymbol = $v.tickerSymbol;
      _type = $v.type;
      _isCashEquivalent = $v.isCashEquivalent;
      _closePrice = $v.closePrice;
      _closePriceAsOf = $v.closePriceAsOf;
      _currencyCode = $v.currencyCode;
      _source_ = $v.source_;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Security other) {
    _$v = other as _$Security;
  }

  @override
  void update(void Function(SecurityBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Security build() => _build();

  _$Security _build() {
    final _$result =
        _$v ??
        _$Security._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'Security', 'id'),
          name: name,
          tickerSymbol: tickerSymbol,
          type: type,
          isCashEquivalent: isCashEquivalent,
          closePrice: closePrice,
          closePriceAsOf: closePriceAsOf,
          currencyCode: BuiltValueNullFieldError.checkNotNull(
            currencyCode,
            r'Security',
            'currencyCode',
          ),
          source_: BuiltValueNullFieldError.checkNotNull(
            source_,
            r'Security',
            'source_',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
