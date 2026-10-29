// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'security.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Security {

 String get id; String? get name; String? get tickerSymbol; String? get type; bool? get isCashEquivalent; Decimal? get closePrice; LocalDate? get closePriceAsOf; String get currencyCode; DataSource get source;
/// Create a copy of Security
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecurityCopyWith<Security> get copyWith => _$SecurityCopyWithImpl<Security>(this as Security, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Security;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Security&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.tickerSymbol, _this.tickerSymbol) || other.tickerSymbol == _this.tickerSymbol)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.isCashEquivalent, _this.isCashEquivalent) || other.isCashEquivalent == _this.isCashEquivalent)&&(identical(other.closePrice, _this.closePrice) || other.closePrice == _this.closePrice)&&(identical(other.closePriceAsOf, _this.closePriceAsOf) || other.closePriceAsOf == _this.closePriceAsOf)&&(identical(other.currencyCode, _this.currencyCode) || other.currencyCode == _this.currencyCode)&&(identical(other.source, _this.source) || other.source == _this.source));
}


@override
int get hashCode {
  final _this = this as Security;
  return Object.hash(runtimeType,_this.id,_this.name,_this.tickerSymbol,_this.type,_this.isCashEquivalent,_this.closePrice,_this.closePriceAsOf,_this.currencyCode,_this.source);
}

@override
String toString() {
  final _this = this as Security;
  return 'Security(id: ${_this.id}, name: ${_this.name}, tickerSymbol: ${_this.tickerSymbol}, type: ${_this.type}, isCashEquivalent: ${_this.isCashEquivalent}, closePrice: ${_this.closePrice}, closePriceAsOf: ${_this.closePriceAsOf}, currencyCode: ${_this.currencyCode}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $SecurityCopyWith<$Res>  {
  factory $SecurityCopyWith(Security value, $Res Function(Security) _then) = _$SecurityCopyWithImpl;
@useResult
$Res call({
 String id, String? name, String? tickerSymbol, String? type, bool? isCashEquivalent, Decimal? closePrice, LocalDate? closePriceAsOf, String currencyCode, DataSource source
});




}
/// @nodoc
class _$SecurityCopyWithImpl<$Res>
    implements $SecurityCopyWith<$Res> {
  _$SecurityCopyWithImpl(this._self, this._then);

  final Security _self;
  final $Res Function(Security) _then;

/// Create a copy of Security
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? tickerSymbol = freezed,Object? type = freezed,Object? isCashEquivalent = freezed,Object? closePrice = freezed,Object? closePriceAsOf = freezed,Object? currencyCode = null,Object? source = null,}) {
  return _then(Security(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,tickerSymbol: freezed == tickerSymbol ? _self.tickerSymbol : tickerSymbol // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,isCashEquivalent: freezed == isCashEquivalent ? _self.isCashEquivalent : isCashEquivalent // ignore: cast_nullable_to_non_nullable
as bool?,closePrice: freezed == closePrice ? _self.closePrice : closePrice // ignore: cast_nullable_to_non_nullable
as Decimal?,closePriceAsOf: freezed == closePriceAsOf ? _self.closePriceAsOf : closePriceAsOf // ignore: cast_nullable_to_non_nullable
as LocalDate?,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DataSource,
  ));
}

}


