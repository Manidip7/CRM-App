import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_result.dart';
import '../data/auth_repository.dart';

part 'login_provider.freezed.dart';
part 'login_provider.g.dart';

@freezed
abstract class LoginState with _$LoginState {
  const factory LoginState({
    @Default(true) bool obscurePassword,
    @Default(false) bool isLoading,

    /// A general error to show (e.g. in a snackbar) after a failed attempt.
    String? errorMessage,

    /// Field-level validation errors keyed by field, e.g.
    /// `{ "email": ["The email field is required."] }` — show under the input.
    Map<String, List<String>>? fieldErrors,
  }) = _LoginState;
}

@riverpod
class LoginController extends _$LoginController {
  @override
  LoginState build() => const LoginState();

  void toggleObscure() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);

  /// Calls the backend and, on success, stores the session app-wide.
  /// Returns `true` only when login succeeded; on failure the reason is left
  /// in [LoginState.errorMessage] / [LoginState.fieldErrors] for the UI.
  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      fieldErrors: null,
    );

    final result = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);

    switch (result) {
      case Success(:final data):
        if (kDebugMode) {
          developer.log(
            'Logged in: ${data.user.name} <${data.user.email}>\n'
            'roles: ${data.roles}\n'
            'permissions (${data.permissions.length}): ${data.permissions}\n'
            'token: ${data.token}',
            name: 'AUTH',
          );
        }
        // Saves the full session (user, roles, permissions, token) to storage.
        await ref.read(authSessionProvider.notifier).setSession(data);
        state = state.copyWith(isLoading: false);
        return true;
      case Failure(:final error):
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.message,
          fieldErrors: error.errors,
        );
        return false;
    }
  }
}

@freezed
abstract class ForgotPasswordState with _$ForgotPasswordState {
  const factory ForgotPasswordState({
    @Default(false) bool isLoading,
    @Default(false) bool isSent,
  }) = _ForgotPasswordState;
}

@riverpod
class ForgotPasswordController extends _$ForgotPasswordController {
  @override
  ForgotPasswordState build() => const ForgotPasswordState();

  Future<void> sendReset() async {
    state = state.copyWith(isLoading: true);
    await Future<void>.delayed(const Duration(seconds: 2));
    state = state.copyWith(isLoading: false, isSent: true);
  }
}
