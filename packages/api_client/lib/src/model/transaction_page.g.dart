// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$TransactionPage extends TransactionPage {
  @override
  final BuiltList<Transaction> transactions;
  @override
  final int nextSince;
  @override
  final bool hasMore;

  factory _$TransactionPage([void Function(TransactionPageBuilder)? updates]) =>
      (TransactionPageBuilder()..update(updates))._build();

  _$TransactionPage._({
    required this.transactions,
    required this.nextSince,
    required this.hasMore,
  }) : super._();
  @override
  TransactionPage rebuild(void Function(TransactionPageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TransactionPageBuilder toBuilder() => TransactionPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TransactionPage &&
        transactions == other.transactions &&
        nextSince == other.nextSince &&
        hasMore == other.hasMore;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, transactions.hashCode);
    _$hash = $jc(_$hash, nextSince.hashCode);
    _$hash = $jc(_$hash, hasMore.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TransactionPage')
          ..add('transactions', transactions)
          ..add('nextSince', nextSince)
          ..add('hasMore', hasMore))
        .toString();
  }
}

class TransactionPageBuilder
    implements Builder<TransactionPage, TransactionPageBuilder> {
  _$TransactionPage? _$v;

  ListBuilder<Transaction>? _transactions;
  ListBuilder<Transaction> get transactions =>
      _$this._transactions ??= ListBuilder<Transaction>();
  set transactions(ListBuilder<Transaction>? transactions) =>
      _$this._transactions = transactions;

  int? _nextSince;
  int? get nextSince => _$this._nextSince;
  set nextSince(int? nextSince) => _$this._nextSince = nextSince;

  bool? _hasMore;
  bool? get hasMore => _$this._hasMore;
  set hasMore(bool? hasMore) => _$this._hasMore = hasMore;

  TransactionPageBuilder() {
    TransactionPage._defaults(this);
  }

  TransactionPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _transactions = $v.transactions.toBuilder();
      _nextSince = $v.nextSince;
      _hasMore = $v.hasMore;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TransactionPage other) {
    _$v = other as _$TransactionPage;
  }

  @override
  void update(void Function(TransactionPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TransactionPage build() => _build();

  _$TransactionPage _build() {
    _$TransactionPage _$result;
    try {
      _$result =
          _$v ??
          _$TransactionPage._(
            transactions: transactions.build(),
            nextSince: BuiltValueNullFieldError.checkNotNull(
              nextSince,
              r'TransactionPage',
              'nextSince',
            ),
            hasMore: BuiltValueNullFieldError.checkNotNull(
              hasMore,
              r'TransactionPage',
              'hasMore',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'transactions';
        transactions.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'TransactionPage',
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
