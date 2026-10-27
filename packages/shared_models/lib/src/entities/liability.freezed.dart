// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'liability.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Liability {

 String get accountId; LiabilityKind get kind; DataSource get source; LocalDate? get nextPaymentDueDate; Money? get minimumPaymentAmount; Money? get lastStatementBalance; LocalDate? get lastStatementIssueDate; Money? get lastPaymentAmount; LocalDate? get lastPaymentDate; bool? get isOverdue; List<LiabilityApr> get aprs; int? get interestRateBasisPoints; LocalDate? get originationDate; Money? get originationPrincipal; String? get loanTerm; Money? get nextMonthlyPayment; Money? get ytdInterestPaid; Money? get ytdPrincipalPaid; Map<String, Object?> get payload;
/// Create a copy of Liability
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiabilityCopyWith<Liability> get copyWith => _$LiabilityCopyWithImpl<Liability>(this as Liability, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Liability;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Liability&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.nextPaymentDueDate, _this.nextPaymentDueDate) || other.nextPaymentDueDate == _this.nextPaymentDueDate)&&(identical(other.minimumPaymentAmount, _this.minimumPaymentAmount) || other.minimumPaymentAmount == _this.minimumPaymentAmount)&&(identical(other.lastStatementBalance, _this.lastStatementBalance) || other.lastStatementBalance == _this.lastStatementBalance)&&(identical(other.lastStatementIssueDate, _this.lastStatementIssueDate) || other.lastStatementIssueDate == _this.lastStatementIssueDate)&&(identical(other.lastPaymentAmount, _this.lastPaymentAmount) || other.lastPaymentAmount == _this.lastPaymentAmount)&&(identical(other.lastPaymentDate, _this.lastPaymentDate) || other.lastPaymentDate == _this.lastPaymentDate)&&(identical(other.isOverdue, _this.isOverdue) || other.isOverdue == _this.isOverdue)&&const DeepCollectionEquality().equals(other.aprs, _this.aprs)&&(identical(other.interestRateBasisPoints, _this.interestRateBasisPoints) || other.interestRateBasisPoints == _this.interestRateBasisPoints)&&(identical(other.originationDate, _this.originationDate) || other.originationDate == _this.originationDate)&&(identical(other.originationPrincipal, _this.originationPrincipal) || other.originationPrincipal == _this.originationPrincipal)&&(identical(other.loanTerm, _this.loanTerm) || other.loanTerm == _this.loanTerm)&&(identical(other.nextMonthlyPayment, _this.nextMonthlyPayment) || other.nextMonthlyPayment == _this.nextMonthlyPayment)&&(identical(other.ytdInterestPaid, _this.ytdInterestPaid) || other.ytdInterestPaid == _this.ytdInterestPaid)&&(identical(other.ytdPrincipalPaid, _this.ytdPrincipalPaid) || other.ytdPrincipalPaid == _this.ytdPrincipalPaid)&&const DeepCollectionEquality().equals(other.payload, _this.payload));
}


@override
int get hashCode {
  final _this = this as Liability;
  return Object.hashAll([runtimeType,_this.accountId,_this.kind,_this.source,_this.nextPaymentDueDate,_this.minimumPaymentAmount,_this.lastStatementBalance,_this.lastStatementIssueDate,_this.lastPaymentAmount,_this.lastPaymentDate,_this.isOverdue,const DeepCollectionEquality().hash(_this.aprs),_this.interestRateBasisPoints,_this.originationDate,_this.originationPrincipal,_this.loanTerm,_this.nextMonthlyPayment,_this.ytdInterestPaid,_this.ytdPrincipalPaid,const DeepCollectionEquality().hash(_this.payload)]);
}

