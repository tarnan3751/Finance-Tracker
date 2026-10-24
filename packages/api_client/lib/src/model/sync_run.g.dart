// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_run.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SyncRun extends SyncRun {
  @override
  final SyncRunStatus status;
  @override
  final int added;
  @override
  final int modified;
  @override
  final int removed;
  @override
  final bool nextCursorSaved;

  factory _$SyncRun([void Function(SyncRunBuilder)? updates]) =>
      (SyncRunBuilder()..update(updates))._build();

  _$SyncRun._({
    required this.status,
    required this.added,
    required this.modified,
    required this.removed,
    required this.nextCursorSaved,
  }) : super._();
  @override
  SyncRun rebuild(void Function(SyncRunBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SyncRunBuilder toBuilder() => SyncRunBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SyncRun &&
        status == other.status &&
        added == other.added &&
        modified == other.modified &&
        removed == other.removed &&
        nextCursorSaved == other.nextCursorSaved;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, added.hashCode);
    _$hash = $jc(_$hash, modified.hashCode);
    _$hash = $jc(_$hash, removed.hashCode);
    _$hash = $jc(_$hash, nextCursorSaved.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SyncRun')
          ..add('status', status)
          ..add('added', added)
          ..add('modified', modified)
          ..add('removed', removed)
          ..add('nextCursorSaved', nextCursorSaved))
        .toString();
  }
}

class SyncRunBuilder implements Builder<SyncRun, SyncRunBuilder> {
  _$SyncRun? _$v;

  SyncRunStatus? _status;
  SyncRunStatus? get status => _$this._status;
  set status(SyncRunStatus? status) => _$this._status = status;

  int? _added;
  int? get added => _$this._added;
  set added(int? added) => _$this._added = added;

  int? _modified;
  int? get modified => _$this._modified;
  set modified(int? modified) => _$this._modified = modified;

  int? _removed;
  int? get removed => _$this._removed;
  set removed(int? removed) => _$this._removed = removed;

  bool? _nextCursorSaved;
  bool? get nextCursorSaved => _$this._nextCursorSaved;
  set nextCursorSaved(bool? nextCursorSaved) =>
      _$this._nextCursorSaved = nextCursorSaved;

  SyncRunBuilder() {
    SyncRun._defaults(this);
  }

  SyncRunBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _added = $v.added;
      _modified = $v.modified;
      _removed = $v.removed;
      _nextCursorSaved = $v.nextCursorSaved;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SyncRun other) {
    _$v = other as _$SyncRun;
  }

  @override
  void update(void Function(SyncRunBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SyncRun build() => _build();

  _$SyncRun _build() {
    final _$result =
        _$v ??
        _$SyncRun._(
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'SyncRun',
            'status',
          ),
          added: BuiltValueNullFieldError.checkNotNull(
            added,
            r'SyncRun',
            'added',
          ),
          modified: BuiltValueNullFieldError.checkNotNull(
            modified,
            r'SyncRun',
            'modified',
          ),
          removed: BuiltValueNullFieldError.checkNotNull(
            removed,
            r'SyncRun',
            'removed',
          ),
          nextCursorSaved: BuiltValueNullFieldError.checkNotNull(
            nextCursorSaved,
            r'SyncRun',
            'nextCursorSaved',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
