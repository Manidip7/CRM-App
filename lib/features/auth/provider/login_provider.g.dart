// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LoginController)
final loginControllerProvider = LoginControllerProvider._();

final class LoginControllerProvider
    extends $NotifierProvider<LoginController, LoginState> {
  LoginControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loginControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loginControllerHash();

  @$internal
  @override
  LoginController create() => LoginController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoginState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoginState>(value),
    );
  }
}

String _$loginControllerHash() => r'4bc77e3230cd2ca7776abee1a633cb86d5430690';

abstract class _$LoginController extends $Notifier<LoginState> {
  LoginState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LoginState, LoginState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LoginState, LoginState>,
              LoginState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ForgotPasswordController)
final forgotPasswordControllerProvider = ForgotPasswordControllerProvider._();

final class ForgotPasswordControllerProvider
    extends $NotifierProvider<ForgotPasswordController, ForgotPasswordState> {
  ForgotPasswordControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forgotPasswordControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$forgotPasswordControllerHash();

  @$internal
  @override
  ForgotPasswordController create() => ForgotPasswordController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ForgotPasswordState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ForgotPasswordState>(value),
    );
  }
}

String _$forgotPasswordControllerHash() =>
    r'8cf4bc73e55df52c7e40e743bb59331e0ef50c2a';

abstract class _$ForgotPasswordController
    extends $Notifier<ForgotPasswordState> {
  ForgotPasswordState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ForgotPasswordState, ForgotPasswordState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ForgotPasswordState, ForgotPasswordState>,
              ForgotPasswordState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
