// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_liability.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreditLiability extends CreditLiability {
  @override
  final String accountId;
  @override
  final DataSource source_;
  @override
  final BuiltList<Apr> aprs;
  @override
  final bool? isOverdue;
  @override
  final Money? lastPaymentAmount;
  @override
  final Date? lastPaymentDate;
  @override
  final Date? lastStatementIssueDate;
  @override
  final Money? lastStatementBalance;
  @override
  final Money? minimumPaymentAmount;
  @override
  final Date? nextPaymentDueDate;

  factory _$CreditLiability([void Function(CreditLiabilityBuilder)? updates]) =>
      (CreditLiabilityBuilder()..update(updates))._build();

  _$CreditLiability._({
    required this.accountId,
    required this.source_,
    required this.aprs,
    this.isOverdue,
    this.lastPaymentAmount,
    this.lastPaymentDate,
    this.lastStatementIssueDate,
    this.lastStatementBalance,
    this.minimumPaymentAmount,
    this.nextPaymentDueDate,
  }) : super._();
  @override
  CreditLiability rebuild(void Function(CreditLiabilityBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreditLiabilityBuilder toBuilder() => CreditLiabilityBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreditLiability &&
        accountId == other.accountId &&
        source_ == other.source_ &&
        aprs == other.aprs &&
        isOverdue == other.isOverdue &&
        lastPaymentAmount == other.lastPaymentAmount &&
        lastPaymentDate == other.lastPaymentDate &&
        lastStatementIssueDate == other.lastStatementIssueDate &&
        lastStatementBalance == other.lastStatementBalance &&
        minimumPaymentAmount == other.minimumPaymentAmount &&
        nextPaymentDueDate == other.nextPaymentDueDate;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accountId.hashCode);
    _$hash = $jc(_$hash, source_.hashCode);
    _$hash = $jc(_$hash, aprs.hashCode);
    _$hash = $jc(_$hash, isOverdue.hashCode);
    _$hash = $jc(_$hash, lastPaymentAmount.hashCode);
    _$hash = $jc(_$hash, lastPaymentDate.hashCode);
    _$hash = $jc(_$hash, lastStatementIssueDate.hashCode);
    _$hash = $jc(_$hash, lastStatementBalance.hashCode);
    _$hash = $jc(_$hash, minimumPaymentAmount.hashCode);
    _$hash = $jc(_$hash, nextPaymentDueDate.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreditLiability')
          ..add('accountId', accountId)
          ..add('source_', source_)
          ..add('aprs', aprs)
          ..add('isOverdue', isOverdue)
          ..add('lastPaymentAmount', lastPaymentAmount)
          ..add('lastPaymentDate', lastPaymentDate)
          ..add('lastStatementIssueDate', lastStatementIssueDate)
          ..add('lastStatementBalance', lastStatementBalance)
          ..add('minimumPaymentAmount', minimumPaymentAmount)
          ..add('nextPaymentDueDate', nextPaymentDueDate))
        .toString();
  }
}

class CreditLiabilityBuilder
    implements Builder<CreditLiability, CreditLiabilityBuilder> {
  _$CreditLiability? _$v;

  String? _accountId;
  String? get accountId => _$this._accountId;
  set accountId(String? accountId) => _$this._accountId = accountId;

  DataSource? _source_;
  DataSource? get source_ => _$this._source_;
  set source_(DataSource? source_) => _$this._source_ = source_;

  ListBuilder<Apr>? _aprs;
  ListBuilder<Apr> get aprs => _$this._aprs ??= ListBuilder<Apr>();
  set aprs(ListBuilder<Apr>? aprs) => _$this._aprs = aprs;

  bool? _isOverdue;
  bool? get isOverdue => _$this._isOverdue;
  set isOverdue(bool? isOverdue) => _$this._isOverdue = isOverdue;

  MoneyBuilder? _lastPaymentAmount;
  MoneyBuilder get lastPaymentAmount =>
      _$this._lastPaymentAmount ??= MoneyBuilder();
  set lastPaymentAmount(MoneyBuilder? lastPaymentAmount) =>
      _$this._lastPaymentAmount = lastPaymentAmount;

  Date? _lastPaymentDate;
  Date? get lastPaymentDate => _$this._lastPaymentDate;
  set lastPaymentDate(Date? lastPaymentDate) =>
      _$this._lastPaymentDate = lastPaymentDate;

  Date? _lastStatementIssueDate;
  Date? get lastStatementIssueDate => _$this._lastStatementIssueDate;
  set lastStatementIssueDate(Date? lastStatementIssueDate) =>
      _$this._lastStatementIssueDate = lastStatementIssueDate;

  MoneyBuilder? _lastStatementBalance;
  MoneyBuilder get lastStatementBalance =>
      _$this._lastStatementBalance ??= MoneyBuilder();
  set lastStatementBalance(MoneyBuilder? lastStatementBalance) =>
      _$this._lastStatementBalance = lastStatementBalance;

  MoneyBuilder? _minimumPaymentAmount;
  MoneyBuilder get minimumPaymentAmount =>
      _$this._minimumPaymentAmount ??= MoneyBuilder();
  set minimumPaymentAmount(MoneyBuilder? minimumPaymentAmount) =>
      _$this._minimumPaymentAmount = minimumPaymentAmount;

  Date? _nextPaymentDueDate;
  Date? get nextPaymentDueDate => _$this._nextPaymentDueDate;
  set nextPaymentDueDate(Date? nextPaymentDueDate) =>
      _$this._nextPaymentDueDate = nextPaymentDueDate;

  CreditLiabilityBuilder() {
    CreditLiability._defaults(this);
  }

  CreditLiabilityBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accountId = $v.accountId;
      _source_ = $v.source_;
      _aprs = $v.aprs.toBuilder();
      _isOverdue = $v.isOverdue;
      _lastPaymentAmount = $v.lastPaymentAmount?.toBuilder();
      _lastPaymentDate = $v.lastPaymentDate;
      _lastStatementIssueDate = $v.lastStatementIssueDate;
      _lastStatementBalance = $v.lastStatementBalance?.toBuilder();
      _minimumPaymentAmount = $v.minimumPaymentAmount?.toBuilder();
      _nextPaymentDueDate = $v.nextPaymentDueDate;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreditLiability other) {
    _$v = other as _$CreditLiability;
  }

  @override
  void update(void Function(CreditLiabilityBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreditLiability build() => _build();

  _$CreditLiability _build() {
    _$CreditLiability _$result;
    try {
      _$result =
          _$v ??
          _$CreditLiability._(
            accountId: BuiltValueNullFieldError.checkNotNull(
              accountId,
              r'CreditLiability',
              'accountId',
            ),
            source_: BuiltValueNullFieldError.checkNotNull(
              source_,
              r'CreditLiability',
              'source_',
            ),
            aprs: aprs.build(),
            isOverdue: isOverdue,
            lastPaymentAmount: _lastPaymentAmount?.build(),
            lastPaymentDate: lastPaymentDate,
            lastStatementIssueDate: lastStatementIssueDate,
            lastStatementBalance: _lastStatementBalance?.build(),
            minimumPaymentAmount: _minimumPaymentAmount?.build(),
            nextPaymentDueDate: nextPaymentDueDate,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'aprs';
        aprs.build();

        _$failedField = 'lastPaymentAmount';
        _lastPaymentAmount?.build();

        _$failedField = 'lastStatementBalance';
        _lastStatementBalance?.build();
        _$failedField = 'minimumPaymentAmount';
        _minimumPaymentAmount?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'CreditLiability',
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
