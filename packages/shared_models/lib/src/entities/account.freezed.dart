// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Account {

 String get id; String? get itemId;@JsonKey(unknownEnumValue: AccountType.other) AccountType get type; String? get subtype; String get name; String? get officialName; String? get mask; String get currencyCode; Money? get currentBalance; Money? get availableBalance; Money? get creditLimit;@UtcInstantConverter() DateTime? get balancesAsOf; bool get isHidden; int get displayOrder;
/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountCopyWith<Account> get copyWith => _$AccountCopyWithImpl<Account>(this as Account, _$identity);

  /// Serializes this Account to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Account;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Account&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.itemId, _this.itemId) || other.itemId == _this.itemId)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.subtype, _this.subtype) || other.subtype == _this.subtype)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.officialName, _this.officialName) || other.officialName == _this.officialName)&&(identical(other.mask, _this.mask) || other.mask == _this.mask)&&(identical(other.currencyCode, _this.currencyCode) || other.currencyCode == _this.currencyCode)&&(identical(other.currentBalance, _this.currentBalance) || other.currentBalance == _this.currentBalance)&&(identical(other.availableBalance, _this.availableBalance) || other.availableBalance == _this.availableBalance)&&(identical(other.creditLimit, _this.creditLimit) || other.creditLimit == _this.creditLimit)&&(identical(other.balancesAsOf, _this.balancesAsOf) || other.balancesAsOf == _this.balancesAsOf)&&(identical(other.isHidden, _this.isHidden) || other.isHidden == _this.isHidden)&&(identical(other.displayOrder, _this.displayOrder) || other.displayOrder == _this.displayOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Account;
  return Object.hash(runtimeType,_this.id,_this.itemId,_this.type,_this.subtype,_this.name,_this.officialName,_this.mask,_this.currencyCode,_this.currentBalance,_this.availableBalance,_this.creditLimit,_this.balancesAsOf,_this.isHidden,_this.displayOrder);
}

@override
String toString() {
  final _this = this as Account;
  return 'Account(id: ${_this.id}, itemId: ${_this.itemId}, type: ${_this.type}, subtype: ${_this.subtype}, name: ${_this.name}, officialName: ${_this.officialName}, mask: ${_this.mask}, currencyCode: ${_this.currencyCode}, currentBalance: ${_this.currentBalance}, availableBalance: ${_this.availableBalance}, creditLimit: ${_this.creditLimit}, balancesAsOf: ${_this.balancesAsOf}, isHidden: ${_this.isHidden}, displayOrder: ${_this.displayOrder})';
}


}

