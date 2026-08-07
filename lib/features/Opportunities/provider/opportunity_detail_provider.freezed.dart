// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'opportunity_detail_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OpportunityDetailState {

 OpportunityStage get stage;/// The raw stage id currently selected in the header dropdown (e.g.
/// `"Prospecting"`). Null until seeded from the opportunity's `stageRaw`.
 String? get stageId; int get probability; bool get closedWon; List<OpportunityProduct> get products;
/// Create a copy of OpportunityDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpportunityDetailStateCopyWith<OpportunityDetailState> get copyWith => _$OpportunityDetailStateCopyWithImpl<OpportunityDetailState>(this as OpportunityDetailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpportunityDetailState&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.stageId, stageId) || other.stageId == stageId)&&(identical(other.probability, probability) || other.probability == probability)&&(identical(other.closedWon, closedWon) || other.closedWon == closedWon)&&const DeepCollectionEquality().equals(other.products, products));
}


@override
int get hashCode => Object.hash(runtimeType,stage,stageId,probability,closedWon,const DeepCollectionEquality().hash(products));

@override
String toString() {
  return 'OpportunityDetailState(stage: $stage, stageId: $stageId, probability: $probability, closedWon: $closedWon, products: $products)';
}


}

/// @nodoc
abstract mixin class $OpportunityDetailStateCopyWith<$Res>  {
  factory $OpportunityDetailStateCopyWith(OpportunityDetailState value, $Res Function(OpportunityDetailState) _then) = _$OpportunityDetailStateCopyWithImpl;
@useResult
$Res call({
 OpportunityStage stage, String? stageId, int probability, bool closedWon, List<OpportunityProduct> products
});




}
/// @nodoc
class _$OpportunityDetailStateCopyWithImpl<$Res>
    implements $OpportunityDetailStateCopyWith<$Res> {
  _$OpportunityDetailStateCopyWithImpl(this._self, this._then);

  final OpportunityDetailState _self;
  final $Res Function(OpportunityDetailState) _then;

/// Create a copy of OpportunityDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stage = null,Object? stageId = freezed,Object? probability = null,Object? closedWon = null,Object? products = null,}) {
  return _then(_self.copyWith(
stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as OpportunityStage,stageId: freezed == stageId ? _self.stageId : stageId // ignore: cast_nullable_to_non_nullable
as String?,probability: null == probability ? _self.probability : probability // ignore: cast_nullable_to_non_nullable
as int,closedWon: null == closedWon ? _self.closedWon : closedWon // ignore: cast_nullable_to_non_nullable
as bool,products: null == products ? _self.products : products // ignore: cast_nullable_to_non_nullable
as List<OpportunityProduct>,
  ));
}

}


/// Adds pattern-matching-related methods to [OpportunityDetailState].
extension OpportunityDetailStatePatterns on OpportunityDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpportunityDetailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpportunityDetailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpportunityDetailState value)  $default,){
final _that = this;
switch (_that) {
case _OpportunityDetailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpportunityDetailState value)?  $default,){
final _that = this;
switch (_that) {
case _OpportunityDetailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OpportunityStage stage,  String? stageId,  int probability,  bool closedWon,  List<OpportunityProduct> products)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpportunityDetailState() when $default != null:
return $default(_that.stage,_that.stageId,_that.probability,_that.closedWon,_that.products);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OpportunityStage stage,  String? stageId,  int probability,  bool closedWon,  List<OpportunityProduct> products)  $default,) {final _that = this;
switch (_that) {
case _OpportunityDetailState():
return $default(_that.stage,_that.stageId,_that.probability,_that.closedWon,_that.products);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OpportunityStage stage,  String? stageId,  int probability,  bool closedWon,  List<OpportunityProduct> products)?  $default,) {final _that = this;
switch (_that) {
case _OpportunityDetailState() when $default != null:
return $default(_that.stage,_that.stageId,_that.probability,_that.closedWon,_that.products);case _:
  return null;

}
}

}

/// @nodoc


