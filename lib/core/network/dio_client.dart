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

  static Dio create({
    required TokenStorage tokenStorage,
    void Function()? onUnauthorized,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        contentType: ApiConstants.contentType,
        responseType: ResponseType.json,
        // Let our own error mapper decide what counts as a failure; Dio only
        // treats 2xx as success by default, which is what we want.
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
