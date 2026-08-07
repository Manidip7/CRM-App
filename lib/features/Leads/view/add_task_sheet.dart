import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';

/// Priority values the task endpoints accept.
const List<String> kTaskPriorities = ['high', 'medium', 'low'];

/// Backend status values, with their labels. Only the lead update endpoint
/// takes a status, so the sheet hides the field unless [AddTaskSheet.setStatus]
/// is given.
const List<(String, String)> kTaskStatuses = [
  ('open', 'Open'),
  ('in_progress', 'In Progress'),
  ('backlog', 'Backlog'),
  ('done', 'Done'),
];

/// The form values [AddTaskSheet] renders, read from whichever provider the
/// calling screen owns.
class TaskSheetValues {
  final DateTime? dueAt;
  final String priority;

  /// The selected status, or `null` when the sheet has no status field.
  final String? status;

  /// True while the save request is in flight.
  final bool saving;

  const TaskSheetValues({
    required this.dueAt,
    required this.priority,
    this.status,
    required this.saving,
  });
}

/// Bottom sheet to add or edit a task: a title, a due date+time picker, a
/// priority dropdown and — when [setStatus] is given — a status dropdown.
///
/// The sheet is entity-agnostic: the Lead detail screen wires it to
/// `POST /leads/{id}/tasks` / `PUT /leads/{id}/tasks/{taskId}` and the
/// Opportunity detail screen to `POST /opportunities/{id}/tasks`, each passing
/// its own provider through [watchValues], the setters and [onSubmit]. Form
/// state therefore stays Riverpod-managed; only the title uses a local
/// controller. Pops `true` when the task is saved.
class AddTaskSheet extends ConsumerStatefulWidget {
  /// Reads the form values off the caller's provider. Called during build, so
  /// the sheet rebuilds as the user picks a date / priority and while saving.
  final TaskSheetValues Function(WidgetRef ref) watchValues;

  final ValueChanged<DateTime> setDueAt;
  final ValueChanged<String> setPriority;

  /// Omit to hide the status field (endpoints that don't accept a status).
  final ValueChanged<String>? setStatus;

  /// Saves the task; returns `null` on success or an error message to show.
  final Future<String?> Function(String title) onSubmit;

  /// Pre-fills the title — non-null puts the sheet in "edit" wording.
  final String? initialTitle;

  const AddTaskSheet({
    super.key,
    required this.watchValues,
    required this.setDueAt,
    required this.setPriority,
    required this.onSubmit,
    this.setStatus,
    this.initialTitle,
  });

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  static const List<String> _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  late final TextEditingController _ctrl;

  bool get _isEdit => widget.initialTitle != null;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialTitle ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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

  Widget _pickerTheme(BuildContext ctx, Widget? child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      );

  Future<void> _pickDue() async {
    final current = widget.watchValues(ref).dueAt ?? DateTime.now();
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
    widget.setDueAt(DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? current.hour,
      time?.minute ?? current.minute,
    ));
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submit() async {
    final error = await widget.onSubmit(_ctrl.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      _error(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.watchValues(ref);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
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
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.task_alt_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit Task' : 'Add Task',
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
            ),
            const SizedBox(height: 18),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const _FieldLabel('Title', Icons.title_rounded),
                    const SizedBox(height: 8),
                    _SheetTextField(
                      controller: _ctrl,
                      hint: 'e.g. Send Quotation',
                    ),
                    const SizedBox(height: 18),
                    // Due date + time
                    const _FieldLabel('Due Date & Time', Icons.event_rounded),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDue,
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.divider, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Text(
                              values.dueAt == null
                                  ? 'Select due date & time'
                                  : _dateLabel(values.dueAt!),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: values.dueAt == null
                                    ? AppColors.textLight
                                    : AppColors.textPrimary,
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
                    // Priority
                    const _FieldLabel('Priority', Icons.flag_rounded),
                    const SizedBox(height: 8),
                    _SheetDropdown<String>(
                      hint: 'Select priority',
                      value: values.priority,
                      options: kTaskPriorities,
                      labelOf: (p) => '${p[0].toUpperCase()}${p.substring(1)}',
                      onChanged: (v) {
                        if (v != null) widget.setPriority(v);
                      },
                    ),
                    // Status — only for endpoints that accept one.
                    if (widget.setStatus != null) ...[
                      const SizedBox(height: 18),
                      const _FieldLabel('Status', Icons.donut_large_rounded),
                      const SizedBox(height: 8),
                      _SheetDropdown<String>(
                        hint: 'Select status',
                        value: values.status,
                        options: kTaskStatuses.map((s) => s.$1).toList(),
                        labelOf: (s) =>
                            kTaskStatuses.firstWhere((e) => e.$1 == s).$2,
                        onChanged: (v) {
                          if (v != null) widget.setStatus!(v);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: values.saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: values.saving
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
                    values.saving
                        ? 'Saving…'
                        : (_isEdit ? 'Save Changes' : 'Add Task'),
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

/// Small label row (icon + text) shown above each field.
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

/// Styled text field used for the task title.
class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _SheetTextField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      // Matches the other detail-screen sheets (the field grows to 3 lines).
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
