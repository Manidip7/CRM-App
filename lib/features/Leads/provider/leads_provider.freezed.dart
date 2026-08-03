// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leads_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LeadsFilterState {

 String get searchQuery; LeadStatus? get filterStatus; LeadSource? get filterSource;/// Server-side `quick_filter` values (today / upcoming / overdue /
/// my_leads). Multiple can be active at once.
 Set<String> get quickFilters; bool get showBacklog;/// Server-side date range filter (`from_date` / `to_date`).
 DateTime? get fromDate; DateTime? get toDate;// ── Advanced filter (the dropdowns behind the tune button) ──────────────
// Each maps to one query param on `GET /leads`. `null` means "All …" and
// the param is left off the request entirely.
/// `status_id` — takes precedence over the [filterStatus] chip.
 int? get statusId;/// `lead_source_id`.
 int? get leadSourceId;/// `lead_type_id`.
 int? get leadTypeId;/// `territory_id`.
 int? get territoryId;/// `assigned_to`.
 int? get assignedTo;/// Which preset the "All Time" dropdown is showing. The dates it resolved
/// to live in [fromDate] / [toDate].
 LeadDateRange get dateRange;
/// Create a copy of LeadsFilterState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeadsFilterStateCopyWith<LeadsFilterState> get copyWith => _$LeadsFilterStateCopyWithImpl<LeadsFilterState>(this as LeadsFilterState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeadsFilterState&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.filterStatus, filterStatus) || other.filterStatus == filterStatus)&&(identical(other.filterSource, filterSource) || other.filterSource == filterSource)&&const DeepCollectionEquality().equals(other.quickFilters, quickFilters)&&(identical(other.showBacklog, showBacklog) || other.showBacklog == showBacklog)&&(identical(other.fromDate, fromDate) || other.fromDate == fromDate)&&(identical(other.toDate, toDate) || other.toDate == toDate)&&(identical(other.statusId, statusId) || other.statusId == statusId)&&(identical(other.leadSourceId, leadSourceId) || other.leadSourceId == leadSourceId)&&(identical(other.leadTypeId, leadTypeId) || other.leadTypeId == leadTypeId)&&(identical(other.territoryId, territoryId) || other.territoryId == territoryId)&&(identical(other.assignedTo, assignedTo) || other.assignedTo == assignedTo)&&(identical(other.dateRange, dateRange) || other.dateRange == dateRange));
}


@override
int get hashCode => Object.hash(runtimeType,searchQuery,filterStatus,filterSource,const DeepCollectionEquality().hash(quickFilters),showBacklog,fromDate,toDate,statusId,leadSourceId,leadTypeId,territoryId,assignedTo,dateRange);

@override
String toString() {
  return 'LeadsFilterState(searchQuery: $searchQuery, filterStatus: $filterStatus, filterSource: $filterSource, quickFilters: $quickFilters, showBacklog: $showBacklog, fromDate: $fromDate, toDate: $toDate, statusId: $statusId, leadSourceId: $leadSourceId, leadTypeId: $leadTypeId, territoryId: $territoryId, assignedTo: $assignedTo, dateRange: $dateRange)';
}


}

