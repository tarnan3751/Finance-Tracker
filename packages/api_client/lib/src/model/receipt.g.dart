// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Receipt extends Receipt {
  @override
  final String sha256;
  @override
  final int size;

  factory _$Receipt([void Function(ReceiptBuilder)? updates]) =>
      (ReceiptBuilder()..update(updates))._build();

  _$Receipt._({required this.sha256, required this.size}) : super._();
  @override
  Receipt rebuild(void Function(ReceiptBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReceiptBuilder toBuilder() => ReceiptBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Receipt && sha256 == other.sha256 && size == other.size;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, sha256.hashCode);
    _$hash = $jc(_$hash, size.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Receipt')
          ..add('sha256', sha256)
          ..add('size', size))
        .toString();
  }
}

class ReceiptBuilder implements Builder<Receipt, ReceiptBuilder> {
  _$Receipt? _$v;

  String? _sha256;
  String? get sha256 => _$this._sha256;
  set sha256(String? sha256) => _$this._sha256 = sha256;

  int? _size;
  int? get size => _$this._size;
  set size(int? size) => _$this._size = size;

  ReceiptBuilder() {
    Receipt._defaults(this);
  }

  ReceiptBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _sha256 = $v.sha256;
      _size = $v.size;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Receipt other) {
    _$v = other as _$Receipt;
  }

  @override
  void update(void Function(ReceiptBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Receipt build() => _build();

  _$Receipt _build() {
    final _$result =
        _$v ??
        _$Receipt._(
          sha256: BuiltValueNullFieldError.checkNotNull(
            sha256,
            r'Receipt',
            'sha256',
          ),
          size: BuiltValueNullFieldError.checkNotNull(size, r'Receipt', 'size'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
