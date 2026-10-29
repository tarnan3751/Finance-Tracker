// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'goal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Goal {

 String get id; String get name; Money get target; GoalKind get kind; List<String> get linkedAccountIds; LocalDate? get targetDate; LocalDate get createdOn; String? get note;@UtcInstantConverter() DateTime? get archivedAt;@UtcInstantConverter() DateTime? get deletedAt;
/// Create a copy of Goal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GoalCopyWith<Goal> get copyWith => _$GoalCopyWithImpl<Goal>(this as Goal, _$identity);

  /// Serializes this Goal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Goal;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Goal&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.target, _this.target) || other.target == _this.target)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&const DeepCollectionEquality().equals(other.linkedAccountIds, _this.linkedAccountIds)&&(identical(other.targetDate, _this.targetDate) || other.targetDate == _this.targetDate)&&(identical(other.createdOn, _this.createdOn) || other.createdOn == _this.createdOn)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.archivedAt, _this.archivedAt) || other.archivedAt == _this.archivedAt)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Goal;
  return Object.hash(runtimeType,_this.id,_this.name,_this.target,_this.kind,const DeepCollectionEquality().hash(_this.linkedAccountIds),_this.targetDate,_this.createdOn,_this.note,_this.archivedAt,_this.deletedAt);
}

@override
String toString() {
  final _this = this as Goal;
  return 'Goal(id: ${_this.id}, name: ${_this.name}, target: ${_this.target}, kind: ${_this.kind}, linkedAccountIds: ${_this.linkedAccountIds}, targetDate: ${_this.targetDate}, createdOn: ${_this.createdOn}, note: ${_this.note}, archivedAt: ${_this.archivedAt}, deletedAt: ${_this.deletedAt})';
}


}

