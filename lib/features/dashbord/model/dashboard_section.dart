import 'package:flutter/material.dart';

import '../../../core/permissions/permissions.dart';

/// One switchable section of the dashboard shell.
///
/// The drawer, the bottom bar and the dashboard body used to each hard-code
/// their own copy of this list, which made it impossible to hide a section
/// consistently. They all read from [DashboardSection.all] now, so a section
/// the role can't view disappears from every one of them at once.
class DashboardSection {
  /// Index stored in `dashboardNavProvider`. These are the historical values —
  /// don't renumber them, the order of [all] controls display order instead.
  final int index;

  final String label;
  final IconData icon;

  /// The user needs **at least one** of these to see the section.
  final List<String> permissions;

  /// Whether the section also appears in the bottom navigation bar.
  final bool inBottomBar;

  const DashboardSection({
    required this.index,
    required this.label,
    required this.icon,
    required this.permissions,
    this.inBottomBar = false,
  });

  bool isVisibleTo(PermissionSet perms) => perms.canAny(permissions);

  /// Index of the Leads section, for the places that switch to it directly
  /// (e.g. tapping a Lead Funnel band on the Overview).
  static const int leadsIndex = 1;

  /// Every section, in the order the drawer shows them.
  static const List<DashboardSection> all = [
    DashboardSection(
      index: 0,
      label: 'Overview',
      icon: Icons.grid_view_rounded,
      permissions: [AppPermissions.dashboardView],
      inBottomBar: true,
    ),
    DashboardSection(
      index: 1,
      label: 'Leads',
      icon: Icons.filter_list_rounded,
      permissions: [AppPermissions.leadsView],
      inBottomBar: true,
    ),
    DashboardSection(
      index: 2,
      label: 'Tasks',
      icon: Icons.task_alt_rounded,
      permissions: [AppPermissions.tasksView],
      inBottomBar: true,
    ),
    DashboardSection(
      index: 3,
      label: 'Opportunities',
      icon: Icons.trending_up_rounded,
      permissions: [AppPermissions.opportunitiesView],
      inBottomBar: true,
    ),
    DashboardSection(
      index: 4,
      label: 'Next Follow-ups',
      // The screen mixes lead and opportunity follow-ups, so either permission
      // is enough to make it worth showing.
      icon: Icons.event_note_rounded,
      permissions: [
        AppPermissions.leadsFollowUp,
        AppPermissions.opportunitiesFollowUp,
      ],
    ),
    DashboardSection(
      index: 5,
      label: 'Quotations',
      icon: Icons.request_quote_rounded,
      permissions: [AppPermissions.quotationsView],
    ),
    DashboardSection(
      index: 6,
      label: 'Customers',
      icon: Icons.people_alt_rounded,
      permissions: [AppPermissions.customersView],
    ),
    DashboardSection(
      index: 7,
      label: 'Invoices',
      icon: Icons.receipt_long_rounded,
      permissions: [AppPermissions.invoicesView],
    ),
    // DashboardSection(
    //   index: 8,
    //   label: 'Projects',
    //   icon: Icons.folder_open_rounded,
    //   permissions: [AppPermissions.projectsView],
    // ),
  ];

  /// The sections this role may see, in display order.
  static List<DashboardSection> visibleTo(PermissionSet perms) =>
      all.where((s) => s.isVisibleTo(perms)).toList(growable: false);

  static DashboardSection? byIndex(int index) {
    for (final section in all) {
      if (section.index == index) return section;
    }
    return null;
  }
}
