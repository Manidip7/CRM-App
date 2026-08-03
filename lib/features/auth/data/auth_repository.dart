import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/permissions/permissions_store.dart';
import '../model/auth_session.dart';
import 'session_store.dart';

/// Talks to the backend's auth endpoints through [ApiClient]. The repository
/// owns the endpoint paths, request payloads and JSON → model decoding;
/// transport concerns (errors, auth header, timeouts) live in the network layer.
class AuthRepository {
  final ApiClient _api;
  final TokenStorage _tokenStorage;

  AuthRepository(this._api, this._tokenStorage);

  /// POST /login → on success, persists the bearer token (so [AuthInterceptor]
  /// attaches it to every future request) and returns the full [AuthSession].
  Future<ApiResult<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    final result = await _api.post<AuthSession>(
      ApiConstants.login,
      data: {'email': email, 'password': password},
      decoder: _decodeSession,
    );

    return switch (result) {
      Success(:final data) => await () async {
          await _tokenStorage.saveTokens(accessToken: data.token);
          return ApiResult.success(data);
        }(),
      Failure(:final error) => ApiResult.failure(error),
    };
  }

  /// POST /forgot-password
  Future<ApiResult<void>> forgotPassword(String email) {
    return _api.post<void>(
      ApiConstants.forgotPassword,
      data: {'email': email},
      decoder: (_) {},
    );
  }

  /// Clears the local token. Best-effort hits the backend too, but local state
  /// is wiped regardless so the user is always logged out on the device.
  Future<void> logout() async {
    await _api.post<void>(ApiConstants.logout, decoder: (_) {});
    await _tokenStorage.clear();
  }

  /// Unwraps the standard `{ success, message, data: {...} }` envelope and
  /// builds an [AuthSession]. Throws a typed [ApiException] if the body says
  /// the request failed or is missing the `data` object.
  static AuthSession _decodeSession(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();

    // Print the raw login response to the console (debug builds only).
    if (kDebugMode) {
      developer.log('Login response: $map', name: 'AUTH');
    }

    if (map['success'] == false) {
      throw ApiException(
        type: ApiErrorType.validation,
        message: map['message'] as String? ?? 'Login failed.',
        raw: json,
      );
    }

    final data = (map['data'] as Map?)?.cast<String, dynamic>();
    if (data == null) {
      throw ApiException.unexpected('Login response had no "data" object.');
    }
    return AuthSession.fromJson(data);
  }
}

/// DI for the repository — inject this into controllers/providers.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

/// Holds the [SessionStore]. Overridden in `main()` with the instance loaded
/// from disk before the app starts.
final sessionStoreProvider = Provider<SessionStore>((ref) {
  throw UnimplementedError('sessionStoreProvider must be overridden in main()');
});

/// App-wide current session. `null` means logged out. Restored from local
/// storage on startup, saved to storage on a successful login, and cleared on
/// logout. Watch this anywhere you need the user, their roles or permissions
/// (e.g. to hide a button the user can't use).
class AuthSessionNotifier extends Notifier<AuthSession?> {
  @override
  AuthSession? build() => ref.read(sessionStoreProvider).cached;

  /// Stores the full session in local storage and updates app state.
  Future<void> setSession(AuthSession session) async {
    // Drop the previous user's cached permission map before the new session
    // goes live, otherwise the first frame after login could briefly gate the
    // UI with the *old* account's role.
    await ref.read(permissionsStoreProvider).clear();
    await ref.read(sessionStoreProvider).save(session);
    state = session;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    await ref.read(sessionStoreProvider).clear();
    await ref.read(permissionsStoreProvider).clear();
    state = null;
  }
}

final authSessionProvider =
    NotifierProvider<AuthSessionNotifier, AuthSession?>(AuthSessionNotifier.new);