/// @nodoc
abstract mixin class $AccountCopyWith<$Res>  {
  factory $AccountCopyWith(Account value, $Res Function(Account) _then) = _$AccountCopyWithImpl;
@useResult
$Res call({
 String id, String? itemId,@JsonKey(unknownEnumValue: AccountType.other) AccountType type, String? subtype, String name, String? officialName, String? mask, String currencyCode, Money? currentBalance, Money? availableBalance, Money? creditLimit,@UtcInstantConverter() DateTime? balancesAsOf, bool isHidden, int displayOrder
});




}
/// @nodoc
class _$AccountCopyWithImpl<$Res>
    implements $AccountCopyWith<$Res> {
  _$AccountCopyWithImpl(this._self, this._then);

  final Account _self;
  final $Res Function(Account) _then;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? itemId = freezed,Object? type = null,Object? subtype = freezed,Object? name = null,Object? officialName = freezed,Object? mask = freezed,Object? currencyCode = null,Object? currentBalance = freezed,Object? availableBalance = freezed,Object? creditLimit = freezed,Object? balancesAsOf = freezed,Object? isHidden = null,Object? displayOrder = null,}) {
  return _then(Account(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,itemId: freezed == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AccountType,subtype: freezed == subtype ? _self.subtype : subtype // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,officialName: freezed == officialName ? _self.officialName : officialName // ignore: cast_nullable_to_non_nullable
as String?,mask: freezed == mask ? _self.mask : mask // ignore: cast_nullable_to_non_nullable
as String?,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,currentBalance: freezed == currentBalance ? _self.currentBalance : currentBalance // ignore: cast_nullable_to_non_nullable
as Money?,availableBalance: freezed == availableBalance ? _self.availableBalance : availableBalance // ignore: cast_nullable_to_non_nullable
as Money?,creditLimit: freezed == creditLimit ? _self.creditLimit : creditLimit // ignore: cast_nullable_to_non_nullable
as Money?,balancesAsOf: freezed == balancesAsOf ? _self.balancesAsOf : balancesAsOf // ignore: cast_nullable_to_non_nullable
as DateTime?,isHidden: null == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Account].
extension AccountPatterns on Account {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Account value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Account() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Account value)  $default,){
final _that = this;
switch (_that) {
case _Account():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Account value)?  $default,){
final _that = this;
switch (_that) {
case _Account() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? itemId, @JsonKey(unknownEnumValue: AccountType.other)  AccountType type,  String? subtype,  String name,  String? officialName,  String? mask,  String currencyCode,  Money? currentBalance,  Money? availableBalance,  Money? creditLimit, @UtcInstantConverter()  DateTime? balancesAsOf,  bool isHidden,  int displayOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Account() when $default != null:
return $default(_that.id,_that.itemId,_that.type,_that.subtype,_that.name,_that.officialName,_that.mask,_that.currencyCode,_that.currentBalance,_that.availableBalance,_that.creditLimit,_that.balancesAsOf,_that.isHidden,_that.displayOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? itemId, @JsonKey(unknownEnumValue: AccountType.other)  AccountType type,  String? subtype,  String name,  String? officialName,  String? mask,  String currencyCode,  Money? currentBalance,  Money? availableBalance,  Money? creditLimit, @UtcInstantConverter()  DateTime? balancesAsOf,  bool isHidden,  int displayOrder)  $default,) {final _that = this;
switch (_that) {
case _Account():
return $default(_that.id,_that.itemId,_that.type,_that.subtype,_that.name,_that.officialName,_that.mask,_that.currencyCode,_that.currentBalance,_that.availableBalance,_that.creditLimit,_that.balancesAsOf,_that.isHidden,_that.displayOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? itemId, @JsonKey(unknownEnumValue: AccountType.other)  AccountType type,  String? subtype,  String name,  String? officialName,  String? mask,  String currencyCode,  Money? currentBalance,  Money? availableBalance,  Money? creditLimit, @UtcInstantConverter()  DateTime? balancesAsOf,  bool isHidden,  int displayOrder)?  $default,) {final _that = this;
switch (_that) {
case _Account() when $default != null:
return $default(_that.id,_that.itemId,_that.type,_that.subtype,_that.name,_that.officialName,_that.mask,_that.currencyCode,_that.currentBalance,_that.availableBalance,_that.creditLimit,_that.balancesAsOf,_that.isHidden,_that.displayOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Account implements Account {
  const _Account({required this.id, this.itemId, @JsonKey(unknownEnumValue: AccountType.other) required this.type, this.subtype, required this.name, this.officialName, this.mask, required this.currencyCode, this.currentBalance, this.availableBalance, this.creditLimit, @UtcInstantConverter() this.balancesAsOf, required this.isHidden, required this.displayOrder});
  factory _Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);

@override final  String id;
@override final  String? itemId;
@override@JsonKey(unknownEnumValue: AccountType.other) final  AccountType type;
@override final  String? subtype;
@override final  String name;
@override final  String? officialName;
@override final  String? mask;
@override final  String currencyCode;
@override final  Money? currentBalance;
@override final  Money? availableBalance;
@override final  Money? creditLimit;
@override@UtcInstantConverter() final  DateTime? balancesAsOf;
@override final  bool isHidden;
@override final  int displayOrder;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountCopyWith<_Account> get copyWith => __$AccountCopyWithImpl<_Account>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccountToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Account&&(identical(other.id, id) || other.id == id)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.type, type) || other.type == type)&&(identical(other.subtype, subtype) || other.subtype == subtype)&&(identical(other.name, name) || other.name == name)&&(identical(other.officialName, officialName) || other.officialName == officialName)&&(identical(other.mask, mask) || other.mask == mask)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.currentBalance, currentBalance) || other.currentBalance == currentBalance)&&(identical(other.availableBalance, availableBalance) || other.availableBalance == availableBalance)&&(identical(other.creditLimit, creditLimit) || other.creditLimit == creditLimit)&&(identical(other.balancesAsOf, balancesAsOf) || other.balancesAsOf == balancesAsOf)&&(identical(other.isHidden, isHidden) || other.isHidden == isHidden)&&(identical(other.displayOrder, displayOrder) || other.displayOrder == displayOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,itemId,type,subtype,name,officialName,mask,currencyCode,currentBalance,availableBalance,creditLimit,balancesAsOf,isHidden,displayOrder);
}

@override
String toString() {
    return 'Account(id: $id, itemId: $itemId, type: $type, subtype: $subtype, name: $name, officialName: $officialName, mask: $mask, currencyCode: $currencyCode, currentBalance: $currentBalance, availableBalance: $availableBalance, creditLimit: $creditLimit, balancesAsOf: $balancesAsOf, isHidden: $isHidden, displayOrder: $displayOrder)';
}


}

