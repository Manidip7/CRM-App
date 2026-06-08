import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs requests, responses and errors to the dev console. Active only in
/// debug builds (gated on [kDebugMode]) so it never leaks data in release.
class LoggingInterceptor extends Interceptor {
  static const _tag = 'API';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '→ ${options.method} ${options.uri}'
        '${options.data != null ? '\n  body: ${options.data}' : ''}',
        name: _tag,
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '← ${response.statusCode} ${response.requestOptions.method} '
        '${response.requestOptions.uri}',
        name: _tag,
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '✗ ${err.response?.statusCode ?? ''} ${err.requestOptions.method} '
        '${err.requestOptions.uri}\n  ${err.message}',
        name: _tag,
        error: err.response?.data,
      );
    }
    handler.next(err);
  }
}
