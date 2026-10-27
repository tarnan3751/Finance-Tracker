// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_stream.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RecurringStream extends RecurringStream {
  @override
  final String id;
  @override
  final String accountId;
  @override
  final String merchantName;
  @override
  final RecurringCadence cadence;
  @override
  final Money averageAmount;
  @override
  final Date? lastExpected;
  @override
  final Date? nextExpected;
  @override
  final RecurringStatus status;
  @override
  final bool isSubscription;
  @override
  final RecurringSource source_;
  @override
  final BuiltList<String> transactionIds;

  factory _$RecurringStream([void Function(RecurringStreamBuilder)? updates]) =>
      (RecurringStreamBuilder()..update(updates))._build();

  _$RecurringStream._({
    required this.id,
    required this.accountId,
    required this.merchantName,
    required this.cadence,
    required this.averageAmount,
    this.lastExpected,
    this.nextExpected,
    required this.status,
    required this.isSubscription,
    required this.source_,
    required this.transactionIds,
  }) : super._();
  @override
  RecurringStream rebuild(void Function(RecurringStreamBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RecurringStreamBuilder toBuilder() => RecurringStreamBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RecurringStream &&
        id == other.id &&
        accountId == other.accountId &&
        merchantName == other.merchantName &&
        cadence == other.cadence &&
        averageAmount == other.averageAmount &&
        lastExpected == other.lastExpected &&
        nextExpected == other.nextExpected &&
        status == other.status &&
        isSubscription == other.isSubscription &&
        source_ == other.source_ &&
        transactionIds == other.transactionIds;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, accountId.hashCode);
    _$hash = $jc(_$hash, merchantName.hashCode);
    _$hash = $jc(_$hash, cadence.hashCode);
    _$hash = $jc(_$hash, averageAmount.hashCode);
    _$hash = $jc(_$hash, lastExpected.hashCode);
    _$hash = $jc(_$hash, nextExpected.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, isSubscription.hashCode);
    _$hash = $jc(_$hash, source_.hashCode);
    _$hash = $jc(_$hash, transactionIds.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RecurringStream')
          ..add('id', id)
          ..add('accountId', accountId)
          ..add('merchantName', merchantName)
          ..add('cadence', cadence)
          ..add('averageAmount', averageAmount)
          ..add('lastExpected', lastExpected)
          ..add('nextExpected', nextExpected)
          ..add('status', status)
          ..add('isSubscription', isSubscription)
          ..add('source_', source_)
          ..add('transactionIds', transactionIds))
        .toString();
  }
}

class RecurringStreamBuilder
    implements Builder<RecurringStream, RecurringStreamBuilder> {
  _$RecurringStream? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _accountId;
  String? get accountId => _$this._accountId;
  set accountId(String? accountId) => _$this._accountId = accountId;

  String? _merchantName;
  String? get merchantName => _$this._merchantName;
  set merchantName(String? merchantName) => _$this._merchantName = merchantName;

  RecurringCadence? _cadence;
  RecurringCadence? get cadence => _$this._cadence;
  set cadence(RecurringCadence? cadence) => _$this._cadence = cadence;

  MoneyBuilder? _averageAmount;
  MoneyBuilder get averageAmount => _$this._averageAmount ??= MoneyBuilder();
  set averageAmount(MoneyBuilder? averageAmount) =>
      _$this._averageAmount = averageAmount;

  Date? _lastExpected;
  Date? get lastExpected => _$this._lastExpected;
  set lastExpected(Date? lastExpected) => _$this._lastExpected = lastExpected;

  Date? _nextExpected;
  Date? get nextExpected => _$this._nextExpected;
  set nextExpected(Date? nextExpected) => _$this._nextExpected = nextExpected;

  RecurringStatus? _status;
  RecurringStatus? get status => _$this._status;
  set status(RecurringStatus? status) => _$this._status = status;

  bool? _isSubscription;
  bool? get isSubscription => _$this._isSubscription;
  set isSubscription(bool? isSubscription) =>
      _$this._isSubscription = isSubscription;

  RecurringSource? _source_;
  RecurringSource? get source_ => _$this._source_;
  set source_(RecurringSource? source_) => _$this._source_ = source_;

  ListBuilder<String>? _transactionIds;
  ListBuilder<String> get transactionIds =>
      _$this._transactionIds ??= ListBuilder<String>();
  set transactionIds(ListBuilder<String>? transactionIds) =>
      _$this._transactionIds = transactionIds;

  RecurringStreamBuilder() {
    RecurringStream._defaults(this);
  }

  RecurringStreamBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _accountId = $v.accountId;
      _merchantName = $v.merchantName;
      _cadence = $v.cadence;
      _averageAmount = $v.averageAmount.toBuilder();
      _lastExpected = $v.lastExpected;
      _nextExpected = $v.nextExpected;
      _status = $v.status;
      _isSubscription = $v.isSubscription;
      _source_ = $v.source_;
      _transactionIds = $v.transactionIds.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RecurringStream other) {
    _$v = other as _$RecurringStream;
  }

  @override
  void update(void Function(RecurringStreamBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RecurringStream build() => _build();

  _$RecurringStream _build() {
    _$RecurringStream _$result;
    try {
      _$result =
          _$v ??
          _$RecurringStream._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'RecurringStream',
              'id',
            ),
            accountId: BuiltValueNullFieldError.checkNotNull(
              accountId,
              r'RecurringStream',
              'accountId',
            ),
            merchantName: BuiltValueNullFieldError.checkNotNull(
              merchantName,
              r'RecurringStream',
              'merchantName',
            ),
            cadence: BuiltValueNullFieldError.checkNotNull(
              cadence,
              r'RecurringStream',
              'cadence',
            ),
            averageAmount: averageAmount.build(),
            lastExpected: lastExpected,
            nextExpected: nextExpected,
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'RecurringStream',
              'status',
            ),
            isSubscription: BuiltValueNullFieldError.checkNotNull(
              isSubscription,
              r'RecurringStream',
              'isSubscription',
            ),
            source_: BuiltValueNullFieldError.checkNotNull(
              source_,
              r'RecurringStream',
              'source_',
            ),
            transactionIds: transactionIds.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'averageAmount';
        averageAmount.build();

        _$failedField = 'transactionIds';
        transactionIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'RecurringStream',
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