@override
String toString() {
  final _this = this as Liability;
  return 'Liability(accountId: ${_this.accountId}, kind: ${_this.kind}, source: ${_this.source}, nextPaymentDueDate: ${_this.nextPaymentDueDate}, minimumPaymentAmount: ${_this.minimumPaymentAmount}, lastStatementBalance: ${_this.lastStatementBalance}, lastStatementIssueDate: ${_this.lastStatementIssueDate}, lastPaymentAmount: ${_this.lastPaymentAmount}, lastPaymentDate: ${_this.lastPaymentDate}, isOverdue: ${_this.isOverdue}, aprs: ${_this.aprs}, interestRateBasisPoints: ${_this.interestRateBasisPoints}, originationDate: ${_this.originationDate}, originationPrincipal: ${_this.originationPrincipal}, loanTerm: ${_this.loanTerm}, nextMonthlyPayment: ${_this.nextMonthlyPayment}, ytdInterestPaid: ${_this.ytdInterestPaid}, ytdPrincipalPaid: ${_this.ytdPrincipalPaid}, payload: ${_this.payload})';
}


}

/// @nodoc
abstract mixin class $LiabilityCopyWith<$Res>  {
  factory $LiabilityCopyWith(Liability value, $Res Function(Liability) _then) = _$LiabilityCopyWithImpl;
@useResult
$Res call({
 String accountId, LiabilityKind kind, DataSource source, LocalDate? nextPaymentDueDate, Money? minimumPaymentAmount, Money? lastStatementBalance, LocalDate? lastStatementIssueDate, Money? lastPaymentAmount, LocalDate? lastPaymentDate, bool? isOverdue, List<LiabilityApr> aprs, int? interestRateBasisPoints, LocalDate? originationDate, Money? originationPrincipal, String? loanTerm, Money? nextMonthlyPayment, Money? ytdInterestPaid, Money? ytdPrincipalPaid, Map<String, Object?> payload
});




}
/// @nodoc
class _$LiabilityCopyWithImpl<$Res>
    implements $LiabilityCopyWith<$Res> {
  _$LiabilityCopyWithImpl(this._self, this._then);

  final Liability _self;
  final $Res Function(Liability) _then;

/// Create a copy of Liability
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountId = null,Object? kind = null,Object? source = null,Object? nextPaymentDueDate = freezed,Object? minimumPaymentAmount = freezed,Object? lastStatementBalance = freezed,Object? lastStatementIssueDate = freezed,Object? lastPaymentAmount = freezed,Object? lastPaymentDate = freezed,Object? isOverdue = freezed,Object? aprs = null,Object? interestRateBasisPoints = freezed,Object? originationDate = freezed,Object? originationPrincipal = freezed,Object? loanTerm = freezed,Object? nextMonthlyPayment = freezed,Object? ytdInterestPaid = freezed,Object? ytdPrincipalPaid = freezed,Object? payload = null,}) {
  return _then(Liability(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as LiabilityKind,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DataSource,nextPaymentDueDate: freezed == nextPaymentDueDate ? _self.nextPaymentDueDate : nextPaymentDueDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,minimumPaymentAmount: freezed == minimumPaymentAmount ? _self.minimumPaymentAmount : minimumPaymentAmount // ignore: cast_nullable_to_non_nullable
as Money?,lastStatementBalance: freezed == lastStatementBalance ? _self.lastStatementBalance : lastStatementBalance // ignore: cast_nullable_to_non_nullable
as Money?,lastStatementIssueDate: freezed == lastStatementIssueDate ? _self.lastStatementIssueDate : lastStatementIssueDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,lastPaymentAmount: freezed == lastPaymentAmount ? _self.lastPaymentAmount : lastPaymentAmount // ignore: cast_nullable_to_non_nullable
as Money?,lastPaymentDate: freezed == lastPaymentDate ? _self.lastPaymentDate : lastPaymentDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,isOverdue: freezed == isOverdue ? _self.isOverdue : isOverdue // ignore: cast_nullable_to_non_nullable
as bool?,aprs: null == aprs ? _self.aprs : aprs // ignore: cast_nullable_to_non_nullable
as List<LiabilityApr>,interestRateBasisPoints: freezed == interestRateBasisPoints ? _self.interestRateBasisPoints : interestRateBasisPoints // ignore: cast_nullable_to_non_nullable
as int?,originationDate: freezed == originationDate ? _self.originationDate : originationDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,originationPrincipal: freezed == originationPrincipal ? _self.originationPrincipal : originationPrincipal // ignore: cast_nullable_to_non_nullable
as Money?,loanTerm: freezed == loanTerm ? _self.loanTerm : loanTerm // ignore: cast_nullable_to_non_nullable
as String?,nextMonthlyPayment: freezed == nextMonthlyPayment ? _self.nextMonthlyPayment : nextMonthlyPayment // ignore: cast_nullable_to_non_nullable
as Money?,ytdInterestPaid: freezed == ytdInterestPaid ? _self.ytdInterestPaid : ytdInterestPaid // ignore: cast_nullable_to_non_nullable
as Money?,ytdPrincipalPaid: freezed == ytdPrincipalPaid ? _self.ytdPrincipalPaid : ytdPrincipalPaid // ignore: cast_nullable_to_non_nullable
as Money?,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [Liability].
extension LiabilityPatterns on Liability {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Liability value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Liability() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Liability value)  $default,){
final _that = this;
switch (_that) {
case _Liability():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Liability value)?  $default,){
final _that = this;
switch (_that) {
case _Liability() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accountId,  LiabilityKind kind,  DataSource source,  LocalDate? nextPaymentDueDate,  Money? minimumPaymentAmount,  Money? lastStatementBalance,  LocalDate? lastStatementIssueDate,  Money? lastPaymentAmount,  LocalDate? lastPaymentDate,  bool? isOverdue,  List<LiabilityApr> aprs,  int? interestRateBasisPoints,  LocalDate? originationDate,  Money? originationPrincipal,  String? loanTerm,  Money? nextMonthlyPayment,  Money? ytdInterestPaid,  Money? ytdPrincipalPaid,  Map<String, Object?> payload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Liability() when $default != null:
return $default(_that.accountId,_that.kind,_that.source,_that.nextPaymentDueDate,_that.minimumPaymentAmount,_that.lastStatementBalance,_that.lastStatementIssueDate,_that.lastPaymentAmount,_that.lastPaymentDate,_that.isOverdue,_that.aprs,_that.interestRateBasisPoints,_that.originationDate,_that.originationPrincipal,_that.loanTerm,_that.nextMonthlyPayment,_that.ytdInterestPaid,_that.ytdPrincipalPaid,_that.payload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accountId,  LiabilityKind kind,  DataSource source,  LocalDate? nextPaymentDueDate,  Money? minimumPaymentAmount,  Money? lastStatementBalance,  LocalDate? lastStatementIssueDate,  Money? lastPaymentAmount,  LocalDate? lastPaymentDate,  bool? isOverdue,  List<LiabilityApr> aprs,  int? interestRateBasisPoints,  LocalDate? originationDate,  Money? originationPrincipal,  String? loanTerm,  Money? nextMonthlyPayment,  Money? ytdInterestPaid,  Money? ytdPrincipalPaid,  Map<String, Object?> payload)  $default,) {final _that = this;
switch (_that) {
case _Liability():
return $default(_that.accountId,_that.kind,_that.source,_that.nextPaymentDueDate,_that.minimumPaymentAmount,_that.lastStatementBalance,_that.lastStatementIssueDate,_that.lastPaymentAmount,_that.lastPaymentDate,_that.isOverdue,_that.aprs,_that.interestRateBasisPoints,_that.originationDate,_that.originationPrincipal,_that.loanTerm,_that.nextMonthlyPayment,_that.ytdInterestPaid,_that.ytdPrincipalPaid,_that.payload);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accountId,  LiabilityKind kind,  DataSource source,  LocalDate? nextPaymentDueDate,  Money? minimumPaymentAmount,  Money? lastStatementBalance,  LocalDate? lastStatementIssueDate,  Money? lastPaymentAmount,  LocalDate? lastPaymentDate,  bool? isOverdue,  List<LiabilityApr> aprs,  int? interestRateBasisPoints,  LocalDate? originationDate,  Money? originationPrincipal,  String? loanTerm,  Money? nextMonthlyPayment,  Money? ytdInterestPaid,  Money? ytdPrincipalPaid,  Map<String, Object?> payload)?  $default,) {final _that = this;
switch (_that) {
case _Liability() when $default != null:
return $default(_that.accountId,_that.kind,_that.source,_that.nextPaymentDueDate,_that.minimumPaymentAmount,_that.lastStatementBalance,_that.lastStatementIssueDate,_that.lastPaymentAmount,_that.lastPaymentDate,_that.isOverdue,_that.aprs,_that.interestRateBasisPoints,_that.originationDate,_that.originationPrincipal,_that.loanTerm,_that.nextMonthlyPayment,_that.ytdInterestPaid,_that.ytdPrincipalPaid,_that.payload);case _:
  return null;

}
}

}

/// @nodoc


class _Liability implements Liability {
  const _Liability({required this.accountId, required this.kind, required this.source, this.nextPaymentDueDate, this.minimumPaymentAmount, this.lastStatementBalance, this.lastStatementIssueDate, this.lastPaymentAmount, this.lastPaymentDate, this.isOverdue,  List<LiabilityApr> aprs = const <LiabilityApr>[], this.interestRateBasisPoints, this.originationDate, this.originationPrincipal, this.loanTerm, this.nextMonthlyPayment, this.ytdInterestPaid, this.ytdPrincipalPaid, required  Map<String, Object?> payload}): _aprs = aprs,_payload = payload;
  

@override final  String accountId;
@override final  LiabilityKind kind;
@override final  DataSource source;
@override final  LocalDate? nextPaymentDueDate;
@override final  Money? minimumPaymentAmount;
@override final  Money? lastStatementBalance;
@override final  LocalDate? lastStatementIssueDate;
@override final  Money? lastPaymentAmount;
@override final  LocalDate? lastPaymentDate;
@override final  bool? isOverdue;
 final  List<LiabilityApr> _aprs;
@override@JsonKey() List<LiabilityApr> get aprs {
  if (_aprs is EqualUnmodifiableListView) return _aprs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_aprs);
}

@override final  int? interestRateBasisPoints;
@override final  LocalDate? originationDate;
@override final  Money? originationPrincipal;
@override final  String? loanTerm;
@override final  Money? nextMonthlyPayment;
@override final  Money? ytdInterestPaid;
@override final  Money? ytdPrincipalPaid;
 final  Map<String, Object?> _payload;
@override Map<String, Object?> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}


/// Create a copy of Liability
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiabilityCopyWith<_Liability> get copyWith => __$LiabilityCopyWithImpl<_Liability>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Liability&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.source, source) || other.source == source)&&(identical(other.nextPaymentDueDate, nextPaymentDueDate) || other.nextPaymentDueDate == nextPaymentDueDate)&&(identical(other.minimumPaymentAmount, minimumPaymentAmount) || other.minimumPaymentAmount == minimumPaymentAmount)&&(identical(other.lastStatementBalance, lastStatementBalance) || other.lastStatementBalance == lastStatementBalance)&&(identical(other.lastStatementIssueDate, lastStatementIssueDate) || other.lastStatementIssueDate == lastStatementIssueDate)&&(identical(other.lastPaymentAmount, lastPaymentAmount) || other.lastPaymentAmount == lastPaymentAmount)&&(identical(other.lastPaymentDate, lastPaymentDate) || other.lastPaymentDate == lastPaymentDate)&&(identical(other.isOverdue, isOverdue) || other.isOverdue == isOverdue)&&const DeepCollectionEquality().equals(other.aprs, _aprs)&&(identical(other.interestRateBasisPoints, interestRateBasisPoints) || other.interestRateBasisPoints == interestRateBasisPoints)&&(identical(other.originationDate, originationDate) || other.originationDate == originationDate)&&(identical(other.originationPrincipal, originationPrincipal) || other.originationPrincipal == originationPrincipal)&&(identical(other.loanTerm, loanTerm) || other.loanTerm == loanTerm)&&(identical(other.nextMonthlyPayment, nextMonthlyPayment) || other.nextMonthlyPayment == nextMonthlyPayment)&&(identical(other.ytdInterestPaid, ytdInterestPaid) || other.ytdInterestPaid == ytdInterestPaid)&&(identical(other.ytdPrincipalPaid, ytdPrincipalPaid) || other.ytdPrincipalPaid == ytdPrincipalPaid)&&const DeepCollectionEquality().equals(other.payload, _payload));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,accountId,kind,source,nextPaymentDueDate,minimumPaymentAmount,lastStatementBalance,lastStatementIssueDate,lastPaymentAmount,lastPaymentDate,isOverdue,const DeepCollectionEquality().hash(_aprs),interestRateBasisPoints,originationDate,originationPrincipal,loanTerm,nextMonthlyPayment,ytdInterestPaid,ytdPrincipalPaid,const DeepCollectionEquality().hash(_payload)]);
}

