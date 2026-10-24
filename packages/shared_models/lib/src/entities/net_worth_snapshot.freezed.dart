// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'net_worth_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NetWorthSnapshot {

 LocalDate get date; Money get assets; Money get liabilities; Map<String, Money> get byAccount; DataSource get source;
/// Create a copy of NetWorthSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetWorthSnapshotCopyWith<NetWorthSnapshot> get copyWith => _$NetWorthSnapshotCopyWithImpl<NetWorthSnapshot>(this as NetWorthSnapshot, _$identity);

  /// Serializes this NetWorthSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NetWorthSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetWorthSnapshot&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.assets, _this.assets) || other.assets == _this.assets)&&(identical(other.liabilities, _this.liabilities) || other.liabilities == _this.liabilities)&&const DeepCollectionEquality().equals(other.byAccount, _this.byAccount)&&(identical(other.source, _this.source) || other.source == _this.source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NetWorthSnapshot;
  return Object.hash(runtimeType,_this.date,_this.assets,_this.liabilities,const DeepCollectionEquality().hash(_this.byAccount),_this.source);
}

@override
String toString() {
  final _this = this as NetWorthSnapshot;
  return 'NetWorthSnapshot(date: ${_this.date}, assets: ${_this.assets}, liabilities: ${_this.liabilities}, byAccount: ${_this.byAccount}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $NetWorthSnapshotCopyWith<$Res>  {
  factory $NetWorthSnapshotCopyWith(NetWorthSnapshot value, $Res Function(NetWorthSnapshot) _then) = _$NetWorthSnapshotCopyWithImpl;
@useResult
$Res call({
 LocalDate date, Money assets, Money liabilities, Map<String, Money> byAccount, DataSource source
});




}
/// @nodoc
class _$NetWorthSnapshotCopyWithImpl<$Res>
    implements $NetWorthSnapshotCopyWith<$Res> {
  _$NetWorthSnapshotCopyWithImpl(this._self, this._then);

  final NetWorthSnapshot _self;
  final $Res Function(NetWorthSnapshot) _then;

/// Create a copy of NetWorthSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? assets = null,Object? liabilities = null,Object? byAccount = null,Object? source = null,}) {
  return _then(NetWorthSnapshot(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,assets: null == assets ? _self.assets : assets // ignore: cast_nullable_to_non_nullable
as Money,liabilities: null == liabilities ? _self.liabilities : liabilities // ignore: cast_nullable_to_non_nullable
as Money,byAccount: null == byAccount ? _self.byAccount : byAccount // ignore: cast_nullable_to_non_nullable
as Map<String, Money>,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DataSource,
  ));
}

}


/// Adds pattern-matching-related methods to [NetWorthSnapshot].
extension NetWorthSnapshotPatterns on NetWorthSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NetWorthSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NetWorthSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NetWorthSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _NetWorthSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NetWorthSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _NetWorthSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LocalDate date,  Money assets,  Money liabilities,  Map<String, Money> byAccount,  DataSource source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NetWorthSnapshot() when $default != null:
return $default(_that.date,_that.assets,_that.liabilities,_that.byAccount,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LocalDate date,  Money assets,  Money liabilities,  Map<String, Money> byAccount,  DataSource source)  $default,) {final _that = this;
switch (_that) {
case _NetWorthSnapshot():
return $default(_that.date,_that.assets,_that.liabilities,_that.byAccount,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LocalDate date,  Money assets,  Money liabilities,  Map<String, Money> byAccount,  DataSource source)?  $default,) {final _that = this;
switch (_that) {
case _NetWorthSnapshot() when $default != null:
return $default(_that.date,_that.assets,_that.liabilities,_that.byAccount,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NetWorthSnapshot implements NetWorthSnapshot {
  const _NetWorthSnapshot({required this.date, required this.assets, required this.liabilities, required  Map<String, Money> byAccount, required this.source}): _byAccount = byAccount;
  factory _NetWorthSnapshot.fromJson(Map<String, dynamic> json) => _$NetWorthSnapshotFromJson(json);

@override final  LocalDate date;
@override final  Money assets;
@override final  Money liabilities;
 final  Map<String, Money> _byAccount;
@override Map<String, Money> get byAccount {
  if (_byAccount is EqualUnmodifiableMapView) return _byAccount;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_byAccount);
}

@override final  DataSource source;

/// Create a copy of NetWorthSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetWorthSnapshotCopyWith<_NetWorthSnapshot> get copyWith => __$NetWorthSnapshotCopyWithImpl<_NetWorthSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NetWorthSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetWorthSnapshot&&(identical(other.date, date) || other.date == date)&&(identical(other.assets, assets) || other.assets == assets)&&(identical(other.liabilities, liabilities) || other.liabilities == liabilities)&&const DeepCollectionEquality().equals(other.byAccount, _byAccount)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,date,assets,liabilities,const DeepCollectionEquality().hash(_byAccount),source);
}

@override
String toString() {
    return 'NetWorthSnapshot(date: $date, assets: $assets, liabilities: $liabilities, byAccount: $byAccount, source: $source)';
}


}

/// @nodoc
abstract mixin class _$NetWorthSnapshotCopyWith<$Res> implements $NetWorthSnapshotCopyWith<$Res> {
  factory _$NetWorthSnapshotCopyWith(_NetWorthSnapshot value, $Res Function(_NetWorthSnapshot) _then) = __$NetWorthSnapshotCopyWithImpl;
@override @useResult
$Res call({
 LocalDate date, Money assets, Money liabilities, Map<String, Money> byAccount, DataSource source
});




}
/// @nodoc
class __$NetWorthSnapshotCopyWithImpl<$Res>
    implements _$NetWorthSnapshotCopyWith<$Res> {
  __$NetWorthSnapshotCopyWithImpl(this._self, this._then);

  final _NetWorthSnapshot _self;
  final $Res Function(_NetWorthSnapshot) _then;

/// Create a copy of NetWorthSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? assets = null,Object? liabilities = null,Object? byAccount = null,Object? source = null,}) {
  return _then(_NetWorthSnapshot(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,assets: null == assets ? _self.assets : assets // ignore: cast_nullable_to_non_nullable
as Money,liabilities: null == liabilities ? _self.liabilities : liabilities // ignore: cast_nullable_to_non_nullable
as Money,byAccount: null == byAccount ? _self._byAccount : byAccount // ignore: cast_nullable_to_non_nullable
as Map<String, Money>,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DataSource,
  ));
}


}

// dart format on
