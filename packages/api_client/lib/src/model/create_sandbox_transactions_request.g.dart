// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_sandbox_transactions_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateSandboxTransactionsRequest
    extends CreateSandboxTransactionsRequest {
  @override
  final BuiltList<SandboxTransaction> transactions;

  factory _$CreateSandboxTransactionsRequest([
    void Function(CreateSandboxTransactionsRequestBuilder)? updates,
  ]) => (CreateSandboxTransactionsRequestBuilder()..update(updates))._build();

  _$CreateSandboxTransactionsRequest._({required this.transactions})
    : super._();
  @override
  CreateSandboxTransactionsRequest rebuild(
    void Function(CreateSandboxTransactionsRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateSandboxTransactionsRequestBuilder toBuilder() =>
      CreateSandboxTransactionsRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateSandboxTransactionsRequest &&
        transactions == other.transactions;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, transactions.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'CreateSandboxTransactionsRequest',
    )..add('transactions', transactions)).toString();
  }
}

class CreateSandboxTransactionsRequestBuilder
    implements
        Builder<
          CreateSandboxTransactionsRequest,
          CreateSandboxTransactionsRequestBuilder
        > {
  _$CreateSandboxTransactionsRequest? _$v;

  ListBuilder<SandboxTransaction>? _transactions;
  ListBuilder<SandboxTransaction> get transactions =>
      _$this._transactions ??= ListBuilder<SandboxTransaction>();
  set transactions(ListBuilder<SandboxTransaction>? transactions) =>
      _$this._transactions = transactions;

  CreateSandboxTransactionsRequestBuilder() {
    CreateSandboxTransactionsRequest._defaults(this);
  }

  CreateSandboxTransactionsRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _transactions = $v.transactions.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateSandboxTransactionsRequest other) {
    _$v = other as _$CreateSandboxTransactionsRequest;
  }

  @override
  void update(void Function(CreateSandboxTransactionsRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateSandboxTransactionsRequest build() => _build();

  _$CreateSandboxTransactionsRequest _build() {
    _$CreateSandboxTransactionsRequest _$result;
    try {
      _$result =
          _$v ??
          _$CreateSandboxTransactionsRequest._(
            transactions: transactions.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'transactions';
        transactions.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'CreateSandboxTransactionsRequest',
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
