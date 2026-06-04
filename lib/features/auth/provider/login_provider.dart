import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_provider.freezed.dart';
part 'login_provider.g.dart';

@freezed
abstract class LoginState with _$LoginState {
  const factory LoginState({
    @Default(true) bool obscurePassword,
    @Default(false) bool isLoading,
  }) = _LoginState;
}

@riverpod
class LoginController extends _$LoginController {
  @override
  LoginState build() => const LoginState();

  void toggleObscure() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);

  /// Simulates an async sign-in. Returns true when login completes.
  Future<bool> login() async {
    state = state.copyWith(isLoading: true);
    await Future<void>.delayed(const Duration(seconds: 2));
    state = state.copyWith(isLoading: false);
    return true;
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
