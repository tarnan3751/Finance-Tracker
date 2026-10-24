// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Transaction extends Transaction {
  @override
  final String id;
  @override
  final String accountId;
  @override
  final Money amount;
  @override
  final Date date;
  @override
  final Date? authorizedDate;
  @override
  final bool pending;
  @override
  final String? pendingTransactionId;
  @override
  final String name;
  @override
  final String? merchantName;
  @override
  final String? merchantLogoUrl;
  @override
  final String? plaidPrimaryCategory;
  @override
  final String? plaidDetailedCategory;
  @override
  final String? userCategoryId;
  @override
  final String? notes;
  @override
  final BuiltList<String> tags;
  @override
  final BuiltList<TransactionSplit> splits;
  @override
  final String? receiptPath;
  @override
  final DataSource source_;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final DateTime? deletedAt;
  @override
  final int syncVersion;

  factory _$Transaction([void Function(TransactionBuilder)? updates]) =>
      (TransactionBuilder()..update(updates))._build();

  _$Transaction._({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.date,
    this.authorizedDate,
    required this.pending,
    this.pendingTransactionId,
    required this.name,
    this.merchantName,
    this.merchantLogoUrl,
    this.plaidPrimaryCategory,
    this.plaidDetailedCategory,
    this.userCategoryId,
    this.notes,
    required this.tags,
    required this.splits,
    this.receiptPath,
    required this.source_,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncVersion,
  }) : super._();
  @override
  Transaction rebuild(void Function(TransactionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TransactionBuilder toBuilder() => TransactionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Transaction &&
        id == other.id &&
        accountId == other.accountId &&
        amount == other.amount &&
        date == other.date &&
        authorizedDate == other.authorizedDate &&
        pending == other.pending &&
        pendingTransactionId == other.pendingTransactionId &&
        name == other.name &&
        merchantName == other.merchantName &&
        merchantLogoUrl == other.merchantLogoUrl &&
        plaidPrimaryCategory == other.plaidPrimaryCategory &&
        plaidDetailedCategory == other.plaidDetailedCategory &&
        userCategoryId == other.userCategoryId &&
        notes == other.notes &&
        tags == other.tags &&
        splits == other.splits &&
        receiptPath == other.receiptPath &&
        source_ == other.source_ &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        deletedAt == other.deletedAt &&
        syncVersion == other.syncVersion;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, accountId.hashCode);
    _$hash = $jc(_$hash, amount.hashCode);
    _$hash = $jc(_$hash, date.hashCode);
    _$hash = $jc(_$hash, authorizedDate.hashCode);
    _$hash = $jc(_$hash, pending.hashCode);
    _$hash = $jc(_$hash, pendingTransactionId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, merchantName.hashCode);
    _$hash = $jc(_$hash, merchantLogoUrl.hashCode);
    _$hash = $jc(_$hash, plaidPrimaryCategory.hashCode);
    _$hash = $jc(_$hash, plaidDetailedCategory.hashCode);
    _$hash = $jc(_$hash, userCategoryId.hashCode);
    _$hash = $jc(_$hash, notes.hashCode);
    _$hash = $jc(_$hash, tags.hashCode);
    _$hash = $jc(_$hash, splits.hashCode);
    _$hash = $jc(_$hash, receiptPath.hashCode);
    _$hash = $jc(_$hash, source_.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, deletedAt.hashCode);
    _$hash = $jc(_$hash, syncVersion.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Transaction')
          ..add('id', id)
          ..add('accountId', accountId)
          ..add('amount', amount)
          ..add('date', date)
          ..add('authorizedDate', authorizedDate)
          ..add('pending', pending)
          ..add('pendingTransactionId', pendingTransactionId)
          ..add('name', name)
          ..add('merchantName', merchantName)
          ..add('merchantLogoUrl', merchantLogoUrl)
          ..add('plaidPrimaryCategory', plaidPrimaryCategory)
          ..add('plaidDetailedCategory', plaidDetailedCategory)
          ..add('userCategoryId', userCategoryId)
          ..add('notes', notes)
          ..add('tags', tags)
          ..add('splits', splits)
          ..add('receiptPath', receiptPath)
          ..add('source_', source_)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('deletedAt', deletedAt)
          ..add('syncVersion', syncVersion))
        .toString();
  }
}

class TransactionBuilder implements Builder<Transaction, TransactionBuilder> {
  _$Transaction? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _accountId;
  String? get accountId => _$this._accountId;
  set accountId(String? accountId) => _$this._accountId = accountId;

  MoneyBuilder? _amount;
  MoneyBuilder get amount => _$this._amount ??= MoneyBuilder();
  set amount(MoneyBuilder? amount) => _$this._amount = amount;

  Date? _date;
  Date? get date => _$this._date;
  set date(Date? date) => _$this._date = date;

  Date? _authorizedDate;
  Date? get authorizedDate => _$this._authorizedDate;
  set authorizedDate(Date? authorizedDate) =>
      _$this._authorizedDate = authorizedDate;

  bool? _pending;
  bool? get pending => _$this._pending;
  set pending(bool? pending) => _$this._pending = pending;

