import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_result.dart';
import '../../../core/utils/AppColors.dart';
import '../model/lead_model.dart';
import '../provider/lead_detail_provider.dart';
import '../provider/leads_provider.dart';

// ── Schedule Follow-up Sheet ──────────────────────────────────────────────────
//
// Shared bottom sheet to schedule the next follow-up. Reused by any screen
// (Lead, Opportunity, …): the caller supplies the accent [color] to match its
// screen and an [onSubmit] callback that persists to the right endpoint. The
// "Current Update" / "Next Action" option lists come from the shared lookups.

/// Signature for persisting a scheduled follow-up. Returns the API result so the
/// sheet can stay open and show the error message on failure.
typedef ScheduleFollowUpSubmit = Future<ApiResult<void>> Function({
  int? currentUpdateId,
  int? nextActionId,
  String? followupRemarks,
  required String nextFollowUpAt,
  required int interestScore,
});

/// The values collected by the "Schedule Next Follow-up" popup, returned to the
/// caller via `Navigator.pop` when the user taps Save.
class FollowUpFormResult {
  final int? currentUpdateId;
  final String? currentUpdate;
  final int? nextActionId;
  final String? nextAction;
  final String? nextRemark;
  final DateTime scheduleDate;
  final int score;

  const FollowUpFormResult({
    required this.currentUpdateId,
    required this.currentUpdate,
    required this.nextActionId,
    required this.nextAction,
    required this.nextRemark,
    required this.scheduleDate,
    required this.score,
  });
}

/// Bottom-sheet form to schedule the next follow-up. Holds its own local form
/// state and returns a [FollowUpFormResult] when saved.
class ScheduleFollowUpSheet extends ConsumerStatefulWidget {
  /// Unique key for this sheet's form state (e.g. the lead/opportunity id).
  final String id;

  /// Accent colour so the popup matches the screen it was opened from.
  final Color color;

  /// Persists the follow-up to the appropriate backend endpoint.
  final ScheduleFollowUpSubmit onSubmit;

  final String? initialCurrentUpdate;
  final String? initialNextAction;
  final int? initialCurrentUpdateId;
  final int? initialNextActionId;
  final String? initialRemark;
  final DateTime initialDate;

  const ScheduleFollowUpSheet({
    super.key,
    required this.id,
    required this.onSubmit,
    this.color = AppColors.primary,
    this.initialCurrentUpdate,
    this.initialNextAction,
    this.initialCurrentUpdateId,
    this.initialNextActionId,
    this.initialRemark,
    required this.initialDate,
  });

  @override
  ConsumerState<ScheduleFollowUpSheet> createState() =>
      _ScheduleFollowUpSheetState();
}

