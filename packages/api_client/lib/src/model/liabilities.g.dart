// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liabilities.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Liabilities extends Liabilities {
  @override
  final BuiltList<CreditLiability> credit;
  @override
  final BuiltList<MortgageLiability> mortgage;
  @override
  final BuiltList<StudentLoanLiability> student;

  factory _$Liabilities([void Function(LiabilitiesBuilder)? updates]) =>
      (LiabilitiesBuilder()..update(updates))._build();

  _$Liabilities._({
    required this.credit,
    required this.mortgage,
    required this.student,
  }) : super._();
  @override
  Liabilities rebuild(void Function(LiabilitiesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LiabilitiesBuilder toBuilder() => LiabilitiesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Liabilities &&
        credit == other.credit &&
        mortgage == other.mortgage &&
        student == other.student;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, credit.hashCode);
    _$hash = $jc(_$hash, mortgage.hashCode);
    _$hash = $jc(_$hash, student.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Liabilities')
          ..add('credit', credit)
          ..add('mortgage', mortgage)
          ..add('student', student))
        .toString();
  }
}

class LiabilitiesBuilder implements Builder<Liabilities, LiabilitiesBuilder> {
  _$Liabilities? _$v;

  ListBuilder<CreditLiability>? _credit;
  ListBuilder<CreditLiability> get credit =>
      _$this._credit ??= ListBuilder<CreditLiability>();
  set credit(ListBuilder<CreditLiability>? credit) => _$this._credit = credit;

  ListBuilder<MortgageLiability>? _mortgage;
  ListBuilder<MortgageLiability> get mortgage =>
      _$this._mortgage ??= ListBuilder<MortgageLiability>();
  set mortgage(ListBuilder<MortgageLiability>? mortgage) =>
      _$this._mortgage = mortgage;

  ListBuilder<StudentLoanLiability>? _student;
  ListBuilder<StudentLoanLiability> get student =>
      _$this._student ??= ListBuilder<StudentLoanLiability>();
  set student(ListBuilder<StudentLoanLiability>? student) =>
      _$this._student = student;

  LiabilitiesBuilder() {
    Liabilities._defaults(this);
  }

  LiabilitiesBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _credit = $v.credit.toBuilder();
      _mortgage = $v.mortgage.toBuilder();
      _student = $v.student.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Liabilities other) {
    _$v = other as _$Liabilities;
  }

  @override
  void update(void Function(LiabilitiesBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Liabilities build() => _build();

  _$Liabilities _build() {
    _$Liabilities _$result;
    try {
      _$result =
          _$v ??
          _$Liabilities._(
            credit: credit.build(),
            mortgage: mortgage.build(),
            student: student.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'credit';
        credit.build();
        _$failedField = 'mortgage';
        mortgage.build();
        _$failedField = 'student';
        student.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'Liabilities',
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
