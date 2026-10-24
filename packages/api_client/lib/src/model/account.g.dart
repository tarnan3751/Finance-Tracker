// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Account extends Account {
  @override
  final String id;
  @override
  final String? itemId;
  @override
  final AccountType type;
  @override
  final String? subtype;
  @override
  final String name;
  @override
  final String? officialName;
  @override
  final String? mask;
  @override
  final String currencyCode;
  @override
  final Money? currentBalance;
  @override
  final Money? availableBalance;
  @override
  final Money? creditLimit;
  @override
  final DateTime? balancesAsOf;
  @override
  final bool isHidden;
  @override
  final int displayOrder;

  factory _$Account([void Function(AccountBuilder)? updates]) =>
      (AccountBuilder()..update(updates))._build();

  _$Account._({
    required this.id,
    this.itemId,
    required this.type,
    this.subtype,
    required this.name,
    this.officialName,
    this.mask,
    required this.currencyCode,
    this.currentBalance,
    this.availableBalance,
    this.creditLimit,
    this.balancesAsOf,
    required this.isHidden,
    required this.displayOrder,
  }) : super._();
  @override
  Account rebuild(void Function(AccountBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AccountBuilder toBuilder() => AccountBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Account &&
        id == other.id &&
        itemId == other.itemId &&
        type == other.type &&
        subtype == other.subtype &&
        name == other.name &&
        officialName == other.officialName &&
        mask == other.mask &&
        currencyCode == other.currencyCode &&
        currentBalance == other.currentBalance &&
        availableBalance == other.availableBalance &&
        creditLimit == other.creditLimit &&
        balancesAsOf == other.balancesAsOf &&
        isHidden == other.isHidden &&
        displayOrder == other.displayOrder;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, itemId.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, subtype.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, officialName.hashCode);
    _$hash = $jc(_$hash, mask.hashCode);
    _$hash = $jc(_$hash, currencyCode.hashCode);
    _$hash = $jc(_$hash, currentBalance.hashCode);
    _$hash = $jc(_$hash, availableBalance.hashCode);
    _$hash = $jc(_$hash, creditLimit.hashCode);
    _$hash = $jc(_$hash, balancesAsOf.hashCode);
    _$hash = $jc(_$hash, isHidden.hashCode);
    _$hash = $jc(_$hash, displayOrder.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Account')
          ..add('id', id)
          ..add('itemId', itemId)
          ..add('type', type)
          ..add('subtype', subtype)
          ..add('name', name)
          ..add('officialName', officialName)
          ..add('mask', mask)
          ..add('currencyCode', currencyCode)
          ..add('currentBalance', currentBalance)
          ..add('availableBalance', availableBalance)
          ..add('creditLimit', creditLimit)
          ..add('balancesAsOf', balancesAsOf)
          ..add('isHidden', isHidden)
          ..add('displayOrder', displayOrder))
        .toString();
  }
}

class AccountBuilder implements Builder<Account, AccountBuilder> {
  _$Account? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _itemId;
  String? get itemId => _$this._itemId;
  set itemId(String? itemId) => _$this._itemId = itemId;

  AccountType? _type;
  AccountType? get type => _$this._type;
  set type(AccountType? type) => _$this._type = type;

  String? _subtype;
  String? get subtype => _$this._subtype;
  set subtype(String? subtype) => _$this._subtype = subtype;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _officialName;
  String? get officialName => _$this._officialName;
  set officialName(String? officialName) => _$this._officialName = officialName;

  String? _mask;
  String? get mask => _$this._mask;
  set mask(String? mask) => _$this._mask = mask;

  String? _currencyCode;
  String? get currencyCode => _$this._currencyCode;
  set currencyCode(String? currencyCode) => _$this._currencyCode = currencyCode;

  MoneyBuilder? _currentBalance;
  MoneyBuilder get currentBalance => _$this._currentBalance ??= MoneyBuilder();
  set currentBalance(MoneyBuilder? currentBalance) =>
      _$this._currentBalance = currentBalance;

  MoneyBuilder? _availableBalance;
  MoneyBuilder get availableBalance =>
      _$this._availableBalance ??= MoneyBuilder();
  set availableBalance(MoneyBuilder? availableBalance) =>
      _$this._availableBalance = availableBalance;

  MoneyBuilder? _creditLimit;
  MoneyBuilder get creditLimit => _$this._creditLimit ??= MoneyBuilder();
  set creditLimit(MoneyBuilder? creditLimit) =>
      _$this._creditLimit = creditLimit;

  DateTime? _balancesAsOf;
  DateTime? get balancesAsOf => _$this._balancesAsOf;
  set balancesAsOf(DateTime? balancesAsOf) =>
      _$this._balancesAsOf = balancesAsOf;

  bool? _isHidden;
  bool? get isHidden => _$this._isHidden;
  set isHidden(bool? isHidden) => _$this._isHidden = isHidden;

  int? _displayOrder;
  int? get displayOrder => _$this._displayOrder;
  set displayOrder(int? displayOrder) => _$this._displayOrder = displayOrder;

  AccountBuilder() {
    Account._defaults(this);
  }

  AccountBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _itemId = $v.itemId;
      _type = $v.type;
      _subtype = $v.subtype;
      _name = $v.name;
      _officialName = $v.officialName;
      _mask = $v.mask;
      _currencyCode = $v.currencyCode;
      _currentBalance = $v.currentBalance?.toBuilder();
      _availableBalance = $v.availableBalance?.toBuilder();
      _creditLimit = $v.creditLimit?.toBuilder();
      _balancesAsOf = $v.balancesAsOf;
      _isHidden = $v.isHidden;
      _displayOrder = $v.displayOrder;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Account other) {
    _$v = other as _$Account;
  }

  @override
  void update(void Function(AccountBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Account build() => _build();

  _$Account _build() {
    _$Account _$result;
    try {
      _$result =
          _$v ??
          _$Account._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'Account', 'id'),
            itemId: itemId,
            type: BuiltValueNullFieldError.checkNotNull(
              type,
              r'Account',
              'type',
            ),
            subtype: subtype,
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'Account',
              'name',
            ),
            officialName: officialName,
            mask: mask,
            currencyCode: BuiltValueNullFieldError.checkNotNull(
              currencyCode,
              r'Account',
              'currencyCode',
            ),
            currentBalance: _currentBalance?.build(),
            availableBalance: _availableBalance?.build(),
            creditLimit: _creditLimit?.build(),
            balancesAsOf: balancesAsOf,
            isHidden: BuiltValueNullFieldError.checkNotNull(
              isHidden,
              r'Account',
              'isHidden',
            ),
            displayOrder: BuiltValueNullFieldError.checkNotNull(
              displayOrder,
              r'Account',
              'displayOrder',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'currentBalance';
        _currentBalance?.build();
        _$failedField = 'availableBalance';
        _availableBalance?.build();
        _$failedField = 'creditLimit';
        _creditLimit?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'Account',
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
