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
 int get currentPage; int get lastPage; int get total; bool get isLoading; bool get isLoadingMore; Object? get error;// Backlog list (API-backed, `category=backlog`).
 bool get backlogLoading; bool get backlogLoaded; Object? get backlogError;// ── Advanced filter (the dropdowns behind the tune button) ──────────────
// Each maps to one query param on `GET /opportunities`. `null` / `false`
// means "All …" and the param is left off the request entirely.
/// `status_id`.
 int? get statusId;/// `stage` — a raw stage id from `GET /opportunity-statuses`. Server-side,
/// unlike [selectedStage], which is the client-side chip row above the list.
 String? get stageFilter;/// `assigned_to`.
 int? get assignedTo;/// Which preset the "All Time" dropdown is showing.
 OpportunityDateRange get dateRange;/// `from_date` / `to_date` — only used by [OpportunityDateRange.custom].
 DateTime? get fromDate; DateTime? get toDate;/// `category=active`.
 bool get activeOnly;/// `quick_filter=my_opportunities`.
 bool get myOpportunitiesOnly;
/// Create a copy of OpportunitiesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpportunitiesStateCopyWith<OpportunitiesState> get copyWith => _$OpportunitiesStateCopyWithImpl<OpportunitiesState>(this as OpportunitiesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpportunitiesState&&const DeepCollectionEquality().equals(other.items, items)&&const DeepCollectionEquality().equals(other.backlogItems, backlogItems)&&(identical(other.selectedStage, selectedStage) || other.selectedStage == selectedStage)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.sortLabel, sortLabel) || other.sortLabel == sortLabel)&&(identical(other.showBacklog, showBacklog) || other.showBacklog == showBacklog)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.lastPage, lastPage) || other.lastPage == lastPage)&&(identical(other.total, total) || other.total == total)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.backlogLoading, backlogLoading) || other.backlogLoading == backlogLoading)&&(identical(other.backlogLoaded, backlogLoaded) || other.backlogLoaded == backlogLoaded)&&const DeepCollectionEquality().equals(other.backlogError, backlogError)&&(identical(other.statusId, statusId) || other.statusId == statusId)&&(identical(other.stageFilter, stageFilter) || other.stageFilter == stageFilter)&&(identical(other.assignedTo, assignedTo) || other.assignedTo == assignedTo)&&(identical(other.dateRange, dateRange) || other.dateRange == dateRange)&&(identical(other.fromDate, fromDate) || other.fromDate == fromDate)&&(identical(other.toDate, toDate) || other.toDate == toDate)&&(identical(other.activeOnly, activeOnly) || other.activeOnly == activeOnly)&&(identical(other.myOpportunitiesOnly, myOpportunitiesOnly) || other.myOpportunitiesOnly == myOpportunitiesOnly));
}


@override
int get hashCode => Object.hashAll([runtimeType,const DeepCollectionEquality().hash(items),const DeepCollectionEquality().hash(backlogItems),selectedStage,searchQuery,sortLabel,showBacklog,currentPage,lastPage,total,isLoading,isLoadingMore,const DeepCollectionEquality().hash(error),backlogLoading,backlogLoaded,const DeepCollectionEquality().hash(backlogError),statusId,stageFilter,assignedTo,dateRange,fromDate,toDate,activeOnly,myOpportunitiesOnly]);

@override
String toString() {
  return 'OpportunitiesState(items: $items, backlogItems: $backlogItems, selectedStage: $selectedStage, searchQuery: $searchQuery, sortLabel: $sortLabel, showBacklog: $showBacklog, currentPage: $currentPage, lastPage: $lastPage, total: $total, isLoading: $isLoading, isLoadingMore: $isLoadingMore, error: $error, backlogLoading: $backlogLoading, backlogLoaded: $backlogLoaded, backlogError: $backlogError, statusId: $statusId, stageFilter: $stageFilter, assignedTo: $assignedTo, dateRange: $dateRange, fromDate: $fromDate, toDate: $toDate, activeOnly: $activeOnly, myOpportunitiesOnly: $myOpportunitiesOnly)';
}


}

