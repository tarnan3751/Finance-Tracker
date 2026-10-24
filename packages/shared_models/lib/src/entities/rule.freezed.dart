// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Rule {

 String get id; String get name; int get position; List<RuleCondition> get conditions; List<RuleAction> get actions;
/// Create a copy of Rule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RuleCopyWith<Rule> get copyWith => _$RuleCopyWithImpl<Rule>(this as Rule, _$identity);

  /// Serializes this Rule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Rule;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Rule&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.position, _this.position) || other.position == _this.position)&&const DeepCollectionEquality().equals(other.conditions, _this.conditions)&&const DeepCollectionEquality().equals(other.actions, _this.actions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Rule;
  return Object.hash(runtimeType,_this.id,_this.name,_this.position,const DeepCollectionEquality().hash(_this.conditions),const DeepCollectionEquality().hash(_this.actions));
}

@override
String toString() {
  final _this = this as Rule;
  return 'Rule(id: ${_this.id}, name: ${_this.name}, position: ${_this.position}, conditions: ${_this.conditions}, actions: ${_this.actions})';
}


}

/// @nodoc
abstract mixin class $RuleCopyWith<$Res>  {
  factory $RuleCopyWith(Rule value, $Res Function(Rule) _then) = _$RuleCopyWithImpl;
@useResult
$Res call({
 String id, String name, int position, List<RuleCondition> conditions, List<RuleAction> actions
});




}
/// @nodoc
class _$RuleCopyWithImpl<$Res>
    implements $RuleCopyWith<$Res> {
  _$RuleCopyWithImpl(this._self, this._then);

  final Rule _self;
  final $Res Function(Rule) _then;

/// Create a copy of Rule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? position = null,Object? conditions = null,Object? actions = null,}) {
  return _then(Rule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,conditions: null == conditions ? _self.conditions : conditions // ignore: cast_nullable_to_non_nullable
as List<RuleCondition>,actions: null == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as List<RuleAction>,
  ));
}

}


/// Adds pattern-matching-related methods to [Rule].
extension RulePatterns on Rule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Rule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Rule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Rule value)  $default,){
final _that = this;
switch (_that) {
case _Rule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Rule value)?  $default,){
final _that = this;
switch (_that) {
case _Rule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int position,  List<RuleCondition> conditions,  List<RuleAction> actions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Rule() when $default != null:
return $default(_that.id,_that.name,_that.position,_that.conditions,_that.actions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int position,  List<RuleCondition> conditions,  List<RuleAction> actions)  $default,) {final _that = this;
switch (_that) {
case _Rule():
return $default(_that.id,_that.name,_that.position,_that.conditions,_that.actions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int position,  List<RuleCondition> conditions,  List<RuleAction> actions)?  $default,) {final _that = this;
switch (_that) {
case _Rule() when $default != null:
return $default(_that.id,_that.name,_that.position,_that.conditions,_that.actions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Rule implements Rule {
  const _Rule({required this.id, required this.name, required this.position, required  List<RuleCondition> conditions, required  List<RuleAction> actions}): _conditions = conditions,_actions = actions;
  factory _Rule.fromJson(Map<String, dynamic> json) => _$RuleFromJson(json);

@override final  String id;
@override final  String name;
@override final  int position;
 final  List<RuleCondition> _conditions;
@override List<RuleCondition> get conditions {
  if (_conditions is EqualUnmodifiableListView) return _conditions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_conditions);
}

 final  List<RuleAction> _actions;
@override List<RuleAction> get actions {
  if (_actions is EqualUnmodifiableListView) return _actions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actions);
}


/// Create a copy of Rule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RuleCopyWith<_Rule> get copyWith => __$RuleCopyWithImpl<_Rule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RuleToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Rule&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.position, position) || other.position == position)&&const DeepCollectionEquality().equals(other.conditions, _conditions)&&const DeepCollectionEquality().equals(other.actions, _actions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,position,const DeepCollectionEquality().hash(_conditions),const DeepCollectionEquality().hash(_actions));
}

@override
String toString() {
    return 'Rule(id: $id, name: $name, position: $position, conditions: $conditions, actions: $actions)';
}


}

/// @nodoc
abstract mixin class _$RuleCopyWith<$Res> implements $RuleCopyWith<$Res> {
  factory _$RuleCopyWith(_Rule value, $Res Function(_Rule) _then) = __$RuleCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int position, List<RuleCondition> conditions, List<RuleAction> actions
});




}
/// @nodoc
class __$RuleCopyWithImpl<$Res>
    implements _$RuleCopyWith<$Res> {
  __$RuleCopyWithImpl(this._self, this._then);

  final _Rule _self;
  final $Res Function(_Rule) _then;

/// Create a copy of Rule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? position = null,Object? conditions = null,Object? actions = null,}) {
  return _then(_Rule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,conditions: null == conditions ? _self._conditions : conditions // ignore: cast_nullable_to_non_nullable
as List<RuleCondition>,actions: null == actions ? _self._actions : actions // ignore: cast_nullable_to_non_nullable
as List<RuleAction>,
  ));
}


}


