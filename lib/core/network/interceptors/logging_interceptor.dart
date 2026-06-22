import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs requests, responses and errors to the dev console. Active only in
/// debug builds (gated on [kDebugMode]) so it never leaks data in release.
class LoggingInterceptor extends Interceptor {
  static const _tag = 'API';
  static const _encoder = JsonEncoder.withIndent('  ');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '→ ${options.method} ${options.uri}'
        '\n  headers: ${_pretty(options.headers)}'
        '${options.data != null ? '\n  body: ${_pretty(options.data)}' : ''}',
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
        '${response.requestOptions.uri}'
        '\n  response: ${_pretty(response.data)}',
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
        '${err.requestOptions.uri}\n  ${err.message}'
        '${err.response?.data != null ? '\n  response: ${_pretty(err.response?.data)}' : ''}',
        name: _tag,
        error: err.response?.data,
      );
    }
    handler.next(err);
  }

  /// Pretty-prints JSON-like values (Map/List). Falls back to `toString()` for
  /// anything that can't be encoded (e.g. FormData, raw strings).
  static String _pretty(Object? data) {
    if (data == null) return 'null';
    try {
      if (data is String) {
        // Try to parse-then-reformat strings that are actually JSON.
        return _encoder.convert(jsonDecode(data));
      }
      return _encoder.convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}
