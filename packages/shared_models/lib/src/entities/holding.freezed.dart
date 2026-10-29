// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'holding.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Holding {

 String get accountId; String get securityId; Decimal get quantity; Decimal get institutionPrice; LocalDate? get institutionPriceAsOf; Money get institutionValue; Money? get costBasis; DataSource get source;
/// Create a copy of Holding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HoldingCopyWith<Holding> get copyWith => _$HoldingCopyWithImpl<Holding>(this as Holding, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Holding;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Holding&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.securityId, _this.securityId) || other.securityId == _this.securityId)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.institutionPrice, _this.institutionPrice) || other.institutionPrice == _this.institutionPrice)&&(identical(other.institutionPriceAsOf, _this.institutionPriceAsOf) || other.institutionPriceAsOf == _this.institutionPriceAsOf)&&(identical(other.institutionValue, _this.institutionValue) || other.institutionValue == _this.institutionValue)&&(identical(other.costBasis, _this.costBasis) || other.costBasis == _this.costBasis)&&(identical(other.source, _this.source) || other.source == _this.source));
}


@override
int get hashCode {
  final _this = this as Holding;
  return Object.hash(runtimeType,_this.accountId,_this.securityId,_this.quantity,_this.institutionPrice,_this.institutionPriceAsOf,_this.institutionValue,_this.costBasis,_this.source);
}

@override
String toString() {
  final _this = this as Holding;
  return 'Holding(accountId: ${_this.accountId}, securityId: ${_this.securityId}, quantity: ${_this.quantity}, institutionPrice: ${_this.institutionPrice}, institutionPriceAsOf: ${_this.institutionPriceAsOf}, institutionValue: ${_this.institutionValue}, costBasis: ${_this.costBasis}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $HoldingCopyWith<$Res>  {
  factory $HoldingCopyWith(Holding value, $Res Function(Holding) _then) = _$HoldingCopyWithImpl;
@useResult
$Res call({
 String accountId, String securityId, Decimal quantity, Decimal institutionPrice, LocalDate? institutionPriceAsOf, Money institutionValue, Money? costBasis, DataSource source
});




}
/// @nodoc
class _$HoldingCopyWithImpl<$Res>
    implements $HoldingCopyWith<$Res> {
  _$HoldingCopyWithImpl(this._self, this._then);

  final Holding _self;
  final $Res Function(Holding) _then;

/// Create a copy of Holding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountId = null,Object? securityId = null,Object? quantity = null,Object? institutionPrice = null,Object? institutionPriceAsOf = freezed,Object? institutionValue = null,Object? costBasis = freezed,Object? source = null,}) {
  return _then(Holding(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,securityId: null == securityId ? _self.securityId : securityId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as Decimal,institutionPrice: null == institutionPrice ? _self.institutionPrice : institutionPrice // ignore: cast_nullable_to_non_nullable
as Decimal,institutionPriceAsOf: freezed == institutionPriceAsOf ? _self.institutionPriceAsOf : institutionPriceAsOf // ignore: cast_nullable_to_non_nullable
as LocalDate?,institutionValue: null == institutionValue ? _self.institutionValue : institutionValue // ignore: cast_nullable_to_non_nullable
as Money,costBasis: freezed == costBasis ? _self.costBasis : costBasis // ignore: cast_nullable_to_non_nullable
as Money?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DataSource,
  ));
}

}


