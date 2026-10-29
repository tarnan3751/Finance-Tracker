// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_transaction.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$InvestmentTransaction extends InvestmentTransaction {
  @override
  final String id;
  @override
  final String accountId;
  @override
  final String? securityId;
  @override
  final Date date;
  @override
  final String name;
  @override
  final String type;
  @override
  final String? subtype;
  @override
  final String quantity;
  @override
  final String price;
  @override
  final Money amount;
  @override
  final Money? fees;
  @override
  final DateTime? deletedAt;
  @override
  final int syncVersion;
  @override
  final DataSource source_;

  factory _$InvestmentTransaction([
    void Function(InvestmentTransactionBuilder)? updates,
  ]) => (InvestmentTransactionBuilder()..update(updates))._build();

  _$InvestmentTransaction._({
    required this.id,
    required this.accountId,
    this.securityId,
    required this.date,
    required this.name,
    required this.type,
    this.subtype,
    required this.quantity,
    required this.price,
    required this.amount,
    this.fees,
    this.deletedAt,
    required this.syncVersion,
    required this.source_,
  }) : super._();
  @override
  InvestmentTransaction rebuild(
    void Function(InvestmentTransactionBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  InvestmentTransactionBuilder toBuilder() =>
      InvestmentTransactionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is InvestmentTransaction &&
        id == other.id &&
        accountId == other.accountId &&
        securityId == other.securityId &&
        date == other.date &&
        name == other.name &&
        type == other.type &&
        subtype == other.subtype &&
        quantity == other.quantity &&
        price == other.price &&
        amount == other.amount &&
        fees == other.fees &&
        deletedAt == other.deletedAt &&
        syncVersion == other.syncVersion &&
        source_ == other.source_;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, accountId.hashCode);
    _$hash = $jc(_$hash, securityId.hashCode);
    _$hash = $jc(_$hash, date.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, subtype.hashCode);
    _$hash = $jc(_$hash, quantity.hashCode);
    _$hash = $jc(_$hash, price.hashCode);
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jc(_$hash, fees.hashCode);
    _$hash = $jc(_$hash, deletedAt.hashCode);
    _$hash = $jc(_$hash, syncVersion.hashCode);
    _$hash = $jc(_$hash, source_.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'InvestmentTransaction')
          ..add('id', id)
          ..add('accountId', accountId)
          ..add('securityId', securityId)
          ..add('date', date)
          ..add('name', name)
          ..add('type', type)
          ..add('subtype', subtype)
          ..add('quantity', quantity)
          ..add('price', price)
          ..add('amount', amount)
          ..add('fees', fees)
          ..add('deletedAt', deletedAt)
          ..add('syncVersion', syncVersion)
          ..add('source_', source_))
        .toString();
  }
}

class InvestmentTransactionBuilder
    implements Builder<InvestmentTransaction, InvestmentTransactionBuilder> {
  _$InvestmentTransaction? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _accountId;
  String? get accountId => _$this._accountId;
  set accountId(String? accountId) => _$this._accountId = accountId;

  String? _securityId;
  String? get securityId => _$this._securityId;
  set securityId(String? securityId) => _$this._securityId = securityId;

  Date? _date;
  Date? get date => _$this._date;
  set date(Date? date) => _$this._date = date;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  String? _subtype;
  String? get subtype => _$this._subtype;
  set subtype(String? subtype) => _$this._subtype = subtype;

  String? _quantity;
  String? get quantity => _$this._quantity;
  set quantity(String? quantity) => _$this._quantity = quantity;

  String? _price;
  String? get price => _$this._price;
  set price(String? price) => _$this._price = price;

  MoneyBuilder? _amount;
  MoneyBuilder get amount => _$this._amount ??= MoneyBuilder();
  set amount(MoneyBuilder? amount) => _$this._amount = amount;

  MoneyBuilder? _fees;
  MoneyBuilder get fees => _$this._fees ??= MoneyBuilder();
  set fees(MoneyBuilder? fees) => _$this._fees = fees;

  DateTime? _deletedAt;
  DateTime? get deletedAt => _$this._deletedAt;
  set deletedAt(DateTime? deletedAt) => _$this._deletedAt = deletedAt;

  int? _syncVersion;
  int? get syncVersion => _$this._syncVersion;
  set syncVersion(int? syncVersion) => _$this._syncVersion = syncVersion;

  DataSource? _source_;
  DataSource? get source_ => _$this._source_;
  set source_(DataSource? source_) => _$this._source_ = source_;

  InvestmentTransactionBuilder() {
    InvestmentTransaction._defaults(this);
  }

  InvestmentTransactionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _accountId = $v.accountId;
      _securityId = $v.securityId;
      _date = $v.date;
      _name = $v.name;
      _type = $v.type;
      _subtype = $v.subtype;
      _quantity = $v.quantity;
      _price = $v.price;
      _amount = $v.amount.toBuilder();
      _fees = $v.fees?.toBuilder();
      _deletedAt = $v.deletedAt;
      _syncVersion = $v.syncVersion;
      _source_ = $v.source_;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(InvestmentTransaction other) {
    _$v = other as _$InvestmentTransaction;
  }

  @override
  void update(void Function(InvestmentTransactionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  InvestmentTransaction build() => _build();

  _$InvestmentTransaction _build() {
    _$InvestmentTransaction _$result;
    try {
      _$result =
          _$v ??
          _$InvestmentTransaction._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'InvestmentTransaction',
              'id',
            ),
            accountId: BuiltValueNullFieldError.checkNotNull(
              accountId,
              r'InvestmentTransaction',
              'accountId',
            ),
            securityId: securityId,
            date: BuiltValueNullFieldError.checkNotNull(
              date,
              r'InvestmentTransaction',
              'date',
            ),
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'InvestmentTransaction',
              'name',
            ),
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'InvestmentTransaction',
              'type',
            ),
            subtype: subtype,
            quantity: BuiltValueNullFieldError.checkNotNull(
              quantity,
              r'InvestmentTransaction',
              'quantity',
            ),
            price: BuiltValueNullFieldError.checkNotNull(
              price,
              r'InvestmentTransaction',
              'price',
            ),
            amount: amount.build(),
            fees: _fees?.build(),
            deletedAt: deletedAt,
            syncVersion: BuiltValueNullFieldError.checkNotNull(
              syncVersion,
              r'InvestmentTransaction',
              'syncVersion',
            ),
            source_: BuiltValueNullFieldError.checkNotNull(
              source_,
              r'InvestmentTransaction',
              'source_',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'amount';
        amount.build();
        _$failedField = 'fees';
        _fees?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'InvestmentTransaction',
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
