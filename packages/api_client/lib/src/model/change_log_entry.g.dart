// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'change_log_entry.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ChangeLogEntry extends ChangeLogEntry {
  @override
  final EntityType entityType;
  @override
  final String entityId;
  @override
  final ChangeOperation operation;
  @override
  final BuiltMap<String, JsonObject?> payload;
  @override
  final String hlc;
  @override
  final String deviceId;

  factory _$ChangeLogEntry([void Function(ChangeLogEntryBuilder)? updates]) =>
      (ChangeLogEntryBuilder()..update(updates))._build();

  _$ChangeLogEntry._({
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.hlc,
    required this.deviceId,
  }) : super._();
  @override
  ChangeLogEntry rebuild(void Function(ChangeLogEntryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ChangeLogEntryBuilder toBuilder() => ChangeLogEntryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ChangeLogEntry &&
        entityType == other.entityType &&
        entityId == other.entityId &&
        operation == other.operation &&
        payload == other.payload &&
        hlc == other.hlc &&
        deviceId == other.deviceId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, entityType.hashCode);
    _$hash = $jc(_$hash, entityId.hashCode);
    _$hash = $jc(_$hash, operation.hashCode);
    _$hash = $jc(_$hash, payload.hashCode);
    _$hash = $jc(_$hash, hlc.hashCode);
    _$hash = $jc(_$hash, deviceId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ChangeLogEntry')
          ..add('entityType', entityType)
          ..add('entityId', entityId)
          ..add('operation', operation)
          ..add('payload', payload)
          ..add('hlc', hlc)
          ..add('deviceId', deviceId))
        .toString();
  }
}

class ChangeLogEntryBuilder
    implements Builder<ChangeLogEntry, ChangeLogEntryBuilder> {
  _$ChangeLogEntry? _$v;

  EntityType? _entityType;
  EntityType? get entityType => _$this._entityType;
  set entityType(EntityType? entityType) => _$this._entityType = entityType;

  String? _entityId;
  String? get entityId => _$this._entityId;
  set entityId(String? entityId) => _$this._entityId = entityId;

  ChangeOperation? _operation;
  ChangeOperation? get operation => _$this._operation;
  set operation(ChangeOperation? operation) => _$this._operation = operation;

  MapBuilder<String, JsonObject?>? _payload;
  MapBuilder<String, JsonObject?> get payload =>
      _$this._payload ??= MapBuilder<String, JsonObject?>();
  set payload(MapBuilder<String, JsonObject?>? payload) =>
      _$this._payload = payload;

  String? _hlc;
  String? get hlc => _$this._hlc;
  set hlc(String? hlc) => _$this._hlc = hlc;

  String? _deviceId;
  String? get deviceId => _$this._deviceId;
  set deviceId(String? deviceId) => _$this._deviceId = deviceId;

  ChangeLogEntryBuilder() {
    ChangeLogEntry._defaults(this);
  }

  ChangeLogEntryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _entityType = $v.entityType;
      _entityId = $v.entityId;
      _operation = $v.operation;
      _payload = $v.payload.toBuilder();
      _hlc = $v.hlc;
      _deviceId = $v.deviceId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ChangeLogEntry other) {
    _$v = other as _$ChangeLogEntry;
  }

  @override
  void update(void Function(ChangeLogEntryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ChangeLogEntry build() => _build();

  _$ChangeLogEntry _build() {
    _$ChangeLogEntry _$result;
    try {
      _$result =
          _$v ??
          _$ChangeLogEntry._(
            entityType: BuiltValueNullFieldError.checkNotNull(
              entityType,
              r'ChangeLogEntry',
              'entityType',
            ),
            entityId: BuiltValueNullFieldError.checkNotNull(
              entityId,
              r'ChangeLogEntry',
              'entityId',
            ),
            operation: BuiltValueNullFieldError.checkNotNull(
              operation,
              r'ChangeLogEntry',
              'operation',
            ),
            payload: payload.build(),
            hlc: BuiltValueNullFieldError.checkNotNull(
              hlc,
              r'ChangeLogEntry',
              'hlc',
            ),
            deviceId: BuiltValueNullFieldError.checkNotNull(
              deviceId,
              r'ChangeLogEntry',
              'deviceId',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'payload';
        payload.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ChangeLogEntry',
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