/// @nodoc
mixin _$RuleCondition {

 RuleConditionKind get kind; String? get text; Money? get minAmount; Money? get maxAmount;
/// Create a copy of RuleCondition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RuleConditionCopyWith<RuleCondition> get copyWith => _$RuleConditionCopyWithImpl<RuleCondition>(this as RuleCondition, _$identity);

  /// Serializes this RuleCondition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RuleCondition;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuleCondition&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.minAmount, _this.minAmount) || other.minAmount == _this.minAmount)&&(identical(other.maxAmount, _this.maxAmount) || other.maxAmount == _this.maxAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RuleCondition;
  return Object.hash(runtimeType,_this.kind,_this.text,_this.minAmount,_this.maxAmount);
}

@override
String toString() {
  final _this = this as RuleCondition;
  return 'RuleCondition(kind: ${_this.kind}, text: ${_this.text}, minAmount: ${_this.minAmount}, maxAmount: ${_this.maxAmount})';
}


}

/// @nodoc
abstract mixin class $RuleConditionCopyWith<$Res>  {
  factory $RuleConditionCopyWith(RuleCondition value, $Res Function(RuleCondition) _then) = _$RuleConditionCopyWithImpl;
@useResult
$Res call({
 RuleConditionKind kind, String? text, Money? minAmount, Money? maxAmount
});




}
/// @nodoc
class _$RuleConditionCopyWithImpl<$Res>
    implements $RuleConditionCopyWith<$Res> {
  _$RuleConditionCopyWithImpl(this._self, this._then);

  final RuleCondition _self;
  final $Res Function(RuleCondition) _then;

/// Create a copy of RuleCondition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? text = freezed,Object? minAmount = freezed,Object? maxAmount = freezed,}) {
  return _then(RuleCondition(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RuleConditionKind,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,minAmount: freezed == minAmount ? _self.minAmount : minAmount // ignore: cast_nullable_to_non_nullable
as Money?,maxAmount: freezed == maxAmount ? _self.maxAmount : maxAmount // ignore: cast_nullable_to_non_nullable
as Money?,
  ));
}

}


