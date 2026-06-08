import 'api_exception.dart';

/// A type-safe result of an API call: either [Success] with data, or
/// [Failure] with a typed [ApiException]. This lets repositories return
/// errors as values instead of throwing, so callers are forced to handle
/// both cases.
///
/// Usage:
/// ```dart
/// final result = await repo.getLeads();
/// result.when(
///   success: (leads) => state = AsyncData(leads),
///   failure: (err) => state = AsyncError(err, StackTrace.current),
/// );
/// ```
sealed class ApiResult<T> {
  const ApiResult();

  const factory ApiResult.success(T data) = Success<T>;
  const factory ApiResult.failure(ApiException error) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// Returns the data if this is a [Success], otherwise null.
  T? get dataOrNull => switch (this) {
        Success<T>(:final data) => data,
        Failure<T>() => null,
      };

  /// Returns the error if this is a [Failure], otherwise null.
  ApiException? get errorOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final error) => error,
      };

  /// Pattern-matches both branches and returns a value of type [R].
  R when<R>({
    required R Function(T data) success,
    required R Function(ApiException error) failure,
  }) {
    return switch (this) {
      Success<T>(:final data) => success(data),
      Failure<T>(:final error) => failure(error),
    };
  }

  /// Transforms the success value while preserving a failure.
  ApiResult<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success<T>(:final data) => Success(transform(data)),
      Failure<T>(:final error) => Failure(error),
    };
  }
}

final class Success<T> extends ApiResult<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends ApiResult<T> {
  final ApiException error;
  const Failure(this.error);
}
