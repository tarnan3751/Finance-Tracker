// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_tokens.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AuthTokens extends AuthTokens {
  @override
  final String accessToken;
  @override
  final String refreshToken;
  @override
  final int accessExpiresIn;
  @override
  final Device device;

  factory _$AuthTokens([void Function(AuthTokensBuilder)? updates]) =>
      (AuthTokensBuilder()..update(updates))._build();

  _$AuthTokens._({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresIn,
    required this.device,
  }) : super._();
  @override
  AuthTokens rebuild(void Function(AuthTokensBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AuthTokensBuilder toBuilder() => AuthTokensBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AuthTokens &&
        accessToken == other.accessToken &&
        refreshToken == other.refreshToken &&
        accessExpiresIn == other.accessExpiresIn &&
        device == other.device;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accessToken.hashCode);
    _$hash = $jc(_$hash, refreshToken.hashCode);
    _$hash = $jc(_$hash, accessExpiresIn.hashCode);
    _$hash = $jc(_$hash, device.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AuthTokens')
          ..add('accessToken', accessToken)
          ..add('refreshToken', refreshToken)
          ..add('accessExpiresIn', accessExpiresIn)
          ..add('device', device))
        .toString();
  }
}

class AuthTokensBuilder implements Builder<AuthTokens, AuthTokensBuilder> {
  _$AuthTokens? _$v;

  String? _accessToken;
  String? get accessToken => _$this._accessToken;
  set accessToken(String? accessToken) => _$this._accessToken = accessToken;

  String? _refreshToken;
  String? get refreshToken => _$this._refreshToken;
  set refreshToken(String? refreshToken) => _$this._refreshToken = refreshToken;

  int? _accessExpiresIn;
  int? get accessExpiresIn => _$this._accessExpiresIn;
  set accessExpiresIn(int? accessExpiresIn) =>
      _$this._accessExpiresIn = accessExpiresIn;

  DeviceBuilder? _device;
  DeviceBuilder get device => _$this._device ??= DeviceBuilder();
  set device(DeviceBuilder? device) => _$this._device = device;

  AuthTokensBuilder() {
    AuthTokens._defaults(this);
  }

  AuthTokensBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accessToken = $v.accessToken;
      _refreshToken = $v.refreshToken;
      _accessExpiresIn = $v.accessExpiresIn;
      _device = $v.device.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AuthTokens other) {
    _$v = other as _$AuthTokens;
  }

  @override
  void update(void Function(AuthTokensBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AuthTokens build() => _build();

  _$AuthTokens _build() {
    _$AuthTokens _$result;
    try {
      _$result =
          _$v ??
          _$AuthTokens._(
            accessToken: BuiltValueNullFieldError.checkNotNull(
              accessToken,
              r'AuthTokens',
              'accessToken',
            ),
            refreshToken: BuiltValueNullFieldError.checkNotNull(
              refreshToken,
              r'AuthTokens',
              'refreshToken',
            ),
            accessExpiresIn: BuiltValueNullFieldError.checkNotNull(
              accessExpiresIn,
              r'AuthTokens',
              'accessExpiresIn',
            ),
            device: device.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'device';
        device.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'AuthTokens',
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
