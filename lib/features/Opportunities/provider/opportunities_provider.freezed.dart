// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'opportunities_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OpportunitiesState {

 List<OpportunityModel> get items; List<OpportunityModel> get backlogItems; OpportunityStage? get selectedStage; String get searchQuery; String get sortLabel; bool get showBacklog;// Pagination / loading (API-backed pipeline list).
 int get currentPage; int get lastPage; int get total; bool get isLoading; bool get isLoadingMore; Object? get error;
/// Create a copy of OpportunitiesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpportunitiesStateCopyWith<OpportunitiesState> get copyWith => _$OpportunitiesStateCopyWithImpl<OpportunitiesState>(this as OpportunitiesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpportunitiesState&&const DeepCollectionEquality().equals(other.items, items)&&const DeepCollectionEquality().equals(other.backlogItems, backlogItems)&&(identical(other.selectedStage, selectedStage) || other.selectedStage == selectedStage)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.sortLabel, sortLabel) || other.sortLabel == sortLabel)&&(identical(other.showBacklog, showBacklog) || other.showBacklog == showBacklog)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.lastPage, lastPage) || other.lastPage == lastPage)&&(identical(other.total, total) || other.total == total)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),const DeepCollectionEquality().hash(backlogItems),selectedStage,searchQuery,sortLabel,showBacklog,currentPage,lastPage,total,isLoading,isLoadingMore,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'OpportunitiesState(items: $items, backlogItems: $backlogItems, selectedStage: $selectedStage, searchQuery: $searchQuery, sortLabel: $sortLabel, showBacklog: $showBacklog, currentPage: $currentPage, lastPage: $lastPage, total: $total, isLoading: $isLoading, isLoadingMore: $isLoadingMore, error: $error)';
}


}

/// @nodoc
abstract mixin class $OpportunitiesStateCopyWith<$Res>  {
  factory $OpportunitiesStateCopyWith(OpportunitiesState value, $Res Function(OpportunitiesState) _then) = _$OpportunitiesStateCopyWithImpl;
@useResult
$Res call({
 List<OpportunityModel> items, List<OpportunityModel> backlogItems, OpportunityStage? selectedStage, String searchQuery, String sortLabel, bool showBacklog, int currentPage, int lastPage, int total, bool isLoading, bool isLoadingMore, Object? error
});




}
/// @nodoc
class _$OpportunitiesStateCopyWithImpl<$Res>
    implements $OpportunitiesStateCopyWith<$Res> {
  _$OpportunitiesStateCopyWithImpl(this._self, this._then);

  final OpportunitiesState _self;
  final $Res Function(OpportunitiesState) _then;

/// Create a copy of OpportunitiesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? backlogItems = null,Object? selectedStage = freezed,Object? searchQuery = null,Object? sortLabel = null,Object? showBacklog = null,Object? currentPage = null,Object? lastPage = null,Object? total = null,Object? isLoading = null,Object? isLoadingMore = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<OpportunityModel>,backlogItems: null == backlogItems ? _self.backlogItems : backlogItems // ignore: cast_nullable_to_non_nullable
as List<OpportunityModel>,selectedStage: freezed == selectedStage ? _self.selectedStage : selectedStage // ignore: cast_nullable_to_non_nullable
as OpportunityStage?,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,sortLabel: null == sortLabel ? _self.sortLabel : sortLabel // ignore: cast_nullable_to_non_nullable
as String,showBacklog: null == showBacklog ? _self.showBacklog : showBacklog // ignore: cast_nullable_to_non_nullable
as bool,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,lastPage: null == lastPage ? _self.lastPage : lastPage // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error ,
  ));
}

}


