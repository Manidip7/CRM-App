// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lead_detail_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LeadDetailState {

 LeadPipelineStatus get pipelineStatus; LeadTemperature get temperature; bool get converted;
/// Create a copy of LeadDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeadDetailStateCopyWith<LeadDetailState> get copyWith => _$LeadDetailStateCopyWithImpl<LeadDetailState>(this as LeadDetailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeadDetailState&&(identical(other.pipelineStatus, pipelineStatus) || other.pipelineStatus == pipelineStatus)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.converted, converted) || other.converted == converted));
}


@override
int get hashCode => Object.hash(runtimeType,pipelineStatus,temperature,converted);

@override
String toString() {
  return 'LeadDetailState(pipelineStatus: $pipelineStatus, temperature: $temperature, converted: $converted)';
}


}

/// @nodoc
abstract mixin class $LeadDetailStateCopyWith<$Res>  {
  factory $LeadDetailStateCopyWith(LeadDetailState value, $Res Function(LeadDetailState) _then) = _$LeadDetailStateCopyWithImpl;
@useResult
$Res call({
 LeadPipelineStatus pipelineStatus, LeadTemperature temperature, bool converted
});




}
/// @nodoc
class _$LeadDetailStateCopyWithImpl<$Res>
    implements $LeadDetailStateCopyWith<$Res> {
  _$LeadDetailStateCopyWithImpl(this._self, this._then);

  final LeadDetailState _self;
  final $Res Function(LeadDetailState) _then;

/// Create a copy of LeadDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pipelineStatus = null,Object? temperature = null,Object? converted = null,}) {
  return _then(_self.copyWith(
pipelineStatus: null == pipelineStatus ? _self.pipelineStatus : pipelineStatus // ignore: cast_nullable_to_non_nullable
as LeadPipelineStatus,temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as LeadTemperature,converted: null == converted ? _self.converted : converted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LeadDetailState].
extension LeadDetailStatePatterns on LeadDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeadDetailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeadDetailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeadDetailState value)  $default,){
final _that = this;
switch (_that) {
case _LeadDetailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeadDetailState value)?  $default,){
final _that = this;
switch (_that) {
case _LeadDetailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LeadPipelineStatus pipelineStatus,  LeadTemperature temperature,  bool converted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeadDetailState() when $default != null:
return $default(_that.pipelineStatus,_that.temperature,_that.converted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LeadPipelineStatus pipelineStatus,  LeadTemperature temperature,  bool converted)  $default,) {final _that = this;
switch (_that) {
case _LeadDetailState():
return $default(_that.pipelineStatus,_that.temperature,_that.converted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LeadPipelineStatus pipelineStatus,  LeadTemperature temperature,  bool converted)?  $default,) {final _that = this;
switch (_that) {
case _LeadDetailState() when $default != null:
return $default(_that.pipelineStatus,_that.temperature,_that.converted);case _:
  return null;

}
}

}

/// @nodoc


class _LeadDetailState implements LeadDetailState {
  const _LeadDetailState({this.pipelineStatus = LeadPipelineStatus.newLead, this.temperature = LeadTemperature.warm, this.converted = false});
  

@override@JsonKey() final  LeadPipelineStatus pipelineStatus;
@override@JsonKey() final  LeadTemperature temperature;
@override@JsonKey() final  bool converted;

/// Create a copy of LeadDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeadDetailStateCopyWith<_LeadDetailState> get copyWith => __$LeadDetailStateCopyWithImpl<_LeadDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeadDetailState&&(identical(other.pipelineStatus, pipelineStatus) || other.pipelineStatus == pipelineStatus)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.converted, converted) || other.converted == converted));
}


@override
int get hashCode => Object.hash(runtimeType,pipelineStatus,temperature,converted);

@override
String toString() {
  return 'LeadDetailState(pipelineStatus: $pipelineStatus, temperature: $temperature, converted: $converted)';
}


}

/// @nodoc
abstract mixin class _$LeadDetailStateCopyWith<$Res> implements $LeadDetailStateCopyWith<$Res> {
  factory _$LeadDetailStateCopyWith(_LeadDetailState value, $Res Function(_LeadDetailState) _then) = __$LeadDetailStateCopyWithImpl;
@override @useResult
$Res call({
 LeadPipelineStatus pipelineStatus, LeadTemperature temperature, bool converted
});




}
/// @nodoc
class __$LeadDetailStateCopyWithImpl<$Res>
    implements _$LeadDetailStateCopyWith<$Res> {
  __$LeadDetailStateCopyWithImpl(this._self, this._then);

  final _LeadDetailState _self;
  final $Res Function(_LeadDetailState) _then;

/// Create a copy of LeadDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pipelineStatus = null,Object? temperature = null,Object? converted = null,}) {
  return _then(_LeadDetailState(
pipelineStatus: null == pipelineStatus ? _self.pipelineStatus : pipelineStatus // ignore: cast_nullable_to_non_nullable
as LeadPipelineStatus,temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as LeadTemperature,converted: null == converted ? _self.converted : converted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
