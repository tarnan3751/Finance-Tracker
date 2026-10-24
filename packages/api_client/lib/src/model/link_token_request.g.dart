// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_token_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LinkTokenRequest extends LinkTokenRequest {
  @override
  final String androidPackageName;
  @override
  final String? updateItemId;

  factory _$LinkTokenRequest([
    void Function(LinkTokenRequestBuilder)? updates,
  ]) => (LinkTokenRequestBuilder()..update(updates))._build();

  _$LinkTokenRequest._({required this.androidPackageName, this.updateItemId})
    : super._();
  @override
  LinkTokenRequest rebuild(void Function(LinkTokenRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LinkTokenRequestBuilder toBuilder() =>
      LinkTokenRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LinkTokenRequest &&
        androidPackageName == other.androidPackageName &&
        updateItemId == other.updateItemId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, androidPackageName.hashCode);
    _$hash = $jc(_$hash, updateItemId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LinkTokenRequest')
          ..add('androidPackageName', androidPackageName)
          ..add('updateItemId', updateItemId))
        .toString();
  }
}

class LinkTokenRequestBuilder
    implements Builder<LinkTokenRequest, LinkTokenRequestBuilder> {
  _$LinkTokenRequest? _$v;

  String? _androidPackageName;
  String? get androidPackageName => _$this._androidPackageName;
  set androidPackageName(String? androidPackageName) =>
      _$this._androidPackageName = androidPackageName;

  String? _updateItemId;
  String? get updateItemId => _$this._updateItemId;
  set updateItemId(String? updateItemId) => _$this._updateItemId = updateItemId;

  LinkTokenRequestBuilder() {
    LinkTokenRequest._defaults(this);
  }

  LinkTokenRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _androidPackageName = $v.androidPackageName;
      _updateItemId = $v.updateItemId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LinkTokenRequest other) {
    _$v = other as _$LinkTokenRequest;
  }

  @override
  void update(void Function(LinkTokenRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LinkTokenRequest build() => _build();

  _$LinkTokenRequest _build() {
    final _$result =
        _$v ??
        _$LinkTokenRequest._(
          androidPackageName: BuiltValueNullFieldError.checkNotNull(
            androidPackageName,
            r'LinkTokenRequest',
            'androidPackageName',
          ),
          updateItemId: updateItemId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