class _OpportunityDetailState implements OpportunityDetailState {
  const _OpportunityDetailState({this.stage = OpportunityStage.proposal, this.stageId, this.probability = 50, this.closedWon = false, final  List<OpportunityProduct> products = const <OpportunityProduct>[]}): _products = products;
  

@override@JsonKey() final  OpportunityStage stage;
/// The raw stage id currently selected in the header dropdown (e.g.
/// `"Prospecting"`). Null until seeded from the opportunity's `stageRaw`.
@override final  String? stageId;
@override@JsonKey() final  int probability;
@override@JsonKey() final  bool closedWon;
 final  List<OpportunityProduct> _products;
@override@JsonKey() List<OpportunityProduct> get products {
  if (_products is EqualUnmodifiableListView) return _products;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_products);
}


/// Create a copy of OpportunityDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpportunityDetailStateCopyWith<_OpportunityDetailState> get copyWith => __$OpportunityDetailStateCopyWithImpl<_OpportunityDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpportunityDetailState&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.stageId, stageId) || other.stageId == stageId)&&(identical(other.probability, probability) || other.probability == probability)&&(identical(other.closedWon, closedWon) || other.closedWon == closedWon)&&const DeepCollectionEquality().equals(other._products, _products));
}


@override
int get hashCode => Object.hash(runtimeType,stage,stageId,probability,closedWon,const DeepCollectionEquality().hash(_products));

@override
String toString() {
  return 'OpportunityDetailState(stage: $stage, stageId: $stageId, probability: $probability, closedWon: $closedWon, products: $products)';
}


}

/// @nodoc
abstract mixin class _$OpportunityDetailStateCopyWith<$Res> implements $OpportunityDetailStateCopyWith<$Res> {
  factory _$OpportunityDetailStateCopyWith(_OpportunityDetailState value, $Res Function(_OpportunityDetailState) _then) = __$OpportunityDetailStateCopyWithImpl;
@override @useResult
$Res call({
 OpportunityStage stage, String? stageId, int probability, bool closedWon, List<OpportunityProduct> products
});




}
/// @nodoc
class __$OpportunityDetailStateCopyWithImpl<$Res>
    implements _$OpportunityDetailStateCopyWith<$Res> {
  __$OpportunityDetailStateCopyWithImpl(this._self, this._then);

  final _OpportunityDetailState _self;
  final $Res Function(_OpportunityDetailState) _then;

/// Create a copy of OpportunityDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stage = null,Object? stageId = freezed,Object? probability = null,Object? closedWon = null,Object? products = null,}) {
  return _then(_OpportunityDetailState(
stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as OpportunityStage,stageId: freezed == stageId ? _self.stageId : stageId // ignore: cast_nullable_to_non_nullable
as String?,probability: null == probability ? _self.probability : probability // ignore: cast_nullable_to_non_nullable
as int,closedWon: null == closedWon ? _self.closedWon : closedWon // ignore: cast_nullable_to_non_nullable
as bool,products: null == products ? _self._products : products // ignore: cast_nullable_to_non_nullable
as List<OpportunityProduct>,
  ));
}


}

/// @nodoc
mixin _$OpportunityTaskFormState {

 DateTime? get dueAt; String get priority;/// Backend status (`open` / `in_progress` / `backlog` / `done`). Only sent
/// when editing — the create endpoint doesn't take it.
 String get status; bool get saving;
/// Create a copy of OpportunityTaskFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpportunityTaskFormStateCopyWith<OpportunityTaskFormState> get copyWith => _$OpportunityTaskFormStateCopyWithImpl<OpportunityTaskFormState>(this as OpportunityTaskFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpportunityTaskFormState&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status)&&(identical(other.saving, saving) || other.saving == saving));
}


@override
int get hashCode => Object.hash(runtimeType,dueAt,priority,status,saving);

@override
String toString() {
  return 'OpportunityTaskFormState(dueAt: $dueAt, priority: $priority, status: $status, saving: $saving)';
}


}