/// @nodoc
abstract mixin class _$AccountCopyWith<$Res> implements $AccountCopyWith<$Res> {
  factory _$AccountCopyWith(_Account value, $Res Function(_Account) _then) = __$AccountCopyWithImpl;
@override @useResult
$Res call({
 String id, String? itemId,@JsonKey(unknownEnumValue: AccountType.other) AccountType type, String? subtype, String name, String? officialName, String? mask, String currencyCode, Money? currentBalance, Money? availableBalance, Money? creditLimit,@UtcInstantConverter() DateTime? balancesAsOf, bool isHidden, int displayOrder
});




}
/// @nodoc
class __$AccountCopyWithImpl<$Res>
    implements _$AccountCopyWith<$Res> {
  __$AccountCopyWithImpl(this._self, this._then);

  final _Account _self;
  final $Res Function(_Account) _then;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? itemId = freezed,Object? type = null,Object? subtype = freezed,Object? name = null,Object? officialName = freezed,Object? mask = freezed,Object? currencyCode = null,Object? currentBalance = freezed,Object? availableBalance = freezed,Object? creditLimit = freezed,Object? balancesAsOf = freezed,Object? isHidden = null,Object? displayOrder = null,}) {
  return _then(_Account(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,itemId: freezed == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AccountType,subtype: freezed == subtype ? _self.subtype : subtype // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,officialName: freezed == officialName ? _self.officialName : officialName // ignore: cast_nullable_to_non_nullable
as String?,mask: freezed == mask ? _self.mask : mask // ignore: cast_nullable_to_non_nullable
as String?,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,currentBalance: freezed == currentBalance ? _self.currentBalance : currentBalance // ignore: cast_nullable_to_non_nullable
as Money?,availableBalance: freezed == availableBalance ? _self.availableBalance : availableBalance // ignore: cast_nullable_to_non_nullable
as Money?,creditLimit: freezed == creditLimit ? _self.creditLimit : creditLimit // ignore: cast_nullable_to_non_nullable
as Money?,balancesAsOf: freezed == balancesAsOf ? _self.balancesAsOf : balancesAsOf // ignore: cast_nullable_to_non_nullable
as DateTime?,isHidden: null == isHidden ? _self.isHidden : isHidden // ignore: cast_nullable_to_non_nullable
as bool,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
