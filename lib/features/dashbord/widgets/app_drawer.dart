import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app/app_restart.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/utils/AppColors.dart';
import '../../../routes/app_routes.dart';
import '../../auth/data/auth_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../model/dashboard_section.dart';
import '../provider/dashboard_provider.dart';

/// Side navigation drawer opened from the dashboard header.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(dashboardNavProvider);
    final perms = ref.watch(permissionsProvider);

    // Only the sections this role is allowed to view. A section whose `*.view`
    // permission is false never reaches the list.
    final sections = DashboardSection.visibleTo(perms);

    // The bottom block is gated too — hide the divider when nothing survives.
    final canSettings = perms.canAny(const [
      AppPermissions.settingsView,
      AppPermissions.mastersView,
      AppPermissions.integrationsView,
    ]);

    return Drawer(
      backgroundColor: AppColors.cardBackground,
      width: 286,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final section in sections)
                    _DrawerItem(
                      icon: section.icon,
                      label: section.label,
                      selected: selected == section.index,
                      onTap: () => _go(context, ref, section.index),
                    ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Divider(color: AppColors.divider, height: 1),
                  ),
                  const SizedBox(height: 8),
                  if (canSettings)
                    _DrawerItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      selected: false,
                      onTap: () => _comingSoon(context, 'Settings'),
                    ),
                  // Help is intentionally ungated — everyone can ask for help.
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
              onTap: () => _logout(context, ref),
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

  /// Confirm → wipe → login. Everything after the confirmation runs against the
  /// root navigator, because the first thing the flow does is close the drawer
  /// this callback was fired from.
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    if (await _confirmLogout(context) != true) return;
    if (!context.mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    final rootContext = navigator.context;

    Navigator.pop(context); // close the drawer

    // Blocking spinner: the server call plus the storage wipe take a moment,
    // and a second tap must not be able to start a second logout.
    showDialog<void>(
      context: rootContext,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    await ref.read(authSessionProvider.notifier).logout();

    if (!rootContext.mounted) return;
    navigator.pop(); // dismiss the spinner

    // Storage is empty but the providers still hold this user's leads,
    // opportunities and dashboard figures. Remounting the scope drops all of
    // it, and the rebuilt router opens on the login screen because the session
    // is now null.
    AppRestart.restart(rootContext);
  }

  Future<bool?> _confirmLogout(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log out?',
            style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Text(
          'You will be signed out and all data saved on this device will be '
          'cleared. You will need to log in again.',
          style:
              GoogleFonts.poppins(fontSize: 13.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Logout',
                style: GoogleFonts.poppins(
                    color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
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

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    // Live profile from GET /my-profile. While it loads (or if it fails) fall
    // back to the user already stored in the session so the header is never
    // empty.
    final profileAsync = ref.watch(profileProvider);
    final sessionUser = ref.watch(authSessionProvider)?.user;

    final name = profileAsync.value?.name ?? sessionUser?.name ?? '';
    final email = profileAsync.value?.email ?? sessionUser?.email ?? '';
    final avatar = profileAsync.value?.avatar ?? sessionUser?.avatar;
    final role = profileAsync.value?.primaryRole;
    final isLoading = profileAsync.isLoading && !profileAsync.hasValue;

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
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
                  child: (avatar != null && avatar.isNotEmpty)
                      ? Image.network(
                          avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30),
                        )
                      : const Icon(Icons.person, color: Colors.white, size: 30),
                ),
              ),
              // Edit button overlapping the top-right of the avatar.
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // close the drawer first
                    context.push(AppRoutes.editProfile);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.edit,
                        color: AppColors.primary, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isLoading && name.isEmpty ? 'Loading…' : name,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            email,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          if (role != null && role.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
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
