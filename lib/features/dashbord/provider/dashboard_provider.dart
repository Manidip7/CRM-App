import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_provider.g.dart';

/// Currently selected bottom-navigation index for the dashboard shell.
@riverpod
class DashboardNav extends _$DashboardNav {
  @override
  int build() => 0;

  void select(int index) => state = index;
}
