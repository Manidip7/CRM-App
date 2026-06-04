// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskListState {

 int get selectedTab;// 0 = My Tasks, 1 = Team View
 List<TaskModel> get tasks;
/// Create a copy of TaskListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskListStateCopyWith<TaskListState> get copyWith => _$TaskListStateCopyWithImpl<TaskListState>(this as TaskListState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskListState&&(identical(other.selectedTab, selectedTab) || other.selectedTab == selectedTab)&&const DeepCollectionEquality().equals(other.tasks, tasks));
}


@override
int get hashCode => Object.hash(runtimeType,selectedTab,const DeepCollectionEquality().hash(tasks));

@override
String toString() {
  return 'TaskListState(selectedTab: $selectedTab, tasks: $tasks)';
}


}

/// @nodoc
abstract mixin class $TaskListStateCopyWith<$Res>  {
  factory $TaskListStateCopyWith(TaskListState value, $Res Function(TaskListState) _then) = _$TaskListStateCopyWithImpl;
@useResult
$Res call({
 int selectedTab, List<TaskModel> tasks
});




}
/// @nodoc
class _$TaskListStateCopyWithImpl<$Res>
    implements $TaskListStateCopyWith<$Res> {
  _$TaskListStateCopyWithImpl(this._self, this._then);

  final TaskListState _self;
  final $Res Function(TaskListState) _then;

/// Create a copy of TaskListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectedTab = null,Object? tasks = null,}) {
  return _then(_self.copyWith(
selectedTab: null == selectedTab ? _self.selectedTab : selectedTab // ignore: cast_nullable_to_non_nullable
as int,tasks: null == tasks ? _self.tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<TaskModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskListState].
extension TaskListStatePatterns on TaskListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskListState value)  $default,){
final _that = this;
switch (_that) {
case _TaskListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskListState value)?  $default,){
final _that = this;
switch (_that) {
case _TaskListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int selectedTab,  List<TaskModel> tasks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskListState() when $default != null:
return $default(_that.selectedTab,_that.tasks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int selectedTab,  List<TaskModel> tasks)  $default,) {final _that = this;
switch (_that) {
case _TaskListState():
return $default(_that.selectedTab,_that.tasks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int selectedTab,  List<TaskModel> tasks)?  $default,) {final _that = this;
switch (_that) {
case _TaskListState() when $default != null:
return $default(_that.selectedTab,_that.tasks);case _:
  return null;

}
}

}

/// @nodoc


class _TaskListState implements TaskListState {
  const _TaskListState({this.selectedTab = 0, final  List<TaskModel> tasks = const <TaskModel>[]}): _tasks = tasks;
  

@override@JsonKey() final  int selectedTab;
// 0 = My Tasks, 1 = Team View
 final  List<TaskModel> _tasks;
// 0 = My Tasks, 1 = Team View
@override@JsonKey() List<TaskModel> get tasks {
  if (_tasks is EqualUnmodifiableListView) return _tasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasks);
}


/// Create a copy of TaskListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskListStateCopyWith<_TaskListState> get copyWith => __$TaskListStateCopyWithImpl<_TaskListState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskListState&&(identical(other.selectedTab, selectedTab) || other.selectedTab == selectedTab)&&const DeepCollectionEquality().equals(other._tasks, _tasks));
}


@override
int get hashCode => Object.hash(runtimeType,selectedTab,const DeepCollectionEquality().hash(_tasks));

@override
String toString() {
  return 'TaskListState(selectedTab: $selectedTab, tasks: $tasks)';
}


}

/// @nodoc
abstract mixin class _$TaskListStateCopyWith<$Res> implements $TaskListStateCopyWith<$Res> {
  factory _$TaskListStateCopyWith(_TaskListState value, $Res Function(_TaskListState) _then) = __$TaskListStateCopyWithImpl;
@override @useResult
$Res call({
 int selectedTab, List<TaskModel> tasks
});




}
/// @nodoc
class __$TaskListStateCopyWithImpl<$Res>
    implements _$TaskListStateCopyWith<$Res> {
  __$TaskListStateCopyWithImpl(this._self, this._then);

  final _TaskListState _self;
  final $Res Function(_TaskListState) _then;

/// Create a copy of TaskListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectedTab = null,Object? tasks = null,}) {
  return _then(_TaskListState(
selectedTab: null == selectedTab ? _self.selectedTab : selectedTab // ignore: cast_nullable_to_non_nullable
as int,tasks: null == tasks ? _self._tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<TaskModel>,
  ));
}


}

// dart format on
