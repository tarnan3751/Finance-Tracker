// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Item {

 String get id; String get institutionId;@JsonKey(unknownEnumValue: ItemStatus.unknown) ItemStatus get status;@UtcInstantConverter() DateTime? get lastSuccessfulSyncAt;
/// Create a copy of Item
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemCopyWith<Item> get copyWith => _$ItemCopyWithImpl<Item>(this as Item, _$identity);

  /// Serializes this Item to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Item;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Item&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.institutionId, _this.institutionId) || other.institutionId == _this.institutionId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.lastSuccessfulSyncAt, _this.lastSuccessfulSyncAt) || other.lastSuccessfulSyncAt == _this.lastSuccessfulSyncAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Item;
  return Object.hash(runtimeType,_this.id,_this.institutionId,_this.status,_this.lastSuccessfulSyncAt);
}

@override
String toString() {
  final _this = this as Item;
  return 'Item(id: ${_this.id}, institutionId: ${_this.institutionId}, status: ${_this.status}, lastSuccessfulSyncAt: ${_this.lastSuccessfulSyncAt})';
}


}

/// @nodoc
abstract mixin class $ItemCopyWith<$Res>  {
  factory $ItemCopyWith(Item value, $Res Function(Item) _then) = _$ItemCopyWithImpl;
@useResult
$Res call({
 String id, String institutionId,@JsonKey(unknownEnumValue: ItemStatus.unknown) ItemStatus status,@UtcInstantConverter() DateTime? lastSuccessfulSyncAt
});




}
/// @nodoc
class _$ItemCopyWithImpl<$Res>
    implements $ItemCopyWith<$Res> {
  _$ItemCopyWithImpl(this._self, this._then);

  final Item _self;
  final $Res Function(Item) _then;

/// Create a copy of Item
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? institutionId = null,Object? status = null,Object? lastSuccessfulSyncAt = freezed,}) {
  return _then(Item(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,institutionId: null == institutionId ? _self.institutionId : institutionId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ItemStatus,lastSuccessfulSyncAt: freezed == lastSuccessfulSyncAt ? _self.lastSuccessfulSyncAt : lastSuccessfulSyncAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Item].
extension ItemPatterns on Item {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Item value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Item() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Item value)  $default,){
final _that = this;
switch (_that) {
case _Item():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Item value)?  $default,){
final _that = this;
switch (_that) {
case _Item() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String institutionId, @JsonKey(unknownEnumValue: ItemStatus.unknown)  ItemStatus status, @UtcInstantConverter()  DateTime? lastSuccessfulSyncAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Item() when $default != null:
return $default(_that.id,_that.institutionId,_that.status,_that.lastSuccessfulSyncAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String institutionId, @JsonKey(unknownEnumValue: ItemStatus.unknown)  ItemStatus status, @UtcInstantConverter()  DateTime? lastSuccessfulSyncAt)  $default,) {final _that = this;
switch (_that) {
case _Item():
return $default(_that.id,_that.institutionId,_that.status,_that.lastSuccessfulSyncAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String institutionId, @JsonKey(unknownEnumValue: ItemStatus.unknown)  ItemStatus status, @UtcInstantConverter()  DateTime? lastSuccessfulSyncAt)?  $default,) {final _that = this;
switch (_that) {
case _Item() when $default != null:
return $default(_that.id,_that.institutionId,_that.status,_that.lastSuccessfulSyncAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Item implements Item {
  const _Item({required this.id, required this.institutionId, @JsonKey(unknownEnumValue: ItemStatus.unknown) required this.status, @UtcInstantConverter() this.lastSuccessfulSyncAt});
  factory _Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

@override final  String id;
@override final  String institutionId;
@override@JsonKey(unknownEnumValue: ItemStatus.unknown) final  ItemStatus status;
@override@UtcInstantConverter() final  DateTime? lastSuccessfulSyncAt;

/// Create a copy of Item
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemCopyWith<_Item> get copyWith => __$ItemCopyWithImpl<_Item>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Item&&(identical(other.id, id) || other.id == id)&&(identical(other.institutionId, institutionId) || other.institutionId == institutionId)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastSuccessfulSyncAt, lastSuccessfulSyncAt) || other.lastSuccessfulSyncAt == lastSuccessfulSyncAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,institutionId,status,lastSuccessfulSyncAt);
}

@override
String toString() {
    return 'Item(id: $id, institutionId: $institutionId, status: $status, lastSuccessfulSyncAt: $lastSuccessfulSyncAt)';
}


}

/// @nodoc
abstract mixin class _$ItemCopyWith<$Res> implements $ItemCopyWith<$Res> {
  factory _$ItemCopyWith(_Item value, $Res Function(_Item) _then) = __$ItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String institutionId,@JsonKey(unknownEnumValue: ItemStatus.unknown) ItemStatus status,@UtcInstantConverter() DateTime? lastSuccessfulSyncAt
});




}
/// @nodoc
class __$ItemCopyWithImpl<$Res>
    implements _$ItemCopyWith<$Res> {
  __$ItemCopyWithImpl(this._self, this._then);

  final _Item _self;
  final $Res Function(_Item) _then;

/// Create a copy of Item
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? institutionId = null,Object? status = null,Object? lastSuccessfulSyncAt = freezed,}) {
  return _then(_Item(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,institutionId: null == institutionId ? _self.institutionId : institutionId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ItemStatus,lastSuccessfulSyncAt: freezed == lastSuccessfulSyncAt ? _self.lastSuccessfulSyncAt : lastSuccessfulSyncAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