@override
String toString() {
    return 'Liability(accountId: $accountId, kind: $kind, source: $source, nextPaymentDueDate: $nextPaymentDueDate, minimumPaymentAmount: $minimumPaymentAmount, lastStatementBalance: $lastStatementBalance, lastStatementIssueDate: $lastStatementIssueDate, lastPaymentAmount: $lastPaymentAmount, lastPaymentDate: $lastPaymentDate, isOverdue: $isOverdue, aprs: $aprs, interestRateBasisPoints: $interestRateBasisPoints, originationDate: $originationDate, originationPrincipal: $originationPrincipal, loanTerm: $loanTerm, nextMonthlyPayment: $nextMonthlyPayment, ytdInterestPaid: $ytdInterestPaid, ytdPrincipalPaid: $ytdPrincipalPaid, payload: $payload)';
}


}

/// @nodoc
abstract mixin class _$LiabilityCopyWith<$Res> implements $LiabilityCopyWith<$Res> {
  factory _$LiabilityCopyWith(_Liability value, $Res Function(_Liability) _then) = __$LiabilityCopyWithImpl;
@override @useResult
$Res call({
 String accountId, LiabilityKind kind, DataSource source, LocalDate? nextPaymentDueDate, Money? minimumPaymentAmount, Money? lastStatementBalance, LocalDate? lastStatementIssueDate, Money? lastPaymentAmount, LocalDate? lastPaymentDate, bool? isOverdue, List<LiabilityApr> aprs, int? interestRateBasisPoints, LocalDate? originationDate, Money? originationPrincipal, String? loanTerm, Money? nextMonthlyPayment, Money? ytdInterestPaid, Money? ytdPrincipalPaid, Map<String, Object?> payload
});




}
/// @nodoc
class __$LiabilityCopyWithImpl<$Res>
    implements _$LiabilityCopyWith<$Res> {
  __$LiabilityCopyWithImpl(this._self, this._then);

  final _Liability _self;
  final $Res Function(_Liability) _then;

/// Create a copy of Liability
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountId = null,Object? kind = null,Object? source = null,Object? nextPaymentDueDate = freezed,Object? minimumPaymentAmount = freezed,Object? lastStatementBalance = freezed,Object? lastStatementIssueDate = freezed,Object? lastPaymentAmount = freezed,Object? lastPaymentDate = freezed,Object? isOverdue = freezed,Object? aprs = null,Object? interestRateBasisPoints = freezed,Object? originationDate = freezed,Object? originationPrincipal = freezed,Object? loanTerm = freezed,Object? nextMonthlyPayment = freezed,Object? ytdInterestPaid = freezed,Object? ytdPrincipalPaid = freezed,Object? payload = null,}) {
  return _then(_Liability(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as LiabilityKind,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as DataSource,nextPaymentDueDate: freezed == nextPaymentDueDate ? _self.nextPaymentDueDate : nextPaymentDueDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,minimumPaymentAmount: freezed == minimumPaymentAmount ? _self.minimumPaymentAmount : minimumPaymentAmount // ignore: cast_nullable_to_non_nullable
as Money?,lastStatementBalance: freezed == lastStatementBalance ? _self.lastStatementBalance : lastStatementBalance // ignore: cast_nullable_to_non_nullable
as Money?,lastStatementIssueDate: freezed == lastStatementIssueDate ? _self.lastStatementIssueDate : lastStatementIssueDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,lastPaymentAmount: freezed == lastPaymentAmount ? _self.lastPaymentAmount : lastPaymentAmount // ignore: cast_nullable_to_non_nullable
as Money?,lastPaymentDate: freezed == lastPaymentDate ? _self.lastPaymentDate : lastPaymentDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,isOverdue: freezed == isOverdue ? _self.isOverdue : isOverdue // ignore: cast_nullable_to_non_nullable
as bool?,aprs: null == aprs ? _self._aprs : aprs // ignore: cast_nullable_to_non_nullable
as List<LiabilityApr>,interestRateBasisPoints: freezed == interestRateBasisPoints ? _self.interestRateBasisPoints : interestRateBasisPoints // ignore: cast_nullable_to_non_nullable
as int?,originationDate: freezed == originationDate ? _self.originationDate : originationDate // ignore: cast_nullable_to_non_nullable
as LocalDate?,originationPrincipal: freezed == originationPrincipal ? _self.originationPrincipal : originationPrincipal // ignore: cast_nullable_to_non_nullable
as Money?,loanTerm: freezed == loanTerm ? _self.loanTerm : loanTerm // ignore: cast_nullable_to_non_nullable
as String?,nextMonthlyPayment: freezed == nextMonthlyPayment ? _self.nextMonthlyPayment : nextMonthlyPayment // ignore: cast_nullable_to_non_nullable
as Money?,ytdInterestPaid: freezed == ytdInterestPaid ? _self.ytdInterestPaid : ytdInterestPaid // ignore: cast_nullable_to_non_nullable
as Money?,ytdPrincipalPaid: freezed == ytdPrincipalPaid ? _self.ytdPrincipalPaid : ytdPrincipalPaid // ignore: cast_nullable_to_non_nullable
as Money?,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}


}

/// @nodoc
mixin _$LiabilityApr {

 String get type; int get percentageBasisPoints; Money? get balanceSubjectToApr;
/// Create a copy of LiabilityApr
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiabilityAprCopyWith<LiabilityApr> get copyWith => _$LiabilityAprCopyWithImpl<LiabilityApr>(this as LiabilityApr, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LiabilityApr;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiabilityApr&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.percentageBasisPoints, _this.percentageBasisPoints) || other.percentageBasisPoints == _this.percentageBasisPoints)&&(identical(other.balanceSubjectToApr, _this.balanceSubjectToApr) || other.balanceSubjectToApr == _this.balanceSubjectToApr));
}


