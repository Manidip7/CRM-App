// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_quotation_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QuotationLineDraft {

 int get id; String get description; int get quantity; double get price;
/// Create a copy of QuotationLineDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuotationLineDraftCopyWith<QuotationLineDraft> get copyWith => _$QuotationLineDraftCopyWithImpl<QuotationLineDraft>(this as QuotationLineDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuotationLineDraft&&(identical(other.id, id) || other.id == id)&&(identical(other.description, description) || other.description == description)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.price, price) || other.price == price));
}


@override
int get hashCode => Object.hash(runtimeType,id,description,quantity,price);

@override
String toString() {
  return 'QuotationLineDraft(id: $id, description: $description, quantity: $quantity, price: $price)';
}


}

/// @nodoc
abstract mixin class $QuotationLineDraftCopyWith<$Res>  {
  factory $QuotationLineDraftCopyWith(QuotationLineDraft value, $Res Function(QuotationLineDraft) _then) = _$QuotationLineDraftCopyWithImpl;
@useResult
$Res call({
 int id, String description, int quantity, double price
});




}
/// @nodoc
class _$QuotationLineDraftCopyWithImpl<$Res>
    implements $QuotationLineDraftCopyWith<$Res> {
  _$QuotationLineDraftCopyWithImpl(this._self, this._then);

  final QuotationLineDraft _self;
  final $Res Function(QuotationLineDraft) _then;

/// Create a copy of QuotationLineDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? description = null,Object? quantity = null,Object? price = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [QuotationLineDraft].
extension QuotationLineDraftPatterns on QuotationLineDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuotationLineDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuotationLineDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuotationLineDraft value)  $default,){
final _that = this;
switch (_that) {
case _QuotationLineDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuotationLineDraft value)?  $default,){
final _that = this;
switch (_that) {
case _QuotationLineDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String description,  int quantity,  double price)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuotationLineDraft() when $default != null:
return $default(_that.id,_that.description,_that.quantity,_that.price);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String description,  int quantity,  double price)  $default,) {final _that = this;
switch (_that) {
case _QuotationLineDraft():
return $default(_that.id,_that.description,_that.quantity,_that.price);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String description,  int quantity,  double price)?  $default,) {final _that = this;
switch (_that) {
case _QuotationLineDraft() when $default != null:
return $default(_that.id,_that.description,_that.quantity,_that.price);case _:
  return null;

}
}

}

/// @nodoc


class _QuotationLineDraft extends QuotationLineDraft {
  const _QuotationLineDraft({required this.id, this.description = '', this.quantity = 1, this.price = 0}): super._();
  

@override final  int id;
@override@JsonKey() final  String description;
@override@JsonKey() final  int quantity;
@override@JsonKey() final  double price;

/// Create a copy of QuotationLineDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuotationLineDraftCopyWith<_QuotationLineDraft> get copyWith => __$QuotationLineDraftCopyWithImpl<_QuotationLineDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuotationLineDraft&&(identical(other.id, id) || other.id == id)&&(identical(other.description, description) || other.description == description)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.price, price) || other.price == price));
}


@override
int get hashCode => Object.hash(runtimeType,id,description,quantity,price);

@override
String toString() {
  return 'QuotationLineDraft(id: $id, description: $description, quantity: $quantity, price: $price)';
}


}

