// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'investment_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InvestmentTransaction {

 String get id; String get accountId; String? get securityId; LocalDate get date; String get name; String get type; String? get subtype; Decimal get quantity; Decimal get price; Money get amount; Money? get fees; DateTime? get deletedAt; int get syncVersion; DataSource get source;
/// Create a copy of InvestmentTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestmentTransactionCopyWith<InvestmentTransaction> get copyWith => _$InvestmentTransactionCopyWithImpl<InvestmentTransaction>(this as InvestmentTransaction, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as InvestmentTransaction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentTransaction&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.securityId, _this.securityId) || other.securityId == _this.securityId)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.subtype, _this.subtype) || other.subtype == _this.subtype)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.price, _this.price) || other.price == _this.price)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.fees, _this.fees) || other.fees == _this.fees)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt)&&(identical(other.syncVersion, _this.syncVersion) || other.syncVersion == _this.syncVersion)&&(identical(other.source, _this.source) || other.source == _this.source));
}


@override
int get hashCode {
  final _this = this as InvestmentTransaction;
  return Object.hash(runtimeType,_this.id,_this.accountId,_this.securityId,_this.date,_this.name,_this.type,_this.subtype,_this.quantity,_this.price,_this.amount,_this.fees,_this.deletedAt,_this.syncVersion,_this.source);
}

@override
String toString() {
  final _this = this as InvestmentTransaction;
  return 'InvestmentTransaction(id: ${_this.id}, accountId: ${_this.accountId}, securityId: ${_this.securityId}, date: ${_this.date}, name: ${_this.name}, type: ${_this.type}, subtype: ${_this.subtype}, quantity: ${_this.quantity}, price: ${_this.price}, amount: ${_this.amount}, fees: ${_this.fees}, deletedAt: ${_this.deletedAt}, syncVersion: ${_this.syncVersion}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $InvestmentTransactionCopyWith<$Res>  {
  factory $InvestmentTransactionCopyWith(InvestmentTransaction value, $Res Function(InvestmentTransaction) _then) = _$InvestmentTransactionCopyWithImpl;
@useResult
$Res call({
 String id, String accountId, String? securityId, LocalDate date, String name, String type, String? subtype, Decimal quantity, Decimal price, Money amount, Money? fees, DateTime? deletedAt, int syncVersion, DataSource source
});




}
/// @nodoc
class _$InvestmentTransactionCopyWithImpl<$Res>
    implements $InvestmentTransactionCopyWith<$Res> {
  _$InvestmentTransactionCopyWithImpl(this._self, this._then);

  final InvestmentTransaction _self;
  final $Res Function(InvestmentTransaction) _then;

/// Create a copy of InvestmentTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? accountId = null,Object? securityId = freezed,Object? date = null,Object? name = null,Object? type = null,Object? subtype = freezed,Object? quantity = null,Object? price = null,Object? amount = null,Object? fees = freezed,Object? deletedAt = freezed,Object? syncVersion = null,Object? source = null,}) {
  return _then(InvestmentTransaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,securityId: freezed == securityId ? _self.securityId : securityId // ignore: cast_nullable_to_non_nullable
as String?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,subtype: freezed == subtype ? _self.subtype : subtype // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as Decimal,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Decimal,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,fees: freezed == fees ? _self.fees : fees // ignore: cast_nullable_to_non_nullable
as Money?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncVersion: null == syncVersion ? _self.syncVersion : syncVersion // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DataSource,
  ));
}

}


