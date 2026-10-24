// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_link_token_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateLinkTokenRequest extends UpdateLinkTokenRequest {
  @override
  final String androidPackageName;

  factory _$UpdateLinkTokenRequest([
    void Function(UpdateLinkTokenRequestBuilder)? updates,
  ]) => (UpdateLinkTokenRequestBuilder()..update(updates))._build();

  _$UpdateLinkTokenRequest._({required this.androidPackageName}) : super._();
  @override
  UpdateLinkTokenRequest rebuild(
    void Function(UpdateLinkTokenRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateLinkTokenRequestBuilder toBuilder() =>
      UpdateLinkTokenRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateLinkTokenRequest &&
        androidPackageName == other.androidPackageName;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, androidPackageName.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'UpdateLinkTokenRequest',
    )..add('androidPackageName', androidPackageName)).toString();
  }
}

class UpdateLinkTokenRequestBuilder
    implements Builder<UpdateLinkTokenRequest, UpdateLinkTokenRequestBuilder> {
  _$UpdateLinkTokenRequest? _$v;

  String? _androidPackageName;
  String? get androidPackageName => _$this._androidPackageName;
  set androidPackageName(String? androidPackageName) =>
      _$this._androidPackageName = androidPackageName;

  UpdateLinkTokenRequestBuilder() {
    UpdateLinkTokenRequest._defaults(this);
  }

  UpdateLinkTokenRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _androidPackageName = $v.androidPackageName;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateLinkTokenRequest other) {
    _$v = other as _$UpdateLinkTokenRequest;
  }

  @override
  void update(void Function(UpdateLinkTokenRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateLinkTokenRequest build() => _build();

  _$UpdateLinkTokenRequest _build() {
    final _$result =
        _$v ??
        _$UpdateLinkTokenRequest._(
          androidPackageName: BuiltValueNullFieldError.checkNotNull(
            androidPackageName,
            r'UpdateLinkTokenRequest',
            'androidPackageName',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