@override
int get hashCode {
  final _this = this as LiabilityApr;
  return Object.hash(runtimeType,_this.type,_this.percentageBasisPoints,_this.balanceSubjectToApr);
}

@override
String toString() {
  final _this = this as LiabilityApr;
  return 'LiabilityApr(type: ${_this.type}, percentageBasisPoints: ${_this.percentageBasisPoints}, balanceSubjectToApr: ${_this.balanceSubjectToApr})';
}


}

/// @nodoc
abstract mixin class $LiabilityAprCopyWith<$Res>  {
  factory $LiabilityAprCopyWith(LiabilityApr value, $Res Function(LiabilityApr) _then) = _$LiabilityAprCopyWithImpl;
@useResult
$Res call({
 String type, int percentageBasisPoints, Money? balanceSubjectToApr
});




}
/// @nodoc
class _$LiabilityAprCopyWithImpl<$Res>
    implements $LiabilityAprCopyWith<$Res> {
  _$LiabilityAprCopyWithImpl(this._self, this._then);

  final LiabilityApr _self;
  final $Res Function(LiabilityApr) _then;

/// Create a copy of LiabilityApr
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? percentageBasisPoints = null,Object? balanceSubjectToApr = freezed,}) {
  return _then(LiabilityApr(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,percentageBasisPoints: null == percentageBasisPoints ? _self.percentageBasisPoints : percentageBasisPoints // ignore: cast_nullable_to_non_nullable
as int,balanceSubjectToApr: freezed == balanceSubjectToApr ? _self.balanceSubjectToApr : balanceSubjectToApr // ignore: cast_nullable_to_non_nullable
as Money?,
  ));
}

}