/// Adds pattern-matching-related methods to [InvestmentTransaction].
extension InvestmentTransactionPatterns on InvestmentTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvestmentTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvestmentTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvestmentTransaction value)  $default,){
final _that = this;
switch (_that) {
case _InvestmentTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvestmentTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _InvestmentTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String accountId,  String? securityId,  LocalDate date,  String name,  String type,  String? subtype,  Decimal quantity,  Decimal price,  Money amount,  Money? fees,  DateTime? deletedAt,  int syncVersion,  DataSource source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvestmentTransaction() when $default != null:
return $default(_that.id,_that.accountId,_that.securityId,_that.date,_that.name,_that.type,_that.subtype,_that.quantity,_that.price,_that.amount,_that.fees,_that.deletedAt,_that.syncVersion,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String accountId,  String? securityId,  LocalDate date,  String name,  String type,  String? subtype,  Decimal quantity,  Decimal price,  Money amount,  Money? fees,  DateTime? deletedAt,  int syncVersion,  DataSource source)  $default,) {final _that = this;
switch (_that) {
case _InvestmentTransaction():
return $default(_that.id,_that.accountId,_that.securityId,_that.date,_that.name,_that.type,_that.subtype,_that.quantity,_that.price,_that.amount,_that.fees,_that.deletedAt,_that.syncVersion,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String accountId,  String? securityId,  LocalDate date,  String name,  String type,  String? subtype,  Decimal quantity,  Decimal price,  Money amount,  Money? fees,  DateTime? deletedAt,  int syncVersion,  DataSource source)?  $default,) {final _that = this;
switch (_that) {
case _InvestmentTransaction() when $default != null:
return $default(_that.id,_that.accountId,_that.securityId,_that.date,_that.name,_that.type,_that.subtype,_that.quantity,_that.price,_that.amount,_that.fees,_that.deletedAt,_that.syncVersion,_that.source);case _:
  return null;

}
}

}

/// @nodoc


class _InvestmentTransaction implements InvestmentTransaction {
  const _InvestmentTransaction({required this.id, required this.accountId, this.securityId, required this.date, required this.name, required this.type, this.subtype, required this.quantity, required this.price, required this.amount, this.fees, this.deletedAt, required this.syncVersion, required this.source});
  

@override final  String id;
@override final  String accountId;
@override final  String? securityId;
@override final  LocalDate date;
@override final  String name;
@override final  String type;
@override final  String? subtype;
@override final  Decimal quantity;
@override final  Decimal price;
@override final  Money amount;
@override final  Money? fees;
@override final  DateTime? deletedAt;
@override final  int syncVersion;
@override final  DataSource source;

/// Create a copy of InvestmentTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvestmentTransactionCopyWith<_InvestmentTransaction> get copyWith => __$InvestmentTransactionCopyWithImpl<_InvestmentTransaction>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvestmentTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.securityId, securityId) || other.securityId == securityId)&&(identical(other.date, date) || other.date == date)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.subtype, subtype) || other.subtype == subtype)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.price, price) || other.price == price)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.fees, fees) || other.fees == fees)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.syncVersion, syncVersion) || other.syncVersion == syncVersion)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,accountId,securityId,date,name,type,subtype,quantity,price,amount,fees,deletedAt,syncVersion,source);
}

@override
String toString() {
    return 'InvestmentTransaction(id: $id, accountId: $accountId, securityId: $securityId, date: $date, name: $name, type: $type, subtype: $subtype, quantity: $quantity, price: $price, amount: $amount, fees: $fees, deletedAt: $deletedAt, syncVersion: $syncVersion, source: $source)';
}


}

/// @nodoc
abstract mixin class _$InvestmentTransactionCopyWith<$Res> implements $InvestmentTransactionCopyWith<$Res> {
  factory _$InvestmentTransactionCopyWith(_InvestmentTransaction value, $Res Function(_InvestmentTransaction) _then) = __$InvestmentTransactionCopyWithImpl;
@override @useResult
$Res call({
 String id, String accountId, String? securityId, LocalDate date, String name, String type, String? subtype, Decimal quantity, Decimal price, Money amount, Money? fees, DateTime? deletedAt, int syncVersion, DataSource source
});




}
/// @nodoc
class __$InvestmentTransactionCopyWithImpl<$Res>
    implements _$InvestmentTransactionCopyWith<$Res> {
  __$InvestmentTransactionCopyWithImpl(this._self, this._then);

  final _InvestmentTransaction _self;
  final $Res Function(_InvestmentTransaction) _then;

/// Create a copy of InvestmentTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? accountId = null,Object? securityId = freezed,Object? date = null,Object? name = null,Object? type = null,Object? subtype = freezed,Object? quantity = null,Object? price = null,Object? amount = null,Object? fees = freezed,Object? deletedAt = freezed,Object? syncVersion = null,Object? source = null,}) {
  return _then(_InvestmentTransaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,securityId: freezed == securityId ? _self.securityId : securityId // ignore: cast_nullable_to_non_nullable
as String?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,subtype: freezed == subtype ? _self.subtype : subtype // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as Decimal,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as Decimal,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,fees: freezed == fees ? _self.fees : fees // ignore: cast_nullable_to_non_nullable
as Money?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,syncVersion: null == syncVersion ? _self.syncVersion : syncVersion // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DataSource,
  ));
}


}

// dart format on