/// Adds pattern-matching-related methods to [OpportunitiesState].
extension OpportunitiesStatePatterns on OpportunitiesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpportunitiesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpportunitiesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpportunitiesState value)  $default,){
final _that = this;
switch (_that) {
case _OpportunitiesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpportunitiesState value)?  $default,){
final _that = this;
switch (_that) {
case _OpportunitiesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<OpportunityModel> items,  List<OpportunityModel> backlogItems,  OpportunityStage? selectedStage,  String searchQuery,  String sortLabel,  bool showBacklog,  int currentPage,  int lastPage,  int total,  bool isLoading,  bool isLoadingMore,  Object? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpportunitiesState() when $default != null:
return $default(_that.items,_that.backlogItems,_that.selectedStage,_that.searchQuery,_that.sortLabel,_that.showBacklog,_that.currentPage,_that.lastPage,_that.total,_that.isLoading,_that.isLoadingMore,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<OpportunityModel> items,  List<OpportunityModel> backlogItems,  OpportunityStage? selectedStage,  String searchQuery,  String sortLabel,  bool showBacklog,  int currentPage,  int lastPage,  int total,  bool isLoading,  bool isLoadingMore,  Object? error)  $default,) {final _that = this;
switch (_that) {
case _OpportunitiesState():
return $default(_that.items,_that.backlogItems,_that.selectedStage,_that.searchQuery,_that.sortLabel,_that.showBacklog,_that.currentPage,_that.lastPage,_that.total,_that.isLoading,_that.isLoadingMore,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<OpportunityModel> items,  List<OpportunityModel> backlogItems,  OpportunityStage? selectedStage,  String searchQuery,  String sortLabel,  bool showBacklog,  int currentPage,  int lastPage,  int total,  bool isLoading,  bool isLoadingMore,  Object? error)?  $default,) {final _that = this;
switch (_that) {
case _OpportunitiesState() when $default != null:
return $default(_that.items,_that.backlogItems,_that.selectedStage,_that.searchQuery,_that.sortLabel,_that.showBacklog,_that.currentPage,_that.lastPage,_that.total,_that.isLoading,_that.isLoadingMore,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _OpportunitiesState extends OpportunitiesState {
  const _OpportunitiesState({final  List<OpportunityModel> items = const <OpportunityModel>[], final  List<OpportunityModel> backlogItems = const <OpportunityModel>[], this.selectedStage, this.searchQuery = '', this.sortLabel = 'Newest first', this.showBacklog = false, this.currentPage = 1, this.lastPage = 1, this.total = 0, this.isLoading = true, this.isLoadingMore = false, this.error}): _items = items,_backlogItems = backlogItems,super._();
  

 final  List<OpportunityModel> _items;
@override@JsonKey() List<OpportunityModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  List<OpportunityModel> _backlogItems;
@override@JsonKey() List<OpportunityModel> get backlogItems {
  if (_backlogItems is EqualUnmodifiableListView) return _backlogItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_backlogItems);
}

@override final  OpportunityStage? selectedStage;
@override@JsonKey() final  String searchQuery;
@override@JsonKey() final  String sortLabel;
@override@JsonKey() final  bool showBacklog;
// Pagination / loading (API-backed pipeline list).
@override@JsonKey() final  int currentPage;
@override@JsonKey() final  int lastPage;
@override@JsonKey() final  int total;
@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isLoadingMore;
@override final  Object? error;

/// Create a copy of OpportunitiesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpportunitiesStateCopyWith<_OpportunitiesState> get copyWith => __$OpportunitiesStateCopyWithImpl<_OpportunitiesState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpportunitiesState&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other._backlogItems, _backlogItems)&&(identical(other.selectedStage, selectedStage) || other.selectedStage == selectedStage)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.sortLabel, sortLabel) || other.sortLabel == sortLabel)&&(identical(other.showBacklog, showBacklog) || other.showBacklog == showBacklog)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.lastPage, lastPage) || other.lastPage == lastPage)&&(identical(other.total, total) || other.total == total)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_backlogItems),selectedStage,searchQuery,sortLabel,showBacklog,currentPage,lastPage,total,isLoading,isLoadingMore,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'OpportunitiesState(items: $items, backlogItems: $backlogItems, selectedStage: $selectedStage, searchQuery: $searchQuery, sortLabel: $sortLabel, showBacklog: $showBacklog, currentPage: $currentPage, lastPage: $lastPage, total: $total, isLoading: $isLoading, isLoadingMore: $isLoadingMore, error: $error)';
}


}

/// @nodoc
abstract mixin class _$OpportunitiesStateCopyWith<$Res> implements $OpportunitiesStateCopyWith<$Res> {
  factory _$OpportunitiesStateCopyWith(_OpportunitiesState value, $Res Function(_OpportunitiesState) _then) = __$OpportunitiesStateCopyWithImpl;
@override @useResult
$Res call({
 List<OpportunityModel> items, List<OpportunityModel> backlogItems, OpportunityStage? selectedStage, String searchQuery, String sortLabel, bool showBacklog, int currentPage, int lastPage, int total, bool isLoading, bool isLoadingMore, Object? error
});




}
/// @nodoc
class __$OpportunitiesStateCopyWithImpl<$Res>
    implements _$OpportunitiesStateCopyWith<$Res> {
  __$OpportunitiesStateCopyWithImpl(this._self, this._then);

  final _OpportunitiesState _self;
  final $Res Function(_OpportunitiesState) _then;

/// Create a copy of OpportunitiesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? backlogItems = null,Object? selectedStage = freezed,Object? searchQuery = null,Object? sortLabel = null,Object? showBacklog = null,Object? currentPage = null,Object? lastPage = null,Object? total = null,Object? isLoading = null,Object? isLoadingMore = null,Object? error = freezed,}) {
  return _then(_OpportunitiesState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<OpportunityModel>,backlogItems: null == backlogItems ? _self._backlogItems : backlogItems // ignore: cast_nullable_to_non_nullable
as List<OpportunityModel>,selectedStage: freezed == selectedStage ? _self.selectedStage : selectedStage // ignore: cast_nullable_to_non_nullable
as OpportunityStage?,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,sortLabel: null == sortLabel ? _self.sortLabel : sortLabel // ignore: cast_nullable_to_non_nullable
as String,showBacklog: null == showBacklog ? _self.showBacklog : showBacklog // ignore: cast_nullable_to_non_nullable
as bool,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,lastPage: null == lastPage ? _self.lastPage : lastPage // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error ,
  ));
}


}

// dart format on
