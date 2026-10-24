// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pulled_change_log_entry.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PulledChangeLogEntry extends PulledChangeLogEntry {
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
  @override
  final int seq;

  factory _$PulledChangeLogEntry([
    void Function(PulledChangeLogEntryBuilder)? updates,
  ]) => (PulledChangeLogEntryBuilder()..update(updates))._build();

  _$PulledChangeLogEntry._({
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.hlc,
    required this.deviceId,
    required this.seq,
  }) : super._();
  @override
  PulledChangeLogEntry rebuild(
    void Function(PulledChangeLogEntryBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  PulledChangeLogEntryBuilder toBuilder() =>
      PulledChangeLogEntryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PulledChangeLogEntry &&
        entityType == other.entityType &&
        entityId == other.entityId &&
        operation == other.operation &&
        payload == other.payload &&
        hlc == other.hlc &&
        deviceId == other.deviceId &&
        seq == other.seq;
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
    _$hash = $jc(_$hash, seq.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PulledChangeLogEntry')
          ..add('entityType', entityType)
          ..add('entityId', entityId)
          ..add('operation', operation)
          ..add('payload', payload)
          ..add('hlc', hlc)
          ..add('deviceId', deviceId)
          ..add('seq', seq))
        .toString();
  }
}

class PulledChangeLogEntryBuilder
    implements Builder<PulledChangeLogEntry, PulledChangeLogEntryBuilder> {
  _$PulledChangeLogEntry? _$v;

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

  int? _seq;
  int? get seq => _$this._seq;
  set seq(int? seq) => _$this._seq = seq;

  PulledChangeLogEntryBuilder() {
    PulledChangeLogEntry._defaults(this);
  }

  PulledChangeLogEntryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _entityType = $v.entityType;
      _entityId = $v.entityId;
      _operation = $v.operation;
      _payload = $v.payload.toBuilder();
      _hlc = $v.hlc;
      _deviceId = $v.deviceId;
      _seq = $v.seq;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PulledChangeLogEntry other) {
    _$v = other as _$PulledChangeLogEntry;
  }

  @override
  void update(void Function(PulledChangeLogEntryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PulledChangeLogEntry build() => _build();

  _$PulledChangeLogEntry _build() {
    _$PulledChangeLogEntry _$result;
    try {
      _$result =
          _$v ??
          _$PulledChangeLogEntry._(
            entityType: BuiltValueNullFieldError.checkNotNull(
              entityType,
              r'PulledChangeLogEntry',
              'entityType',
            ),
            entityId: BuiltValueNullFieldError.checkNotNull(
              entityId,
              r'PulledChangeLogEntry',
              'entityId',
            ),
            operation: BuiltValueNullFieldError.checkNotNull(
              operation,
              r'PulledChangeLogEntry',
              'operation',
            ),
            payload: payload.build(),
            hlc: BuiltValueNullFieldError.checkNotNull(
              hlc,
              r'PulledChangeLogEntry',
              'hlc',
            ),
            deviceId: BuiltValueNullFieldError.checkNotNull(
              deviceId,
              r'PulledChangeLogEntry',
              'deviceId',
            ),
            seq: BuiltValueNullFieldError.checkNotNull(
              seq,
              r'PulledChangeLogEntry',
              'seq',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'payload';
        payload.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'PulledChangeLogEntry',
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