/// @nodoc
abstract mixin class $LeadsFilterStateCopyWith<$Res>  {
  factory $LeadsFilterStateCopyWith(LeadsFilterState value, $Res Function(LeadsFilterState) _then) = _$LeadsFilterStateCopyWithImpl;
@useResult
$Res call({
 String searchQuery, LeadStatus? filterStatus, LeadSource? filterSource, Set<String> quickFilters, bool showBacklog, DateTime? fromDate, DateTime? toDate, int? statusId, int? leadSourceId, int? leadTypeId, int? territoryId, int? assignedTo, LeadDateRange dateRange
});




}
/// @nodoc
class _$LeadsFilterStateCopyWithImpl<$Res>
    implements $LeadsFilterStateCopyWith<$Res> {
  _$LeadsFilterStateCopyWithImpl(this._self, this._then);

  final LeadsFilterState _self;
  final $Res Function(LeadsFilterState) _then;

/// Create a copy of LeadsFilterState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? searchQuery = null,Object? filterStatus = freezed,Object? filterSource = freezed,Object? quickFilters = null,Object? showBacklog = null,Object? fromDate = freezed,Object? toDate = freezed,Object? statusId = freezed,Object? leadSourceId = freezed,Object? leadTypeId = freezed,Object? territoryId = freezed,Object? assignedTo = freezed,Object? dateRange = null,}) {
  return _then(_self.copyWith(
searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,filterStatus: freezed == filterStatus ? _self.filterStatus : filterStatus // ignore: cast_nullable_to_non_nullable
as LeadStatus?,filterSource: freezed == filterSource ? _self.filterSource : filterSource // ignore: cast_nullable_to_non_nullable
as LeadSource?,quickFilters: null == quickFilters ? _self.quickFilters : quickFilters // ignore: cast_nullable_to_non_nullable
as Set<String>,showBacklog: null == showBacklog ? _self.showBacklog : showBacklog // ignore: cast_nullable_to_non_nullable
as bool,fromDate: freezed == fromDate ? _self.fromDate : fromDate // ignore: cast_nullable_to_non_nullable
as DateTime?,toDate: freezed == toDate ? _self.toDate : toDate // ignore: cast_nullable_to_non_nullable
as DateTime?,statusId: freezed == statusId ? _self.statusId : statusId // ignore: cast_nullable_to_non_nullable
as int?,leadSourceId: freezed == leadSourceId ? _self.leadSourceId : leadSourceId // ignore: cast_nullable_to_non_nullable
as int?,leadTypeId: freezed == leadTypeId ? _self.leadTypeId : leadTypeId // ignore: cast_nullable_to_non_nullable
as int?,territoryId: freezed == territoryId ? _self.territoryId : territoryId // ignore: cast_nullable_to_non_nullable
as int?,assignedTo: freezed == assignedTo ? _self.assignedTo : assignedTo // ignore: cast_nullable_to_non_nullable
as int?,dateRange: null == dateRange ? _self.dateRange : dateRange // ignore: cast_nullable_to_non_nullable
as LeadDateRange,
  ));
}

}


/// Adds pattern-matching-related methods to [LeadsFilterState].
extension LeadsFilterStatePatterns on LeadsFilterState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeadsFilterState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeadsFilterState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeadsFilterState value)  $default,){
final _that = this;
switch (_that) {
case _LeadsFilterState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeadsFilterState value)?  $default,){
final _that = this;
switch (_that) {
case _LeadsFilterState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String searchQuery,  LeadStatus? filterStatus,  LeadSource? filterSource,  Set<String> quickFilters,  bool showBacklog,  DateTime? fromDate,  DateTime? toDate,  int? statusId,  int? leadSourceId,  int? leadTypeId,  int? territoryId,  int? assignedTo,  LeadDateRange dateRange)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeadsFilterState() when $default != null:
return $default(_that.searchQuery,_that.filterStatus,_that.filterSource,_that.quickFilters,_that.showBacklog,_that.fromDate,_that.toDate,_that.statusId,_that.leadSourceId,_that.leadTypeId,_that.territoryId,_that.assignedTo,_that.dateRange);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String searchQuery,  LeadStatus? filterStatus,  LeadSource? filterSource,  Set<String> quickFilters,  bool showBacklog,  DateTime? fromDate,  DateTime? toDate,  int? statusId,  int? leadSourceId,  int? leadTypeId,  int? territoryId,  int? assignedTo,  LeadDateRange dateRange)  $default,) {final _that = this;
switch (_that) {
case _LeadsFilterState():
return $default(_that.searchQuery,_that.filterStatus,_that.filterSource,_that.quickFilters,_that.showBacklog,_that.fromDate,_that.toDate,_that.statusId,_that.leadSourceId,_that.leadTypeId,_that.territoryId,_that.assignedTo,_that.dateRange);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String searchQuery,  LeadStatus? filterStatus,  LeadSource? filterSource,  Set<String> quickFilters,  bool showBacklog,  DateTime? fromDate,  DateTime? toDate,  int? statusId,  int? leadSourceId,  int? leadTypeId,  int? territoryId,  int? assignedTo,  LeadDateRange dateRange)?  $default,) {final _that = this;
switch (_that) {
case _LeadsFilterState() when $default != null:
return $default(_that.searchQuery,_that.filterStatus,_that.filterSource,_that.quickFilters,_that.showBacklog,_that.fromDate,_that.toDate,_that.statusId,_that.leadSourceId,_that.leadTypeId,_that.territoryId,_that.assignedTo,_that.dateRange);case _:
  return null;

}
}

}

