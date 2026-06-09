import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/AppColors.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // `index` maps each tab to the dashboard body switch (Overview 0, Leads 1,
    // Tasks 2, Opportunities 3) so the visual order can differ from those ids.
    final items = [
      _NavItem(icon: Icons.grid_view_rounded, label: 'Overview', index: 0),
      _NavItem(icon: Icons.filter_list_rounded, label: 'Leads', index: 1),
      _NavItem(
          icon: Icons.trending_up_rounded,
          label: 'Opportunities',
          index: 3),
      _NavItem(icon: Icons.task_alt_rounded, label: 'Tasks', index: 2),
    ];

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
}

class _NavItem {
  final IconData icon;
  final String label;

  /// Dashboard body index this tab activates (see DashboardScreen switch).
  final int index;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}
