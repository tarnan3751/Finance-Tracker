// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Device extends Device {
  @override
  final String id;
  @override
  final String userId;
  @override
  final String name;
  @override
  final DateTime? lastSyncAt;

  factory _$Device([void Function(DeviceBuilder)? updates]) =>
      (DeviceBuilder()..update(updates))._build();

  _$Device._({
    required this.id,
    required this.userId,
    required this.name,
    this.lastSyncAt,
  }) : super._();
  @override
  Device rebuild(void Function(DeviceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeviceBuilder toBuilder() => DeviceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Device &&
        id == other.id &&
        userId == other.userId &&
        name == other.name &&
        lastSyncAt == other.lastSyncAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, lastSyncAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Device')
          ..add('id', id)
          ..add('userId', userId)
          ..add('name', name)
          ..add('lastSyncAt', lastSyncAt))
        .toString();
  }
}

class DeviceBuilder implements Builder<Device, DeviceBuilder> {
  _$Device? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  DateTime? _lastSyncAt;
  DateTime? get lastSyncAt => _$this._lastSyncAt;
  set lastSyncAt(DateTime? lastSyncAt) => _$this._lastSyncAt = lastSyncAt;

  DeviceBuilder() {
    Device._defaults(this);
  }

  DeviceBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _userId = $v.userId;
      _name = $v.name;
      _lastSyncAt = $v.lastSyncAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Device other) {
    _$v = other as _$Device;
  }

  @override
  void update(void Function(DeviceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Device build() => _build();

  _$Device _build() {
    final _$result =
        _$v ??
        _$Device._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'Device', 'id'),
          userId: BuiltValueNullFieldError.checkNotNull(
            userId,
            r'Device',
            'userId',
          ),
          name: BuiltValueNullFieldError.checkNotNull(name, r'Device', 'name'),
          lastSyncAt: lastSyncAt,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