/// @nodoc


class _LeadsFilterState extends LeadsFilterState {
  const _LeadsFilterState({this.searchQuery = '', this.filterStatus, this.filterSource, final  Set<String> quickFilters = const <String>{}, this.showBacklog = false, this.fromDate, this.toDate, this.statusId, this.leadSourceId, this.leadTypeId, this.territoryId, this.assignedTo, this.dateRange = LeadDateRange.allTime}): _quickFilters = quickFilters,super._();
  

@override@JsonKey() final  String searchQuery;
@override final  LeadStatus? filterStatus;
@override final  LeadSource? filterSource;
/// Server-side `quick_filter` values (today / upcoming / overdue /
/// my_leads). Multiple can be active at once.
 final  Set<String> _quickFilters;
/// Server-side `quick_filter` values (today / upcoming / overdue /
/// my_leads). Multiple can be active at once.
@override@JsonKey() Set<String> get quickFilters {
  if (_quickFilters is EqualUnmodifiableSetView) return _quickFilters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_quickFilters);
}

@override@JsonKey() final  bool showBacklog;
/// Server-side date range filter (`from_date` / `to_date`).
@override final  DateTime? fromDate;
@override final  DateTime? toDate;
// ── Advanced filter (the dropdowns behind the tune button) ──────────────
// Each maps to one query param on `GET /leads`. `null` means "All …" and
// the param is left off the request entirely.
/// `status_id` — takes precedence over the [filterStatus] chip.
@override final  int? statusId;
/// `lead_source_id`.
@override final  int? leadSourceId;
/// `lead_type_id`.
@override final  int? leadTypeId;
/// `territory_id`.
@override final  int? territoryId;
/// `assigned_to`.
@override final  int? assignedTo;
/// Which preset the "All Time" dropdown is showing. The dates it resolved
/// to live in [fromDate] / [toDate].
@override@JsonKey() final  LeadDateRange dateRange;

/// Create a copy of LeadsFilterState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeadsFilterStateCopyWith<_LeadsFilterState> get copyWith => __$LeadsFilterStateCopyWithImpl<_LeadsFilterState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeadsFilterState&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.filterStatus, filterStatus) || other.filterStatus == filterStatus)&&(identical(other.filterSource, filterSource) || other.filterSource == filterSource)&&const DeepCollectionEquality().equals(other._quickFilters, _quickFilters)&&(identical(other.showBacklog, showBacklog) || other.showBacklog == showBacklog)&&(identical(other.fromDate, fromDate) || other.fromDate == fromDate)&&(identical(other.toDate, toDate) || other.toDate == toDate)&&(identical(other.statusId, statusId) || other.statusId == statusId)&&(identical(other.leadSourceId, leadSourceId) || other.leadSourceId == leadSourceId)&&(identical(other.leadTypeId, leadTypeId) || other.leadTypeId == leadTypeId)&&(identical(other.territoryId, territoryId) || other.territoryId == territoryId)&&(identical(other.assignedTo, assignedTo) || other.assignedTo == assignedTo)&&(identical(other.dateRange, dateRange) || other.dateRange == dateRange));
}


@override
int get hashCode => Object.hash(runtimeType,searchQuery,filterStatus,filterSource,const DeepCollectionEquality().hash(_quickFilters),showBacklog,fromDate,toDate,statusId,leadSourceId,leadTypeId,territoryId,assignedTo,dateRange);