/// Adds pattern-matching-related methods to [LiabilityApr].
extension LiabilityAprPatterns on LiabilityApr {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiabilityApr value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiabilityApr() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiabilityApr value)  $default,){
final _that = this;
switch (_that) {
case _LiabilityApr():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiabilityApr value)?  $default,){
final _that = this;
switch (_that) {
case _LiabilityApr() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  int percentageBasisPoints,  Money? balanceSubjectToApr)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiabilityApr() when $default != null:
return $default(_that.type,_that.percentageBasisPoints,_that.balanceSubjectToApr);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  int percentageBasisPoints,  Money? balanceSubjectToApr)  $default,) {final _that = this;
switch (_that) {
case _LiabilityApr():
return $default(_that.type,_that.percentageBasisPoints,_that.balanceSubjectToApr);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  int percentageBasisPoints,  Money? balanceSubjectToApr)?  $default,) {final _that = this;
switch (_that) {
case _LiabilityApr() when $default != null:
return $default(_that.type,_that.percentageBasisPoints,_that.balanceSubjectToApr);case _:
  return null;

}
}

}

/// @nodoc


class _LiabilityApr implements LiabilityApr {
  const _LiabilityApr({required this.type, required this.percentageBasisPoints, this.balanceSubjectToApr});
  

@override final  String type;
@override final  int percentageBasisPoints;
@override final  Money? balanceSubjectToApr;

/// Create a copy of LiabilityApr
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiabilityAprCopyWith<_LiabilityApr> get copyWith => __$LiabilityAprCopyWithImpl<_LiabilityApr>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiabilityApr&&(identical(other.type, type) || other.type == type)&&(identical(other.percentageBasisPoints, percentageBasisPoints) || other.percentageBasisPoints == percentageBasisPoints)&&(identical(other.balanceSubjectToApr, balanceSubjectToApr) || other.balanceSubjectToApr == balanceSubjectToApr));
}


