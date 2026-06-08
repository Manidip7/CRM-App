import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/network/token_storage.dart';

/// Example repository showing how a feature talks to the backend through
/// [ApiClient]. Repositories own the endpoint paths, the request payloads and
/// the JSON → model decoding; everything else (errors, auth header, timeouts)
/// is handled by the network layer.
class AuthRepository {
  final ApiClient _api;
  final TokenStorage _tokenStorage;

  AuthRepository(this._api, this._tokenStorage);

  /// POST /auth/login → saves the returned token and returns the user id.
  Future<ApiResult<String>> login({
    required String email,
    required String password,
  }) async {
    final result = await _api.post<_LoginResponse>(
      ApiConstants.login,
      data: {'email': email, 'password': password},
      decoder: (json) => _LoginResponse.fromJson(json as Map<String, dynamic>),
    );

    // On success, persist the token so AuthInterceptor attaches it to every
    // future request, then surface just the bit the caller cares about.
    return switch (result) {
      Success(:final data) => await () async {
          await _tokenStorage.saveTokens(
            accessToken: data.accessToken,
            refreshToken: data.refreshToken,
          );
          return ApiResult.success(data.userId);
        }(),
      Failure(:final error) => ApiResult.failure(error),
    };
  }

  /// POST /auth/forgot-password
  Future<ApiResult<void>> forgotPassword(String email) {
    return _api.post<void>(
      ApiConstants.forgotPassword,
      data: {'email': email},
      decoder: (_) {},
    );
  }

  Future<void> logout() => _tokenStorage.clear();
}

/// Internal DTO for the login endpoint response.
class _LoginResponse {
  final String accessToken;
  final String? refreshToken;
  final String userId;

  _LoginResponse({
    required this.accessToken,
    required this.userId,
    this.refreshToken,
  });

  factory _LoginResponse.fromJson(Map<String, dynamic> json) {
    return _LoginResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      userId: '${json['user_id'] ?? json['id'] ?? ''}',
    );
  }
}

/// DI for the repository — inject this into your controllers/providers.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});
