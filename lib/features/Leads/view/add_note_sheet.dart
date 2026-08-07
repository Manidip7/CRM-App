import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';

/// Bottom sheet to add a note, as an `x-www-form-urlencoded` `content` field.
/// The sheet itself is target-agnostic: the Lead detail screen points it at
/// `POST /leads/{id}/notes` and the Opportunity detail screen at
/// `POST /opportunities/{id}/notes`, each passing its own provider.
///
/// [watchSaving] reads the in-flight flag off the caller's provider (so saving
/// state stays Riverpod-managed) and [onSubmit] performs the call, returning
/// `null` on success or the message to show on failure. The text field uses a
/// local controller. Pops `true` when the note is saved.
class AddNoteSheet extends ConsumerStatefulWidget {
  /// Watches the `saving` flag of the notifier behind [onSubmit]. Called during
  /// build, so the sheet rebuilds while the request is in flight.
  final bool Function(WidgetRef ref) watchSaving;

  /// Sends the note; returns `null` on success or an error message.
  final Future<String?> Function(String content) onSubmit;

  /// Placeholder text — lets each screen name what the note is about.
  final String hint;

  const AddNoteSheet({
    super.key,
    required this.watchSaving,
    required this.onSubmit,
    this.hint = 'Write a note…',
  });

  @override
  ConsumerState<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends ConsumerState<AddNoteSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = await widget.onSubmit(_ctrl.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = widget.watchSaving(ref);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sticky_note_2_outlined,
                      color: AppColors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add Note',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _FieldLabel('Note', Icons.notes_rounded),
            const SizedBox(height: 8),
            _SheetTextField(controller: _ctrl, hint: widget.hint),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 19),
                label: Text(
                  saving ? 'Saving…' : 'Add Note',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small label row (icon + text) shown above the note field.
class _FieldLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  const _FieldLabel(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Styled multiline text field matching the other detail-screen sheets.
class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _SheetTextField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      minLines: 2,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textLight,
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
    );
  }
}
