import 'package:dio/dio.dart';

import 'api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'token_storage.dart';

/// Builds and configures the single [Dio] instance used across the app.
///
/// Centralising creation here means base URL, timeouts, default headers and
/// the interceptor chain are defined in exactly one place.
class DioClient {
  DioClient._();

  /// [baseUrl] is the API root of the server the user set up on first launch;
  /// it falls back to the compiled-in default until they have chosen one.
  static Dio create({
    required TokenStorage tokenStorage,
    String? baseUrl,
    void Function()? onUnauthorized,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConstants.apiBaseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        contentType: ApiConstants.contentType,
        // Makes the backend answer with JSON errors (401/422) rather than a
        // 302 redirect to its web login page. See [ApiConstants.jsonHeaders].
        headers: Map<String, String>.from(ApiConstants.jsonHeaders),
        responseType: ResponseType.json,
        // Encode list query params as repeated keys without `[]` brackets,
        // e.g. `quick_filter=today&quick_filter=upcoming`.
        listFormat: ListFormat.multi,
        // The backend answers an expired/missing session with a 302 redirect to
        // its web login page. Do NOT follow it — otherwise Dio chases the
        // redirect into an HTML page (or a cross-origin chain) and the request
        // never resolves into JSON, leaving the UI spinning forever. Keeping the
        // 302 lets [validateStatus] reject it so it surfaces as a clean auth
        // failure (see AuthInterceptor).
        followRedirects: false,
        maxRedirects: 0,
        // Let our own error mapper decide what counts as a failure; Dio only
        // treats 2xx as success, so any 3xx redirect is treated as an error.
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(
        tokenStorage: tokenStorage,
        onUnauthorized: onUnauthorized,
      ),
      LoggingInterceptor(),
    ]);

    return dio;
  }
}