/// @nodoc
abstract mixin class $GoalCopyWith<$Res>  {
  factory $GoalCopyWith(Goal value, $Res Function(Goal) _then) = _$GoalCopyWithImpl;
@useResult
$Res call({
 String id, String name, Money target, GoalKind kind, List<String> linkedAccountIds, LocalDate? targetDate, LocalDate createdOn, String? note,@UtcInstantConverter() DateTime? archivedAt,@UtcInstantConverter() DateTime? deletedAt
});




}
/// @nodoc
class _$GoalCopyWithImpl<$Res>
    implements $GoalCopyWith<$Res> {
  _$GoalCopyWithImpl(this._self, this._then);

  final Goal _self;
  final $Res Function(Goal) _then;

/// Create a copy of Goal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? target = null,Object? kind = null,Object? linkedAccountIds = null,Object? targetDate = freezed,Object? createdOn = null,Object? note = freezed,Object? archivedAt = freezed,Object? deletedAt = freezed,}) {
  return _then(Goal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as Money,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as GoalKind,linkedAccountIds: null == linkedAccountIds ? _self.linkedAccountIds : linkedAccountIds // ignore: cast_nullable_to_non_nullable
as List<String>,targetDate: freezed == targetDate ? _self.targetDate : targetDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,createdOn: null == createdOn ? _self.createdOn : createdOn // ignore: cast_nullable_to_non_nullable
as LocalDate,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Goal].
extension GoalPatterns on Goal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Goal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Goal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Goal value)  $default,){
final _that = this;
switch (_that) {
case _Goal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Goal value)?  $default,){
final _that = this;
switch (_that) {
case _Goal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  Money target,  GoalKind kind,  List<String> linkedAccountIds,  LocalDate? targetDate,  LocalDate createdOn,  String? note, @UtcInstantConverter()  DateTime? archivedAt, @UtcInstantConverter()  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Goal() when $default != null:
return $default(_that.id,_that.name,_that.target,_that.kind,_that.linkedAccountIds,_that.targetDate,_that.createdOn,_that.note,_that.archivedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  Money target,  GoalKind kind,  List<String> linkedAccountIds,  LocalDate? targetDate,  LocalDate createdOn,  String? note, @UtcInstantConverter()  DateTime? archivedAt, @UtcInstantConverter()  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _Goal():
return $default(_that.id,_that.name,_that.target,_that.kind,_that.linkedAccountIds,_that.targetDate,_that.createdOn,_that.note,_that.archivedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  Money target,  GoalKind kind,  List<String> linkedAccountIds,  LocalDate? targetDate,  LocalDate createdOn,  String? note, @UtcInstantConverter()  DateTime? archivedAt, @UtcInstantConverter()  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _Goal() when $default != null:
return $default(_that.id,_that.name,_that.target,_that.kind,_that.linkedAccountIds,_that.targetDate,_that.createdOn,_that.note,_that.archivedAt,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Goal implements Goal {
  const _Goal({required this.id, required this.name, required this.target, required this.kind,  List<String> linkedAccountIds = const <String>[], this.targetDate, required this.createdOn, this.note, @UtcInstantConverter() this.archivedAt, @UtcInstantConverter() this.deletedAt}): _linkedAccountIds = linkedAccountIds;
  factory _Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);

@override final  String id;
@override final  String name;
@override final  Money target;
@override final  GoalKind kind;
 final  List<String> _linkedAccountIds;
@override@JsonKey() List<String> get linkedAccountIds {
  if (_linkedAccountIds is EqualUnmodifiableListView) return _linkedAccountIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_linkedAccountIds);
}

@override final  LocalDate? targetDate;
@override final  LocalDate createdOn;
@override final  String? note;
@override@UtcInstantConverter() final  DateTime? archivedAt;
@override@UtcInstantConverter() final  DateTime? deletedAt;

/// Create a copy of Goal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoalCopyWith<_Goal> get copyWith => __$GoalCopyWithImpl<_Goal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GoalToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Goal&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.target, target) || other.target == target)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.linkedAccountIds, _linkedAccountIds)&&(identical(other.targetDate, targetDate) || other.targetDate == targetDate)&&(identical(other.createdOn, createdOn) || other.createdOn == createdOn)&&(identical(other.note, note) || other.note == note)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,target,kind,const DeepCollectionEquality().hash(_linkedAccountIds),targetDate,createdOn,note,archivedAt,deletedAt);
}

@override
String toString() {
    return 'Goal(id: $id, name: $name, target: $target, kind: $kind, linkedAccountIds: $linkedAccountIds, targetDate: $targetDate, createdOn: $createdOn, note: $note, archivedAt: $archivedAt, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$GoalCopyWith<$Res> implements $GoalCopyWith<$Res> {
  factory _$GoalCopyWith(_Goal value, $Res Function(_Goal) _then) = __$GoalCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, Money target, GoalKind kind, List<String> linkedAccountIds, LocalDate? targetDate, LocalDate createdOn, String? note,@UtcInstantConverter() DateTime? archivedAt,@UtcInstantConverter() DateTime? deletedAt
});




}
/// @nodoc
class __$GoalCopyWithImpl<$Res>
    implements _$GoalCopyWith<$Res> {
  __$GoalCopyWithImpl(this._self, this._then);

  final _Goal _self;
  final $Res Function(_Goal) _then;

/// Create a copy of Goal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? target = null,Object? kind = null,Object? linkedAccountIds = null,Object? targetDate = freezed,Object? createdOn = null,Object? note = freezed,Object? archivedAt = freezed,Object? deletedAt = freezed,}) {
  return _then(_Goal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as Money,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as GoalKind,linkedAccountIds: null == linkedAccountIds ? _self._linkedAccountIds : linkedAccountIds // ignore: cast_nullable_to_non_nullable
as List<String>,targetDate: freezed == targetDate ? _self.targetDate : targetDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,createdOn: null == createdOn ? _self.createdOn : createdOn // ignore: cast_nullable_to_non_nullable
as LocalDate,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$GoalContribution {

 String get id; String get goalId; LocalDate get date; Money get amount; String? get note;@UtcInstantConverter() DateTime? get deletedAt;
/// Create a copy of GoalContribution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GoalContributionCopyWith<GoalContribution> get copyWith => _$GoalContributionCopyWithImpl<GoalContribution>(this as GoalContribution, _$identity);

  /// Serializes this GoalContribution to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GoalContribution;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GoalContribution&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.goalId, _this.goalId) || other.goalId == _this.goalId)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GoalContribution;
  return Object.hash(runtimeType,_this.id,_this.goalId,_this.date,_this.amount,_this.note,_this.deletedAt);
}

@override
String toString() {
  final _this = this as GoalContribution;
  return 'GoalContribution(id: ${_this.id}, goalId: ${_this.goalId}, date: ${_this.date}, amount: ${_this.amount}, note: ${_this.note}, deletedAt: ${_this.deletedAt})';
}


}

/// @nodoc
abstract mixin class $GoalContributionCopyWith<$Res>  {
  factory $GoalContributionCopyWith(GoalContribution value, $Res Function(GoalContribution) _then) = _$GoalContributionCopyWithImpl;
@useResult
$Res call({
 String id, String goalId, LocalDate date, Money amount, String? note,@UtcInstantConverter() DateTime? deletedAt
});




}
/// @nodoc
class _$GoalContributionCopyWithImpl<$Res>
    implements $GoalContributionCopyWith<$Res> {
  _$GoalContributionCopyWithImpl(this._self, this._then);

  final GoalContribution _self;
  final $Res Function(GoalContribution) _then;

/// Create a copy of GoalContribution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? goalId = null,Object? date = null,Object? amount = null,Object? note = freezed,Object? deletedAt = freezed,}) {
  return _then(GoalContribution(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,goalId: null == goalId ? _self.goalId : goalId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GoalContribution].
extension GoalContributionPatterns on GoalContribution {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GoalContribution value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GoalContribution() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GoalContribution value)  $default,){
final _that = this;
switch (_that) {
case _GoalContribution():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GoalContribution value)?  $default,){
final _that = this;
switch (_that) {
case _GoalContribution() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String goalId,  LocalDate date,  Money amount,  String? note, @UtcInstantConverter()  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GoalContribution() when $default != null:
return $default(_that.id,_that.goalId,_that.date,_that.amount,_that.note,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String goalId,  LocalDate date,  Money amount,  String? note, @UtcInstantConverter()  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _GoalContribution():
return $default(_that.id,_that.goalId,_that.date,_that.amount,_that.note,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String goalId,  LocalDate date,  Money amount,  String? note, @UtcInstantConverter()  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _GoalContribution() when $default != null:
return $default(_that.id,_that.goalId,_that.date,_that.amount,_that.note,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GoalContribution implements GoalContribution {
  const _GoalContribution({required this.id, required this.goalId, required this.date, required this.amount, this.note, @UtcInstantConverter() this.deletedAt});
  factory _GoalContribution.fromJson(Map<String, dynamic> json) => _$GoalContributionFromJson(json);

@override final  String id;
@override final  String goalId;
@override final  LocalDate date;
@override final  Money amount;
@override final  String? note;
@override@UtcInstantConverter() final  DateTime? deletedAt;

/// Create a copy of GoalContribution
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoalContributionCopyWith<_GoalContribution> get copyWith => __$GoalContributionCopyWithImpl<_GoalContribution>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GoalContributionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GoalContribution&&(identical(other.id, id) || other.id == id)&&(identical(other.goalId, goalId) || other.goalId == goalId)&&(identical(other.date, date) || other.date == date)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.note, note) || other.note == note)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,goalId,date,amount,note,deletedAt);
}

@override
String toString() {
    return 'GoalContribution(id: $id, goalId: $goalId, date: $date, amount: $amount, note: $note, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$GoalContributionCopyWith<$Res> implements $GoalContributionCopyWith<$Res> {
  factory _$GoalContributionCopyWith(_GoalContribution value, $Res Function(_GoalContribution) _then) = __$GoalContributionCopyWithImpl;
@override @useResult
$Res call({
 String id, String goalId, LocalDate date, Money amount, String? note,@UtcInstantConverter() DateTime? deletedAt
});




}
/// @nodoc
class __$GoalContributionCopyWithImpl<$Res>
    implements _$GoalContributionCopyWith<$Res> {
  __$GoalContributionCopyWithImpl(this._self, this._then);

  final _GoalContribution _self;
  final $Res Function(_GoalContribution) _then;

/// Create a copy of GoalContribution
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? goalId = null,Object? date = null,Object? amount = null,Object? note = freezed,Object? deletedAt = freezed,}) {
  return _then(_GoalContribution(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,goalId: null == goalId ? _self.goalId : goalId // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as LocalDate,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Money,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
