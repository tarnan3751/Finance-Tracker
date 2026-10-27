// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_stream.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecurringStream {

 String get id; String get accountId; String get merchantName;@JsonKey(unknownEnumValue: RecurringCadence.unknown) RecurringCadence get cadence; Money get averageAmount; LocalDate? get lastExpected; LocalDate? get nextExpected; RecurringStatus get status; bool get isSubscription; RecurringSource get source; List<String> get transactionIds;
/// Create a copy of RecurringStream
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringStreamCopyWith<RecurringStream> get copyWith => _$RecurringStreamCopyWithImpl<RecurringStream>(this as RecurringStream, _$identity);

  /// Serializes this RecurringStream to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RecurringStream;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringStream&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.merchantName, _this.merchantName) || other.merchantName == _this.merchantName)&&(identical(other.cadence, _this.cadence) || other.cadence == _this.cadence)&&(identical(other.averageAmount, _this.averageAmount) || other.averageAmount == _this.averageAmount)&&(identical(other.lastExpected, _this.lastExpected) || other.lastExpected == _this.lastExpected)&&(identical(other.nextExpected, _this.nextExpected) || other.nextExpected == _this.nextExpected)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.isSubscription, _this.isSubscription) || other.isSubscription == _this.isSubscription)&&(identical(other.source, _this.source) || other.source == _this.source)&&const DeepCollectionEquality().equals(other.transactionIds, _this.transactionIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RecurringStream;
  return Object.hash(runtimeType,_this.id,_this.accountId,_this.merchantName,_this.cadence,_this.averageAmount,_this.lastExpected,_this.nextExpected,_this.status,_this.isSubscription,_this.source,const DeepCollectionEquality().hash(_this.transactionIds));
}

@override
String toString() {
  final _this = this as RecurringStream;
  return 'RecurringStream(id: ${_this.id}, accountId: ${_this.accountId}, merchantName: ${_this.merchantName}, cadence: ${_this.cadence}, averageAmount: ${_this.averageAmount}, lastExpected: ${_this.lastExpected}, nextExpected: ${_this.nextExpected}, status: ${_this.status}, isSubscription: ${_this.isSubscription}, source: ${_this.source}, transactionIds: ${_this.transactionIds})';
}


}

