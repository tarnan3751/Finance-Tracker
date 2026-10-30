// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Transaction {

 String get id; String get accountId; Money get amount; LocalDate get date; LocalDate? get authorizedDate; bool get pending; String? get pendingTransactionId; String get name; String? get merchantName; Uri? get merchantLogoUrl; String? get plaidPrimaryCategory; String? get plaidDetailedCategory; String? get userCategoryId; String? get notes; List<String> get tags; List<TransactionSplit> get splits; String? get receiptPath; String? get receiptSha256; bool get hidden; DataSource get source;@UtcInstantConverter() DateTime get createdAt;@UtcInstantConverter() DateTime get updatedAt;@UtcInstantConverter() DateTime? get deletedAt; int get syncVersion;
/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionCopyWith<Transaction> get copyWith => _$TransactionCopyWithImpl<Transaction>(this as Transaction, _$identity);

  /// Serializes this Transaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Transaction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transaction&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.authorizedDate, _this.authorizedDate) || other.authorizedDate == _this.authorizedDate)&&(identical(other.pending, _this.pending) || other.pending == _this.pending)&&(identical(other.pendingTransactionId, _this.pendingTransactionId) || other.pendingTransactionId == _this.pendingTransactionId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.merchantName, _this.merchantName) || other.merchantName == _this.merchantName)&&(identical(other.merchantLogoUrl, _this.merchantLogoUrl) || other.merchantLogoUrl == _this.merchantLogoUrl)&&(identical(other.plaidPrimaryCategory, _this.plaidPrimaryCategory) || other.plaidPrimaryCategory == _this.plaidPrimaryCategory)&&(identical(other.plaidDetailedCategory, _this.plaidDetailedCategory) || other.plaidDetailedCategory == _this.plaidDetailedCategory)&&(identical(other.userCategoryId, _this.userCategoryId) || other.userCategoryId == _this.userCategoryId)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&const DeepCollectionEquality().equals(other.tags, _this.tags)&&const DeepCollectionEquality().equals(other.splits, _this.splits)&&(identical(other.receiptPath, _this.receiptPath) || other.receiptPath == _this.receiptPath)&&(identical(other.receiptSha256, _this.receiptSha256) || other.receiptSha256 == _this.receiptSha256)&&(identical(other.hidden, _this.hidden) || other.hidden == _this.hidden)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt)&&(identical(other.syncVersion, _this.syncVersion) || other.syncVersion == _this.syncVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Transaction;
  return Object.hashAll([runtimeType,_this.id,_this.accountId,_this.amount,_this.date,_this.authorizedDate,_this.pending,_this.pendingTransactionId,_this.name,_this.merchantName,_this.merchantLogoUrl,_this.plaidPrimaryCategory,_this.plaidDetailedCategory,_this.userCategoryId,_this.notes,const DeepCollectionEquality().hash(_this.tags),const DeepCollectionEquality().hash(_this.splits),_this.receiptPath,_this.receiptSha256,_this.hidden,_this.source,_this.createdAt,_this.updatedAt,_this.deletedAt,_this.syncVersion]);
}

@override
String toString() {
  final _this = this as Transaction;
  return 'Transaction(id: ${_this.id}, accountId: ${_this.accountId}, amount: ${_this.amount}, date: ${_this.date}, authorizedDate: ${_this.authorizedDate}, pending: ${_this.pending}, pendingTransactionId: ${_this.pendingTransactionId}, name: ${_this.name}, merchantName: ${_this.merchantName}, merchantLogoUrl: ${_this.merchantLogoUrl}, plaidPrimaryCategory: ${_this.plaidPrimaryCategory}, plaidDetailedCategory: ${_this.plaidDetailedCategory}, userCategoryId: ${_this.userCategoryId}, notes: ${_this.notes}, tags: ${_this.tags}, splits: ${_this.splits}, receiptPath: ${_this.receiptPath}, receiptSha256: ${_this.receiptSha256}, hidden: ${_this.hidden}, source: ${_this.source}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, deletedAt: ${_this.deletedAt}, syncVersion: ${_this.syncVersion})';
}


}