/// @nodoc
abstract mixin class $OpportunityTaskFormStateCopyWith<$Res>  {
  factory $OpportunityTaskFormStateCopyWith(OpportunityTaskFormState value, $Res Function(OpportunityTaskFormState) _then) = _$OpportunityTaskFormStateCopyWithImpl;
@useResult
$Res call({
 DateTime? dueAt, String priority, String status, bool saving
});




}
/// @nodoc
class _$OpportunityTaskFormStateCopyWithImpl<$Res>
    implements $OpportunityTaskFormStateCopyWith<$Res> {
  _$OpportunityTaskFormStateCopyWithImpl(this._self, this._then);

  final OpportunityTaskFormState _self;
  final $Res Function(OpportunityTaskFormState) _then;

/// Create a copy of OpportunityTaskFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dueAt = freezed,Object? priority = null,Object? status = null,Object? saving = null,}) {
  return _then(_self.copyWith(
dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OpportunityTaskFormState].
extension OpportunityTaskFormStatePatterns on OpportunityTaskFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpportunityTaskFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpportunityTaskFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpportunityTaskFormState value)  $default,){
final _that = this;
switch (_that) {
case _OpportunityTaskFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpportunityTaskFormState value)?  $default,){
final _that = this;
switch (_that) {
case _OpportunityTaskFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime? dueAt,  String priority,  String status,  bool saving)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpportunityTaskFormState() when $default != null:
return $default(_that.dueAt,_that.priority,_that.status,_that.saving);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime? dueAt,  String priority,  String status,  bool saving)  $default,) {final _that = this;
switch (_that) {
case _OpportunityTaskFormState():
return $default(_that.dueAt,_that.priority,_that.status,_that.saving);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime? dueAt,  String priority,  String status,  bool saving)?  $default,) {final _that = this;
switch (_that) {
case _OpportunityTaskFormState() when $default != null:
return $default(_that.dueAt,_that.priority,_that.status,_that.saving);case _:
  return null;

}
}

}

/// @nodoc


class _OpportunityTaskFormState implements OpportunityTaskFormState {
  const _OpportunityTaskFormState({this.dueAt, this.priority = 'medium', this.status = 'open', this.saving = false});
  

@override final  DateTime? dueAt;
@override@JsonKey() final  String priority;
/// Backend status (`open` / `in_progress` / `backlog` / `done`). Only sent
/// when editing — the create endpoint doesn't take it.
@override@JsonKey() final  String status;
@override@JsonKey() final  bool saving;

/// Create a copy of OpportunityTaskFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpportunityTaskFormStateCopyWith<_OpportunityTaskFormState> get copyWith => __$OpportunityTaskFormStateCopyWithImpl<_OpportunityTaskFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpportunityTaskFormState&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status)&&(identical(other.saving, saving) || other.saving == saving));
}


@override
int get hashCode => Object.hash(runtimeType,dueAt,priority,status,saving);

@override
String toString() {
  return 'OpportunityTaskFormState(dueAt: $dueAt, priority: $priority, status: $status, saving: $saving)';
}


}

/// @nodoc
abstract mixin class _$OpportunityTaskFormStateCopyWith<$Res> implements $OpportunityTaskFormStateCopyWith<$Res> {
  factory _$OpportunityTaskFormStateCopyWith(_OpportunityTaskFormState value, $Res Function(_OpportunityTaskFormState) _then) = __$OpportunityTaskFormStateCopyWithImpl;
@override @useResult
$Res call({
 DateTime? dueAt, String priority, String status, bool saving
});




}
/// @nodoc
class __$OpportunityTaskFormStateCopyWithImpl<$Res>
    implements _$OpportunityTaskFormStateCopyWith<$Res> {
  __$OpportunityTaskFormStateCopyWithImpl(this._self, this._then);

  final _OpportunityTaskFormState _self;
  final $Res Function(_OpportunityTaskFormState) _then;

/// Create a copy of OpportunityTaskFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dueAt = freezed,Object? priority = null,Object? status = null,Object? saving = null,}) {
  return _then(_OpportunityTaskFormState(
dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
