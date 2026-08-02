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

 LeadPipelineStatus get pipelineStatus; LeadTemperature get temperature; bool get converted;/// Selected backend status id (from `GET /statuses`), shown on the header.
 int? get statusId;
/// Create a copy of LeadDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeadDetailStateCopyWith<LeadDetailState> get copyWith => _$LeadDetailStateCopyWithImpl<LeadDetailState>(this as LeadDetailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeadDetailState&&(identical(other.pipelineStatus, pipelineStatus) || other.pipelineStatus == pipelineStatus)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.converted, converted) || other.converted == converted)&&(identical(other.statusId, statusId) || other.statusId == statusId));
}


@override
int get hashCode => Object.hash(runtimeType,pipelineStatus,temperature,converted,statusId);

@override
String toString() {
  return 'LeadDetailState(pipelineStatus: $pipelineStatus, temperature: $temperature, converted: $converted, statusId: $statusId)';
}


}

/// @nodoc
abstract mixin class $LeadDetailStateCopyWith<$Res>  {
  factory $LeadDetailStateCopyWith(LeadDetailState value, $Res Function(LeadDetailState) _then) = _$LeadDetailStateCopyWithImpl;
@useResult
$Res call({
 LeadPipelineStatus pipelineStatus, LeadTemperature temperature, bool converted, int? statusId
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
@pragma('vm:prefer-inline') @override $Res call({Object? pipelineStatus = null,Object? temperature = null,Object? converted = null,Object? statusId = freezed,}) {
  return _then(_self.copyWith(
pipelineStatus: null == pipelineStatus ? _self.pipelineStatus : pipelineStatus // ignore: cast_nullable_to_non_nullable
as LeadPipelineStatus,temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as LeadTemperature,converted: null == converted ? _self.converted : converted // ignore: cast_nullable_to_non_nullable
as bool,statusId: freezed == statusId ? _self.statusId : statusId // ignore: cast_nullable_to_non_nullable
as int?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LeadPipelineStatus pipelineStatus,  LeadTemperature temperature,  bool converted,  int? statusId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeadDetailState() when $default != null:
return $default(_that.pipelineStatus,_that.temperature,_that.converted,_that.statusId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LeadPipelineStatus pipelineStatus,  LeadTemperature temperature,  bool converted,  int? statusId)  $default,) {final _that = this;
switch (_that) {
case _LeadDetailState():
return $default(_that.pipelineStatus,_that.temperature,_that.converted,_that.statusId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LeadPipelineStatus pipelineStatus,  LeadTemperature temperature,  bool converted,  int? statusId)?  $default,) {final _that = this;
switch (_that) {
case _LeadDetailState() when $default != null:
return $default(_that.pipelineStatus,_that.temperature,_that.converted,_that.statusId);case _:
  return null;

}
}

}

/// @nodoc


class _LeadDetailState implements LeadDetailState {
  const _LeadDetailState({this.pipelineStatus = LeadPipelineStatus.newLead, this.temperature = LeadTemperature.warm, this.converted = false, this.statusId});
  

@override@JsonKey() final  LeadPipelineStatus pipelineStatus;
@override@JsonKey() final  LeadTemperature temperature;
@override@JsonKey() final  bool converted;
/// Selected backend status id (from `GET /statuses`), shown on the header.
@override final  int? statusId;

/// Create a copy of LeadDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeadDetailStateCopyWith<_LeadDetailState> get copyWith => __$LeadDetailStateCopyWithImpl<_LeadDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeadDetailState&&(identical(other.pipelineStatus, pipelineStatus) || other.pipelineStatus == pipelineStatus)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.converted, converted) || other.converted == converted)&&(identical(other.statusId, statusId) || other.statusId == statusId));
}


@override
int get hashCode => Object.hash(runtimeType,pipelineStatus,temperature,converted,statusId);

@override
String toString() {
  return 'LeadDetailState(pipelineStatus: $pipelineStatus, temperature: $temperature, converted: $converted, statusId: $statusId)';
}


}

/// @nodoc
abstract mixin class _$LeadDetailStateCopyWith<$Res> implements $LeadDetailStateCopyWith<$Res> {
  factory _$LeadDetailStateCopyWith(_LeadDetailState value, $Res Function(_LeadDetailState) _then) = __$LeadDetailStateCopyWithImpl;
@override @useResult
$Res call({
 LeadPipelineStatus pipelineStatus, LeadTemperature temperature, bool converted, int? statusId
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
@override @pragma('vm:prefer-inline') $Res call({Object? pipelineStatus = null,Object? temperature = null,Object? converted = null,Object? statusId = freezed,}) {
  return _then(_LeadDetailState(
pipelineStatus: null == pipelineStatus ? _self.pipelineStatus : pipelineStatus // ignore: cast_nullable_to_non_nullable
as LeadPipelineStatus,temperature: null == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as LeadTemperature,converted: null == converted ? _self.converted : converted // ignore: cast_nullable_to_non_nullable
as bool,statusId: freezed == statusId ? _self.statusId : statusId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$ConvertLeadState {

 double get probability; bool get saving;
/// Create a copy of ConvertLeadState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConvertLeadStateCopyWith<ConvertLeadState> get copyWith => _$ConvertLeadStateCopyWithImpl<ConvertLeadState>(this as ConvertLeadState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConvertLeadState&&(identical(other.probability, probability) || other.probability == probability)&&(identical(other.saving, saving) || other.saving == saving));
}


@override
int get hashCode => Object.hash(runtimeType,probability,saving);

@override
String toString() {
  return 'ConvertLeadState(probability: $probability, saving: $saving)';
}


}

/// @nodoc
abstract mixin class $ConvertLeadStateCopyWith<$Res>  {
  factory $ConvertLeadStateCopyWith(ConvertLeadState value, $Res Function(ConvertLeadState) _then) = _$ConvertLeadStateCopyWithImpl;
@useResult
$Res call({
 double probability, bool saving
});




}
/// @nodoc
class _$ConvertLeadStateCopyWithImpl<$Res>
    implements $ConvertLeadStateCopyWith<$Res> {
  _$ConvertLeadStateCopyWithImpl(this._self, this._then);

  final ConvertLeadState _self;
  final $Res Function(ConvertLeadState) _then;

/// Create a copy of ConvertLeadState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? probability = null,Object? saving = null,}) {
  return _then(_self.copyWith(
probability: null == probability ? _self.probability : probability // ignore: cast_nullable_to_non_nullable
as double,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ConvertLeadState].
extension ConvertLeadStatePatterns on ConvertLeadState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConvertLeadState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConvertLeadState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConvertLeadState value)  $default,){
final _that = this;
switch (_that) {
case _ConvertLeadState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConvertLeadState value)?  $default,){
final _that = this;
switch (_that) {
case _ConvertLeadState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double probability,  bool saving)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConvertLeadState() when $default != null:
return $default(_that.probability,_that.saving);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double probability,  bool saving)  $default,) {final _that = this;
switch (_that) {
case _ConvertLeadState():
return $default(_that.probability,_that.saving);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double probability,  bool saving)?  $default,) {final _that = this;
switch (_that) {
case _ConvertLeadState() when $default != null:
return $default(_that.probability,_that.saving);case _:
  return null;

}
}

}

/// @nodoc


class _ConvertLeadState implements ConvertLeadState {
  const _ConvertLeadState({this.probability = 50, this.saving = false});
  

@override@JsonKey() final  double probability;
@override@JsonKey() final  bool saving;

/// Create a copy of ConvertLeadState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConvertLeadStateCopyWith<_ConvertLeadState> get copyWith => __$ConvertLeadStateCopyWithImpl<_ConvertLeadState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConvertLeadState&&(identical(other.probability, probability) || other.probability == probability)&&(identical(other.saving, saving) || other.saving == saving));
}


@override
int get hashCode => Object.hash(runtimeType,probability,saving);

@override
String toString() {
  return 'ConvertLeadState(probability: $probability, saving: $saving)';
}


}

/// @nodoc
abstract mixin class _$ConvertLeadStateCopyWith<$Res> implements $ConvertLeadStateCopyWith<$Res> {
  factory _$ConvertLeadStateCopyWith(_ConvertLeadState value, $Res Function(_ConvertLeadState) _then) = __$ConvertLeadStateCopyWithImpl;
@override @useResult
$Res call({
 double probability, bool saving
});




}
/// @nodoc
class __$ConvertLeadStateCopyWithImpl<$Res>
    implements _$ConvertLeadStateCopyWith<$Res> {
  __$ConvertLeadStateCopyWithImpl(this._self, this._then);

  final _ConvertLeadState _self;
  final $Res Function(_ConvertLeadState) _then;

/// Create a copy of ConvertLeadState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? probability = null,Object? saving = null,}) {
  return _then(_ConvertLeadState(
probability: null == probability ? _self.probability : probability // ignore: cast_nullable_to_non_nullable
as double,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$AddTaskState {

 DateTime? get dueAt; String get priority; bool get saving;
/// Create a copy of AddTaskState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddTaskStateCopyWith<AddTaskState> get copyWith => _$AddTaskStateCopyWithImpl<AddTaskState>(this as AddTaskState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddTaskState&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.saving, saving) || other.saving == saving));
}


@override
int get hashCode => Object.hash(runtimeType,dueAt,priority,saving);

@override
String toString() {
  return 'AddTaskState(dueAt: $dueAt, priority: $priority, saving: $saving)';
}


}

/// @nodoc
abstract mixin class $AddTaskStateCopyWith<$Res>  {
  factory $AddTaskStateCopyWith(AddTaskState value, $Res Function(AddTaskState) _then) = _$AddTaskStateCopyWithImpl;
@useResult
$Res call({
 DateTime? dueAt, String priority, bool saving
});




}
/// @nodoc
class _$AddTaskStateCopyWithImpl<$Res>
    implements $AddTaskStateCopyWith<$Res> {
  _$AddTaskStateCopyWithImpl(this._self, this._then);

  final AddTaskState _self;
  final $Res Function(AddTaskState) _then;

/// Create a copy of AddTaskState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dueAt = freezed,Object? priority = null,Object? saving = null,}) {
  return _then(_self.copyWith(
dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AddTaskState].
extension AddTaskStatePatterns on AddTaskState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AddTaskState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddTaskState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AddTaskState value)  $default,){
final _that = this;
switch (_that) {
case _AddTaskState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AddTaskState value)?  $default,){
final _that = this;
switch (_that) {
case _AddTaskState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime? dueAt,  String priority,  bool saving)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddTaskState() when $default != null:
return $default(_that.dueAt,_that.priority,_that.saving);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime? dueAt,  String priority,  bool saving)  $default,) {final _that = this;
switch (_that) {
case _AddTaskState():
return $default(_that.dueAt,_that.priority,_that.saving);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime? dueAt,  String priority,  bool saving)?  $default,) {final _that = this;
switch (_that) {
case _AddTaskState() when $default != null:
return $default(_that.dueAt,_that.priority,_that.saving);case _:
  return null;

}
}

}

/// @nodoc


class _AddTaskState implements AddTaskState {
  const _AddTaskState({this.dueAt, this.priority = 'medium', this.saving = false});
  

@override final  DateTime? dueAt;
@override@JsonKey() final  String priority;
@override@JsonKey() final  bool saving;

/// Create a copy of AddTaskState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddTaskStateCopyWith<_AddTaskState> get copyWith => __$AddTaskStateCopyWithImpl<_AddTaskState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddTaskState&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.saving, saving) || other.saving == saving));
}


@override
int get hashCode => Object.hash(runtimeType,dueAt,priority,saving);

@override
String toString() {
  return 'AddTaskState(dueAt: $dueAt, priority: $priority, saving: $saving)';
}


}

/// @nodoc
abstract mixin class _$AddTaskStateCopyWith<$Res> implements $AddTaskStateCopyWith<$Res> {
  factory _$AddTaskStateCopyWith(_AddTaskState value, $Res Function(_AddTaskState) _then) = __$AddTaskStateCopyWithImpl;
@override @useResult
$Res call({
 DateTime? dueAt, String priority, bool saving
});




}
/// @nodoc
class __$AddTaskStateCopyWithImpl<$Res>
    implements _$AddTaskStateCopyWith<$Res> {
  __$AddTaskStateCopyWithImpl(this._self, this._then);

  final _AddTaskState _self;
  final $Res Function(_AddTaskState) _then;

/// Create a copy of AddTaskState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dueAt = freezed,Object? priority = null,Object? saving = null,}) {
  return _then(_AddTaskState(
dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$FollowUpFormState {

 NamedLookup? get currentUpdate; NamedLookup? get nextAction; DateTime? get scheduleDate; double get score; bool get saving;
/// Create a copy of FollowUpFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FollowUpFormStateCopyWith<FollowUpFormState> get copyWith => _$FollowUpFormStateCopyWithImpl<FollowUpFormState>(this as FollowUpFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FollowUpFormState&&(identical(other.currentUpdate, currentUpdate) || other.currentUpdate == currentUpdate)&&(identical(other.nextAction, nextAction) || other.nextAction == nextAction)&&(identical(other.scheduleDate, scheduleDate) || other.scheduleDate == scheduleDate)&&(identical(other.score, score) || other.score == score)&&(identical(other.saving, saving) || other.saving == saving));
}


@override
int get hashCode => Object.hash(runtimeType,currentUpdate,nextAction,scheduleDate,score,saving);

@override
String toString() {
  return 'FollowUpFormState(currentUpdate: $currentUpdate, nextAction: $nextAction, scheduleDate: $scheduleDate, score: $score, saving: $saving)';
}


}

/// @nodoc
abstract mixin class $FollowUpFormStateCopyWith<$Res>  {
  factory $FollowUpFormStateCopyWith(FollowUpFormState value, $Res Function(FollowUpFormState) _then) = _$FollowUpFormStateCopyWithImpl;
@useResult
$Res call({
 NamedLookup? currentUpdate, NamedLookup? nextAction, DateTime? scheduleDate, double score, bool saving
});




}
/// @nodoc
class _$FollowUpFormStateCopyWithImpl<$Res>
    implements $FollowUpFormStateCopyWith<$Res> {
  _$FollowUpFormStateCopyWithImpl(this._self, this._then);

  final FollowUpFormState _self;
  final $Res Function(FollowUpFormState) _then;

/// Create a copy of FollowUpFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentUpdate = freezed,Object? nextAction = freezed,Object? scheduleDate = freezed,Object? score = null,Object? saving = null,}) {
  return _then(_self.copyWith(
currentUpdate: freezed == currentUpdate ? _self.currentUpdate : currentUpdate // ignore: cast_nullable_to_non_nullable
as NamedLookup?,nextAction: freezed == nextAction ? _self.nextAction : nextAction // ignore: cast_nullable_to_non_nullable
as NamedLookup?,scheduleDate: freezed == scheduleDate ? _self.scheduleDate : scheduleDate // ignore: cast_nullable_to_non_nullable
as DateTime?,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FollowUpFormState].
extension FollowUpFormStatePatterns on FollowUpFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FollowUpFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FollowUpFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FollowUpFormState value)  $default,){
final _that = this;
switch (_that) {
case _FollowUpFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FollowUpFormState value)?  $default,){
final _that = this;
switch (_that) {
case _FollowUpFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( NamedLookup? currentUpdate,  NamedLookup? nextAction,  DateTime? scheduleDate,  double score,  bool saving)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FollowUpFormState() when $default != null:
return $default(_that.currentUpdate,_that.nextAction,_that.scheduleDate,_that.score,_that.saving);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( NamedLookup? currentUpdate,  NamedLookup? nextAction,  DateTime? scheduleDate,  double score,  bool saving)  $default,) {final _that = this;
switch (_that) {
case _FollowUpFormState():
return $default(_that.currentUpdate,_that.nextAction,_that.scheduleDate,_that.score,_that.saving);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( NamedLookup? currentUpdate,  NamedLookup? nextAction,  DateTime? scheduleDate,  double score,  bool saving)?  $default,) {final _that = this;
switch (_that) {
case _FollowUpFormState() when $default != null:
return $default(_that.currentUpdate,_that.nextAction,_that.scheduleDate,_that.score,_that.saving);case _:
  return null;

}
}

}

/// @nodoc


class _FollowUpFormState implements FollowUpFormState {
  const _FollowUpFormState({this.currentUpdate, this.nextAction, this.scheduleDate, this.score = 50, this.saving = false});
  

@override final  NamedLookup? currentUpdate;
@override final  NamedLookup? nextAction;
@override final  DateTime? scheduleDate;
@override@JsonKey() final  double score;
@override@JsonKey() final  bool saving;

/// Create a copy of FollowUpFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FollowUpFormStateCopyWith<_FollowUpFormState> get copyWith => __$FollowUpFormStateCopyWithImpl<_FollowUpFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FollowUpFormState&&(identical(other.currentUpdate, currentUpdate) || other.currentUpdate == currentUpdate)&&(identical(other.nextAction, nextAction) || other.nextAction == nextAction)&&(identical(other.scheduleDate, scheduleDate) || other.scheduleDate == scheduleDate)&&(identical(other.score, score) || other.score == score)&&(identical(other.saving, saving) || other.saving == saving));
}


@override
int get hashCode => Object.hash(runtimeType,currentUpdate,nextAction,scheduleDate,score,saving);

@override
String toString() {
  return 'FollowUpFormState(currentUpdate: $currentUpdate, nextAction: $nextAction, scheduleDate: $scheduleDate, score: $score, saving: $saving)';
}


}

/// @nodoc
abstract mixin class _$FollowUpFormStateCopyWith<$Res> implements $FollowUpFormStateCopyWith<$Res> {
  factory _$FollowUpFormStateCopyWith(_FollowUpFormState value, $Res Function(_FollowUpFormState) _then) = __$FollowUpFormStateCopyWithImpl;
@override @useResult
$Res call({
 NamedLookup? currentUpdate, NamedLookup? nextAction, DateTime? scheduleDate, double score, bool saving
});




}
/// @nodoc
class __$FollowUpFormStateCopyWithImpl<$Res>
    implements _$FollowUpFormStateCopyWith<$Res> {
  __$FollowUpFormStateCopyWithImpl(this._self, this._then);

  final _FollowUpFormState _self;
  final $Res Function(_FollowUpFormState) _then;

/// Create a copy of FollowUpFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentUpdate = freezed,Object? nextAction = freezed,Object? scheduleDate = freezed,Object? score = null,Object? saving = null,}) {
  return _then(_FollowUpFormState(
currentUpdate: freezed == currentUpdate ? _self.currentUpdate : currentUpdate // ignore: cast_nullable_to_non_nullable
as NamedLookup?,nextAction: freezed == nextAction ? _self.nextAction : nextAction // ignore: cast_nullable_to_non_nullable
as NamedLookup?,scheduleDate: freezed == scheduleDate ? _self.scheduleDate : scheduleDate // ignore: cast_nullable_to_non_nullable
as DateTime?,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$AssignLeadFormState {

 NamedLookup? get territory; NamedLookup? get branch; Set<int> get selectedUserIds; bool get isPrivate; bool get saving;/// Turns the assignee picker red once a submit is attempted with none
/// selected.
 bool get assigneeError;
/// Create a copy of AssignLeadFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssignLeadFormStateCopyWith<AssignLeadFormState> get copyWith => _$AssignLeadFormStateCopyWithImpl<AssignLeadFormState>(this as AssignLeadFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssignLeadFormState&&(identical(other.territory, territory) || other.territory == territory)&&(identical(other.branch, branch) || other.branch == branch)&&const DeepCollectionEquality().equals(other.selectedUserIds, selectedUserIds)&&(identical(other.isPrivate, isPrivate) || other.isPrivate == isPrivate)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.assigneeError, assigneeError) || other.assigneeError == assigneeError));
}


@override
int get hashCode => Object.hash(runtimeType,territory,branch,const DeepCollectionEquality().hash(selectedUserIds),isPrivate,saving,assigneeError);

@override
String toString() {
  return 'AssignLeadFormState(territory: $territory, branch: $branch, selectedUserIds: $selectedUserIds, isPrivate: $isPrivate, saving: $saving, assigneeError: $assigneeError)';
}


}

/// @nodoc
abstract mixin class $AssignLeadFormStateCopyWith<$Res>  {
  factory $AssignLeadFormStateCopyWith(AssignLeadFormState value, $Res Function(AssignLeadFormState) _then) = _$AssignLeadFormStateCopyWithImpl;
@useResult
$Res call({
 NamedLookup? territory, NamedLookup? branch, Set<int> selectedUserIds, bool isPrivate, bool saving, bool assigneeError
});




}
/// @nodoc
class _$AssignLeadFormStateCopyWithImpl<$Res>
    implements $AssignLeadFormStateCopyWith<$Res> {
  _$AssignLeadFormStateCopyWithImpl(this._self, this._then);

  final AssignLeadFormState _self;
  final $Res Function(AssignLeadFormState) _then;

/// Create a copy of AssignLeadFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? territory = freezed,Object? branch = freezed,Object? selectedUserIds = null,Object? isPrivate = null,Object? saving = null,Object? assigneeError = null,}) {
  return _then(_self.copyWith(
territory: freezed == territory ? _self.territory : territory // ignore: cast_nullable_to_non_nullable
as NamedLookup?,branch: freezed == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as NamedLookup?,selectedUserIds: null == selectedUserIds ? _self.selectedUserIds : selectedUserIds // ignore: cast_nullable_to_non_nullable
as Set<int>,isPrivate: null == isPrivate ? _self.isPrivate : isPrivate // ignore: cast_nullable_to_non_nullable
as bool,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,assigneeError: null == assigneeError ? _self.assigneeError : assigneeError // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AssignLeadFormState].
extension AssignLeadFormStatePatterns on AssignLeadFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssignLeadFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssignLeadFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssignLeadFormState value)  $default,){
final _that = this;
switch (_that) {
case _AssignLeadFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssignLeadFormState value)?  $default,){
final _that = this;
switch (_that) {
case _AssignLeadFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( NamedLookup? territory,  NamedLookup? branch,  Set<int> selectedUserIds,  bool isPrivate,  bool saving,  bool assigneeError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssignLeadFormState() when $default != null:
return $default(_that.territory,_that.branch,_that.selectedUserIds,_that.isPrivate,_that.saving,_that.assigneeError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( NamedLookup? territory,  NamedLookup? branch,  Set<int> selectedUserIds,  bool isPrivate,  bool saving,  bool assigneeError)  $default,) {final _that = this;
switch (_that) {
case _AssignLeadFormState():
return $default(_that.territory,_that.branch,_that.selectedUserIds,_that.isPrivate,_that.saving,_that.assigneeError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( NamedLookup? territory,  NamedLookup? branch,  Set<int> selectedUserIds,  bool isPrivate,  bool saving,  bool assigneeError)?  $default,) {final _that = this;
switch (_that) {
case _AssignLeadFormState() when $default != null:
return $default(_that.territory,_that.branch,_that.selectedUserIds,_that.isPrivate,_that.saving,_that.assigneeError);case _:
  return null;

}
}

}

/// @nodoc


class _AssignLeadFormState implements AssignLeadFormState {
  const _AssignLeadFormState({this.territory, this.branch, final  Set<int> selectedUserIds = const <int>{}, this.isPrivate = false, this.saving = false, this.assigneeError = false}): _selectedUserIds = selectedUserIds;
  

@override final  NamedLookup? territory;
@override final  NamedLookup? branch;
 final  Set<int> _selectedUserIds;
@override@JsonKey() Set<int> get selectedUserIds {
  if (_selectedUserIds is EqualUnmodifiableSetView) return _selectedUserIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedUserIds);
}

@override@JsonKey() final  bool isPrivate;
@override@JsonKey() final  bool saving;
/// Turns the assignee picker red once a submit is attempted with none
/// selected.
@override@JsonKey() final  bool assigneeError;

/// Create a copy of AssignLeadFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssignLeadFormStateCopyWith<_AssignLeadFormState> get copyWith => __$AssignLeadFormStateCopyWithImpl<_AssignLeadFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssignLeadFormState&&(identical(other.territory, territory) || other.territory == territory)&&(identical(other.branch, branch) || other.branch == branch)&&const DeepCollectionEquality().equals(other._selectedUserIds, _selectedUserIds)&&(identical(other.isPrivate, isPrivate) || other.isPrivate == isPrivate)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.assigneeError, assigneeError) || other.assigneeError == assigneeError));
}


@override
int get hashCode => Object.hash(runtimeType,territory,branch,const DeepCollectionEquality().hash(_selectedUserIds),isPrivate,saving,assigneeError);

@override
String toString() {
  return 'AssignLeadFormState(territory: $territory, branch: $branch, selectedUserIds: $selectedUserIds, isPrivate: $isPrivate, saving: $saving, assigneeError: $assigneeError)';
}


}

/// @nodoc
abstract mixin class _$AssignLeadFormStateCopyWith<$Res> implements $AssignLeadFormStateCopyWith<$Res> {
  factory _$AssignLeadFormStateCopyWith(_AssignLeadFormState value, $Res Function(_AssignLeadFormState) _then) = __$AssignLeadFormStateCopyWithImpl;
@override @useResult
$Res call({
 NamedLookup? territory, NamedLookup? branch, Set<int> selectedUserIds, bool isPrivate, bool saving, bool assigneeError
});




}
/// @nodoc
class __$AssignLeadFormStateCopyWithImpl<$Res>
    implements _$AssignLeadFormStateCopyWith<$Res> {
  __$AssignLeadFormStateCopyWithImpl(this._self, this._then);

  final _AssignLeadFormState _self;
  final $Res Function(_AssignLeadFormState) _then;

/// Create a copy of AssignLeadFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? territory = freezed,Object? branch = freezed,Object? selectedUserIds = null,Object? isPrivate = null,Object? saving = null,Object? assigneeError = null,}) {
  return _then(_AssignLeadFormState(
territory: freezed == territory ? _self.territory : territory // ignore: cast_nullable_to_non_nullable
as NamedLookup?,branch: freezed == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as NamedLookup?,selectedUserIds: null == selectedUserIds ? _self._selectedUserIds : selectedUserIds // ignore: cast_nullable_to_non_nullable
as Set<int>,isPrivate: null == isPrivate ? _self.isPrivate : isPrivate // ignore: cast_nullable_to_non_nullable
as bool,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,assigneeError: null == assigneeError ? _self.assigneeError : assigneeError // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