/// @nodoc
abstract mixin class $RecurringStreamCopyWith<$Res>  {
  factory $RecurringStreamCopyWith(RecurringStream value, $Res Function(RecurringStream) _then) = _$RecurringStreamCopyWithImpl;
@useResult
$Res call({
 String id, String accountId, String merchantName,@JsonKey(unknownEnumValue: RecurringCadence.unknown) RecurringCadence cadence, Money averageAmount, LocalDate? lastExpected, LocalDate? nextExpected, RecurringStatus status, bool isSubscription, RecurringSource source, List<String> transactionIds
});




}
/// @nodoc
class _$RecurringStreamCopyWithImpl<$Res>
    implements $RecurringStreamCopyWith<$Res> {
  _$RecurringStreamCopyWithImpl(this._self, this._then);

  final RecurringStream _self;
  final $Res Function(RecurringStream) _then;

/// Create a copy of RecurringStream
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? accountId = null,Object? merchantName = null,Object? cadence = null,Object? averageAmount = null,Object? lastExpected = freezed,Object? nextExpected = freezed,Object? status = null,Object? isSubscription = null,Object? source = null,Object? transactionIds = null,}) {
  return _then(RecurringStream(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,merchantName: null == merchantName ? _self.merchantName : merchantName // ignore: cast_nullable_to_non_nullable
as String,cadence: null == cadence ? _self.cadence : cadence // ignore: cast_nullable_to_non_nullable
as RecurringCadence,averageAmount: null == averageAmount ? _self.averageAmount : averageAmount // ignore: cast_nullable_to_non_nullable
as Money,lastExpected: freezed == lastExpected ? _self.lastExpected : lastExpected // ignore: cast_nullable_to_non_nullable
as LocalDate?,nextExpected: freezed == nextExpected ? _self.nextExpected : nextExpected // ignore: cast_nullable_to_non_nullable
as LocalDate?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RecurringStatus,isSubscription: null == isSubscription ? _self.isSubscription : isSubscription // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as RecurringSource,transactionIds: null == transactionIds ? _self.transactionIds : transactionIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [RecurringStream].
extension RecurringStreamPatterns on RecurringStream {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurringStream value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurringStream() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurringStream value)  $default,){
final _that = this;
switch (_that) {
case _RecurringStream():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurringStream value)?  $default,){
final _that = this;
switch (_that) {
case _RecurringStream() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String accountId,  String merchantName, @JsonKey(unknownEnumValue: RecurringCadence.unknown)  RecurringCadence cadence,  Money averageAmount,  LocalDate? lastExpected,  LocalDate? nextExpected,  RecurringStatus status,  bool isSubscription,  RecurringSource source,  List<String> transactionIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurringStream() when $default != null:
return $default(_that.id,_that.accountId,_that.merchantName,_that.cadence,_that.averageAmount,_that.lastExpected,_that.nextExpected,_that.status,_that.isSubscription,_that.source,_that.transactionIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String accountId,  String merchantName, @JsonKey(unknownEnumValue: RecurringCadence.unknown)  RecurringCadence cadence,  Money averageAmount,  LocalDate? lastExpected,  LocalDate? nextExpected,  RecurringStatus status,  bool isSubscription,  RecurringSource source,  List<String> transactionIds)  $default,) {final _that = this;
switch (_that) {
case _RecurringStream():
return $default(_that.id,_that.accountId,_that.merchantName,_that.cadence,_that.averageAmount,_that.lastExpected,_that.nextExpected,_that.status,_that.isSubscription,_that.source,_that.transactionIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String accountId,  String merchantName, @JsonKey(unknownEnumValue: RecurringCadence.unknown)  RecurringCadence cadence,  Money averageAmount,  LocalDate? lastExpected,  LocalDate? nextExpected,  RecurringStatus status,  bool isSubscription,  RecurringSource source,  List<String> transactionIds)?  $default,) {final _that = this;
switch (_that) {
case _RecurringStream() when $default != null:
return $default(_that.id,_that.accountId,_that.merchantName,_that.cadence,_that.averageAmount,_that.lastExpected,_that.nextExpected,_that.status,_that.isSubscription,_that.source,_that.transactionIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecurringStream implements RecurringStream {
  const _RecurringStream({required this.id, required this.accountId, required this.merchantName, @JsonKey(unknownEnumValue: RecurringCadence.unknown) required this.cadence, required this.averageAmount, this.lastExpected, this.nextExpected, required this.status, required this.isSubscription, required this.source,  List<String> transactionIds = const <String>[]}): _transactionIds = transactionIds;
  factory _RecurringStream.fromJson(Map<String, dynamic> json) => _$RecurringStreamFromJson(json);

@override final  String id;
@override final  String accountId;
@override final  String merchantName;
@override@JsonKey(unknownEnumValue: RecurringCadence.unknown) final  RecurringCadence cadence;
@override final  Money averageAmount;
@override final  LocalDate? lastExpected;
@override final  LocalDate? nextExpected;
@override final  RecurringStatus status;
@override final  bool isSubscription;
@override final  RecurringSource source;
 final  List<String> _transactionIds;
@override@JsonKey() List<String> get transactionIds {
  if (_transactionIds is EqualUnmodifiableListView) return _transactionIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transactionIds);
}


/// Create a copy of RecurringStream
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurringStreamCopyWith<_RecurringStream> get copyWith => __$RecurringStreamCopyWithImpl<_RecurringStream>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecurringStreamToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurringStream&&(identical(other.id, id) || other.id == id)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.merchantName, merchantName) || other.merchantName == merchantName)&&(identical(other.cadence, cadence) || other.cadence == cadence)&&(identical(other.averageAmount, averageAmount) || other.averageAmount == averageAmount)&&(identical(other.lastExpected, lastExpected) || other.lastExpected == lastExpected)&&(identical(other.nextExpected, nextExpected) || other.nextExpected == nextExpected)&&(identical(other.status, status) || other.status == status)&&(identical(other.isSubscription, isSubscription) || other.isSubscription == isSubscription)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other.transactionIds, _transactionIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,accountId,merchantName,cadence,averageAmount,lastExpected,nextExpected,status,isSubscription,source,const DeepCollectionEquality().hash(_transactionIds));
}

@override
String toString() {
    return 'RecurringStream(id: $id, accountId: $accountId, merchantName: $merchantName, cadence: $cadence, averageAmount: $averageAmount, lastExpected: $lastExpected, nextExpected: $nextExpected, status: $status, isSubscription: $isSubscription, source: $source, transactionIds: $transactionIds)';
}


}

/// @nodoc
abstract mixin class _$RecurringStreamCopyWith<$Res> implements $RecurringStreamCopyWith<$Res> {
  factory _$RecurringStreamCopyWith(_RecurringStream value, $Res Function(_RecurringStream) _then) = __$RecurringStreamCopyWithImpl;
@override @useResult
$Res call({
 String id, String accountId, String merchantName,@JsonKey(unknownEnumValue: RecurringCadence.unknown) RecurringCadence cadence, Money averageAmount, LocalDate? lastExpected, LocalDate? nextExpected, RecurringStatus status, bool isSubscription, RecurringSource source, List<String> transactionIds
});




}
/// @nodoc
class __$RecurringStreamCopyWithImpl<$Res>
    implements _$RecurringStreamCopyWith<$Res> {
  __$RecurringStreamCopyWithImpl(this._self, this._then);

  final _RecurringStream _self;
  final $Res Function(_RecurringStream) _then;

/// Create a copy of RecurringStream
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? accountId = null,Object? merchantName = null,Object? cadence = null,Object? averageAmount = null,Object? lastExpected = freezed,Object? nextExpected = freezed,Object? status = null,Object? isSubscription = null,Object? source = null,Object? transactionIds = null,}) {
  return _then(_RecurringStream(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,merchantName: null == merchantName ? _self.merchantName : merchantName // ignore: cast_nullable_to_non_nullable
as String,cadence: null == cadence ? _self.cadence : cadence // ignore: cast_nullable_to_non_nullable
as RecurringCadence,averageAmount: null == averageAmount ? _self.averageAmount : averageAmount // ignore: cast_nullable_to_non_nullable
as Money,lastExpected: freezed == lastExpected ? _self.lastExpected : lastExpected // ignore: cast_nullable_to_non_nullable
as LocalDate?,nextExpected: freezed == nextExpected ? _self.nextExpected : nextExpected // ignore: cast_nullable_to_non_nullable
as LocalDate?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RecurringStatus,isSubscription: null == isSubscription ? _self.isSubscription : isSubscription // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as RecurringSource,transactionIds: null == transactionIds ? _self._transactionIds : transactionIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