/// @nodoc
abstract mixin class $OpportunitiesStateCopyWith<$Res>  {
  factory $OpportunitiesStateCopyWith(OpportunitiesState value, $Res Function(OpportunitiesState) _then) = _$OpportunitiesStateCopyWithImpl;
@useResult
$Res call({
 List<OpportunityModel> items, List<OpportunityModel> backlogItems, OpportunityStage? selectedStage, String searchQuery, String sortLabel, bool showBacklog, int currentPage, int lastPage, int total, bool isLoading, bool isLoadingMore, Object? error, bool backlogLoading, bool backlogLoaded, Object? backlogError, int? statusId, String? stageFilter, int? assignedTo, OpportunityDateRange dateRange, DateTime? fromDate, DateTime? toDate, bool activeOnly, bool myOpportunitiesOnly
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
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? backlogItems = null,Object? selectedStage = freezed,Object? searchQuery = null,Object? sortLabel = null,Object? showBacklog = null,Object? currentPage = null,Object? lastPage = null,Object? total = null,Object? isLoading = null,Object? isLoadingMore = null,Object? error = freezed,Object? backlogLoading = null,Object? backlogLoaded = null,Object? backlogError = freezed,Object? statusId = freezed,Object? stageFilter = freezed,Object? assignedTo = freezed,Object? dateRange = null,Object? fromDate = freezed,Object? toDate = freezed,Object? activeOnly = null,Object? myOpportunitiesOnly = null,}) {
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
as bool,error: freezed == error ? _self.error : error ,backlogLoading: null == backlogLoading ? _self.backlogLoading : backlogLoading // ignore: cast_nullable_to_non_nullable
as bool,backlogLoaded: null == backlogLoaded ? _self.backlogLoaded : backlogLoaded // ignore: cast_nullable_to_non_nullable
as bool,backlogError: freezed == backlogError ? _self.backlogError : backlogError ,statusId: freezed == statusId ? _self.statusId : statusId // ignore: cast_nullable_to_non_nullable
as int?,stageFilter: freezed == stageFilter ? _self.stageFilter : stageFilter // ignore: cast_nullable_to_non_nullable
as String?,assignedTo: freezed == assignedTo ? _self.assignedTo : assignedTo // ignore: cast_nullable_to_non_nullable
as int?,dateRange: null == dateRange ? _self.dateRange : dateRange // ignore: cast_nullable_to_non_nullable
as OpportunityDateRange,fromDate: freezed == fromDate ? _self.fromDate : fromDate // ignore: cast_nullable_to_non_nullable
as DateTime?,toDate: freezed == toDate ? _self.toDate : toDate // ignore: cast_nullable_to_non_nullable
as DateTime?,activeOnly: null == activeOnly ? _self.activeOnly : activeOnly // ignore: cast_nullable_to_non_nullable
as bool,myOpportunitiesOnly: null == myOpportunitiesOnly ? _self.myOpportunitiesOnly : myOpportunitiesOnly // ignore: cast_nullable_to_non_nullable
as bool,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<OpportunityModel> items,  List<OpportunityModel> backlogItems,  OpportunityStage? selectedStage,  String searchQuery,  String sortLabel,  bool showBacklog,  int currentPage,  int lastPage,  int total,  bool isLoading,  bool isLoadingMore,  Object? error,  bool backlogLoading,  bool backlogLoaded,  Object? backlogError,  int? statusId,  String? stageFilter,  int? assignedTo,  OpportunityDateRange dateRange,  DateTime? fromDate,  DateTime? toDate,  bool activeOnly,  bool myOpportunitiesOnly)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpportunitiesState() when $default != null:
return $default(_that.items,_that.backlogItems,_that.selectedStage,_that.searchQuery,_that.sortLabel,_that.showBacklog,_that.currentPage,_that.lastPage,_that.total,_that.isLoading,_that.isLoadingMore,_that.error,_that.backlogLoading,_that.backlogLoaded,_that.backlogError,_that.statusId,_that.stageFilter,_that.assignedTo,_that.dateRange,_that.fromDate,_that.toDate,_that.activeOnly,_that.myOpportunitiesOnly);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<OpportunityModel> items,  List<OpportunityModel> backlogItems,  OpportunityStage? selectedStage,  String searchQuery,  String sortLabel,  bool showBacklog,  int currentPage,  int lastPage,  int total,  bool isLoading,  bool isLoadingMore,  Object? error,  bool backlogLoading,  bool backlogLoaded,  Object? backlogError,  int? statusId,  String? stageFilter,  int? assignedTo,  OpportunityDateRange dateRange,  DateTime? fromDate,  DateTime? toDate,  bool activeOnly,  bool myOpportunitiesOnly)  $default,) {final _that = this;
switch (_that) {
case _OpportunitiesState():
return $default(_that.items,_that.backlogItems,_that.selectedStage,_that.searchQuery,_that.sortLabel,_that.showBacklog,_that.currentPage,_that.lastPage,_that.total,_that.isLoading,_that.isLoadingMore,_that.error,_that.backlogLoading,_that.backlogLoaded,_that.backlogError,_that.statusId,_that.stageFilter,_that.assignedTo,_that.dateRange,_that.fromDate,_that.toDate,_that.activeOnly,_that.myOpportunitiesOnly);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<OpportunityModel> items,  List<OpportunityModel> backlogItems,  OpportunityStage? selectedStage,  String searchQuery,  String sortLabel,  bool showBacklog,  int currentPage,  int lastPage,  int total,  bool isLoading,  bool isLoadingMore,  Object? error,  bool backlogLoading,  bool backlogLoaded,  Object? backlogError,  int? statusId,  String? stageFilter,  int? assignedTo,  OpportunityDateRange dateRange,  DateTime? fromDate,  DateTime? toDate,  bool activeOnly,  bool myOpportunitiesOnly)?  $default,) {final _that = this;
switch (_that) {
case _OpportunitiesState() when $default != null:
return $default(_that.items,_that.backlogItems,_that.selectedStage,_that.searchQuery,_that.sortLabel,_that.showBacklog,_that.currentPage,_that.lastPage,_that.total,_that.isLoading,_that.isLoadingMore,_that.error,_that.backlogLoading,_that.backlogLoaded,_that.backlogError,_that.statusId,_that.stageFilter,_that.assignedTo,_that.dateRange,_that.fromDate,_that.toDate,_that.activeOnly,_that.myOpportunitiesOnly);case _:
  return null;

}
}

}

