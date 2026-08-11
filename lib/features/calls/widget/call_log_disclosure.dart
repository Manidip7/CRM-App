import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';
import '../provider/call_providers.dart';

/// Google Play's **prominent disclosure** for `READ_CALL_LOG`, and the only
/// route in the app to the system permission dialog.
///
/// Play policy requires that before the OS prompt appears the app shows its own
/// screen that (a) names the data, (b) says what it is used for, (c) states
/// that it is transferred off the device, and (d) is dismissible — the user has
/// to take an affirmative action to continue. A privacy policy or store listing
/// does not satisfy this; it has to be in the app, right before the prompt.
///
/// Deliberate details, each of which a reviewer checks:
///  * `barrierDismissible: false` plus a `PopScope` block — the dialog cannot be
///    swiped away into an accidental "yes"; only the two buttons resolve it.
///  * The confirm button says **Continue**, not "Allow". "Allow" is the system
///    dialog's own word and a disclosure that mimics the OS prompt is a
///    rejection reason on its own.
///  * "Not now" genuinely stops. It does not fall through to the OS prompt.
///
/// ```dart
/// final granted = await ensureCallLogAccess(context, ref);
/// ```
class CallLogDisclosureDialog extends StatelessWidget {
  const CallLogDisclosureDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // A back-gesture must not read as either answer — the user picks a button.
      canPop: false,
      child: Dialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.phone_callback_rounded,
                        size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Peplo CRM needs access to your call log',
                      style: GoogleFonts.poppins(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _paragraph(
                'When you call a lead or contact from Peplo, we read only that '
                "call's type, duration and time from your phone's call log and "
                "upload it to your company's CRM server, so the call shows up "
                "in that lead's activity history for your team.",
              ),
              const SizedBox(height: 10),
              _paragraph(
                'Calls with numbers that are not CRM contacts are never read or '
                'uploaded. We never read your messages, and we never change or '
                'delete anything in your call log.',
              ),
              const SizedBox(height: 10),
              _paragraph(
                'Peplo still works if you decline — calls just will not be '
                'logged automatically, and you can always add them by hand with '
                '"Log Call".',
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Not now',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paragraph(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      );
}

/// Makes sure the app may read the call log, showing the prominent disclosure
/// first if it hasn't been answered yet. Returns whether access ended up
/// granted.
///
/// Callers should treat `false` as "carry on without call logging" — never as
/// an error. Placing the call, opening the dialer and every other feature must
/// still work, which is both good product behaviour and what Play expects of a
/// non-core permission.
///
/// Set [force] for an explicit user request to turn the feature on (the *Enable
/// call logging* button). That re-shows the disclosure even after a previous
/// "no"; the automatic gate on the Call button asks only once.
Future<bool> ensureCallLogAccess(
  BuildContext context,
  WidgetRef ref, {
  bool force = false,
}) async {
  final gate = ref.read(callDisclosureProvider.notifier);
  if (await gate.isGranted) return true;
  if (!await gate.shouldDisclose(force: force)) return false;
  if (!context.mounted) return false;

  final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const CallLogDisclosureDialog(),
      ) ??
      false;

  if (!accepted) {
    await gate.markDeclined();
    return false;
  }
  return gate.grantAfterDisclosure();
}
