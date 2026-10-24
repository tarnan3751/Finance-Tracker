// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provision_job.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProvisionJob extends ProvisionJob {
  @override
  final String id;
  @override
  final ProvisionPersona persona;
  @override
  final int seed;
  @override
  final ProvisionJobStatus status;
  @override
  final DateTime createdAt;
  @override
  final DateTime? finishedAt;
  @override
  final ProvisionProgress progress;
  @override
  final String? error;
  @override
  final BuiltList<String> itemIds;

  factory _$ProvisionJob([void Function(ProvisionJobBuilder)? updates]) =>
      (ProvisionJobBuilder()..update(updates))._build();

  _$ProvisionJob._({
    required this.id,
    required this.persona,
    required this.seed,
    required this.status,
    required this.createdAt,
    this.finishedAt,
    required this.progress,
    this.error,
    required this.itemIds,
  }) : super._();
  @override
  ProvisionJob rebuild(void Function(ProvisionJobBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProvisionJobBuilder toBuilder() => ProvisionJobBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProvisionJob &&
        id == other.id &&
        persona == other.persona &&
        seed == other.seed &&
        status == other.status &&
        createdAt == other.createdAt &&
        finishedAt == other.finishedAt &&
        progress == other.progress &&
        error == other.error &&
        itemIds == other.itemIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, persona.hashCode);
    _$hash = $jc(_$hash, seed.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, finishedAt.hashCode);
    _$hash = $jc(_$hash, progress.hashCode);
    _$hash = $jc(_$hash, error.hashCode);
    _$hash = $jc(_$hash, itemIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProvisionJob')
          ..add('id', id)
          ..add('persona', persona)
          ..add('seed', seed)
          ..add('status', status)
          ..add('createdAt', createdAt)
          ..add('finishedAt', finishedAt)
          ..add('progress', progress)
          ..add('error', error)
          ..add('itemIds', itemIds))
        .toString();
  }
}

class ProvisionJobBuilder
    implements Builder<ProvisionJob, ProvisionJobBuilder> {
  _$ProvisionJob? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  ProvisionPersona? _persona;
  ProvisionPersona? get persona => _$this._persona;
  set persona(ProvisionPersona? persona) => _$this._persona = persona;

  int? _seed;
  int? get seed => _$this._seed;
  set seed(int? seed) => _$this._seed = seed;

  ProvisionJobStatus? _status;
  ProvisionJobStatus? get status => _$this._status;
  set status(ProvisionJobStatus? status) => _$this._status = status;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _finishedAt;
  DateTime? get finishedAt => _$this._finishedAt;
  set finishedAt(DateTime? finishedAt) => _$this._finishedAt = finishedAt;

  ProvisionProgressBuilder? _progress;
  ProvisionProgressBuilder get progress =>
      _$this._progress ??= ProvisionProgressBuilder();
  set progress(ProvisionProgressBuilder? progress) =>
      _$this._progress = progress;

  String? _error;
  String? get error => _$this._error;
  set error(String? error) => _$this._error = error;

  ListBuilder<String>? _itemIds;
  ListBuilder<String> get itemIds => _$this._itemIds ??= ListBuilder<String>();
  set itemIds(ListBuilder<String>? itemIds) => _$this._itemIds = itemIds;

  ProvisionJobBuilder() {
    ProvisionJob._defaults(this);
  }

  ProvisionJobBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _persona = $v.persona;
      _seed = $v.seed;
      _status = $v.status;
      _createdAt = $v.createdAt;
      _finishedAt = $v.finishedAt;
      _progress = $v.progress.toBuilder();
      _error = $v.error;
      _itemIds = $v.itemIds.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProvisionJob other) {
    _$v = other as _$ProvisionJob;
  }

  @override
  void update(void Function(ProvisionJobBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProvisionJob build() => _build();

  _$ProvisionJob _build() {
    _$ProvisionJob _$result;
    try {
      _$result =
          _$v ??
          _$ProvisionJob._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'ProvisionJob',
              'id',
            ),
            persona: BuiltValueNullFieldError.checkNotNull(
              persona,
              r'ProvisionJob',
              'persona',
            ),
            seed: BuiltValueNullFieldError.checkNotNull(
              seed,
              r'ProvisionJob',
              'seed',
            ),
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'ProvisionJob',
              'status',
            ),
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'ProvisionJob',
              'createdAt',
            ),
            finishedAt: finishedAt,
            progress: progress.build(),
            error: error,
            itemIds: itemIds.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'progress';
        progress.build();

        _$failedField = 'itemIds';
        itemIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ProvisionJob',
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