class _ScheduleFollowUpSheetState
    extends ConsumerState<ScheduleFollowUpSheet> {
  // Both "Current Update" and "Next Action" options are fetched from the API.
  static const List<String> _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  late final TextEditingController _remarkCtrl;

  /// The Riverpod notifier for this sheet's form state.
  FollowUpForm get _form =>
      ref.read(followUpFormProvider(widget.id).notifier);

  /// The current form state (read, no subscription).
  FollowUpFormState get _state =>
      ref.read(followUpFormProvider(widget.id));

  @override
  void initState() {
    super.initState();
    _remarkCtrl = TextEditingController(text: widget.initialRemark ?? '');
  }

  @override
  void dispose() {
    _remarkCtrl.dispose();
    super.dispose();
  }

  /// The currently-selected Current Update: the form value, or — if untouched —
  /// the option matching the lead's existing value.
  NamedLookup? _effectiveUpdate(List<NamedLookup> options) =>
      _state.currentUpdate ??
      _matchOption(options, widget.initialCurrentUpdateId,
          widget.initialCurrentUpdate);

  NamedLookup? _effectiveAction(List<NamedLookup> options) =>
      _state.nextAction ??
      _matchOption(
          options, widget.initialNextActionId, widget.initialNextAction);

  DateTime get _effectiveDate => _state.scheduleDate ?? widget.initialDate;

  /// Finds the option matching [id] (preferred) or [name]; null if none.
  NamedLookup? _matchOption(
      List<NamedLookup> options, int? id, String? name) {
    for (final o in options) {
      if (id != null && o.id == id) return o;
    }
    if (name != null) {
      for (final o in options) {
        if (o.name == name) return o;
      }
    }
    return null;
  }

  /// Colour for the score bar/label: red <40, amber <70, green otherwise.
  Color _scoreColor(double score) {
    if (score < 40) return AppColors.red;
    if (score < 70) return const Color(0xFFFFB547);
    return AppColors.green;
  }

  String _dateLabel(DateTime d) {
    final h = d.hour > 12
        ? d.hour - 12
        : d.hour == 0
            ? 12
            : d.hour;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final min = d.minute.toString().padLeft(2, '0');
    return '${_months[d.month - 1]} ${d.day}, ${d.year} · $h:$min $ampm';
  }

  /// `next_followup_at` in the API's `yyyy-MM-dd HH:mm:ss` format.
  String _apiDateTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  /// Themes the date/time pickers to match the screen's accent colour.
  Widget _pickerTheme(BuildContext ctx, Widget? child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: widget.color,
            onPrimary: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      );

  /// Picks a date, then a time, and stores them via the form notifier.
  Future<void> _pickDate() async {
    final current = _effectiveDate;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: _pickerTheme,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      builder: _pickerTheme,
    );
    _form.setScheduleDate(DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? current.hour,
      time?.minute ?? current.minute,
    ));
  }

  /// Persists the follow-up via the caller's [ScheduleFollowUpSubmit]. Keeps the
  /// sheet open on error, and pops with the result on success.
  Future<void> _submit() async {
    if (_state.saving) return;

    // Resolve the effective selections/date/score from the form state.
    final updateOptions =
        ref.read(currentUpdatesProvider).asData?.value ?? const <NamedLookup>[];
    final actionOptions =
        ref.read(nextActionsProvider).asData?.value ?? const <NamedLookup>[];
    final selectedUpdate = _effectiveUpdate(updateOptions);
    final selectedAction = _effectiveAction(actionOptions);
    final scheduleDate = _effectiveDate;
    final score = _state.score.round();

    _form.setSaving(true);
    final result = await widget.onSubmit(
      currentUpdateId: selectedUpdate?.id,
      nextActionId: selectedAction?.id,
      followupRemarks: _remarkCtrl.text.trim(),
      nextFollowUpAt: _apiDateTime(scheduleDate),
      interestScore: score,
    );
    if (!mounted) return;

    result.when(
      success: (_) {
        Navigator.pop(
          context,
          FollowUpFormResult(
            currentUpdateId: selectedUpdate?.id,
            currentUpdate: selectedUpdate?.name,
            nextActionId: selectedAction?.id,
            nextAction: selectedAction?.name,
            nextRemark: _remarkCtrl.text.trim().isEmpty
                ? null
                : _remarkCtrl.text.trim(),
            scheduleDate: scheduleDate,
            score: score,
          ),
        );
      },
      failure: (error) {
        _form.setSaving(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.message,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pad the sheet above the keyboard when the remark field is focused.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    // Form state (selections, date, score, saving) from Riverpod.
    final form = ref.watch(followUpFormProvider(widget.id));
    // "Current Update" options from GET /current-updates.
    final updatesAsync = ref.watch(currentUpdatesProvider);
    final updateOptions = updatesAsync.asData?.value ?? const <NamedLookup>[];
    final updateHint = updatesAsync.isLoading
        ? 'Loading updates…'
        : updatesAsync.hasError
            ? 'Could not load updates'
            : 'Select current update';
    // "Next Action" options from GET /next-actions.
    final actionsAsync = ref.watch(nextActionsProvider);
    final actionOptions = actionsAsync.asData?.value ?? const <NamedLookup>[];
    final actionHint = actionsAsync.isLoading
        ? 'Loading actions…'
        : actionsAsync.hasError
            ? 'Could not load actions'
            : 'Select next action';
    // Effective values: form selection, or fall back to the lead's existing.
    final selectedUpdate = form.currentUpdate ??
        _matchOption(updateOptions, widget.initialCurrentUpdateId,
            widget.initialCurrentUpdate);
    final selectedAction = form.nextAction ??
        _matchOption(actionOptions, widget.initialNextActionId,
            widget.initialNextAction);
    final scheduleDate = form.scheduleDate ?? widget.initialDate;
    final score = form.score;
    final scoreColor = _scoreColor(score);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.event_available_rounded,
                        color: widget.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule Follow-up',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Update progress and plan the next step',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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
            ),
            const SizedBox(height: 18),
            // Scrollable form body
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Update (dropdown, fetched from the API)
                    _FieldLabel(
                        'Current Update', Icons.update_rounded, widget.color),
                    const SizedBox(height: 8),
                    _SheetDropdown<NamedLookup>(
                      hint: updateHint,
                      value: selectedUpdate,
                      options: updateOptions,
                      labelOf: (o) => o.name,
                      onChanged: _form.setCurrentUpdate,
                    ),
                    const SizedBox(height: 18),
                    // Next Remark (text field)
                    _FieldLabel(
                        'Next Remark', Icons.notes_rounded, widget.color),
                    const SizedBox(height: 8),
                    _SheetTextField(
                      controller: _remarkCtrl,
                      hint: 'Add a remark for the next follow-up…',
                      color: widget.color,
                    ),
                    const SizedBox(height: 18),
                    // Next Action (dropdown, fetched from the API)
                    _FieldLabel(
                        'Next Action', Icons.bolt_rounded, widget.color),
                    const SizedBox(height: 8),
                    _SheetDropdown<NamedLookup>(
                      hint: actionHint,
                      value: selectedAction,
                      options: actionOptions,
                      labelOf: (o) => o.name,
                      onChanged: _form.setNextAction,
                    ),
                    const SizedBox(height: 18),
                    // Schedule Date (picker)
                    _FieldLabel('Schedule Date',
                        Icons.calendar_month_rounded, widget.color),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.divider, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_rounded,
                                size: 18, color: widget.color),
                            const SizedBox(width: 10),
                            Text(
                              _dateLabel(scheduleDate),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Score (%) slider
                    Row(
                      children: [
                        _FieldLabel(
                            'Score', Icons.percent_rounded, widget.color),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: scoreColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${score.round()}%',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: scoreColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: score / 100,
                        minHeight: 8,
                        backgroundColor: AppColors.divider,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: scoreColor,
                        inactiveTrackColor: AppColors.divider,
                        thumbColor: scoreColor,
                        overlayColor: scoreColor.withOpacity(0.15),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: score,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        onChanged: _form.setScore,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Save button (pinned to the bottom)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: form.saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    disabledBackgroundColor:
                        widget.color.withOpacity(0.6),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: form.saving
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
                    form.saving ? 'Scheduling…' : 'Schedule Follow-up',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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

/// Small label row (icon + text) used above each field in the follow-up sheet.
class _FieldLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _FieldLabel(this.text, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
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

/// Styled dropdown matching the sheet's design language. Generic over the
/// option type [T]; [labelOf] maps an option to its display text.
class _SheetDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  const _SheetDropdown({
    required this.hint,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(
            hint,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          dropdownColor: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          items: options
              .map((o) => DropdownMenuItem<T>(
                    value: o,
                    child: Text(labelOf(o)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Styled multiline text field used for the "Next Remark" input.
class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color color;

  const _SheetTextField(
      {required this.controller, required this.hint, required this.color});

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
          borderSide:
              const BorderSide(color: AppColors.divider, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.divider, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 1.2),
        ),
      ),
    );
  }
}
