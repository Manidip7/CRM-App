// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Currently selected bottom-navigation index for the dashboard shell.

@ProviderFor(DashboardNav)
final dashboardNavProvider = DashboardNavProvider._();

/// Currently selected bottom-navigation index for the dashboard shell.
final class DashboardNavProvider extends $NotifierProvider<DashboardNav, int> {
  /// Currently selected bottom-navigation index for the dashboard shell.
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

String _$dashboardNavHash() => r'cd987ae2643e46d7e65c9f7c0996bd0bd7311f79';

/// Currently selected bottom-navigation index for the dashboard shell.

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
