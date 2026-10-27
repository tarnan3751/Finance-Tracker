// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mortgage_liability.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MortgageLiability extends MortgageLiability {
  @override
  final String accountId;
  @override
  final DataSource source_;
  @override
  final String? loanTypeDescription;
  @override
  final String? loanTerm;
  @override
  final String? interestRatePercentage;
  @override
  final String? interestRateType;
  @override
  final Money? currentLateFee;
  @override
  final Money? escrowBalance;
  @override
  final bool? hasPmi;
  @override
  final bool? hasPrepaymentPenalty;
  @override
  final Money? lastPaymentAmount;
  @override
  final Date? lastPaymentDate;
  @override
  final Date? maturityDate;
  @override
  final Money? nextMonthlyPayment;
  @override
  final Date? nextPaymentDueDate;
  @override
  final Date? originationDate;
  @override
  final Money? originationPrincipalAmount;
  @override
  final Money? pastDueAmount;
  @override
  final Money? ytdInterestPaid;
  @override
  final Money? ytdPrincipalPaid;

  factory _$MortgageLiability([
    void Function(MortgageLiabilityBuilder)? updates,
  ]) => (MortgageLiabilityBuilder()..update(updates))._build();

  _$MortgageLiability._({
    required this.accountId,
    required this.source_,
    this.loanTypeDescription,
    this.loanTerm,
    this.interestRatePercentage,
    this.interestRateType,
    this.currentLateFee,
    this.escrowBalance,
    this.hasPmi,
    this.hasPrepaymentPenalty,
    this.lastPaymentAmount,
    this.lastPaymentDate,
    this.maturityDate,
    this.nextMonthlyPayment,
    this.nextPaymentDueDate,
    this.originationDate,
    this.originationPrincipalAmount,
    this.pastDueAmount,
    this.ytdInterestPaid,
    this.ytdPrincipalPaid,
  }) : super._();
  @override
  MortgageLiability rebuild(void Function(MortgageLiabilityBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MortgageLiabilityBuilder toBuilder() =>
      MortgageLiabilityBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MortgageLiability &&
        accountId == other.accountId &&
        source_ == other.source_ &&
        loanTypeDescription == other.loanTypeDescription &&
        loanTerm == other.loanTerm &&
        interestRatePercentage == other.interestRatePercentage &&
        interestRateType == other.interestRateType &&
        currentLateFee == other.currentLateFee &&
        escrowBalance == other.escrowBalance &&
        hasPmi == other.hasPmi &&
        hasPrepaymentPenalty == other.hasPrepaymentPenalty &&
        lastPaymentAmount == other.lastPaymentAmount &&
        lastPaymentDate == other.lastPaymentDate &&
        maturityDate == other.maturityDate &&
        nextMonthlyPayment == other.nextMonthlyPayment &&
        nextPaymentDueDate == other.nextPaymentDueDate &&
        originationDate == other.originationDate &&
        originationPrincipalAmount == other.originationPrincipalAmount &&
        pastDueAmount == other.pastDueAmount &&
        ytdInterestPaid == other.ytdInterestPaid &&
        ytdPrincipalPaid == other.ytdPrincipalPaid;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accountId.hashCode);
    _$hash = $jc(_$hash, source_.hashCode);
    _$hash = $jc(_$hash, loanTypeDescription.hashCode);
    _$hash = $jc(_$hash, loanTerm.hashCode);
    _$hash = $jc(_$hash, interestRatePercentage.hashCode);
    _$hash = $jc(_$hash, interestRateType.hashCode);
    _$hash = $jc(_$hash, currentLateFee.hashCode);
    _$hash = $jc(_$hash, escrowBalance.hashCode);
    _$hash = $jc(_$hash, hasPmi.hashCode);
    _$hash = $jc(_$hash, hasPrepaymentPenalty.hashCode);
    _$hash = $jc(_$hash, lastPaymentAmount.hashCode);
    _$hash = $jc(_$hash, lastPaymentDate.hashCode);
    _$hash = $jc(_$hash, maturityDate.hashCode);
    _$hash = $jc(_$hash, nextMonthlyPayment.hashCode);
    _$hash = $jc(_$hash, nextPaymentDueDate.hashCode);
    _$hash = $jc(_$hash, originationDate.hashCode);
    _$hash = $jc(_$hash, originationPrincipalAmount.hashCode);
    _$hash = $jc(_$hash, pastDueAmount.hashCode);
    _$hash = $jc(_$hash, ytdInterestPaid.hashCode);
    _$hash = $jc(_$hash, ytdPrincipalPaid.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MortgageLiability')
          ..add('accountId', accountId)
          ..add('source_', source_)
          ..add('loanTypeDescription', loanTypeDescription)
          ..add('loanTerm', loanTerm)
          ..add('interestRatePercentage', interestRatePercentage)
          ..add('interestRateType', interestRateType)
          ..add('currentLateFee', currentLateFee)
          ..add('escrowBalance', escrowBalance)
          ..add('hasPmi', hasPmi)
          ..add('hasPrepaymentPenalty', hasPrepaymentPenalty)
          ..add('lastPaymentAmount', lastPaymentAmount)
          ..add('lastPaymentDate', lastPaymentDate)
          ..add('maturityDate', maturityDate)
          ..add('nextMonthlyPayment', nextMonthlyPayment)
          ..add('nextPaymentDueDate', nextPaymentDueDate)
          ..add('originationDate', originationDate)
          ..add('originationPrincipalAmount', originationPrincipalAmount)
          ..add('pastDueAmount', pastDueAmount)
          ..add('ytdInterestPaid', ytdInterestPaid)
          ..add('ytdPrincipalPaid', ytdPrincipalPaid))
        .toString();
  }
}

