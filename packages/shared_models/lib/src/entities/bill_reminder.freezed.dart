// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bill_reminder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BillReminder {

 String get id; String? get streamId; String? get name; Money? get amount; LocalDate get dueDate; List<int> get reminderOffsetDays;
/// Create a copy of BillReminder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillReminderCopyWith<BillReminder> get copyWith => _$BillReminderCopyWithImpl<BillReminder>(this as BillReminder, _$identity);

  /// Serializes this BillReminder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BillReminder;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillReminder&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.streamId, _this.streamId) || other.streamId == _this.streamId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.dueDate, _this.dueDate) || other.dueDate == _this.dueDate)&&const DeepCollectionEquality().equals(other.reminderOffsetDays, _this.reminderOffsetDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BillReminder;
  return Object.hash(runtimeType,_this.id,_this.streamId,_this.name,_this.amount,_this.dueDate,const DeepCollectionEquality().hash(_this.reminderOffsetDays));
}

@override
String toString() {
  final _this = this as BillReminder;
  return 'BillReminder(id: ${_this.id}, streamId: ${_this.streamId}, name: ${_this.name}, amount: ${_this.amount}, dueDate: ${_this.dueDate}, reminderOffsetDays: ${_this.reminderOffsetDays})';
}


}

/// @nodoc
abstract mixin class $BillReminderCopyWith<$Res>  {
  factory $BillReminderCopyWith(BillReminder value, $Res Function(BillReminder) _then) = _$BillReminderCopyWithImpl;
@useResult
$Res call({
 String id, String? streamId, String? name, Money? amount, LocalDate dueDate, List<int> reminderOffsetDays
});




}
/// @nodoc
class _$BillReminderCopyWithImpl<$Res>
    implements $BillReminderCopyWith<$Res> {
  _$BillReminderCopyWithImpl(this._self, this._then);

  final BillReminder _self;
  final $Res Function(BillReminder) _then;

/// Create a copy of BillReminder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? streamId = freezed,Object? name = freezed,Object? amount = freezed,Object? dueDate = null,Object? reminderOffsetDays = null,}) {
  return _then(BillReminder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,streamId: freezed == streamId ? _self.streamId : streamId // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money?,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as LocalDate,reminderOffsetDays: null == reminderOffsetDays ? _self.reminderOffsetDays : reminderOffsetDays // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [BillReminder].
extension BillReminderPatterns on BillReminder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BillReminder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BillReminder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BillReminder value)  $default,){
final _that = this;
switch (_that) {
case _BillReminder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BillReminder value)?  $default,){
final _that = this;
switch (_that) {
case _BillReminder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? streamId,  String? name,  Money? amount,  LocalDate dueDate,  List<int> reminderOffsetDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BillReminder() when $default != null:
return $default(_that.id,_that.streamId,_that.name,_that.amount,_that.dueDate,_that.reminderOffsetDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? streamId,  String? name,  Money? amount,  LocalDate dueDate,  List<int> reminderOffsetDays)  $default,) {final _that = this;
switch (_that) {
case _BillReminder():
return $default(_that.id,_that.streamId,_that.name,_that.amount,_that.dueDate,_that.reminderOffsetDays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? streamId,  String? name,  Money? amount,  LocalDate dueDate,  List<int> reminderOffsetDays)?  $default,) {final _that = this;
switch (_that) {
case _BillReminder() when $default != null:
return $default(_that.id,_that.streamId,_that.name,_that.amount,_that.dueDate,_that.reminderOffsetDays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BillReminder implements BillReminder {
  const _BillReminder({required this.id, this.streamId, this.name, this.amount, required this.dueDate, required  List<int> reminderOffsetDays}): _reminderOffsetDays = reminderOffsetDays;
  factory _BillReminder.fromJson(Map<String, dynamic> json) => _$BillReminderFromJson(json);

@override final  String id;
@override final  String? streamId;
@override final  String? name;
@override final  Money? amount;
@override final  LocalDate dueDate;
 final  List<int> _reminderOffsetDays;
@override List<int> get reminderOffsetDays {
  if (_reminderOffsetDays is EqualUnmodifiableListView) return _reminderOffsetDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reminderOffsetDays);
}


/// Create a copy of BillReminder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BillReminderCopyWith<_BillReminder> get copyWith => __$BillReminderCopyWithImpl<_BillReminder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BillReminderToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BillReminder&&(identical(other.id, id) || other.id == id)&&(identical(other.streamId, streamId) || other.streamId == streamId)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&const DeepCollectionEquality().equals(other.reminderOffsetDays, _reminderOffsetDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,streamId,name,amount,dueDate,const DeepCollectionEquality().hash(_reminderOffsetDays));
}

@override
String toString() {
    return 'BillReminder(id: $id, streamId: $streamId, name: $name, amount: $amount, dueDate: $dueDate, reminderOffsetDays: $reminderOffsetDays)';
}


}

/// @nodoc
abstract mixin class _$BillReminderCopyWith<$Res> implements $BillReminderCopyWith<$Res> {
  factory _$BillReminderCopyWith(_BillReminder value, $Res Function(_BillReminder) _then) = __$BillReminderCopyWithImpl;
@override @useResult
$Res call({
 String id, String? streamId, String? name, Money? amount, LocalDate dueDate, List<int> reminderOffsetDays
});




}
/// @nodoc
class __$BillReminderCopyWithImpl<$Res>
    implements _$BillReminderCopyWith<$Res> {
  __$BillReminderCopyWithImpl(this._self, this._then);

  final _BillReminder _self;
  final $Res Function(_BillReminder) _then;

/// Create a copy of BillReminder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? streamId = freezed,Object? name = freezed,Object? amount = freezed,Object? dueDate = null,Object? reminderOffsetDays = null,}) {
  return _then(_BillReminder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,streamId: freezed == streamId ? _self.streamId : streamId // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money?,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as LocalDate,reminderOffsetDays: null == reminderOffsetDays ? _self._reminderOffsetDays : reminderOffsetDays // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

// dart format on