/// @nodoc


class _OpportunitiesState extends OpportunitiesState {
  const _OpportunitiesState({final  List<OpportunityModel> items = const <OpportunityModel>[], final  List<OpportunityModel> backlogItems = const <OpportunityModel>[], this.selectedStage, this.searchQuery = '', this.sortLabel = 'Newest first', this.showBacklog = false, this.currentPage = 1, this.lastPage = 1, this.total = 0, this.isLoading = true, this.isLoadingMore = false, this.error, this.backlogLoading = false, this.backlogLoaded = false, this.backlogError, this.statusId, this.stageFilter, this.assignedTo, this.dateRange = OpportunityDateRange.allTime, this.fromDate, this.toDate, this.activeOnly = false, this.myOpportunitiesOnly = false}): _items = items,_backlogItems = backlogItems,super._();
  

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
// Backlog list (API-backed, `category=backlog`).
@override@JsonKey() final  bool backlogLoading;
@override@JsonKey() final  bool backlogLoaded;
@override final  Object? backlogError;
// ── Advanced filter (the dropdowns behind the tune button) ──────────────
// Each maps to one query param on `GET /opportunities`. `null` / `false`
// means "All …" and the param is left off the request entirely.
/// `status_id`.
@override final  int? statusId;
/// `stage` — a raw stage id from `GET /opportunity-statuses`. Server-side,
/// unlike [selectedStage], which is the client-side chip row above the list.
@override final  String? stageFilter;
/// `assigned_to`.
@override final  int? assignedTo;
/// Which preset the "All Time" dropdown is showing.
@override@JsonKey() final  OpportunityDateRange dateRange;
/// `from_date` / `to_date` — only used by [OpportunityDateRange.custom].
@override final  DateTime? fromDate;
@override final  DateTime? toDate;
/// `category=active`.
@override@JsonKey() final  bool activeOnly;
/// `quick_filter=my_opportunities`.
@override@JsonKey() final  bool myOpportunitiesOnly;

/// Create a copy of OpportunitiesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpportunitiesStateCopyWith<_OpportunitiesState> get copyWith => __$OpportunitiesStateCopyWithImpl<_OpportunitiesState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpportunitiesState&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other._backlogItems, _backlogItems)&&(identical(other.selectedStage, selectedStage) || other.selectedStage == selectedStage)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.sortLabel, sortLabel) || other.sortLabel == sortLabel)&&(identical(other.showBacklog, showBacklog) || other.showBacklog == showBacklog)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.lastPage, lastPage) || other.lastPage == lastPage)&&(identical(other.total, total) || other.total == total)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.backlogLoading, backlogLoading) || other.backlogLoading == backlogLoading)&&(identical(other.backlogLoaded, backlogLoaded) || other.backlogLoaded == backlogLoaded)&&const DeepCollectionEquality().equals(other.backlogError, backlogError)&&(identical(other.statusId, statusId) || other.statusId == statusId)&&(identical(other.stageFilter, stageFilter) || other.stageFilter == stageFilter)&&(identical(other.assignedTo, assignedTo) || other.assignedTo == assignedTo)&&(identical(other.dateRange, dateRange) || other.dateRange == dateRange)&&(identical(other.fromDate, fromDate) || other.fromDate == fromDate)&&(identical(other.toDate, toDate) || other.toDate == toDate)&&(identical(other.activeOnly, activeOnly) || other.activeOnly == activeOnly)&&(identical(other.myOpportunitiesOnly, myOpportunitiesOnly) || other.myOpportunitiesOnly == myOpportunitiesOnly));
}


