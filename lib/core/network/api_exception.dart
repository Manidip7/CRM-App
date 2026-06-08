import 'package:dio/dio.dart';

/// Categorises the kind of failure so the UI can react differently
/// (e.g. show a "retry" button on [network], force logout on [unauthorized]).
enum ApiErrorType {
  /// No internet / host unreachable / connection dropped.
  network,

  /// Connection / send / receive timed out.
  timeout,

  /// Request was cancelled (e.g. user navigated away).
  cancelled,

  /// 401 — token missing/expired/invalid.
  unauthorized,

  /// 403 — authenticated but not allowed.
  forbidden,

  /// 404 — resource not found.
  notFound,

  /// 422 / 400 — validation failed; see [ApiException.errors].
  validation,

  /// 5xx — something blew up on the server.
  server,

  /// Anything we couldn't classify (incl. JSON parsing).
  unknown,
}

/// A single, typed exception that the whole app throws/catches for network
/// failures. Every [DioException] is converted into one of these by
/// [ApiException.fromDio] so callers never deal with Dio internals directly.
class ApiException implements Exception {
  final ApiErrorType type;

  /// Human-readable message safe to show to the user.
  final String message;

  /// HTTP status code, when there was a response.
  final int? statusCode;

  /// Field-level validation errors keyed by field name, e.g.
  /// `{ "email": ["The email is invalid."] }`.
  final Map<String, List<String>>? errors;

  /// The raw response body, for debugging/logging.
  final dynamic raw;

  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.errors,
    this.raw,
  });

  /// True for failures where retrying the exact same request might succeed.
  bool get isRetryable =>
      type == ApiErrorType.network ||
      type == ApiErrorType.timeout ||
      type == ApiErrorType.server;

  bool get isUnauthorized => type == ApiErrorType.unauthorized;

  /// Converts any [DioException] into a typed [ApiException].
  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          type: ApiErrorType.timeout,
          message: 'The connection timed out. Please try again.',
        );

      case DioExceptionType.cancel:
        return const ApiException(
          type: ApiErrorType.cancelled,
          message: 'Request was cancelled.',
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          type: ApiErrorType.network,
          message: 'No internet connection. Check your network and try again.',
        );

      case DioExceptionType.badCertificate:
        return const ApiException(
          type: ApiErrorType.network,
          message: 'Could not establish a secure connection.',
        );

      case DioExceptionType.badResponse:
        return ApiException._fromResponse(e.response);

      case DioExceptionType.unknown:
        return ApiException(
          type: ApiErrorType.unknown,
          message: e.message ?? 'Something went wrong. Please try again.',
          raw: e.error,
        );
    }
  }

  /// Builds an exception from a non-2xx HTTP response, pulling out the
  /// backend's message and any validation errors.
  factory ApiException._fromResponse(Response? response) {
    final status = response?.statusCode;
    final data = response?.data;

    final serverMessage = _extractMessage(data);
    final validationErrors = _extractErrors(data);

    final ApiErrorType type;
    final String fallback;
    switch (status) {
      case 400:
      case 422:
        type = ApiErrorType.validation;
        fallback = 'Please check the information you entered.';
        break;
      case 401:
        type = ApiErrorType.unauthorized;
        fallback = 'Your session has expired. Please sign in again.';
        break;
      case 403:
        type = ApiErrorType.forbidden;
        fallback = "You don't have permission to do that.";
        break;
      case 404:
        type = ApiErrorType.notFound;
        fallback = 'The requested resource was not found.';
        break;
      default:
        if (status != null && status >= 500) {
          type = ApiErrorType.server;
          fallback = 'Server error. Please try again later.';
        } else {
          type = ApiErrorType.unknown;
          fallback = 'Something went wrong. Please try again.';
        }
    }

    return ApiException(
      type: type,
      message: serverMessage ?? fallback,
      statusCode: status,
      errors: validationErrors,
      raw: data,
    );
  }

  /// Convenience for non-Dio failures (e.g. JSON parsing in a repository).
  factory ApiException.unexpected([Object? error]) => ApiException(
        type: ApiErrorType.unknown,
        message: 'Something went wrong. Please try again.',
        raw: error,
      );

  // Tries common backend shapes: { "message": "..." } or { "error": "..." }.
  static String? _extractMessage(dynamic data) {
    if (data is Map) {
      final msg = data['message'] ?? data['error'] ?? data['detail'];
      if (msg is String && msg.trim().isNotEmpty) return msg;
    }
    return null;
  }

  // Tries Laravel-style { "errors": { "field": ["msg", ...] } }.
  static Map<String, List<String>>? _extractErrors(dynamic data) {
    if (data is Map && data['errors'] is Map) {
      final raw = data['errors'] as Map;
      final out = <String, List<String>>{};
      raw.forEach((key, value) {
        if (value is List) {
          out['$key'] = value.map((e) => '$e').toList();
        } else {
          out['$key'] = ['$value'];
        }
      });
      return out.isEmpty ? null : out;
    }
    return null;
  }

  @override
  String toString() =>
      'ApiException(type: $type, statusCode: $statusCode, message: $message)';
}