  String? _pendingTransactionId;
  String? get pendingTransactionId => _$this._pendingTransactionId;
  set pendingTransactionId(String? pendingTransactionId) =>
      _$this._pendingTransactionId = pendingTransactionId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _merchantName;
  String? get merchantName => _$this._merchantName;
  set merchantName(String? merchantName) => _$this._merchantName = merchantName;

  String? _merchantLogoUrl;
  String? get merchantLogoUrl => _$this._merchantLogoUrl;
  set merchantLogoUrl(String? merchantLogoUrl) =>
      _$this._merchantLogoUrl = merchantLogoUrl;

  String? _plaidPrimaryCategory;
  String? get plaidPrimaryCategory => _$this._plaidPrimaryCategory;
  set plaidPrimaryCategory(String? plaidPrimaryCategory) =>
      _$this._plaidPrimaryCategory = plaidPrimaryCategory;

  String? _plaidDetailedCategory;
  String? get plaidDetailedCategory => _$this._plaidDetailedCategory;
  set plaidDetailedCategory(String? plaidDetailedCategory) =>
      _$this._plaidDetailedCategory = plaidDetailedCategory;

  String? _userCategoryId;
  String? get userCategoryId => _$this._userCategoryId;
  set userCategoryId(String? userCategoryId) =>
      _$this._userCategoryId = userCategoryId;

  String? _notes;
  String? get notes => _$this._notes;
  set notes(String? notes) => _$this._notes = notes;

  ListBuilder<String>? _tags;
  ListBuilder<String> get tags => _$this._tags ??= ListBuilder<String>();
  set tags(ListBuilder<String>? tags) => _$this._tags = tags;

  ListBuilder<TransactionSplit>? _splits;
  ListBuilder<TransactionSplit> get splits =>
      _$this._splits ??= ListBuilder<TransactionSplit>();
  set splits(ListBuilder<TransactionSplit>? splits) => _$this._splits = splits;

  String? _receiptPath;
  String? get receiptPath => _$this._receiptPath;
  set receiptPath(String? receiptPath) => _$this._receiptPath = receiptPath;

  DataSource? _source_;
  DataSource? get source_ => _$this._source_;
  set source_(DataSource? source_) => _$this._source_ = source_;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  DateTime? _deletedAt;
  DateTime? get deletedAt => _$this._deletedAt;
  set deletedAt(DateTime? deletedAt) => _$this._deletedAt = deletedAt;

  int? _syncVersion;
  int? get syncVersion => _$this._syncVersion;
  set syncVersion(int? syncVersion) => _$this._syncVersion = syncVersion;

  TransactionBuilder() {
    Transaction._defaults(this);
  }

  TransactionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _accountId = $v.accountId;
      _amount = $v.amount.toBuilder();
      _date = $v.date;
      _authorizedDate = $v.authorizedDate;
      _pending = $v.pending;
      _pendingTransactionId = $v.pendingTransactionId;
      _name = $v.name;
      _merchantName = $v.merchantName;
      _merchantLogoUrl = $v.merchantLogoUrl;
      _plaidPrimaryCategory = $v.plaidPrimaryCategory;
      _plaidDetailedCategory = $v.plaidDetailedCategory;
      _userCategoryId = $v.userCategoryId;
      _notes = $v.notes;
      _tags = $v.tags.toBuilder();
      _splits = $v.splits.toBuilder();
      _receiptPath = $v.receiptPath;
      _source_ = $v.source_;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _deletedAt = $v.deletedAt;
      _syncVersion = $v.syncVersion;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Transaction other) {
    _$v = other as _$Transaction;
  }

  @override
  void update(void Function(TransactionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Transaction build() => _build();

  _$Transaction _build() {
    _$Transaction _$result;
    try {
      _$result =
          _$v ??
          _$Transaction._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'Transaction', 'id'),
            accountId: BuiltValueNullFieldError.checkNotNull(
              accountId,
              r'Transaction',
              'accountId',
            ),
            amount: amount.build(),
            date: BuiltValueNullFieldError.checkNotNull(
              date,
              r'Transaction',
              'date',
            ),
            authorizedDate: authorizedDate,
            pending: BuiltValueNullFieldError.checkNotNull(
              pending,
              r'Transaction',
              'pending',
            ),
            pendingTransactionId: pendingTransactionId,
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'Transaction',
              'name',
            ),
            merchantName: merchantName,
            merchantLogoUrl: merchantLogoUrl,
            plaidPrimaryCategory: plaidPrimaryCategory,
            plaidDetailedCategory: plaidDetailedCategory,
            userCategoryId: userCategoryId,
            notes: notes,
            tags: tags.build(),
            splits: splits.build(),
            receiptPath: receiptPath,
            source_: BuiltValueNullFieldError.checkNotNull(
              source_,
              r'Transaction',
              'source_',
            ),
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'Transaction',
              'createdAt',
            ),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt,
              r'Transaction',
              'updatedAt',
            ),
            deletedAt: deletedAt,
            syncVersion: BuiltValueNullFieldError.checkNotNull(
              syncVersion,
              r'Transaction',
              'syncVersion',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'amount';
        amount.build();

        _$failedField = 'tags';
        tags.build();
        _$failedField = 'splits';
        splits.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'Transaction',
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
