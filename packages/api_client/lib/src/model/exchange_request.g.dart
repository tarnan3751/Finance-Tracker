// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exchange_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ExchangeRequest extends ExchangeRequest {
  @override
  final String publicToken;

  factory _$ExchangeRequest([void Function(ExchangeRequestBuilder)? updates]) =>
      (ExchangeRequestBuilder()..update(updates))._build();

  _$ExchangeRequest._({required this.publicToken}) : super._();
  @override
  ExchangeRequest rebuild(void Function(ExchangeRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ExchangeRequestBuilder toBuilder() => ExchangeRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExchangeRequest && publicToken == other.publicToken;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, publicToken.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ExchangeRequest',
    )..add('publicToken', publicToken)).toString();
  }
}

class ExchangeRequestBuilder
    implements Builder<ExchangeRequest, ExchangeRequestBuilder> {
  _$ExchangeRequest? _$v;

  String? _publicToken;
  String? get publicToken => _$this._publicToken;
  set publicToken(String? publicToken) => _$this._publicToken = publicToken;

  ExchangeRequestBuilder() {
    ExchangeRequest._defaults(this);
  }

  ExchangeRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _publicToken = $v.publicToken;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ExchangeRequest other) {
    _$v = other as _$ExchangeRequest;
  }

  @override
  void update(void Function(ExchangeRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ExchangeRequest build() => _build();

  _$ExchangeRequest _build() {
    final _$result =
        _$v ??
        _$ExchangeRequest._(
          publicToken: BuiltValueNullFieldError.checkNotNull(
            publicToken,
            r'ExchangeRequest',
            'publicToken',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
