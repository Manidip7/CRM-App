import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'api_result.dart';

/// Thin, generic wrapper around [Dio] that every repository should use instead
/// of touching Dio directly.
///
/// Each method:
///  * performs the HTTP call,
///  * decodes the body with the [decoder] you pass in,
///  * and returns an [ApiResult] — never throwing for expected network errors.
///
/// The [decoder] receives the raw JSON (`dynamic`) and turns it into your
/// model type. Keep parsing in the repository so this class stays generic.
class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  Dio get dio => _dio;

  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) decoder,
    CancelToken? cancelToken,
  }) {
    return _request(
      () => _dio.get(path, queryParameters: queryParameters, cancelToken: cancelToken),
      decoder,
    );
  }

  Future<ApiResult<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) decoder,
    CancelToken? cancelToken,
  }) {
    return _request(
      () => _dio.post(path,
          data: data, queryParameters: queryParameters, cancelToken: cancelToken),
      decoder,
    );
  }

  Future<ApiResult<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) decoder,
    CancelToken? cancelToken,
  }) {
    return _request(
      () => _dio.put(path,
          data: data, queryParameters: queryParameters, cancelToken: cancelToken),
      decoder,
    );
  }

  Future<ApiResult<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) decoder,
    CancelToken? cancelToken,
  }) {
    return _request(
      () => _dio.patch(path,
          data: data, queryParameters: queryParameters, cancelToken: cancelToken),
      decoder,
    );
  }

  Future<ApiResult<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) decoder,
    CancelToken? cancelToken,
  }) {
    return _request(
      () => _dio.delete(path,
          data: data, queryParameters: queryParameters, cancelToken: cancelToken),
      decoder,
    );
  }

  /// Runs [call], maps Dio/parse failures to a typed [ApiException], and wraps
  /// everything in an [ApiResult].
  Future<ApiResult<T>> _request<T>(
    Future<Response> Function() call,
    T Function(dynamic json) decoder,
  ) async {
    try {
      final response = await call();
      final data = decoder(response.data);
      return ApiResult.success(data);
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDio(e));
    } on ApiException catch (e) {
      // Allow decoders to throw a typed ApiException directly.
      return ApiResult.failure(e);
    } catch (e) {
      // Anything else (e.g. a JSON shape mismatch in the decoder).
      return ApiResult.failure(ApiException.unexpected(e));
    }
  }
}
