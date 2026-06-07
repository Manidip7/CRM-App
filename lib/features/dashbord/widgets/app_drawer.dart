import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';
import '../provider/dashboard_provider.dart';

/// Side navigation drawer opened from the dashboard header.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(dashboardNavProvider);

    return Drawer(
      backgroundColor: AppColors.cardBackground,
      width: 286,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerItem(
                    icon: Icons.grid_view_rounded,
                    label: 'Overview',
                    selected: selected == 0,
                    onTap: () => _go(context, ref, 0),
                  ),
                  _DrawerItem(
                    icon: Icons.filter_list_rounded,
                    label: 'Leads',
                    selected: selected == 1,
                    onTap: () => _go(context, ref, 1),
                  ),
                  _DrawerItem(
                    icon: Icons.task_alt_rounded,
                    label: 'Tasks',
                    selected: selected == 2,
                    onTap: () => _go(context, ref, 2),
                  ),
                  _DrawerItem(
                    icon: Icons.trending_up_rounded,
                    label: 'Opportunities',
                    selected: selected == 3,
                    onTap: () => _go(context, ref, 3),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Divider(color: AppColors.divider, height: 1),
                  ),
                  const SizedBox(height: 8),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    selected: false,
                    onTap: () => _comingSoon(context, 'Settings'),
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    selected: false,
                    onTap: () => _comingSoon(context, 'Help & Support'),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Divider(color: AppColors.divider, height: 1),
            ),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              selected: false,
              danger: true,
              onTap: () => _comingSoon(context, 'Logout'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, WidgetRef ref, int index) {
    ref.read(dashboardNavProvider.notifier).select(index);
    Navigator.pop(context);
  }

  void _comingSoon(BuildContext context, String label) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label coming soon',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: ClipOval(
              child: Image.network(
                'https://i.pravatar.cc/120?img=12',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, color: Colors.white, size: 30),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Admin Owner',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'admin@crm.app',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppColors.red
        : selected
            ? AppColors.primary
            : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: danger ? AppColors.red : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (selected)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