@override
String toString() {
  return 'LeadsFilterState(searchQuery: $searchQuery, filterStatus: $filterStatus, filterSource: $filterSource, quickFilters: $quickFilters, showBacklog: $showBacklog, fromDate: $fromDate, toDate: $toDate, statusId: $statusId, leadSourceId: $leadSourceId, leadTypeId: $leadTypeId, territoryId: $territoryId, assignedTo: $assignedTo, dateRange: $dateRange)';
}


}

/// @nodoc
abstract mixin class _$LeadsFilterStateCopyWith<$Res> implements $LeadsFilterStateCopyWith<$Res> {
  factory _$LeadsFilterStateCopyWith(_LeadsFilterState value, $Res Function(_LeadsFilterState) _then) = __$LeadsFilterStateCopyWithImpl;
@override @useResult
$Res call({
 String searchQuery, LeadStatus? filterStatus, LeadSource? filterSource, Set<String> quickFilters, bool showBacklog, DateTime? fromDate, DateTime? toDate, int? statusId, int? leadSourceId, int? leadTypeId, int? territoryId, int? assignedTo, LeadDateRange dateRange
});




}
/// @nodoc
class __$LeadsFilterStateCopyWithImpl<$Res>
    implements _$LeadsFilterStateCopyWith<$Res> {
  __$LeadsFilterStateCopyWithImpl(this._self, this._then);

  final _LeadsFilterState _self;
  final $Res Function(_LeadsFilterState) _then;

/// Create a copy of LeadsFilterState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? searchQuery = null,Object? filterStatus = freezed,Object? filterSource = freezed,Object? quickFilters = null,Object? showBacklog = null,Object? fromDate = freezed,Object? toDate = freezed,Object? statusId = freezed,Object? leadSourceId = freezed,Object? leadTypeId = freezed,Object? territoryId = freezed,Object? assignedTo = freezed,Object? dateRange = null,}) {
  return _then(_LeadsFilterState(
searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,filterStatus: freezed == filterStatus ? _self.filterStatus : filterStatus // ignore: cast_nullable_to_non_nullable
as LeadStatus?,filterSource: freezed == filterSource ? _self.filterSource : filterSource // ignore: cast_nullable_to_non_nullable
as LeadSource?,quickFilters: null == quickFilters ? _self._quickFilters : quickFilters // ignore: cast_nullable_to_non_nullable
as Set<String>,showBacklog: null == showBacklog ? _self.showBacklog : showBacklog // ignore: cast_nullable_to_non_nullable
as bool,fromDate: freezed == fromDate ? _self.fromDate : fromDate // ignore: cast_nullable_to_non_nullable
as DateTime?,toDate: freezed == toDate ? _self.toDate : toDate // ignore: cast_nullable_to_non_nullable
as DateTime?,statusId: freezed == statusId ? _self.statusId : statusId // ignore: cast_nullable_to_non_nullable
as int?,leadSourceId: freezed == leadSourceId ? _self.leadSourceId : leadSourceId // ignore: cast_nullable_to_non_nullable
as int?,leadTypeId: freezed == leadTypeId ? _self.leadTypeId : leadTypeId // ignore: cast_nullable_to_non_nullable
as int?,territoryId: freezed == territoryId ? _self.territoryId : territoryId // ignore: cast_nullable_to_non_nullable
as int?,assignedTo: freezed == assignedTo ? _self.assignedTo : assignedTo // ignore: cast_nullable_to_non_nullable
as int?,dateRange: null == dateRange ? _self.dateRange : dateRange // ignore: cast_nullable_to_non_nullable
as LeadDateRange,
  ));
}


}

/// @nodoc
mixin _$LeadsPagination {

 int get currentPage; int get lastPage; int get total; bool get isLoadingMore;
/// Create a copy of LeadsPagination
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeadsPaginationCopyWith<LeadsPagination> get copyWith => _$LeadsPaginationCopyWithImpl<LeadsPagination>(this as LeadsPagination, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeadsPagination&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.lastPage, lastPage) || other.lastPage == lastPage)&&(identical(other.total, total) || other.total == total)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore));
}


@override
int get hashCode => Object.hash(runtimeType,currentPage,lastPage,total,isLoadingMore);