/// @nodoc
abstract mixin class $TransactionCopyWith<$Res>  {
  factory $TransactionCopyWith(Transaction value, $Res Function(Transaction) _then) = _$TransactionCopyWithImpl;
@useResult
$Res call({
 String id, String accountId, Money amount, LocalDate date, LocalDate? authorizedDate, bool pending, String? pendingTransactionId, String name, String? merchantName, Uri? merchantLogoUrl, String? plaidPrimaryCategory, String? plaidDetailedCategory, String? userCategoryId, String? notes, List<String> tags, List<TransactionSplit> splits, String? receiptPath, String? receiptSha256, bool hidden, DataSource source,@UtcInstantConverter() DateTime createdAt,@UtcInstantConverter() DateTime updatedAt,@UtcInstantConverter() DateTime? deletedAt, int syncVersion
});




}
/// @nodoc
class _$TransactionCopyWithImpl<$Res>
    implements $TransactionCopyWith<$Res> {
  _$TransactionCopyWithImpl(this._self, this._then);

  final Transaction _self;
  final $Res Function(Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? accountId = null,Object? amount = null,Object? date = null,Object? authorizedDate = freezed,Object? pending = null,Object? pendingTransactionId = freezed,Object? name = null,Object? merchantName = freezed,Object? merchantLogoUrl = freezed,Object? plaidPrimaryCategory = freezed,Object? plaidDetailedCategory = freezed,Object? userCategoryId = freezed,Object? notes = freezed,Object? tags = null,Object? splits = null,Object? receiptPath = freezed,Object? receiptSha256 = freezed,Object? hidden = null,Object? source = null,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,Object? syncVersion = null,}) {
  return _then(Transaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,authorizedDate: freezed == authorizedDate ? _self.authorizedDate : authorizedDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,pendingTransactionId: freezed == pendingTransactionId ? _self.pendingTransactionId : pendingTransactionId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,merchantName: freezed == merchantName ? _self.merchantName : merchantName // ignore: cast_nullable_to_non_nullable
as String?,merchantLogoUrl: freezed == merchantLogoUrl ? _self.merchantLogoUrl : merchantLogoUrl // ignore: cast_nullable_to_non_nullable
as Uri?,plaidPrimaryCategory: freezed == plaidPrimaryCategory ? _self.plaidPrimaryCategory : plaidPrimaryCategory // ignore: cast_nullable_to_non_nullable
as String?,plaidDetailedCategory: freezed == plaidDetailedCategory ? _self.plaidDetailedCategory : plaidDetailedCategory // ignore: cast_nullable_to_non_nullable
as String?,userCategoryId: freezed == userCategoryId ? _self.userCategoryId : userCategoryId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,splits: null == splits ? _self.splits : splits // ignore: cast_nullable_to_non_nullable
as List<TransactionSplit>,receiptPath: freezed == receiptPath ? _self.receiptPath : receiptPath // ignore: cast_nullable_to_non_nullable
as String?,receiptSha256: freezed == receiptSha256 ? _self.receiptSha256 : receiptSha256 // ignore: cast_nullable_to_non_nullable
as String?,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DataSource,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncVersion: null == syncVersion ? _self.syncVersion : syncVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Transaction].
extension TransactionPatterns on Transaction {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Transaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Transaction value)  $default,){
final _that = this;
switch (_that) {
case _Transaction():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Transaction value)?  $default,){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String accountId,  Money amount,  LocalDate date,  LocalDate? authorizedDate,  bool pending,  String? pendingTransactionId,  String name,  String? merchantName,  Uri? merchantLogoUrl,  String? plaidPrimaryCategory,  String? plaidDetailedCategory,  String? userCategoryId,  String? notes,  List<String> tags,  List<TransactionSplit> splits,  String? receiptPath,  String? receiptSha256,  bool hidden,  DataSource source, @UtcInstantConverter()  DateTime createdAt, @UtcInstantConverter()  DateTime updatedAt, @UtcInstantConverter()  DateTime? deletedAt,  int syncVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.accountId,_that.amount,_that.date,_that.authorizedDate,_that.pending,_that.pendingTransactionId,_that.name,_that.merchantName,_that.merchantLogoUrl,_that.plaidPrimaryCategory,_that.plaidDetailedCategory,_that.userCategoryId,_that.notes,_that.tags,_that.splits,_that.receiptPath,_that.receiptSha256,_that.hidden,_that.source,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncVersion);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String accountId,  Money amount,  LocalDate date,  LocalDate? authorizedDate,  bool pending,  String? pendingTransactionId,  String name,  String? merchantName,  Uri? merchantLogoUrl,  String? plaidPrimaryCategory,  String? plaidDetailedCategory,  String? userCategoryId,  String? notes,  List<String> tags,  List<TransactionSplit> splits,  String? receiptPath,  String? receiptSha256,  bool hidden,  DataSource source, @UtcInstantConverter()  DateTime createdAt, @UtcInstantConverter()  DateTime updatedAt, @UtcInstantConverter()  DateTime? deletedAt,  int syncVersion)  $default,) {final _that = this;
switch (_that) {
case _Transaction():
return $default(_that.id,_that.accountId,_that.amount,_that.date,_that.authorizedDate,_that.pending,_that.pendingTransactionId,_that.name,_that.merchantName,_that.merchantLogoUrl,_that.plaidPrimaryCategory,_that.plaidDetailedCategory,_that.userCategoryId,_that.notes,_that.tags,_that.splits,_that.receiptPath,_that.receiptSha256,_that.hidden,_that.source,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncVersion);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String accountId,  Money amount,  LocalDate date,  LocalDate? authorizedDate,  bool pending,  String? pendingTransactionId,  String name,  String? merchantName,  Uri? merchantLogoUrl,  String? plaidPrimaryCategory,  String? plaidDetailedCategory,  String? userCategoryId,  String? notes,  List<String> tags,  List<TransactionSplit> splits,  String? receiptPath,  String? receiptSha256,  bool hidden,  DataSource source, @UtcInstantConverter()  DateTime createdAt, @UtcInstantConverter()  DateTime updatedAt, @UtcInstantConverter()  DateTime? deletedAt,  int syncVersion)?  $default,) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.accountId,_that.amount,_that.date,_that.authorizedDate,_that.pending,_that.pendingTransactionId,_that.name,_that.merchantName,_that.merchantLogoUrl,_that.plaidPrimaryCategory,_that.plaidDetailedCategory,_that.userCategoryId,_that.notes,_that.tags,_that.splits,_that.receiptPath,_that.receiptSha256,_that.hidden,_that.source,_that.createdAt,_that.updatedAt,_that.deletedAt,_that.syncVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Transaction implements Transaction {
  const _Transaction({required this.id, required this.accountId, required this.amount, required this.date, this.authorizedDate, required this.pending, this.pendingTransactionId, required this.name, this.merchantName, this.merchantLogoUrl, this.plaidPrimaryCategory, this.plaidDetailedCategory, this.userCategoryId, this.notes,  List<String> tags = const <String>[],  List<TransactionSplit> splits = const <TransactionSplit>[], this.receiptPath, this.receiptSha256, this.hidden = false, required this.source, @UtcInstantConverter() required this.createdAt, @UtcInstantConverter() required this.updatedAt, @UtcInstantConverter() this.deletedAt, required this.syncVersion}): _tags = tags,_splits = splits;
  factory _Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);

