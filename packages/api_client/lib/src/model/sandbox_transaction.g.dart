// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sandbox_transaction.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SandboxTransaction extends SandboxTransaction {
  @override
  final Date dateTransacted;
  @override
  final Date datePosted;
  @override
  final Money amount;
  @override
  final String description;
  @override
  final String? accountId;

  factory _$SandboxTransaction([
    void Function(SandboxTransactionBuilder)? updates,
  ]) => (SandboxTransactionBuilder()..update(updates))._build();

  _$SandboxTransaction._({
    required this.dateTransacted,
    required this.datePosted,
    required this.amount,
    required this.description,
    this.accountId,
  }) : super._();
  @override
  SandboxTransaction rebuild(
    void Function(SandboxTransactionBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  SandboxTransactionBuilder toBuilder() =>
      SandboxTransactionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SandboxTransaction &&
        dateTransacted == other.dateTransacted &&
        datePosted == other.datePosted &&
        amount == other.amount &&
        description == other.description &&
        accountId == other.accountId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, dateTransacted.hashCode);
    _$hash = $jc(_$hash, datePosted.hashCode);
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, accountId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SandboxTransaction')
          ..add('dateTransacted', dateTransacted)
          ..add('datePosted', datePosted)
          ..add('amount', amount)
          ..add('description', description)
          ..add('accountId', accountId))
        .toString();
  }
}

class SandboxTransactionBuilder
    implements Builder<SandboxTransaction, SandboxTransactionBuilder> {
  _$SandboxTransaction? _$v;

  Date? _dateTransacted;
  Date? get dateTransacted => _$this._dateTransacted;
  set dateTransacted(Date? dateTransacted) =>
      _$this._dateTransacted = dateTransacted;

  Date? _datePosted;
  Date? get datePosted => _$this._datePosted;
  set datePosted(Date? datePosted) => _$this._datePosted = datePosted;

  MoneyBuilder? _amount;
  MoneyBuilder get amount => _$this._amount ??= MoneyBuilder();
  set amount(MoneyBuilder? amount) => _$this._amount = amount;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _accountId;
  String? get accountId => _$this._accountId;
  set accountId(String? accountId) => _$this._accountId = accountId;

  SandboxTransactionBuilder() {
    SandboxTransaction._defaults(this);
  }

  SandboxTransactionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _dateTransacted = $v.dateTransacted;
      _datePosted = $v.datePosted;
      _amount = $v.amount.toBuilder();
      _description = $v.description;
      _accountId = $v.accountId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SandboxTransaction other) {
    _$v = other as _$SandboxTransaction;
  }

  @override
  void update(void Function(SandboxTransactionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SandboxTransaction build() => _build();

  _$SandboxTransaction _build() {
    _$SandboxTransaction _$result;
    try {
      _$result =
          _$v ??
          _$SandboxTransaction._(
            dateTransacted: BuiltValueNullFieldError.checkNotNull(
              dateTransacted,
              r'SandboxTransaction',
              'dateTransacted',
            ),
            datePosted: BuiltValueNullFieldError.checkNotNull(
              datePosted,
              r'SandboxTransaction',
              'datePosted',
            ),
            amount: amount.build(),
            description: BuiltValueNullFieldError.checkNotNull(
              description,
              r'SandboxTransaction',
              'description',
            ),
            accountId: accountId,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'amount';
        amount.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'SandboxTransaction',
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
