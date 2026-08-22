import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_constants.dart';
import '../../../core/network/interceptors/logging_interceptor.dart';
import '../../../core/network/server_config.dart';

/// Looks a company's CRM up from the address the user typed or scanned.
///
/// The lookup does **not** go to that address — it goes to the app's own fixed
/// host ([ApiConstants.appBaseUrl]), which answers with the tenant's real
/// domain. That returned domain is what the whole app talks to afterwards, so a
/// company whose CRM lives somewhere other than the address the user knows it
/// by still ends up pointed at the right server.
///
/// Uses its own bare [Dio]: the shared client is built around the *saved*
/// server and carries the auth interceptor, neither of which applies here.
class ServerSetupRepository {
  /// Deliberately shorter than the app's normal timeouts — a wrong address
  /// should fail fast enough that the user retypes it instead of waiting.
  static const _timeout = Duration(seconds: 15);

  /// `POST {appBaseUrl}/api/v1/tenant-info` with `{ "url": "<address>" }`.
  ///
  /// Returns the verified [ServerConfig] built from the tenant's own domain, or
  /// throws a [ServerSetupException] whose message is safe to show as-is.
  Future<ServerConfig> verify(String rawUrl) async {
    final origin = ServerConfig.normalizeOrigin(rawUrl);
    if (origin == null) {
      throw const ServerSetupException(
        'That doesn\'t look like a valid web address.\n'
        'Example: https://yourcompany.peplocrm.in',
      );
    }

    final dio = Dio(
      BaseOptions(
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        sendTimeout: _timeout,
        contentType: Headers.jsonContentType,
        headers: Map<String, String>.from(ApiConstants.jsonHeaders),
        responseType: ResponseType.json,
        followRedirects: false,
        maxRedirects: 0,
        validateStatus: (s) => s != null && s >= 200 && s < 300,
      ),
    );
    // Skips the auth interceptor (no token exists yet) but keeps the logging
    // one, so the lookup shows up in the console like every other call.
    dio.interceptors.add(LoggingInterceptor());

    try {
      final response = await dio.post<dynamic>(
        '${ApiConstants.appApiBaseUrl}${ApiConstants.tenantInfo}',
        data: {'url': origin},
      );
      return _readConfig(origin, response.data);
    } on DioException catch (e) {
      throw ServerSetupException(_messageFor(e));
    } finally {
      dio.close();
    }
  }

  /// Reads the tenant out of the reply:
  ///
  /// ```json
  /// { "success": true, "data": { "company_name": "PeploCRM",
  ///   "domain": "demo.peplocrm.in", "domains": ["demo.peplocrm.in"],
  ///   "is_active": true } }
  /// ```
  ///
  /// The returned `domain` wins over whatever the user typed. [entered] is only
  /// the fallback for a reply that names no domain at all.
  static ServerConfig _readConfig(String entered, dynamic body) {
    final map = body is Map ? body.cast<String, dynamic>() : null;

    if (map == null || map['success'] == false) {
      final message = map?['message'] as String?;
      throw ServerSetupException(
        message?.trim().isNotEmpty ?? false
            ? message!
            : 'No CRM was found at that address.\n'
                  'Check the spelling or ask your admin.',
      );
    }

    final data = (map['data'] as Map?)?.cast<String, dynamic>();
    if (data == null) {
      throw const ServerSetupException(
        'The lookup succeeded but returned no CRM details.\n'
        'Please ask your admin to check the account.',
      );
    }

    // A suspended account would let the user through to a login they can never
    // pass, so it's stopped here where the reason can still be explained.
    if (data['is_active'] == false) {
      throw const ServerSetupException(
        'This CRM account is not active.\n'
        'Please contact your administrator.',
      );
    }

    final domain = _firstDomain(data);
    final origin = domain == null
        ? entered
        : (ServerConfig.normalizeOrigin(domain) ?? entered);

    return ServerConfig(
      origin: origin,
      companyName: _string(data, const ['company_name', 'name', 'company']),
      logoUrl: _string(data, const ['logo', 'logo_url', 'company_logo']),
    );
  }

  /// The tenant's domain: the singular `domain` field, else the first usable
  /// entry of `domains`.
  static String? _firstDomain(Map<String, dynamic> data) {
    final single = _string(data, const ['domain', 'url', 'base_url']);
    if (single != null) return single;

    final list = data['domains'];
    if (list is List) {
      for (final entry in list) {
        if (entry is String && entry.trim().isNotEmpty) return entry.trim();
      }
    }
    return null;
  }

  static String? _string(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  /// Turns a transport failure into something a non-technical user can act on.
  static String _messageFor(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to reply.\n'
            'Check your internet connection and try again.';
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return 'Could not reach the server.\n'
            'Check your internet connection and try again.';
      case DioExceptionType.badCertificate:
        return 'The server\'s security certificate could not be trusted.';
      case DioExceptionType.cancel:
        return 'The connection check was cancelled.';
      case DioExceptionType.badResponse:
        // The lookup itself answered, so its own message (if any) is the most
        // accurate thing to show — typically "tenant not found".
        final body = e.response?.data;
        final message = body is Map ? body['message'] as String? : null;
        if (message != null && message.trim().isNotEmpty) return message.trim();

        final status = e.response?.statusCode;
        if (status == 404 || status == 422) {
          return 'No CRM was found at that address.\n'
              'Check the spelling or ask your admin.';
        }
        return 'The server replied with an error'
            '${status == null ? '' : ' ($status)'}. '
            'Please try again or ask your admin.';
    }
  }
}

/// A connection-check failure whose [message] is written for the user, not the
/// log.
class ServerSetupException implements Exception {
  final String message;

  const ServerSetupException(this.message);

  @override
  String toString() => message;
}

final serverSetupRepositoryProvider = Provider<ServerSetupRepository>((ref) {
  return ServerSetupRepository();
});