/// Adds pattern-matching-related methods to [Security].
extension SecurityPatterns on Security {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Security value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Security() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Security value)  $default,){
final _that = this;
switch (_that) {
case _Security():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Security value)?  $default,){
final _that = this;
switch (_that) {
case _Security() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? name,  String? tickerSymbol,  String? type,  bool? isCashEquivalent,  Decimal? closePrice,  LocalDate? closePriceAsOf,  String currencyCode,  DataSource source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Security() when $default != null:
return $default(_that.id,_that.name,_that.tickerSymbol,_that.type,_that.isCashEquivalent,_that.closePrice,_that.closePriceAsOf,_that.currencyCode,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? name,  String? tickerSymbol,  String? type,  bool? isCashEquivalent,  Decimal? closePrice,  LocalDate? closePriceAsOf,  String currencyCode,  DataSource source)  $default,) {final _that = this;
switch (_that) {
case _Security():
return $default(_that.id,_that.name,_that.tickerSymbol,_that.type,_that.isCashEquivalent,_that.closePrice,_that.closePriceAsOf,_that.currencyCode,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? name,  String? tickerSymbol,  String? type,  bool? isCashEquivalent,  Decimal? closePrice,  LocalDate? closePriceAsOf,  String currencyCode,  DataSource source)?  $default,) {final _that = this;
switch (_that) {
case _Security() when $default != null:
return $default(_that.id,_that.name,_that.tickerSymbol,_that.type,_that.isCashEquivalent,_that.closePrice,_that.closePriceAsOf,_that.currencyCode,_that.source);case _:
  return null;

}
}

}

/// @nodoc


class _Security implements Security {
  const _Security({required this.id, this.name, this.tickerSymbol, this.type, this.isCashEquivalent, this.closePrice, this.closePriceAsOf, required this.currencyCode, required this.source});
  

@override final  String id;
@override final  String? name;
@override final  String? tickerSymbol;
@override final  String? type;
@override final  bool? isCashEquivalent;
@override final  Decimal? closePrice;
@override final  LocalDate? closePriceAsOf;
@override final  String currencyCode;
@override final  DataSource source;

/// Create a copy of Security
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SecurityCopyWith<_Security> get copyWith => __$SecurityCopyWithImpl<_Security>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Security&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.tickerSymbol, tickerSymbol) || other.tickerSymbol == tickerSymbol)&&(identical(other.type, type) || other.type == type)&&(identical(other.isCashEquivalent, isCashEquivalent) || other.isCashEquivalent == isCashEquivalent)&&(identical(other.closePrice, closePrice) || other.closePrice == closePrice)&&(identical(other.closePriceAsOf, closePriceAsOf) || other.closePriceAsOf == closePriceAsOf)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,tickerSymbol,type,isCashEquivalent,closePrice,closePriceAsOf,currencyCode,source);
}

@override
String toString() {
    return 'Security(id: $id, name: $name, tickerSymbol: $tickerSymbol, type: $type, isCashEquivalent: $isCashEquivalent, closePrice: $closePrice, closePriceAsOf: $closePriceAsOf, currencyCode: $currencyCode, source: $source)';
}


}

/// @nodoc
abstract mixin class _$SecurityCopyWith<$Res> implements $SecurityCopyWith<$Res> {
  factory _$SecurityCopyWith(_Security value, $Res Function(_Security) _then) = __$SecurityCopyWithImpl;
@override @useResult
$Res call({
 String id, String? name, String? tickerSymbol, String? type, bool? isCashEquivalent, Decimal? closePrice, LocalDate? closePriceAsOf, String currencyCode, DataSource source
});




}
/// @nodoc
class __$SecurityCopyWithImpl<$Res>
    implements _$SecurityCopyWith<$Res> {
  __$SecurityCopyWithImpl(this._self, this._then);

  final _Security _self;
  final $Res Function(_Security) _then;

/// Create a copy of Security
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? tickerSymbol = freezed,Object? type = freezed,Object? isCashEquivalent = freezed,Object? closePrice = freezed,Object? closePriceAsOf = freezed,Object? currencyCode = null,Object? source = null,}) {
  return _then(_Security(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,tickerSymbol: freezed == tickerSymbol ? _self.tickerSymbol : tickerSymbol // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,isCashEquivalent: freezed == isCashEquivalent ? _self.isCashEquivalent : isCashEquivalent // ignore: cast_nullable_to_non_nullable
as bool?,closePrice: freezed == closePrice ? _self.closePrice : closePrice // ignore: cast_nullable_to_non_nullable
as Decimal?,closePriceAsOf: freezed == closePriceAsOf ? _self.closePriceAsOf : closePriceAsOf // ignore: cast_nullable_to_non_nullable
as LocalDate?,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DataSource,
  ));
}


}

// dart format on