@override
String toString() {
  return 'LeadsPagination(currentPage: $currentPage, lastPage: $lastPage, total: $total, isLoadingMore: $isLoadingMore)';
}


}

/// @nodoc
abstract mixin class $LeadsPaginationCopyWith<$Res>  {
  factory $LeadsPaginationCopyWith(LeadsPagination value, $Res Function(LeadsPagination) _then) = _$LeadsPaginationCopyWithImpl;
@useResult
$Res call({
 int currentPage, int lastPage, int total, bool isLoadingMore
});




}
/// @nodoc
class _$LeadsPaginationCopyWithImpl<$Res>
    implements $LeadsPaginationCopyWith<$Res> {
  _$LeadsPaginationCopyWithImpl(this._self, this._then);

  final LeadsPagination _self;
  final $Res Function(LeadsPagination) _then;

/// Create a copy of LeadsPagination
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentPage = null,Object? lastPage = null,Object? total = null,Object? isLoadingMore = null,}) {
  return _then(_self.copyWith(
currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,lastPage: null == lastPage ? _self.lastPage : lastPage // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LeadsPagination].
extension LeadsPaginationPatterns on LeadsPagination {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeadsPagination value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeadsPagination() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeadsPagination value)  $default,){
final _that = this;
switch (_that) {
case _LeadsPagination():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeadsPagination value)?  $default,){
final _that = this;
switch (_that) {
case _LeadsPagination() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int currentPage,  int lastPage,  int total,  bool isLoadingMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeadsPagination() when $default != null:
return $default(_that.currentPage,_that.lastPage,_that.total,_that.isLoadingMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int currentPage,  int lastPage,  int total,  bool isLoadingMore)  $default,) {final _that = this;
switch (_that) {
case _LeadsPagination():
return $default(_that.currentPage,_that.lastPage,_that.total,_that.isLoadingMore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int currentPage,  int lastPage,  int total,  bool isLoadingMore)?  $default,) {final _that = this;
switch (_that) {
case _LeadsPagination() when $default != null:
return $default(_that.currentPage,_that.lastPage,_that.total,_that.isLoadingMore);case _:
  return null;

}
}

}

/// @nodoc


class _LeadsPagination extends LeadsPagination {
  const _LeadsPagination({this.currentPage = 1, this.lastPage = 1, this.total = 0, this.isLoadingMore = false}): super._();
  

@override@JsonKey() final  int currentPage;
@override@JsonKey() final  int lastPage;
@override@JsonKey() final  int total;
@override@JsonKey() final  bool isLoadingMore;

/// Create a copy of LeadsPagination
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeadsPaginationCopyWith<_LeadsPagination> get copyWith => __$LeadsPaginationCopyWithImpl<_LeadsPagination>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeadsPagination&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.lastPage, lastPage) || other.lastPage == lastPage)&&(identical(other.total, total) || other.total == total)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore));
}


@override
int get hashCode => Object.hash(runtimeType,currentPage,lastPage,total,isLoadingMore);

@override
String toString() {
  return 'LeadsPagination(currentPage: $currentPage, lastPage: $lastPage, total: $total, isLoadingMore: $isLoadingMore)';
}


}

/// @nodoc
abstract mixin class _$LeadsPaginationCopyWith<$Res> implements $LeadsPaginationCopyWith<$Res> {
  factory _$LeadsPaginationCopyWith(_LeadsPagination value, $Res Function(_LeadsPagination) _then) = __$LeadsPaginationCopyWithImpl;
@override @useResult
$Res call({
 int currentPage, int lastPage, int total, bool isLoadingMore
});




}
/// @nodoc
class __$LeadsPaginationCopyWithImpl<$Res>
    implements _$LeadsPaginationCopyWith<$Res> {
  __$LeadsPaginationCopyWithImpl(this._self, this._then);

  final _LeadsPagination _self;
  final $Res Function(_LeadsPagination) _then;

/// Create a copy of LeadsPagination
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentPage = null,Object? lastPage = null,Object? total = null,Object? isLoadingMore = null,}) {
  return _then(_LeadsPagination(
currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,lastPage: null == lastPage ? _self.lastPage : lastPage // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
