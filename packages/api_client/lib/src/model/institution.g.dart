// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'institution.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Institution extends Institution {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? logoUrl;
  @override
  final int? primaryColor;

  factory _$Institution([void Function(InstitutionBuilder)? updates]) =>
      (InstitutionBuilder()..update(updates))._build();

  _$Institution._({
    required this.id,
    required this.name,
    this.logoUrl,
    this.primaryColor,
  }) : super._();
  @override
  Institution rebuild(void Function(InstitutionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  InstitutionBuilder toBuilder() => InstitutionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Institution &&
        id == other.id &&
        name == other.name &&
        logoUrl == other.logoUrl &&
        primaryColor == other.primaryColor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, logoUrl.hashCode);
    _$hash = $jc(_$hash, primaryColor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Institution')
          ..add('id', id)
          ..add('name', name)
          ..add('logoUrl', logoUrl)
          ..add('primaryColor', primaryColor))
        .toString();
  }
}

class InstitutionBuilder implements Builder<Institution, InstitutionBuilder> {
  _$Institution? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _logoUrl;
  String? get logoUrl => _$this._logoUrl;
  set logoUrl(String? logoUrl) => _$this._logoUrl = logoUrl;

  int? _primaryColor;
  int? get primaryColor => _$this._primaryColor;
  set primaryColor(int? primaryColor) => _$this._primaryColor = primaryColor;

  InstitutionBuilder() {
    Institution._defaults(this);
  }

  InstitutionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _logoUrl = $v.logoUrl;
      _primaryColor = $v.primaryColor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Institution other) {
    _$v = other as _$Institution;
  }

  @override
  void update(void Function(InstitutionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Institution build() => _build();

  _$Institution _build() {
    final _$result =
        _$v ??
        _$Institution._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'Institution', 'id'),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'Institution',
            'name',
          ),
          logoUrl: logoUrl,
          primaryColor: primaryColor,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