@override final  String id;
@override final  String accountId;
@override final  Money amount;
@override final  LocalDate date;
@override final  LocalDate? authorizedDate;
@override final  bool pending;
@override final  String? pendingTransactionId;
@override final  String name;
@override final  String? merchantName;
@override final  Uri? merchantLogoUrl;
@override final  String? plaidPrimaryCategory;
@override final  String? plaidDetailedCategory;
@override final  String? userCategoryId;
@override final  String? notes;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  List<TransactionSplit> _splits;
@override@JsonKey() List<TransactionSplit> get splits {
  if (_splits is EqualUnmodifiableListView) return _splits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_splits);
}

@override final  String? receiptPath;
@override final  String? receiptSha256;
@override@JsonKey() final  bool hidden;
@override final  DataSource source;
@override@UtcInstantConverter() final  DateTime createdAt;
@override@UtcInstantConverter() final  DateTime updatedAt;
@override@UtcInstantConverter() final  DateTime? deletedAt;
@override final  int syncVersion;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionCopyWith<_Transaction> get copyWith => __$TransactionCopyWithImpl<_Transaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransactionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Transaction&&(identical(other.id, id) || other.id == id)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.date, date) || other.date == date)&&(identical(other.authorizedDate, authorizedDate) || other.authorizedDate == authorizedDate)&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.pendingTransactionId, pendingTransactionId) || other.pendingTransactionId == pendingTransactionId)&&(identical(other.name, name) || other.name == name)&&(identical(other.merchantName, merchantName) || other.merchantName == merchantName)&&(identical(other.merchantLogoUrl, merchantLogoUrl) || other.merchantLogoUrl == merchantLogoUrl)&&(identical(other.plaidPrimaryCategory, plaidPrimaryCategory) || other.plaidPrimaryCategory == plaidPrimaryCategory)&&(identical(other.plaidDetailedCategory, plaidDetailedCategory) || other.plaidDetailedCategory == plaidDetailedCategory)&&(identical(other.userCategoryId, userCategoryId) || other.userCategoryId == userCategoryId)&&(identical(other.notes, notes) || other.notes == notes)&&const DeepCollectionEquality().equals(other.tags, _tags)&&const DeepCollectionEquality().equals(other.splits, _splits)&&(identical(other.receiptPath, receiptPath) || other.receiptPath == receiptPath)&&(identical(other.receiptSha256, receiptSha256) || other.receiptSha256 == receiptSha256)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.source, source) || other.source == source)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncVersion, syncVersion) || other.syncVersion == syncVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,accountId,amount,date,authorizedDate,pending,pendingTransactionId,name,merchantName,merchantLogoUrl,plaidPrimaryCategory,plaidDetailedCategory,userCategoryId,notes,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_splits),receiptPath,receiptSha256,hidden,source,createdAt,updatedAt,deletedAt,syncVersion]);
}

