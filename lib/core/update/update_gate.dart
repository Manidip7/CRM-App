import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/AppColors.dart';
import 'app_update_provider.dart';

/// Wraps the whole app and covers it with a blocking "Update required" screen
/// whenever Play reports a newer version.
///
/// It sits in `MaterialApp.router`'s `builder`, above every route, so it needs
/// no navigator of its own and there is no screen the user can reach behind it.
/// [PopScope] holds the back button, so the only way past it is to install the
/// update — which restarts the app.
class UpdateGate extends ConsumerWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUpdateProvider);
    if (!state.updateRequired) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: PopScope(
            canPop: false,
            child: Material(
              color: AppColors.background,
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.system_update_rounded,
                            size: 42,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Update required',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'A newer version of Peplo CRM is available. Install '
                          'it to keep using the app.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            height: 1.55,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (state.message != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.primary.withOpacity(0.25),
                                  width: 0.8),
                            ),
                            child: Text(
                              state.message!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                height: 1.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: state.inProgress
                                ? null
                                : () =>
                                    ref.read(appUpdateProvider.notifier).start(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor:
                                  AppColors.primary.withOpacity(0.5),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: state.inProgress
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.download_rounded, size: 20),
                            label: Text(
                              state.inProgress ? 'Updating…' : 'Update now',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
