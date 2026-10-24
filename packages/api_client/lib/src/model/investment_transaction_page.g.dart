// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_transaction_page.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$InvestmentTransactionPage extends InvestmentTransactionPage {
  @override
  final BuiltList<InvestmentTransaction> investmentTransactions;
  @override
  final int nextSince;
  @override
  final bool hasMore;

  factory _$InvestmentTransactionPage([
    void Function(InvestmentTransactionPageBuilder)? updates,
  ]) => (InvestmentTransactionPageBuilder()..update(updates))._build();

  _$InvestmentTransactionPage._({
    required this.investmentTransactions,
    required this.nextSince,
    required this.hasMore,
  }) : super._();
  @override
  InvestmentTransactionPage rebuild(
    void Function(InvestmentTransactionPageBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  InvestmentTransactionPageBuilder toBuilder() =>
      InvestmentTransactionPageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is InvestmentTransactionPage &&
        investmentTransactions == other.investmentTransactions &&
        nextSince == other.nextSince &&
        hasMore == other.hasMore;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, investmentTransactions.hashCode);
    _$hash = $jc(_$hash, nextSince.hashCode);
    _$hash = $jc(_$hash, hasMore.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'InvestmentTransactionPage')
          ..add('investmentTransactions', investmentTransactions)
          ..add('nextSince', nextSince)
          ..add('hasMore', hasMore))
        .toString();
  }
}

class InvestmentTransactionPageBuilder
    implements
        Builder<InvestmentTransactionPage, InvestmentTransactionPageBuilder> {
  _$InvestmentTransactionPage? _$v;

  ListBuilder<InvestmentTransaction>? _investmentTransactions;
  ListBuilder<InvestmentTransaction> get investmentTransactions =>
      _$this._investmentTransactions ??= ListBuilder<InvestmentTransaction>();
  set investmentTransactions(
    ListBuilder<InvestmentTransaction>? investmentTransactions,
  ) => _$this._investmentTransactions = investmentTransactions;

  int? _nextSince;
  int? get nextSince => _$this._nextSince;
  set nextSince(int? nextSince) => _$this._nextSince = nextSince;

  bool? _hasMore;
  bool? get hasMore => _$this._hasMore;
  set hasMore(bool? hasMore) => _$this._hasMore = hasMore;

  InvestmentTransactionPageBuilder() {
    InvestmentTransactionPage._defaults(this);
  }

  InvestmentTransactionPageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _investmentTransactions = $v.investmentTransactions.toBuilder();
      _nextSince = $v.nextSince;
      _hasMore = $v.hasMore;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(InvestmentTransactionPage other) {
    _$v = other as _$InvestmentTransactionPage;
  }

  @override
  void update(void Function(InvestmentTransactionPageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  InvestmentTransactionPage build() => _build();

  _$InvestmentTransactionPage _build() {
    _$InvestmentTransactionPage _$result;
    try {
      _$result =
          _$v ??
          _$InvestmentTransactionPage._(
            investmentTransactions: investmentTransactions.build(),
            nextSince: BuiltValueNullFieldError.checkNotNull(
              nextSince,
              r'InvestmentTransactionPage',
              'nextSince',
            ),
            hasMore: BuiltValueNullFieldError.checkNotNull(
              hasMore,
              r'InvestmentTransactionPage',
              'hasMore',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'investmentTransactions';
        investmentTransactions.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'InvestmentTransactionPage',
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
