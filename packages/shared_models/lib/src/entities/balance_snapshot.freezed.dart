// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'balance_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BalanceSnapshot {

 String get accountId; LocalDate get date; Money get current; Money? get available; Money? get limit; DataSource get source;
/// Create a copy of BalanceSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BalanceSnapshotCopyWith<BalanceSnapshot> get copyWith => _$BalanceSnapshotCopyWithImpl<BalanceSnapshot>(this as BalanceSnapshot, _$identity);

  /// Serializes this BalanceSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BalanceSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BalanceSnapshot&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.current, _this.current) || other.current == _this.current)&&(identical(other.available, _this.available) || other.available == _this.available)&&(identical(other.limit, _this.limit) || other.limit == _this.limit)&&(identical(other.source, _this.source) || other.source == _this.source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BalanceSnapshot;
  return Object.hash(runtimeType,_this.accountId,_this.date,_this.current,_this.available,_this.limit,_this.source);
}

@override
String toString() {
  final _this = this as BalanceSnapshot;
  return 'BalanceSnapshot(accountId: ${_this.accountId}, date: ${_this.date}, current: ${_this.current}, available: ${_this.available}, limit: ${_this.limit}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $BalanceSnapshotCopyWith<$Res>  {
  factory $BalanceSnapshotCopyWith(BalanceSnapshot value, $Res Function(BalanceSnapshot) _then) = _$BalanceSnapshotCopyWithImpl;
@useResult
$Res call({
 String accountId, LocalDate date, Money current, Money? available, Money? limit, DataSource source
});




}
/// @nodoc
class _$BalanceSnapshotCopyWithImpl<$Res>
    implements $BalanceSnapshotCopyWith<$Res> {
  _$BalanceSnapshotCopyWithImpl(this._self, this._then);

  final BalanceSnapshot _self;
  final $Res Function(BalanceSnapshot) _then;

/// Create a copy of BalanceSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountId = null,Object? date = null,Object? current = null,Object? available = freezed,Object? limit = freezed,Object? source = null,}) {
  return _then(BalanceSnapshot(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as Money,available: freezed == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as Money?,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as Money?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DataSource,
  ));
}

}


/// Adds pattern-matching-related methods to [BalanceSnapshot].
extension BalanceSnapshotPatterns on BalanceSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BalanceSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BalanceSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BalanceSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _BalanceSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BalanceSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _BalanceSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accountId,  LocalDate date,  Money current,  Money? available,  Money? limit,  DataSource source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BalanceSnapshot() when $default != null:
return $default(_that.accountId,_that.date,_that.current,_that.available,_that.limit,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accountId,  LocalDate date,  Money current,  Money? available,  Money? limit,  DataSource source)  $default,) {final _that = this;
switch (_that) {
case _BalanceSnapshot():
return $default(_that.accountId,_that.date,_that.current,_that.available,_that.limit,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accountId,  LocalDate date,  Money current,  Money? available,  Money? limit,  DataSource source)?  $default,) {final _that = this;
switch (_that) {
case _BalanceSnapshot() when $default != null:
return $default(_that.accountId,_that.date,_that.current,_that.available,_that.limit,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BalanceSnapshot implements BalanceSnapshot {
  const _BalanceSnapshot({required this.accountId, required this.date, required this.current, this.available, this.limit, required this.source});
  factory _BalanceSnapshot.fromJson(Map<String, dynamic> json) => _$BalanceSnapshotFromJson(json);

@override final  String accountId;
@override final  LocalDate date;
@override final  Money current;
@override final  Money? available;
@override final  Money? limit;
@override final  DataSource source;

/// Create a copy of BalanceSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BalanceSnapshotCopyWith<_BalanceSnapshot> get copyWith => __$BalanceSnapshotCopyWithImpl<_BalanceSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BalanceSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BalanceSnapshot&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.date, date) || other.date == date)&&(identical(other.current, current) || other.current == current)&&(identical(other.available, available) || other.available == available)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,accountId,date,current,available,limit,source);
}

@override
String toString() {
    return 'BalanceSnapshot(accountId: $accountId, date: $date, current: $current, available: $available, limit: $limit, source: $source)';
}


}

/// @nodoc
abstract mixin class _$BalanceSnapshotCopyWith<$Res> implements $BalanceSnapshotCopyWith<$Res> {
  factory _$BalanceSnapshotCopyWith(_BalanceSnapshot value, $Res Function(_BalanceSnapshot) _then) = __$BalanceSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String accountId, LocalDate date, Money current, Money? available, Money? limit, DataSource source
});




}
/// @nodoc
class __$BalanceSnapshotCopyWithImpl<$Res>
    implements _$BalanceSnapshotCopyWith<$Res> {
  __$BalanceSnapshotCopyWithImpl(this._self, this._then);

  final _BalanceSnapshot _self;
  final $Res Function(_BalanceSnapshot) _then;

/// Create a copy of BalanceSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountId = null,Object? date = null,Object? current = null,Object? available = freezed,Object? limit = freezed,Object? source = null,}) {
  return _then(_BalanceSnapshot(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as Money,available: freezed == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as Money?,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as Money?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DataSource,
  ));
}


}

// dart format on
