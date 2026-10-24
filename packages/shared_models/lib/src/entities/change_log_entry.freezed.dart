// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'change_log_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChangeLogEntry {

 EntityType get entityType; String get entityId; ChangeOperation get operation; Map<String, dynamic> get payload;@HlcConverter() Hlc get hlc; String get deviceId; bool get synced;
/// Create a copy of ChangeLogEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChangeLogEntryCopyWith<ChangeLogEntry> get copyWith => _$ChangeLogEntryCopyWithImpl<ChangeLogEntry>(this as ChangeLogEntry, _$identity);

  /// Serializes this ChangeLogEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChangeLogEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangeLogEntry&&(identical(other.entityType, _this.entityType) || other.entityType == _this.entityType)&&(identical(other.entityId, _this.entityId) || other.entityId == _this.entityId)&&(identical(other.operation, _this.operation) || other.operation == _this.operation)&&const DeepCollectionEquality().equals(other.payload, _this.payload)&&(identical(other.hlc, _this.hlc) || other.hlc == _this.hlc)&&(identical(other.deviceId, _this.deviceId) || other.deviceId == _this.deviceId)&&(identical(other.synced, _this.synced) || other.synced == _this.synced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChangeLogEntry;
  return Object.hash(runtimeType,_this.entityType,_this.entityId,_this.operation,const DeepCollectionEquality().hash(_this.payload),_this.hlc,_this.deviceId,_this.synced);
}

@override
String toString() {
  final _this = this as ChangeLogEntry;
  return 'ChangeLogEntry(entityType: ${_this.entityType}, entityId: ${_this.entityId}, operation: ${_this.operation}, payload: ${_this.payload}, hlc: ${_this.hlc}, deviceId: ${_this.deviceId}, synced: ${_this.synced})';
}


}

/// @nodoc
abstract mixin class $ChangeLogEntryCopyWith<$Res>  {
  factory $ChangeLogEntryCopyWith(ChangeLogEntry value, $Res Function(ChangeLogEntry) _then) = _$ChangeLogEntryCopyWithImpl;
@useResult
$Res call({
 EntityType entityType, String entityId, ChangeOperation operation, Map<String, dynamic> payload,@HlcConverter() Hlc hlc, String deviceId, bool synced
});




}
/// @nodoc
class _$ChangeLogEntryCopyWithImpl<$Res>
    implements $ChangeLogEntryCopyWith<$Res> {
  _$ChangeLogEntryCopyWithImpl(this._self, this._then);

  final ChangeLogEntry _self;
  final $Res Function(ChangeLogEntry) _then;

/// Create a copy of ChangeLogEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entityType = null,Object? entityId = null,Object? operation = null,Object? payload = null,Object? hlc = null,Object? deviceId = null,Object? synced = null,}) {
  return _then(ChangeLogEntry(
entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as ChangeOperation,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,hlc: null == hlc ? _self.hlc : hlc // ignore: cast_nullable_to_non_nullable
as Hlc,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,synced: null == synced ? _self.synced : synced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChangeLogEntry].
extension ChangeLogEntryPatterns on ChangeLogEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChangeLogEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChangeLogEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChangeLogEntry value)  $default,){
final _that = this;
switch (_that) {
case _ChangeLogEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChangeLogEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ChangeLogEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EntityType entityType,  String entityId,  ChangeOperation operation,  Map<String, dynamic> payload, @HlcConverter()  Hlc hlc,  String deviceId,  bool synced)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChangeLogEntry() when $default != null:
return $default(_that.entityType,_that.entityId,_that.operation,_that.payload,_that.hlc,_that.deviceId,_that.synced);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EntityType entityType,  String entityId,  ChangeOperation operation,  Map<String, dynamic> payload, @HlcConverter()  Hlc hlc,  String deviceId,  bool synced)  $default,) {final _that = this;
switch (_that) {
case _ChangeLogEntry():
return $default(_that.entityType,_that.entityId,_that.operation,_that.payload,_that.hlc,_that.deviceId,_that.synced);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EntityType entityType,  String entityId,  ChangeOperation operation,  Map<String, dynamic> payload, @HlcConverter()  Hlc hlc,  String deviceId,  bool synced)?  $default,) {final _that = this;
switch (_that) {
case _ChangeLogEntry() when $default != null:
return $default(_that.entityType,_that.entityId,_that.operation,_that.payload,_that.hlc,_that.deviceId,_that.synced);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChangeLogEntry implements ChangeLogEntry {
  const _ChangeLogEntry({required this.entityType, required this.entityId, required this.operation, required  Map<String, dynamic> payload, @HlcConverter() required this.hlc, required this.deviceId, required this.synced}): _payload = payload;
  factory _ChangeLogEntry.fromJson(Map<String, dynamic> json) => _$ChangeLogEntryFromJson(json);

@override final  EntityType entityType;
@override final  String entityId;
@override final  ChangeOperation operation;
 final  Map<String, dynamic> _payload;
@override Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

@override@HlcConverter() final  Hlc hlc;
@override final  String deviceId;
@override final  bool synced;

/// Create a copy of ChangeLogEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChangeLogEntryCopyWith<_ChangeLogEntry> get copyWith => __$ChangeLogEntryCopyWithImpl<_ChangeLogEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChangeLogEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChangeLogEntry&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.operation, operation) || other.operation == operation)&&const DeepCollectionEquality().equals(other.payload, _payload)&&(identical(other.hlc, hlc) || other.hlc == hlc)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.synced, synced) || other.synced == synced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,entityType,entityId,operation,const DeepCollectionEquality().hash(_payload),hlc,deviceId,synced);
}

@override
String toString() {
    return 'ChangeLogEntry(entityType: $entityType, entityId: $entityId, operation: $operation, payload: $payload, hlc: $hlc, deviceId: $deviceId, synced: $synced)';
}


}

/// @nodoc
abstract mixin class _$ChangeLogEntryCopyWith<$Res> implements $ChangeLogEntryCopyWith<$Res> {
  factory _$ChangeLogEntryCopyWith(_ChangeLogEntry value, $Res Function(_ChangeLogEntry) _then) = __$ChangeLogEntryCopyWithImpl;
@override @useResult
$Res call({
 EntityType entityType, String entityId, ChangeOperation operation, Map<String, dynamic> payload,@HlcConverter() Hlc hlc, String deviceId, bool synced
});




}
/// @nodoc
class __$ChangeLogEntryCopyWithImpl<$Res>
    implements _$ChangeLogEntryCopyWith<$Res> {
  __$ChangeLogEntryCopyWithImpl(this._self, this._then);

  final _ChangeLogEntry _self;
  final $Res Function(_ChangeLogEntry) _then;

/// Create a copy of ChangeLogEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entityType = null,Object? entityId = null,Object? operation = null,Object? payload = null,Object? hlc = null,Object? deviceId = null,Object? synced = null,}) {
  return _then(_ChangeLogEntry(
entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as ChangeOperation,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,hlc: null == hlc ? _self.hlc : hlc // ignore: cast_nullable_to_non_nullable
as Hlc,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,synced: null == synced ? _self.synced : synced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
