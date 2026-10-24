// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_loan_liability.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$StudentLoanLiability extends StudentLoanLiability {
  @override
  final String accountId;
  @override
  final String? loanName;
  @override
  final String? guarantor;
  @override
  final String interestRatePercentage;
  @override
  final bool? isOverdue;
  @override
  final Date? expectedPayoffDate;
  @override
  final Money? lastPaymentAmount;
  @override
  final Date? lastPaymentDate;
  @override
  final Money? lastStatementBalance;
  @override
  final Date? lastStatementIssueDate;
  @override
  final Money? minimumPaymentAmount;
  @override
  final Date? nextPaymentDueDate;
  @override
  final Date? originationDate;
  @override
  final Money? originationPrincipalAmount;
  @override
  final Money? outstandingInterestAmount;
  @override
  final String? loanStatusType;
  @override
  final String? repaymentPlanType;
  @override
  final Money? ytdInterestPaid;
  @override
  final Money? ytdPrincipalPaid;

  factory _$StudentLoanLiability([
    void Function(StudentLoanLiabilityBuilder)? updates,
  ]) => (StudentLoanLiabilityBuilder()..update(updates))._build();

  _$StudentLoanLiability._({
    required this.accountId,
    this.loanName,
    this.guarantor,
    required this.interestRatePercentage,
    this.isOverdue,
    this.expectedPayoffDate,
    this.lastPaymentAmount,
    this.lastPaymentDate,
    this.lastStatementBalance,
    this.lastStatementIssueDate,
    this.minimumPaymentAmount,
    this.nextPaymentDueDate,
    this.originationDate,
    this.originationPrincipalAmount,
    this.outstandingInterestAmount,
    this.loanStatusType,
    this.repaymentPlanType,
    this.ytdInterestPaid,
    this.ytdPrincipalPaid,
  }) : super._();
  @override
  StudentLoanLiability rebuild(
    void Function(StudentLoanLiabilityBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  StudentLoanLiabilityBuilder toBuilder() =>
      StudentLoanLiabilityBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is StudentLoanLiability &&
        accountId == other.accountId &&
        loanName == other.loanName &&
        guarantor == other.guarantor &&
        interestRatePercentage == other.interestRatePercentage &&
        isOverdue == other.isOverdue &&
        expectedPayoffDate == other.expectedPayoffDate &&
        lastPaymentAmount == other.lastPaymentAmount &&
        lastPaymentDate == other.lastPaymentDate &&
        lastStatementBalance == other.lastStatementBalance &&
        lastStatementIssueDate == other.lastStatementIssueDate &&
        minimumPaymentAmount == other.minimumPaymentAmount &&
        nextPaymentDueDate == other.nextPaymentDueDate &&
        originationDate == other.originationDate &&
        originationPrincipalAmount == other.originationPrincipalAmount &&
        outstandingInterestAmount == other.outstandingInterestAmount &&
        loanStatusType == other.loanStatusType &&
        repaymentPlanType == other.repaymentPlanType &&
        ytdInterestPaid == other.ytdInterestPaid &&
        ytdPrincipalPaid == other.ytdPrincipalPaid;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accountId.hashCode);
    _$hash = $jc(_$hash, loanName.hashCode);
    _$hash = $jc(_$hash, guarantor.hashCode);
    _$hash = $jc(_$hash, interestRatePercentage.hashCode);
    _$hash = $jc(_$hash, isOverdue.hashCode);
    _$hash = $jc(_$hash, expectedPayoffDate.hashCode);
    _$hash = $jc(_$hash, lastPaymentAmount.hashCode);
    _$hash = $jc(_$hash, lastPaymentDate.hashCode);
    _$hash = $jc(_$hash, lastStatementBalance.hashCode);
    _$hash = $jc(_$hash, lastStatementIssueDate.hashCode);
    _$hash = $jc(_$hash, minimumPaymentAmount.hashCode);
    _$hash = $jc(_$hash, nextPaymentDueDate.hashCode);
    _$hash = $jc(_$hash, originationDate.hashCode);
    _$hash = $jc(_$hash, originationPrincipalAmount.hashCode);
    _$hash = $jc(_$hash, outstandingInterestAmount.hashCode);
    _$hash = $jc(_$hash, loanStatusType.hashCode);
    _$hash = $jc(_$hash, repaymentPlanType.hashCode);
    _$hash = $jc(_$hash, ytdInterestPaid.hashCode);
    _$hash = $jc(_$hash, ytdPrincipalPaid.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'StudentLoanLiability')
          ..add('accountId', accountId)
          ..add('loanName', loanName)
          ..add('guarantor', guarantor)
          ..add('interestRatePercentage', interestRatePercentage)
          ..add('isOverdue', isOverdue)
          ..add('expectedPayoffDate', expectedPayoffDate)
          ..add('lastPaymentAmount', lastPaymentAmount)
          ..add('lastPaymentDate', lastPaymentDate)
          ..add('lastStatementBalance', lastStatementBalance)
          ..add('lastStatementIssueDate', lastStatementIssueDate)
          ..add('minimumPaymentAmount', minimumPaymentAmount)
          ..add('nextPaymentDueDate', nextPaymentDueDate)
          ..add('originationDate', originationDate)
          ..add('originationPrincipalAmount', originationPrincipalAmount)
          ..add('outstandingInterestAmount', outstandingInterestAmount)
          ..add('loanStatusType', loanStatusType)
          ..add('repaymentPlanType', repaymentPlanType)
          ..add('ytdInterestPaid', ytdInterestPaid)
          ..add('ytdPrincipalPaid', ytdPrincipalPaid))
        .toString();
  }
}