/// Adds pattern-matching-related methods to [Holding].
extension HoldingPatterns on Holding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Holding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Holding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Holding value)  $default,){
final _that = this;
switch (_that) {
case _Holding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Holding value)?  $default,){
final _that = this;
switch (_that) {
case _Holding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accountId,  String securityId,  Decimal quantity,  Decimal institutionPrice,  LocalDate? institutionPriceAsOf,  Money institutionValue,  Money? costBasis,  DataSource source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Holding() when $default != null:
return $default(_that.accountId,_that.securityId,_that.quantity,_that.institutionPrice,_that.institutionPriceAsOf,_that.institutionValue,_that.costBasis,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accountId,  String securityId,  Decimal quantity,  Decimal institutionPrice,  LocalDate? institutionPriceAsOf,  Money institutionValue,  Money? costBasis,  DataSource source)  $default,) {final _that = this;
switch (_that) {
case _Holding():
return $default(_that.accountId,_that.securityId,_that.quantity,_that.institutionPrice,_that.institutionPriceAsOf,_that.institutionValue,_that.costBasis,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accountId,  String securityId,  Decimal quantity,  Decimal institutionPrice,  LocalDate? institutionPriceAsOf,  Money institutionValue,  Money? costBasis,  DataSource source)?  $default,) {final _that = this;
switch (_that) {
case _Holding() when $default != null:
return $default(_that.accountId,_that.securityId,_that.quantity,_that.institutionPrice,_that.institutionPriceAsOf,_that.institutionValue,_that.costBasis,_that.source);case _:
  return null;

}
}

}

/// @nodoc


class _Holding implements Holding {
  const _Holding({required this.accountId, required this.securityId, required this.quantity, required this.institutionPrice, this.institutionPriceAsOf, required this.institutionValue, this.costBasis, required this.source});
  

@override final  String accountId;
@override final  String securityId;
@override final  Decimal quantity;
@override final  Decimal institutionPrice;
@override final  LocalDate? institutionPriceAsOf;
@override final  Money institutionValue;
@override final  Money? costBasis;
@override final  DataSource source;

/// Create a copy of Holding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HoldingCopyWith<_Holding> get copyWith => __$HoldingCopyWithImpl<_Holding>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Holding&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.securityId, securityId) || other.securityId == securityId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.institutionPrice, institutionPrice) || other.institutionPrice == institutionPrice)&&(identical(other.institutionPriceAsOf, institutionPriceAsOf) || other.institutionPriceAsOf == institutionPriceAsOf)&&(identical(other.institutionValue, institutionValue) || other.institutionValue == institutionValue)&&(identical(other.costBasis, costBasis) || other.costBasis == costBasis)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode {
    return Object.hash(runtimeType,accountId,securityId,quantity,institutionPrice,institutionPriceAsOf,institutionValue,costBasis,source);
}

@override
String toString() {
    return 'Holding(accountId: $accountId, securityId: $securityId, quantity: $quantity, institutionPrice: $institutionPrice, institutionPriceAsOf: $institutionPriceAsOf, institutionValue: $institutionValue, costBasis: $costBasis, source: $source)';
}


}

/// @nodoc
abstract mixin class _$HoldingCopyWith<$Res> implements $HoldingCopyWith<$Res> {
  factory _$HoldingCopyWith(_Holding value, $Res Function(_Holding) _then) = __$HoldingCopyWithImpl;
@override @useResult
$Res call({
 String accountId, String securityId, Decimal quantity, Decimal institutionPrice, LocalDate? institutionPriceAsOf, Money institutionValue, Money? costBasis, DataSource source
});




}
/// @nodoc
class __$HoldingCopyWithImpl<$Res>
    implements _$HoldingCopyWith<$Res> {
  __$HoldingCopyWithImpl(this._self, this._then);

  final _Holding _self;
  final $Res Function(_Holding) _then;

/// Create a copy of Holding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountId = null,Object? securityId = null,Object? quantity = null,Object? institutionPrice = null,Object? institutionPriceAsOf = freezed,Object? institutionValue = null,Object? costBasis = freezed,Object? source = null,}) {
  return _then(_Holding(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,securityId: null == securityId ? _self.securityId : securityId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as Decimal,institutionPrice: null == institutionPrice ? _self.institutionPrice : institutionPrice // ignore: cast_nullable_to_non_nullable
as Decimal,institutionPriceAsOf: freezed == institutionPriceAsOf ? _self.institutionPriceAsOf : institutionPriceAsOf // ignore: cast_nullable_to_non_nullable
as LocalDate?,institutionValue: null == institutionValue ? _self.institutionValue : institutionValue // ignore: cast_nullable_to_non_nullable
as Money,costBasis: freezed == costBasis ? _self.costBasis : costBasis // ignore: cast_nullable_to_non_nullable
as Money?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DataSource,
  ));
}


}

// dart format on
