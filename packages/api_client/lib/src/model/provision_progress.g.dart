// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provision_progress.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProvisionProgress extends ProvisionProgress {
  @override
  final int itemsTotal;
  @override
  final int itemsLinked;
  @override
  final int batchesTotal;
  @override
  final int batchesSent;
  @override
  final int skipped;

  factory _$ProvisionProgress([
    void Function(ProvisionProgressBuilder)? updates,
  ]) => (ProvisionProgressBuilder()..update(updates))._build();

  _$ProvisionProgress._({
    required this.itemsTotal,
    required this.itemsLinked,
    required this.batchesTotal,
    required this.batchesSent,
    required this.skipped,
  }) : super._();
  @override
  ProvisionProgress rebuild(void Function(ProvisionProgressBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProvisionProgressBuilder toBuilder() =>
      ProvisionProgressBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProvisionProgress &&
        itemsTotal == other.itemsTotal &&
        itemsLinked == other.itemsLinked &&
        batchesTotal == other.batchesTotal &&
        batchesSent == other.batchesSent &&
        skipped == other.skipped;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, itemsTotal.hashCode);
    _$hash = $jc(_$hash, itemsLinked.hashCode);
    _$hash = $jc(_$hash, batchesTotal.hashCode);
    _$hash = $jc(_$hash, batchesSent.hashCode);
    _$hash = $jc(_$hash, skipped.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProvisionProgress')
          ..add('itemsTotal', itemsTotal)
          ..add('itemsLinked', itemsLinked)
          ..add('batchesTotal', batchesTotal)
          ..add('batchesSent', batchesSent)
          ..add('skipped', skipped))
        .toString();
  }
}

class ProvisionProgressBuilder
    implements Builder<ProvisionProgress, ProvisionProgressBuilder> {
  _$ProvisionProgress? _$v;

  int? _itemsTotal;
  int? get itemsTotal => _$this._itemsTotal;
  set itemsTotal(int? itemsTotal) => _$this._itemsTotal = itemsTotal;

  int? _itemsLinked;
  int? get itemsLinked => _$this._itemsLinked;
  set itemsLinked(int? itemsLinked) => _$this._itemsLinked = itemsLinked;

  int? _batchesTotal;
  int? get batchesTotal => _$this._batchesTotal;
  set batchesTotal(int? batchesTotal) => _$this._batchesTotal = batchesTotal;

  int? _batchesSent;
  int? get batchesSent => _$this._batchesSent;
  set batchesSent(int? batchesSent) => _$this._batchesSent = batchesSent;

  int? _skipped;
  int? get skipped => _$this._skipped;
  set skipped(int? skipped) => _$this._skipped = skipped;

  ProvisionProgressBuilder() {
    ProvisionProgress._defaults(this);
  }

  ProvisionProgressBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _itemsTotal = $v.itemsTotal;
      _itemsLinked = $v.itemsLinked;
      _batchesTotal = $v.batchesTotal;
      _batchesSent = $v.batchesSent;
      _skipped = $v.skipped;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProvisionProgress other) {
    _$v = other as _$ProvisionProgress;
  }

  @override
  void update(void Function(ProvisionProgressBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProvisionProgress build() => _build();

  _$ProvisionProgress _build() {
    final _$result =
        _$v ??
        _$ProvisionProgress._(
          itemsTotal: BuiltValueNullFieldError.checkNotNull(
            itemsTotal,
            r'ProvisionProgress',
            'itemsTotal',
          ),
          itemsLinked: BuiltValueNullFieldError.checkNotNull(
            itemsLinked,
            r'ProvisionProgress',
            'itemsLinked',
          ),
          batchesTotal: BuiltValueNullFieldError.checkNotNull(
            batchesTotal,
            r'ProvisionProgress',
            'batchesTotal',
          ),
          batchesSent: BuiltValueNullFieldError.checkNotNull(
            batchesSent,
            r'ProvisionProgress',
            'batchesSent',
          ),
          skipped: BuiltValueNullFieldError.checkNotNull(
            skipped,
            r'ProvisionProgress',
            'skipped',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
