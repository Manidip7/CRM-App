import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/AppColors.dart';
import 'permissions_provider.dart';

/// Shows [child] only when the user holds [permission]; otherwise renders
/// [fallback] (nothing by default).
///
/// ```dart
/// Can(
///   permission: AppPermissions.leadsAdd,
///   child: FloatingActionButton(onPressed: _addLead, child: Icon(Icons.add)),
/// )
/// ```
class Can extends ConsumerWidget {
  final String permission;
  final Widget child;
  final Widget fallback;

  const Can({
    super.key,
    required this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(canProvider(permission)) ? child : fallback;
  }
}

/// Shows [child] when the user holds **any** of [permissions]. Use for a
/// container that several separately-gated actions live in — e.g. an overflow
/// menu that should disappear entirely once every item inside it is hidden.
class CanAny extends ConsumerWidget {
  final List<String> permissions;
  final Widget child;
  final Widget fallback;

  const CanAny({
    super.key,
    required this.permissions,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(permissionsProvider).canAny(permissions);
    return allowed ? child : fallback;
  }
}

/// Guards a whole screen/section. Renders [child] when [permission] is
/// granted, and a friendly "no access" panel when it isn't.
///
/// Use this for anything reachable by other means (a deep link, a stale route,
/// a back-stack entry) — hiding the entry point alone isn't enough there.
class PermissionGate extends ConsumerWidget {
  final String permission;
  final Widget child;

  /// Shown instead of [child] when the permission is missing.
  final Widget? denied;

  /// Name used in the default denied message, e.g. "Projects".
  final String? label;

  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.denied,
    this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(canProvider(permission))) return child;
    return denied ?? NoAccessView(label: label);
  }
}

/// The standard "you don't have access" panel. Kept in one place so every
/// blocked screen looks the same.
class NoAccessView extends StatelessWidget {
  final String? label;

  const NoAccessView({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded,
                size: 34, color: AppColors.primary),
          ),
          const SizedBox(height: 18),
          Text(
            label == null ? 'No access' : '$label is not available',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your role does not have permission to view this section. '
            'Contact your administrator if you think this is a mistake.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Snackbar for the rare case where an action must stay visible but can't be
/// performed (e.g. a row tap that leads somewhere the user can't go).
void showNoPermissionSnackBar(BuildContext context, {String? action}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        action == null
            ? "You don't have permission to do that."
            : "You don't have permission to $action.",
        style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
      ),
      backgroundColor: AppColors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ),
  );
}