/// Adds pattern-matching-related methods to [RuleCondition].
extension RuleConditionPatterns on RuleCondition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RuleCondition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RuleCondition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RuleCondition value)  $default,){
final _that = this;
switch (_that) {
case _RuleCondition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RuleCondition value)?  $default,){
final _that = this;
switch (_that) {
case _RuleCondition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RuleConditionKind kind,  String? text,  Money? minAmount,  Money? maxAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RuleCondition() when $default != null:
return $default(_that.kind,_that.text,_that.minAmount,_that.maxAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RuleConditionKind kind,  String? text,  Money? minAmount,  Money? maxAmount)  $default,) {final _that = this;
switch (_that) {
case _RuleCondition():
return $default(_that.kind,_that.text,_that.minAmount,_that.maxAmount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RuleConditionKind kind,  String? text,  Money? minAmount,  Money? maxAmount)?  $default,) {final _that = this;
switch (_that) {
case _RuleCondition() when $default != null:
return $default(_that.kind,_that.text,_that.minAmount,_that.maxAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RuleCondition implements RuleCondition {
  const _RuleCondition({required this.kind, this.text, this.minAmount, this.maxAmount});
  factory _RuleCondition.fromJson(Map<String, dynamic> json) => _$RuleConditionFromJson(json);

@override final  RuleConditionKind kind;
@override final  String? text;
@override final  Money? minAmount;
@override final  Money? maxAmount;

/// Create a copy of RuleCondition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RuleConditionCopyWith<_RuleCondition> get copyWith => __$RuleConditionCopyWithImpl<_RuleCondition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RuleConditionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RuleCondition&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.text, text) || other.text == text)&&(identical(other.minAmount, minAmount) || other.minAmount == minAmount)&&(identical(other.maxAmount, maxAmount) || other.maxAmount == maxAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,text,minAmount,maxAmount);
}

@override
String toString() {
    return 'RuleCondition(kind: $kind, text: $text, minAmount: $minAmount, maxAmount: $maxAmount)';
}


}

/// @nodoc
abstract mixin class _$RuleConditionCopyWith<$Res> implements $RuleConditionCopyWith<$Res> {
  factory _$RuleConditionCopyWith(_RuleCondition value, $Res Function(_RuleCondition) _then) = __$RuleConditionCopyWithImpl;
@override @useResult
$Res call({
 RuleConditionKind kind, String? text, Money? minAmount, Money? maxAmount
});




}
/// @nodoc
class __$RuleConditionCopyWithImpl<$Res>
    implements _$RuleConditionCopyWith<$Res> {
  __$RuleConditionCopyWithImpl(this._self, this._then);

  final _RuleCondition _self;
  final $Res Function(_RuleCondition) _then;

/// Create a copy of RuleCondition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? text = freezed,Object? minAmount = freezed,Object? maxAmount = freezed,}) {
  return _then(_RuleCondition(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RuleConditionKind,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,minAmount: freezed == minAmount ? _self.minAmount : minAmount // ignore: cast_nullable_to_non_nullable
as Money?,maxAmount: freezed == maxAmount ? _self.maxAmount : maxAmount // ignore: cast_nullable_to_non_nullable
as Money?,
  ));
}


}


/// @nodoc
mixin _$RuleAction {

 RuleActionKind get kind; String? get value;
/// Create a copy of RuleAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RuleActionCopyWith<RuleAction> get copyWith => _$RuleActionCopyWithImpl<RuleAction>(this as RuleAction, _$identity);

  /// Serializes this RuleAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RuleAction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuleAction&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.value, _this.value) || other.value == _this.value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RuleAction;
  return Object.hash(runtimeType,_this.kind,_this.value);
}

@override
String toString() {
  final _this = this as RuleAction;
  return 'RuleAction(kind: ${_this.kind}, value: ${_this.value})';
}


}

/// @nodoc
abstract mixin class $RuleActionCopyWith<$Res>  {
  factory $RuleActionCopyWith(RuleAction value, $Res Function(RuleAction) _then) = _$RuleActionCopyWithImpl;
@useResult
$Res call({
 RuleActionKind kind, String? value
});




}
/// @nodoc
class _$RuleActionCopyWithImpl<$Res>
    implements $RuleActionCopyWith<$Res> {
  _$RuleActionCopyWithImpl(this._self, this._then);

  final RuleAction _self;
  final $Res Function(RuleAction) _then;

/// Create a copy of RuleAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? value = freezed,}) {
  return _then(RuleAction(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RuleActionKind,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RuleAction].
extension RuleActionPatterns on RuleAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RuleAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RuleAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RuleAction value)  $default,){
final _that = this;
switch (_that) {
case _RuleAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RuleAction value)?  $default,){
final _that = this;
switch (_that) {
case _RuleAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RuleActionKind kind,  String? value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RuleAction() when $default != null:
return $default(_that.kind,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RuleActionKind kind,  String? value)  $default,) {final _that = this;
switch (_that) {
case _RuleAction():
return $default(_that.kind,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RuleActionKind kind,  String? value)?  $default,) {final _that = this;
switch (_that) {
case _RuleAction() when $default != null:
return $default(_that.kind,_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RuleAction implements RuleAction {
  const _RuleAction({required this.kind, this.value});
  factory _RuleAction.fromJson(Map<String, dynamic> json) => _$RuleActionFromJson(json);

@override final  RuleActionKind kind;
@override final  String? value;

/// Create a copy of RuleAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RuleActionCopyWith<_RuleAction> get copyWith => __$RuleActionCopyWithImpl<_RuleAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RuleActionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RuleAction&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,value);
}

@override
String toString() {
    return 'RuleAction(kind: $kind, value: $value)';
}


}

/// @nodoc
abstract mixin class _$RuleActionCopyWith<$Res> implements $RuleActionCopyWith<$Res> {
  factory _$RuleActionCopyWith(_RuleAction value, $Res Function(_RuleAction) _then) = __$RuleActionCopyWithImpl;
@override @useResult
$Res call({
 RuleActionKind kind, String? value
});




}
/// @nodoc
class __$RuleActionCopyWithImpl<$Res>
    implements _$RuleActionCopyWith<$Res> {
  __$RuleActionCopyWithImpl(this._self, this._then);

  final _RuleAction _self;
  final $Res Function(_RuleAction) _then;

/// Create a copy of RuleAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? value = freezed,}) {
  return _then(_RuleAction(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RuleActionKind,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