@override
String toString() {
    return 'Transaction(id: $id, accountId: $accountId, amount: $amount, date: $date, authorizedDate: $authorizedDate, pending: $pending, pendingTransactionId: $pendingTransactionId, name: $name, merchantName: $merchantName, merchantLogoUrl: $merchantLogoUrl, plaidPrimaryCategory: $plaidPrimaryCategory, plaidDetailedCategory: $plaidDetailedCategory, userCategoryId: $userCategoryId, notes: $notes, tags: $tags, splits: $splits, receiptPath: $receiptPath, receiptSha256: $receiptSha256, hidden: $hidden, source: $source, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, syncVersion: $syncVersion)';
}


}

/// @nodoc
abstract mixin class _$TransactionCopyWith<$Res> implements $TransactionCopyWith<$Res> {
  factory _$TransactionCopyWith(_Transaction value, $Res Function(_Transaction) _then) = __$TransactionCopyWithImpl;
@override @useResult
$Res call({
 String id, String accountId, Money amount, LocalDate date, LocalDate? authorizedDate, bool pending, String? pendingTransactionId, String name, String? merchantName, Uri? merchantLogoUrl, String? plaidPrimaryCategory, String? plaidDetailedCategory, String? userCategoryId, String? notes, List<String> tags, List<TransactionSplit> splits, String? receiptPath, String? receiptSha256, bool hidden, DataSource source,@UtcInstantConverter() DateTime createdAt,@UtcInstantConverter() DateTime updatedAt,@UtcInstantConverter() DateTime? deletedAt, int syncVersion
});




}
/// @nodoc
class __$TransactionCopyWithImpl<$Res>
    implements _$TransactionCopyWith<$Res> {
  __$TransactionCopyWithImpl(this._self, this._then);

  final _Transaction _self;
  final $Res Function(_Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? accountId = null,Object? amount = null,Object? date = null,Object? authorizedDate = freezed,Object? pending = null,Object? pendingTransactionId = freezed,Object? name = null,Object? merchantName = freezed,Object? merchantLogoUrl = freezed,Object? plaidPrimaryCategory = freezed,Object? plaidDetailedCategory = freezed,Object? userCategoryId = freezed,Object? notes = freezed,Object? tags = null,Object? splits = null,Object? receiptPath = freezed,Object? receiptSha256 = freezed,Object? hidden = null,Object? source = null,Object? createdAt = null,Object? updatedAt = null,Object? deletedAt = freezed,Object? syncVersion = null,}) {
  return _then(_Transaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,authorizedDate: freezed == authorizedDate ? _self.authorizedDate : authorizedDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,pendingTransactionId: freezed == pendingTransactionId ? _self.pendingTransactionId : pendingTransactionId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,merchantName: freezed == merchantName ? _self.merchantName : merchantName // ignore: cast_nullable_to_non_nullable
as String?,merchantLogoUrl: freezed == merchantLogoUrl ? _self.merchantLogoUrl : merchantLogoUrl // ignore: cast_nullable_to_non_nullable
as Uri?,plaidPrimaryCategory: freezed == plaidPrimaryCategory ? _self.plaidPrimaryCategory : plaidPrimaryCategory // ignore: cast_nullable_to_non_nullable
as String?,plaidDetailedCategory: freezed == plaidDetailedCategory ? _self.plaidDetailedCategory : plaidDetailedCategory // ignore: cast_nullable_to_non_nullable
as String?,userCategoryId: freezed == userCategoryId ? _self.userCategoryId : userCategoryId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,splits: null == splits ? _self._splits : splits // ignore: cast_nullable_to_non_nullable
as List<TransactionSplit>,receiptPath: freezed == receiptPath ? _self.receiptPath : receiptPath // ignore: cast_nullable_to_non_nullable
as String?,receiptSha256: freezed == receiptSha256 ? _self.receiptSha256 : receiptSha256 // ignore: cast_nullable_to_non_nullable
as String?,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DataSource,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncVersion: null == syncVersion ? _self.syncVersion : syncVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$TransactionSplit {

 String get categoryId; Money get amount; String? get note;
/// Create a copy of TransactionSplit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionSplitCopyWith<TransactionSplit> get copyWith => _$TransactionSplitCopyWithImpl<TransactionSplit>(this as TransactionSplit, _$identity);

  /// Serializes this TransactionSplit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TransactionSplit;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionSplit&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.note, _this.note) || other.note == _this.note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TransactionSplit;
  return Object.hash(runtimeType,_this.categoryId,_this.amount,_this.note);
}

@override
String toString() {
  final _this = this as TransactionSplit;
  return 'TransactionSplit(categoryId: ${_this.categoryId}, amount: ${_this.amount}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $TransactionSplitCopyWith<$Res>  {
  factory $TransactionSplitCopyWith(TransactionSplit value, $Res Function(TransactionSplit) _then) = _$TransactionSplitCopyWithImpl;
@useResult
$Res call({
 String categoryId, Money amount, String? note
});




}
/// @nodoc
class _$TransactionSplitCopyWithImpl<$Res>
    implements $TransactionSplitCopyWith<$Res> {
  _$TransactionSplitCopyWithImpl(this._self, this._then);

  final TransactionSplit _self;
  final $Res Function(TransactionSplit) _then;

/// Create a copy of TransactionSplit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryId = null,Object? amount = null,Object? note = freezed,}) {
  return _then(TransactionSplit(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionSplit].
extension TransactionSplitPatterns on TransactionSplit {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionSplit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionSplit() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionSplit value)  $default,){
final _that = this;
switch (_that) {
case _TransactionSplit():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionSplit value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionSplit() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String categoryId,  Money amount,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionSplit() when $default != null:
return $default(_that.categoryId,_that.amount,_that.note);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String categoryId,  Money amount,  String? note)  $default,) {final _that = this;
switch (_that) {
case _TransactionSplit():
return $default(_that.categoryId,_that.amount,_that.note);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String categoryId,  Money amount,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _TransactionSplit() when $default != null:
return $default(_that.categoryId,_that.amount,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TransactionSplit implements TransactionSplit {
  const _TransactionSplit({required this.categoryId, required this.amount, this.note});
  factory _TransactionSplit.fromJson(Map<String, dynamic> json) => _$TransactionSplitFromJson(json);

@override final  String categoryId;
@override final  Money amount;
@override final  String? note;

/// Create a copy of TransactionSplit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionSplitCopyWith<_TransactionSplit> get copyWith => __$TransactionSplitCopyWithImpl<_TransactionSplit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransactionSplitToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionSplit&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,categoryId,amount,note);
}

@override
String toString() {
    return 'TransactionSplit(categoryId: $categoryId, amount: $amount, note: $note)';
}


}

/// @nodoc
abstract mixin class _$TransactionSplitCopyWith<$Res> implements $TransactionSplitCopyWith<$Res> {
  factory _$TransactionSplitCopyWith(_TransactionSplit value, $Res Function(_TransactionSplit) _then) = __$TransactionSplitCopyWithImpl;
@override @useResult
$Res call({
 String categoryId, Money amount, String? note
});




}
/// @nodoc
class __$TransactionSplitCopyWithImpl<$Res>
    implements _$TransactionSplitCopyWith<$Res> {
  __$TransactionSplitCopyWithImpl(this._self, this._then);

  final _TransactionSplit _self;
  final $Res Function(_TransactionSplit) _then;

/// Create a copy of TransactionSplit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryId = null,Object? amount = null,Object? note = freezed,}) {
  return _then(_TransactionSplit(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
