import 'package:dio/dio.dart';

import '../api_constants.dart';
import '../token_storage.dart';

/// Attaches the bearer token (if present) to every outgoing request.
///
/// On a 401 it clears the stored tokens and fires [onUnauthorized] so the app
/// can route the user back to the login screen. Token *refresh* logic can be
/// added here later; for now we fail fast on expiry.
class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;
  final void Function()? onUnauthorized;

  AuthInterceptor({required this.tokenStorage, this.onUnauthorized});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenStorage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers[ApiConstants.authHeader] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    // A 401, or a 3xx redirect to the web login page, both mean the session is
    // no longer valid — wipe the token and notify the app so it can route back
    // to login instead of leaving the request hanging.
    final isAuthFailure =
        status == 401 || (status != null && status >= 300 && status < 400);
    if (isAuthFailure) {
      tokenStorage.clear();
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}