class StudentLoanLiabilityBuilder
    implements Builder<StudentLoanLiability, StudentLoanLiabilityBuilder> {
  _$StudentLoanLiability? _$v;

  String? _accountId;
  String? get accountId => _$this._accountId;
  set accountId(String? accountId) => _$this._accountId = accountId;

  String? _loanName;
  String? get loanName => _$this._loanName;
  set loanName(String? loanName) => _$this._loanName = loanName;

  String? _guarantor;
  String? get guarantor => _$this._guarantor;
  set guarantor(String? guarantor) => _$this._guarantor = guarantor;

  String? _interestRatePercentage;
  String? get interestRatePercentage => _$this._interestRatePercentage;
  set interestRatePercentage(String? interestRatePercentage) =>
      _$this._interestRatePercentage = interestRatePercentage;

  bool? _isOverdue;
  bool? get isOverdue => _$this._isOverdue;
  set isOverdue(bool? isOverdue) => _$this._isOverdue = isOverdue;

  Date? _expectedPayoffDate;
  Date? get expectedPayoffDate => _$this._expectedPayoffDate;
  set expectedPayoffDate(Date? expectedPayoffDate) =>
      _$this._expectedPayoffDate = expectedPayoffDate;

  MoneyBuilder? _lastPaymentAmount;
  MoneyBuilder get lastPaymentAmount =>
      _$this._lastPaymentAmount ??= MoneyBuilder();
  set lastPaymentAmount(MoneyBuilder? lastPaymentAmount) =>
      _$this._lastPaymentAmount = lastPaymentAmount;

  Date? _lastPaymentDate;
  Date? get lastPaymentDate => _$this._lastPaymentDate;
  set lastPaymentDate(Date? lastPaymentDate) =>
      _$this._lastPaymentDate = lastPaymentDate;

  MoneyBuilder? _lastStatementBalance;
  MoneyBuilder get lastStatementBalance =>
      _$this._lastStatementBalance ??= MoneyBuilder();
  set lastStatementBalance(MoneyBuilder? lastStatementBalance) =>
      _$this._lastStatementBalance = lastStatementBalance;

  Date? _lastStatementIssueDate;
  Date? get lastStatementIssueDate => _$this._lastStatementIssueDate;
  set lastStatementIssueDate(Date? lastStatementIssueDate) =>
      _$this._lastStatementIssueDate = lastStatementIssueDate;

  MoneyBuilder? _minimumPaymentAmount;
  MoneyBuilder get minimumPaymentAmount =>
      _$this._minimumPaymentAmount ??= MoneyBuilder();
  set minimumPaymentAmount(MoneyBuilder? minimumPaymentAmount) =>
      _$this._minimumPaymentAmount = minimumPaymentAmount;

  Date? _nextPaymentDueDate;
  Date? get nextPaymentDueDate => _$this._nextPaymentDueDate;
  set nextPaymentDueDate(Date? nextPaymentDueDate) =>
      _$this._nextPaymentDueDate = nextPaymentDueDate;

  Date? _originationDate;
  Date? get originationDate => _$this._originationDate;
  set originationDate(Date? originationDate) =>
      _$this._originationDate = originationDate;

  MoneyBuilder? _originationPrincipalAmount;
  MoneyBuilder get originationPrincipalAmount =>
      _$this._originationPrincipalAmount ??= MoneyBuilder();
  set originationPrincipalAmount(MoneyBuilder? originationPrincipalAmount) =>
      _$this._originationPrincipalAmount = originationPrincipalAmount;

  MoneyBuilder? _outstandingInterestAmount;
  MoneyBuilder get outstandingInterestAmount =>
      _$this._outstandingInterestAmount ??= MoneyBuilder();
  set outstandingInterestAmount(MoneyBuilder? outstandingInterestAmount) =>
      _$this._outstandingInterestAmount = outstandingInterestAmount;

  String? _loanStatusType;
  String? get loanStatusType => _$this._loanStatusType;
  set loanStatusType(String? loanStatusType) =>
      _$this._loanStatusType = loanStatusType;

  String? _repaymentPlanType;
  String? get repaymentPlanType => _$this._repaymentPlanType;
  set repaymentPlanType(String? repaymentPlanType) =>
      _$this._repaymentPlanType = repaymentPlanType;

  MoneyBuilder? _ytdInterestPaid;
  MoneyBuilder get ytdInterestPaid =>
      _$this._ytdInterestPaid ??= MoneyBuilder();
  set ytdInterestPaid(MoneyBuilder? ytdInterestPaid) =>
      _$this._ytdInterestPaid = ytdInterestPaid;

  MoneyBuilder? _ytdPrincipalPaid;
  MoneyBuilder get ytdPrincipalPaid =>
      _$this._ytdPrincipalPaid ??= MoneyBuilder();
  set ytdPrincipalPaid(MoneyBuilder? ytdPrincipalPaid) =>
      _$this._ytdPrincipalPaid = ytdPrincipalPaid;

  StudentLoanLiabilityBuilder() {
    StudentLoanLiability._defaults(this);
  }

  StudentLoanLiabilityBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accountId = $v.accountId;
      _loanName = $v.loanName;
      _guarantor = $v.guarantor;
      _interestRatePercentage = $v.interestRatePercentage;
      _isOverdue = $v.isOverdue;
      _expectedPayoffDate = $v.expectedPayoffDate;
      _lastPaymentAmount = $v.lastPaymentAmount?.toBuilder();
      _lastPaymentDate = $v.lastPaymentDate;
      _lastStatementBalance = $v.lastStatementBalance?.toBuilder();
      _lastStatementIssueDate = $v.lastStatementIssueDate;
      _minimumPaymentAmount = $v.minimumPaymentAmount?.toBuilder();
      _nextPaymentDueDate = $v.nextPaymentDueDate;
      _originationDate = $v.originationDate;
      _originationPrincipalAmount = $v.originationPrincipalAmount?.toBuilder();
      _outstandingInterestAmount = $v.outstandingInterestAmount?.toBuilder();
      _loanStatusType = $v.loanStatusType;
      _repaymentPlanType = $v.repaymentPlanType;
      _ytdInterestPaid = $v.ytdInterestPaid?.toBuilder();
      _ytdPrincipalPaid = $v.ytdPrincipalPaid?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(StudentLoanLiability other) {
    _$v = other as _$StudentLoanLiability;
  }

  @override
  void update(void Function(StudentLoanLiabilityBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  StudentLoanLiability build() => _build();

  _$StudentLoanLiability _build() {
    _$StudentLoanLiability _$result;
    try {
      _$result =
          _$v ??
          _$StudentLoanLiability._(
            accountId: BuiltValueNullFieldError.checkNotNull(
              accountId,
              r'StudentLoanLiability',
              'accountId',
            ),
            loanName: loanName,
            guarantor: guarantor,
            interestRatePercentage: BuiltValueNullFieldError.checkNotNull(
              interestRatePercentage,
              r'StudentLoanLiability',
              'interestRatePercentage',
            ),
            isOverdue: isOverdue,
            expectedPayoffDate: expectedPayoffDate,
            lastPaymentAmount: _lastPaymentAmount?.build(),
            lastPaymentDate: lastPaymentDate,
            lastStatementBalance: _lastStatementBalance?.build(),
            lastStatementIssueDate: lastStatementIssueDate,
            minimumPaymentAmount: _minimumPaymentAmount?.build(),
            nextPaymentDueDate: nextPaymentDueDate,
            originationDate: originationDate,
            originationPrincipalAmount: _originationPrincipalAmount?.build(),
            outstandingInterestAmount: _outstandingInterestAmount?.build(),
            loanStatusType: loanStatusType,
            repaymentPlanType: repaymentPlanType,
            ytdInterestPaid: _ytdInterestPaid?.build(),
            ytdPrincipalPaid: _ytdPrincipalPaid?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'lastPaymentAmount';
        _lastPaymentAmount?.build();

        _$failedField = 'lastStatementBalance';
        _lastStatementBalance?.build();

        _$failedField = 'minimumPaymentAmount';
        _minimumPaymentAmount?.build();

        _$failedField = 'originationPrincipalAmount';
        _originationPrincipalAmount?.build();
        _$failedField = 'outstandingInterestAmount';
        _outstandingInterestAmount?.build();

        _$failedField = 'ytdInterestPaid';
        _ytdInterestPaid?.build();
        _$failedField = 'ytdPrincipalPaid';
        _ytdPrincipalPaid?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'StudentLoanLiability',
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
