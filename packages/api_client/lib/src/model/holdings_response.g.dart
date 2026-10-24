// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holdings_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$HoldingsResponse extends HoldingsResponse {
  @override
  final BuiltList<Holding> holdings;
  @override
  final BuiltList<Security> securities;

  factory _$HoldingsResponse([
    void Function(HoldingsResponseBuilder)? updates,
  ]) => (HoldingsResponseBuilder()..update(updates))._build();

  _$HoldingsResponse._({required this.holdings, required this.securities})
    : super._();
  @override
  HoldingsResponse rebuild(void Function(HoldingsResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  HoldingsResponseBuilder toBuilder() =>
      HoldingsResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is HoldingsResponse &&
        holdings == other.holdings &&
        securities == other.securities;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, holdings.hashCode);
    _$hash = $jc(_$hash, securities.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'HoldingsResponse')
          ..add('holdings', holdings)
          ..add('securities', securities))
        .toString();
  }
}

class HoldingsResponseBuilder
    implements Builder<HoldingsResponse, HoldingsResponseBuilder> {
  _$HoldingsResponse? _$v;

  ListBuilder<Holding>? _holdings;
  ListBuilder<Holding> get holdings =>
      _$this._holdings ??= ListBuilder<Holding>();
  set holdings(ListBuilder<Holding>? holdings) => _$this._holdings = holdings;

  ListBuilder<Security>? _securities;
  ListBuilder<Security> get securities =>
      _$this._securities ??= ListBuilder<Security>();
  set securities(ListBuilder<Security>? securities) =>
      _$this._securities = securities;

  HoldingsResponseBuilder() {
    HoldingsResponse._defaults(this);
  }

  HoldingsResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _holdings = $v.holdings.toBuilder();
      _securities = $v.securities.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(HoldingsResponse other) {
    _$v = other as _$HoldingsResponse;
  }

  @override
  void update(void Function(HoldingsResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  HoldingsResponse build() => _build();

  _$HoldingsResponse _build() {
    _$HoldingsResponse _$result;
    try {
      _$result =
          _$v ??
          _$HoldingsResponse._(
            holdings: holdings.build(),
            securities: securities.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'holdings';
        holdings.build();
        _$failedField = 'securities';
        securities.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'HoldingsResponse',
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