/// @nodoc
abstract mixin class _$QuotationLineDraftCopyWith<$Res> implements $QuotationLineDraftCopyWith<$Res> {
  factory _$QuotationLineDraftCopyWith(_QuotationLineDraft value, $Res Function(_QuotationLineDraft) _then) = __$QuotationLineDraftCopyWithImpl;
@override @useResult
$Res call({
 int id, String description, int quantity, double price
});




}
/// @nodoc
class __$QuotationLineDraftCopyWithImpl<$Res>
    implements _$QuotationLineDraftCopyWith<$Res> {
  __$QuotationLineDraftCopyWithImpl(this._self, this._then);

  final _QuotationLineDraft _self;
  final $Res Function(_QuotationLineDraft) _then;

/// Create a copy of QuotationLineDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? description = null,Object? quantity = null,Object? price = null,}) {
  return _then(_QuotationLineDraft(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$CreateQuotationFormState {

 DateTime get date; DateTime get validUntil; double get taxPercent; List<QuotationLineDraft> get lines; String? get error;/// Set once the screen has handed over the products it was opened with, so
/// a rebuild doesn't seed them a second time.
 bool get seeded;
/// Create a copy of CreateQuotationFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateQuotationFormStateCopyWith<CreateQuotationFormState> get copyWith => _$CreateQuotationFormStateCopyWithImpl<CreateQuotationFormState>(this as CreateQuotationFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateQuotationFormState&&(identical(other.date, date) || other.date == date)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.taxPercent, taxPercent) || other.taxPercent == taxPercent)&&const DeepCollectionEquality().equals(other.lines, lines)&&(identical(other.error, error) || other.error == error)&&(identical(other.seeded, seeded) || other.seeded == seeded));
}


@override
int get hashCode => Object.hash(runtimeType,date,validUntil,taxPercent,const DeepCollectionEquality().hash(lines),error,seeded);

@override
String toString() {
  return 'CreateQuotationFormState(date: $date, validUntil: $validUntil, taxPercent: $taxPercent, lines: $lines, error: $error, seeded: $seeded)';
}


}

/// @nodoc
abstract mixin class $CreateQuotationFormStateCopyWith<$Res>  {
  factory $CreateQuotationFormStateCopyWith(CreateQuotationFormState value, $Res Function(CreateQuotationFormState) _then) = _$CreateQuotationFormStateCopyWithImpl;
@useResult
$Res call({
 DateTime date, DateTime validUntil, double taxPercent, List<QuotationLineDraft> lines, String? error, bool seeded
});




}
/// @nodoc
class _$CreateQuotationFormStateCopyWithImpl<$Res>
    implements $CreateQuotationFormStateCopyWith<$Res> {
  _$CreateQuotationFormStateCopyWithImpl(this._self, this._then);

  final CreateQuotationFormState _self;
  final $Res Function(CreateQuotationFormState) _then;

/// Create a copy of CreateQuotationFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? validUntil = null,Object? taxPercent = null,Object? lines = null,Object? error = freezed,Object? seeded = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,validUntil: null == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as DateTime,taxPercent: null == taxPercent ? _self.taxPercent : taxPercent // ignore: cast_nullable_to_non_nullable
as double,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<QuotationLineDraft>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,seeded: null == seeded ? _self.seeded : seeded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateQuotationFormState].
extension CreateQuotationFormStatePatterns on CreateQuotationFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateQuotationFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateQuotationFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateQuotationFormState value)  $default,){
final _that = this;
switch (_that) {
case _CreateQuotationFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateQuotationFormState value)?  $default,){
final _that = this;
switch (_that) {
case _CreateQuotationFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  DateTime validUntil,  double taxPercent,  List<QuotationLineDraft> lines,  String? error,  bool seeded)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateQuotationFormState() when $default != null:
return $default(_that.date,_that.validUntil,_that.taxPercent,_that.lines,_that.error,_that.seeded);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  DateTime validUntil,  double taxPercent,  List<QuotationLineDraft> lines,  String? error,  bool seeded)  $default,) {final _that = this;
switch (_that) {
case _CreateQuotationFormState():
return $default(_that.date,_that.validUntil,_that.taxPercent,_that.lines,_that.error,_that.seeded);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  DateTime validUntil,  double taxPercent,  List<QuotationLineDraft> lines,  String? error,  bool seeded)?  $default,) {final _that = this;
switch (_that) {
case _CreateQuotationFormState() when $default != null:
return $default(_that.date,_that.validUntil,_that.taxPercent,_that.lines,_that.error,_that.seeded);case _:
  return null;

}
}

}

/// @nodoc


class _CreateQuotationFormState extends CreateQuotationFormState {
  const _CreateQuotationFormState({required this.date, required this.validUntil, this.taxPercent = 18, final  List<QuotationLineDraft> lines = const <QuotationLineDraft>[], this.error, this.seeded = false}): _lines = lines,super._();
  

@override final  DateTime date;
@override final  DateTime validUntil;
@override@JsonKey() final  double taxPercent;
 final  List<QuotationLineDraft> _lines;
@override@JsonKey() List<QuotationLineDraft> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

@override final  String? error;
/// Set once the screen has handed over the products it was opened with, so
/// a rebuild doesn't seed them a second time.
@override@JsonKey() final  bool seeded;

/// Create a copy of CreateQuotationFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateQuotationFormStateCopyWith<_CreateQuotationFormState> get copyWith => __$CreateQuotationFormStateCopyWithImpl<_CreateQuotationFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateQuotationFormState&&(identical(other.date, date) || other.date == date)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.taxPercent, taxPercent) || other.taxPercent == taxPercent)&&const DeepCollectionEquality().equals(other._lines, _lines)&&(identical(other.error, error) || other.error == error)&&(identical(other.seeded, seeded) || other.seeded == seeded));
}


@override
int get hashCode => Object.hash(runtimeType,date,validUntil,taxPercent,const DeepCollectionEquality().hash(_lines),error,seeded);

@override
String toString() {
  return 'CreateQuotationFormState(date: $date, validUntil: $validUntil, taxPercent: $taxPercent, lines: $lines, error: $error, seeded: $seeded)';
}


}

/// @nodoc
abstract mixin class _$CreateQuotationFormStateCopyWith<$Res> implements $CreateQuotationFormStateCopyWith<$Res> {
  factory _$CreateQuotationFormStateCopyWith(_CreateQuotationFormState value, $Res Function(_CreateQuotationFormState) _then) = __$CreateQuotationFormStateCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, DateTime validUntil, double taxPercent, List<QuotationLineDraft> lines, String? error, bool seeded
});




}
/// @nodoc
class __$CreateQuotationFormStateCopyWithImpl<$Res>
    implements _$CreateQuotationFormStateCopyWith<$Res> {
  __$CreateQuotationFormStateCopyWithImpl(this._self, this._then);

  final _CreateQuotationFormState _self;
  final $Res Function(_CreateQuotationFormState) _then;

/// Create a copy of CreateQuotationFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? validUntil = null,Object? taxPercent = null,Object? lines = null,Object? error = freezed,Object? seeded = null,}) {
  return _then(_CreateQuotationFormState(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,validUntil: null == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as DateTime,taxPercent: null == taxPercent ? _self.taxPercent : taxPercent // ignore: cast_nullable_to_non_nullable
as double,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<QuotationLineDraft>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,seeded: null == seeded ? _self.seeded : seeded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
