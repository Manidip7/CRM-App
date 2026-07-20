import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';
import '../data/calls_repository.dart';
import '../model/call_record.dart';
import '../provider/call_providers.dart';

/// Bottom sheet to manually log a call against a lead. Submits url-encoded
/// `{ call_type, duration, description, contact_name, outcome }` to
/// `POST /leads/{id}/call-logs`, then refreshes the lead's call history. Pops
/// `true` on success.
class LogCallSheet extends ConsumerStatefulWidget {
  final String leadId;

  const LogCallSheet({super.key, required this.leadId});

  @override
  ConsumerState<LogCallSheet> createState() => _LogCallSheetState();
}

class _LogCallSheetState extends ConsumerState<LogCallSheet> {
  final _duration = TextEditingController();
  final _description = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(logCallFormProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _duration.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(logCallFormProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Log Call',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Call Type'),
                        _buildCallTypeDropdown(form.callType),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Duration (sec)'),
                        _textField(_duration,
                            hint: 'e.g. 120',
                            keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _label('Outcome'),
              _buildOutcomeDropdown(form.outcome),
              const SizedBox(height: 14),
              _label('Description'),
              _textField(_description,
                  hint: 'What was discussed?', maxLines: 3),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: form.submitting ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: form.submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: Colors.white),
                        )
                      : Text(
                          'Save Call Log',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller,
      {String? hint, TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13.5),
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: _border(AppColors.divider),
        enabledBorder: _border(AppColors.divider),
        focusedBorder: _border(AppColors.primary),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  Widget _buildCallTypeDropdown(AppCallType selected) {
    return _shell(
      Icons.call_rounded,
      DropdownButtonHideUnderline(
        child: DropdownButton<AppCallType>(
          value: selected,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
          items: kLogCallTypes
              .map((t) => DropdownMenuItem<AppCallType>(
                    value: t,
                    // Display capitalized (Outbound/Inbound); the value sent
                    // stays lowercase via directionApiValue.
                    child: Text(
                      t == AppCallType.outgoing ? 'Outbound' : 'Inbound',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: (t) {
            if (t != null) {
              ref.read(logCallFormProvider.notifier).setCallType(t);
            }
          },
        ),
      ),
    );
  }

  Widget _buildOutcomeDropdown(CallOutcome selected) {
    return _shell(
      Icons.assignment_turned_in_outlined,
      DropdownButtonHideUnderline(
        child: DropdownButton<CallOutcome>(
          value: selected,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
          items: CallOutcome.values
              .map((o) => DropdownMenuItem<CallOutcome>(
                    value: o,
                    child: Text(o.label, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (o) {
            if (o != null) {
              ref.read(logCallFormProvider.notifier).setOutcome(o);
            }
          },
        ),
      ),
    );
  }

  Widget _shell(IconData icon, Widget child) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final form = ref.read(logCallFormProvider);
    final notifier = ref.read(logCallFormProvider.notifier);
    notifier.setSubmitting(true);

    final result = await ref.read(callsRepositoryProvider).logLeadCall(
          widget.leadId,
          callType: form.callType.directionApiValue,
          duration: int.tryParse(_duration.text.trim()) ?? 0,
          description: _description.text.trim(),
          outcome: form.outcome.apiValue,
        );

    if (!mounted) return;
    notifier.setSubmitting(false);

    final error = result.errorOrNull;
    if (error != null) {
      _toast(error.message, isError: true);
      return;
    }

    // Refresh the lead's call history so the new entry shows.
    ref.invalidate(leadCallHistoryProvider(widget.leadId));
    Navigator.pop(context, true);
    _toast('Call logged');
  }

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontSize: 13, color: Colors.white)),
        backgroundColor: isError ? AppColors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