@override
int get hashCode => Object.hashAll([runtimeType,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_backlogItems),selectedStage,searchQuery,sortLabel,showBacklog,currentPage,lastPage,total,isLoading,isLoadingMore,const DeepCollectionEquality().hash(error),backlogLoading,backlogLoaded,const DeepCollectionEquality().hash(backlogError),statusId,stageFilter,assignedTo,dateRange,fromDate,toDate,activeOnly,myOpportunitiesOnly]);

@override
String toString() {
  return 'OpportunitiesState(items: $items, backlogItems: $backlogItems, selectedStage: $selectedStage, searchQuery: $searchQuery, sortLabel: $sortLabel, showBacklog: $showBacklog, currentPage: $currentPage, lastPage: $lastPage, total: $total, isLoading: $isLoading, isLoadingMore: $isLoadingMore, error: $error, backlogLoading: $backlogLoading, backlogLoaded: $backlogLoaded, backlogError: $backlogError, statusId: $statusId, stageFilter: $stageFilter, assignedTo: $assignedTo, dateRange: $dateRange, fromDate: $fromDate, toDate: $toDate, activeOnly: $activeOnly, myOpportunitiesOnly: $myOpportunitiesOnly)';
}


}

/// @nodoc
abstract mixin class _$OpportunitiesStateCopyWith<$Res> implements $OpportunitiesStateCopyWith<$Res> {
  factory _$OpportunitiesStateCopyWith(_OpportunitiesState value, $Res Function(_OpportunitiesState) _then) = __$OpportunitiesStateCopyWithImpl;
@override @useResult
$Res call({
 List<OpportunityModel> items, List<OpportunityModel> backlogItems, OpportunityStage? selectedStage, String searchQuery, String sortLabel, bool showBacklog, int currentPage, int lastPage, int total, bool isLoading, bool isLoadingMore, Object? error, bool backlogLoading, bool backlogLoaded, Object? backlogError, int? statusId, String? stageFilter, int? assignedTo, OpportunityDateRange dateRange, DateTime? fromDate, DateTime? toDate, bool activeOnly, bool myOpportunitiesOnly
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
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? backlogItems = null,Object? selectedStage = freezed,Object? searchQuery = null,Object? sortLabel = null,Object? showBacklog = null,Object? currentPage = null,Object? lastPage = null,Object? total = null,Object? isLoading = null,Object? isLoadingMore = null,Object? error = freezed,Object? backlogLoading = null,Object? backlogLoaded = null,Object? backlogError = freezed,Object? statusId = freezed,Object? stageFilter = freezed,Object? assignedTo = freezed,Object? dateRange = null,Object? fromDate = freezed,Object? toDate = freezed,Object? activeOnly = null,Object? myOpportunitiesOnly = null,}) {
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
as bool,error: freezed == error ? _self.error : error ,backlogLoading: null == backlogLoading ? _self.backlogLoading : backlogLoading // ignore: cast_nullable_to_non_nullable
as bool,backlogLoaded: null == backlogLoaded ? _self.backlogLoaded : backlogLoaded // ignore: cast_nullable_to_non_nullable
as bool,backlogError: freezed == backlogError ? _self.backlogError : backlogError ,statusId: freezed == statusId ? _self.statusId : statusId // ignore: cast_nullable_to_non_nullable
as int?,stageFilter: freezed == stageFilter ? _self.stageFilter : stageFilter // ignore: cast_nullable_to_non_nullable
as String?,assignedTo: freezed == assignedTo ? _self.assignedTo : assignedTo // ignore: cast_nullable_to_non_nullable
as int?,dateRange: null == dateRange ? _self.dateRange : dateRange // ignore: cast_nullable_to_non_nullable
as OpportunityDateRange,fromDate: freezed == fromDate ? _self.fromDate : fromDate // ignore: cast_nullable_to_non_nullable
as DateTime?,toDate: freezed == toDate ? _self.toDate : toDate // ignore: cast_nullable_to_non_nullable
as DateTime?,activeOnly: null == activeOnly ? _self.activeOnly : activeOnly // ignore: cast_nullable_to_non_nullable
as bool,myOpportunitiesOnly: null == myOpportunitiesOnly ? _self.myOpportunitiesOnly : myOpportunitiesOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
