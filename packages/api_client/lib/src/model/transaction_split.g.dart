// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_split.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TransactionSplit extends TransactionSplit {
  @override
  final String categoryId;
  @override
  final Money amount;
  @override
  final String? note;

  factory _$TransactionSplit([
    void Function(TransactionSplitBuilder)? updates,
  ]) => (TransactionSplitBuilder()..update(updates))._build();

  _$TransactionSplit._({
    required this.categoryId,
    required this.amount,
    this.note,
  }) : super._();
  @override
  TransactionSplit rebuild(void Function(TransactionSplitBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TransactionSplitBuilder toBuilder() =>
      TransactionSplitBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TransactionSplit &&
        categoryId == other.categoryId &&
        amount == other.amount &&
        note == other.note;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, categoryId.hashCode);
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jc(_$hash, note.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TransactionSplit')
          ..add('categoryId', categoryId)
          ..add('amount', amount)
          ..add('note', note))
        .toString();
  }
}

class TransactionSplitBuilder
    implements Builder<TransactionSplit, TransactionSplitBuilder> {
  _$TransactionSplit? _$v;

  String? _categoryId;
  String? get categoryId => _$this._categoryId;
  set categoryId(String? categoryId) => _$this._categoryId = categoryId;

  MoneyBuilder? _amount;
  MoneyBuilder get amount => _$this._amount ??= MoneyBuilder();
  set amount(MoneyBuilder? amount) => _$this._amount = amount;

  String? _note;
  String? get note => _$this._note;
  set note(String? note) => _$this._note = note;

  TransactionSplitBuilder() {
    TransactionSplit._defaults(this);
  }

  TransactionSplitBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _categoryId = $v.categoryId;
      _amount = $v.amount.toBuilder();
      _note = $v.note;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TransactionSplit other) {
    _$v = other as _$TransactionSplit;
  }

  @override
  void update(void Function(TransactionSplitBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TransactionSplit build() => _build();

  _$TransactionSplit _build() {
    _$TransactionSplit _$result;
    try {
      _$result =
          _$v ??
          _$TransactionSplit._(
            categoryId: BuiltValueNullFieldError.checkNotNull(
              categoryId,
              r'TransactionSplit',
              'categoryId',
            ),
            amount: amount.build(),
            note: note,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'amount';
        amount.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'TransactionSplit',
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
