import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/permissions/permissions.dart';
import '../model/dashboard_section.dart';

part 'dashboard_provider.g.dart';

/// Currently selected bottom-navigation index for the dashboard shell.
///
/// The starting section is permission-aware: a role without `dashboard.view`
/// would otherwise land on an Overview it isn't allowed to see, so we open the
/// first section it *can* see instead. Re-evaluated if the permission set
/// changes (login, or the roles request landing after a cold start).
@riverpod
class DashboardNav extends _$DashboardNav {
  @override
  int build() {
    final perms = ref.watch(permissionsProvider);
    final visible = DashboardSection.visibleTo(perms);
    // No section at all is an edge case (a role with nothing but settings
    // permissions); keep Overview so the shell still renders, and it shows the
    // "no access" panel.
    return visible.isEmpty ? 0 : visible.first.index;
  }

  void select(int index) {
    final section = DashboardSection.byIndex(index);
    // Defensive: every entry point is already filtered by permission, so this
    // only trips if a new caller forgets to.
    if (section != null && !section.isVisibleTo(ref.read(permissionsProvider))) {
      return;
    }
    state = index;
  }
}