@override
int get hashCode {
    return Object.hash(runtimeType,type,percentageBasisPoints,balanceSubjectToApr);
}

@override
String toString() {
    return 'LiabilityApr(type: $type, percentageBasisPoints: $percentageBasisPoints, balanceSubjectToApr: $balanceSubjectToApr)';
}


}

/// @nodoc
abstract mixin class _$LiabilityAprCopyWith<$Res> implements $LiabilityAprCopyWith<$Res> {
  factory _$LiabilityAprCopyWith(_LiabilityApr value, $Res Function(_LiabilityApr) _then) = __$LiabilityAprCopyWithImpl;
@override @useResult
$Res call({
 String type, int percentageBasisPoints, Money? balanceSubjectToApr
});




}
/// @nodoc
class __$LiabilityAprCopyWithImpl<$Res>
    implements _$LiabilityAprCopyWith<$Res> {
  __$LiabilityAprCopyWithImpl(this._self, this._then);

  final _LiabilityApr _self;
  final $Res Function(_LiabilityApr) _then;

/// Create a copy of LiabilityApr
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? percentageBasisPoints = null,Object? balanceSubjectToApr = freezed,}) {
  return _then(_LiabilityApr(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,percentageBasisPoints: null == percentageBasisPoints ? _self.percentageBasisPoints : percentageBasisPoints // ignore: cast_nullable_to_non_nullable
as int,balanceSubjectToApr: freezed == balanceSubjectToApr ? _self.balanceSubjectToApr : balanceSubjectToApr // ignore: cast_nullable_to_non_nullable
as Money?,
  ));
}


}

// dart format on