class MortgageLiabilityBuilder
    implements Builder<MortgageLiability, MortgageLiabilityBuilder> {
  _$MortgageLiability? _$v;

  String? _accountId;
  String? get accountId => _$this._accountId;
  set accountId(String? accountId) => _$this._accountId = accountId;

  DataSource? _source_;
  DataSource? get source_ => _$this._source_;
  set source_(DataSource? source_) => _$this._source_ = source_;

  String? _loanTypeDescription;
  String? get loanTypeDescription => _$this._loanTypeDescription;
  set loanTypeDescription(String? loanTypeDescription) =>
      _$this._loanTypeDescription = loanTypeDescription;

  String? _loanTerm;
  String? get loanTerm => _$this._loanTerm;
  set loanTerm(String? loanTerm) => _$this._loanTerm = loanTerm;

  String? _interestRatePercentage;
  String? get interestRatePercentage => _$this._interestRatePercentage;
  set interestRatePercentage(String? interestRatePercentage) =>
      _$this._interestRatePercentage = interestRatePercentage;

  String? _interestRateType;
  String? get interestRateType => _$this._interestRateType;
  set interestRateType(String? interestRateType) =>
      _$this._interestRateType = interestRateType;

  MoneyBuilder? _currentLateFee;
  MoneyBuilder get currentLateFee => _$this._currentLateFee ??= MoneyBuilder();
  set currentLateFee(MoneyBuilder? currentLateFee) =>
      _$this._currentLateFee = currentLateFee;

  MoneyBuilder? _escrowBalance;
  MoneyBuilder get escrowBalance => _$this._escrowBalance ??= MoneyBuilder();
  set escrowBalance(MoneyBuilder? escrowBalance) =>
      _$this._escrowBalance = escrowBalance;

  bool? _hasPmi;
  bool? get hasPmi => _$this._hasPmi;
  set hasPmi(bool? hasPmi) => _$this._hasPmi = hasPmi;

  bool? _hasPrepaymentPenalty;
  bool? get hasPrepaymentPenalty => _$this._hasPrepaymentPenalty;
  set hasPrepaymentPenalty(bool? hasPrepaymentPenalty) =>
      _$this._hasPrepaymentPenalty = hasPrepaymentPenalty;

  MoneyBuilder? _lastPaymentAmount;
  MoneyBuilder get lastPaymentAmount =>
      _$this._lastPaymentAmount ??= MoneyBuilder();
  set lastPaymentAmount(MoneyBuilder? lastPaymentAmount) =>
      _$this._lastPaymentAmount = lastPaymentAmount;

  Date? _lastPaymentDate;
  Date? get lastPaymentDate => _$this._lastPaymentDate;
  set lastPaymentDate(Date? lastPaymentDate) =>
      _$this._lastPaymentDate = lastPaymentDate;

  Date? _maturityDate;
  Date? get maturityDate => _$this._maturityDate;
  set maturityDate(Date? maturityDate) => _$this._maturityDate = maturityDate;

  MoneyBuilder? _nextMonthlyPayment;
  MoneyBuilder get nextMonthlyPayment =>
      _$this._nextMonthlyPayment ??= MoneyBuilder();
  set nextMonthlyPayment(MoneyBuilder? nextMonthlyPayment) =>
      _$this._nextMonthlyPayment = nextMonthlyPayment;

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

  MoneyBuilder? _pastDueAmount;
  MoneyBuilder get pastDueAmount => _$this._pastDueAmount ??= MoneyBuilder();
  set pastDueAmount(MoneyBuilder? pastDueAmount) =>
      _$this._pastDueAmount = pastDueAmount;

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

  MortgageLiabilityBuilder() {
    MortgageLiability._defaults(this);
  }

  MortgageLiabilityBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accountId = $v.accountId;
      _source_ = $v.source_;
      _loanTypeDescription = $v.loanTypeDescription;
      _loanTerm = $v.loanTerm;
      _interestRatePercentage = $v.interestRatePercentage;
      _interestRateType = $v.interestRateType;
      _currentLateFee = $v.currentLateFee?.toBuilder();
      _escrowBalance = $v.escrowBalance?.toBuilder();
      _hasPmi = $v.hasPmi;
      _hasPrepaymentPenalty = $v.hasPrepaymentPenalty;
      _lastPaymentAmount = $v.lastPaymentAmount?.toBuilder();
      _lastPaymentDate = $v.lastPaymentDate;
      _maturityDate = $v.maturityDate;
      _nextMonthlyPayment = $v.nextMonthlyPayment?.toBuilder();
      _nextPaymentDueDate = $v.nextPaymentDueDate;
      _originationDate = $v.originationDate;
      _originationPrincipalAmount = $v.originationPrincipalAmount?.toBuilder();
      _pastDueAmount = $v.pastDueAmount?.toBuilder();
      _ytdInterestPaid = $v.ytdInterestPaid?.toBuilder();
      _ytdPrincipalPaid = $v.ytdPrincipalPaid?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MortgageLiability other) {
    _$v = other as _$MortgageLiability;
  }

  @override
  void update(void Function(MortgageLiabilityBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MortgageLiability build() => _build();

  _$MortgageLiability _build() {
    _$MortgageLiability _$result;
    try {
      _$result =
          _$v ??
          _$MortgageLiability._(
            accountId: BuiltValueNullFieldError.checkNotNull(
              accountId,
              r'MortgageLiability',
              'accountId',
            ),
            source_: BuiltValueNullFieldError.checkNotNull(
              source_,
              r'MortgageLiability',
              'source_',
            ),
            loanTypeDescription: loanTypeDescription,
            loanTerm: loanTerm,
            interestRatePercentage: interestRatePercentage,
            interestRateType: interestRateType,
            currentLateFee: _currentLateFee?.build(),
            escrowBalance: _escrowBalance?.build(),
            hasPmi: hasPmi,
            hasPrepaymentPenalty: hasPrepaymentPenalty,
            lastPaymentAmount: _lastPaymentAmount?.build(),
            lastPaymentDate: lastPaymentDate,
            maturityDate: maturityDate,
            nextMonthlyPayment: _nextMonthlyPayment?.build(),
            nextPaymentDueDate: nextPaymentDueDate,
            originationDate: originationDate,
            originationPrincipalAmount: _originationPrincipalAmount?.build(),
            pastDueAmount: _pastDueAmount?.build(),
            ytdInterestPaid: _ytdInterestPaid?.build(),
            ytdPrincipalPaid: _ytdPrincipalPaid?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'currentLateFee';
        _currentLateFee?.build();
        _$failedField = 'escrowBalance';
        _escrowBalance?.build();

        _$failedField = 'lastPaymentAmount';
        _lastPaymentAmount?.build();

        _$failedField = 'nextMonthlyPayment';
        _nextMonthlyPayment?.build();

        _$failedField = 'originationPrincipalAmount';
        _originationPrincipalAmount?.build();
        _$failedField = 'pastDueAmount';
        _pastDueAmount?.build();
        _$failedField = 'ytdInterestPaid';
        _ytdInterestPaid?.build();
        _$failedField = 'ytdPrincipalPaid';
        _ytdPrincipalPaid?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'MortgageLiability',
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
