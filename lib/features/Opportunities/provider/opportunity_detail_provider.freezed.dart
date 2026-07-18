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

// dart format on
