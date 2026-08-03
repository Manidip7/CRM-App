// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Currently selected bottom-navigation index for the dashboard shell.
///
/// The starting section is permission-aware: a role without `dashboard.view`
/// would otherwise land on an Overview it isn't allowed to see, so we open the
/// first section it *can* see instead. Re-evaluated if the permission set
/// changes (login, or the roles request landing after a cold start).

@ProviderFor(DashboardNav)
final dashboardNavProvider = DashboardNavProvider._();

/// Currently selected bottom-navigation index for the dashboard shell.
///
/// The starting section is permission-aware: a role without `dashboard.view`
/// would otherwise land on an Overview it isn't allowed to see, so we open the
/// first section it *can* see instead. Re-evaluated if the permission set
/// changes (login, or the roles request landing after a cold start).
final class DashboardNavProvider extends $NotifierProvider<DashboardNav, int> {
  /// Currently selected bottom-navigation index for the dashboard shell.
  ///
  /// The starting section is permission-aware: a role without `dashboard.view`
  /// would otherwise land on an Overview it isn't allowed to see, so we open the
  /// first section it *can* see instead. Re-evaluated if the permission set
  /// changes (login, or the roles request landing after a cold start).
  DashboardNavProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardNavProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardNavHash();

  @$internal
  @override
  DashboardNav create() => DashboardNav();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$dashboardNavHash() => r'8a88fca8dbfead102f9bb937c7f3a719a0663f22';

/// Currently selected bottom-navigation index for the dashboard shell.
///
/// The starting section is permission-aware: a role without `dashboard.view`
/// would otherwise land on an Overview it isn't allowed to see, so we open the
/// first section it *can* see instead. Re-evaluated if the permission set
/// changes (login, or the roles request landing after a cold start).

abstract class _$DashboardNav extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
