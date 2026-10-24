// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Item extends Item {
  @override
  final String id;
  @override
  final String institutionId;
  @override
  final ItemStatus status;
  @override
  final DateTime? lastSuccessfulSyncAt;
  @override
  final String? errorCode;
  @override
  final Institution institution;

  factory _$Item([void Function(ItemBuilder)? updates]) =>
      (ItemBuilder()..update(updates))._build();

  _$Item._({
    required this.id,
    required this.institutionId,
    required this.status,
    this.lastSuccessfulSyncAt,
    this.errorCode,
    required this.institution,
  }) : super._();
  @override
  Item rebuild(void Function(ItemBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ItemBuilder toBuilder() => ItemBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Item &&
        id == other.id &&
        institutionId == other.institutionId &&
        status == other.status &&
        lastSuccessfulSyncAt == other.lastSuccessfulSyncAt &&
        errorCode == other.errorCode &&
        institution == other.institution;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, institutionId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, lastSuccessfulSyncAt.hashCode);
    _$hash = $jc(_$hash, errorCode.hashCode);
    _$hash = $jc(_$hash, institution.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Item')
          ..add('id', id)
          ..add('institutionId', institutionId)
          ..add('status', status)
          ..add('lastSuccessfulSyncAt', lastSuccessfulSyncAt)
          ..add('errorCode', errorCode)
          ..add('institution', institution))
        .toString();
  }
}

class ItemBuilder implements Builder<Item, ItemBuilder> {
  _$Item? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _institutionId;
  String? get institutionId => _$this._institutionId;
  set institutionId(String? institutionId) =>
      _$this._institutionId = institutionId;

  ItemStatus? _status;
  ItemStatus? get status => _$this._status;
  set status(ItemStatus? status) => _$this._status = status;

  DateTime? _lastSuccessfulSyncAt;
  DateTime? get lastSuccessfulSyncAt => _$this._lastSuccessfulSyncAt;
  set lastSuccessfulSyncAt(DateTime? lastSuccessfulSyncAt) =>
      _$this._lastSuccessfulSyncAt = lastSuccessfulSyncAt;

  String? _errorCode;
  String? get errorCode => _$this._errorCode;
  set errorCode(String? errorCode) => _$this._errorCode = errorCode;

  InstitutionBuilder? _institution;
  InstitutionBuilder get institution =>
      _$this._institution ??= InstitutionBuilder();
  set institution(InstitutionBuilder? institution) =>
      _$this._institution = institution;

  ItemBuilder() {
    Item._defaults(this);
  }

  ItemBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _institutionId = $v.institutionId;
      _status = $v.status;
      _lastSuccessfulSyncAt = $v.lastSuccessfulSyncAt;
      _errorCode = $v.errorCode;
      _institution = $v.institution.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Item other) {
    _$v = other as _$Item;
  }

  @override
  void update(void Function(ItemBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Item build() => _build();

  _$Item _build() {
    _$Item _$result;
    try {
      _$result =
          _$v ??
          _$Item._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'Item', 'id'),
            institutionId: BuiltValueNullFieldError.checkNotNull(
              institutionId,
              r'Item',
              'institutionId',
            ),
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'Item',
              'status',
            ),
            lastSuccessfulSyncAt: lastSuccessfulSyncAt,
            errorCode: errorCode,
            institution: institution.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'institution';
        institution.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'Item', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
