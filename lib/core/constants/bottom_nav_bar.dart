import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/dashbord/model/dashboard_section.dart';
import '../permissions/permissions.dart';
import '../utils/AppColors.dart';

/// Bottom navigation for the dashboard shell.
///
/// The tabs come from [DashboardSection.all] (filtered by permission), so a
/// section the role can't view disappears here and in the drawer together —
/// and the bar hides entirely if fewer than two tabs survive, since a
/// single-tab bar is just wasted space.
class BottomNavBar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(permissionsProvider);

    // `index` maps each tab to the dashboard body switch (Overview 0, Leads 1,
    // Tasks 2, Opportunities 3) so the visual order can differ from those ids.
    final items = [
      for (final section in DashboardSection.all)
        if (section.inBottomBar && section.isVisibleTo(perms)) section,
    ]..sort((a, b) => _barOrder(a.index).compareTo(_barOrder(b.index)));

    if (items.length < 2) return const SizedBox.shrink();

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 72 + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: AppColors.navBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isSelected = item.index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(item.index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.navUnselected,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.navUnselected,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Display order in the bar, which deliberately differs from the section
  /// ids: Overview, Leads, Opportunities, Tasks.
  static int _barOrder(int sectionIndex) => switch (sectionIndex) {
        0 => 0,
        1 => 1,
        3 => 2,
        2 => 3,
        _ => 99,
      };
}
