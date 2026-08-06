import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';
import '../../Leads/model/lead_model.dart';
import '../../Leads/provider/assign_providers.dart';
import '../model/TaskStatus.dart';
import '../model/task_item_model.dart';
import '../provider/create_task_provider.dart';
import '../provider/task_list_api_provider.dart';

/// Form to create *or* edit a task. Submits `{ title, description, assigned_to,
/// status, priority, start_date, due_at }` to `POST /tasks` — or to
/// `PUT /tasks/{id}` when [task] is given — via [taskListApiProvider], then
/// refreshes the list. Dropdown / date state lives in Riverpod (no [setState])
/// via [createTaskDraftProvider].
class CreateTaskScreen extends ConsumerStatefulWidget {
  /// The task being edited. Null means "create a new task".
  final TaskItem? task;

  const CreateTaskScreen({super.key, this.task});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      _title.text = task.title;
      _description.text = task.description ?? '';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(createTaskDraftProvider.notifier);
      if (task == null) {
        // Fresh form each time the screen opens.
        notifier.reset();
      } else {
        notifier.prefill(
          status: NewTaskStatus.fromApi(task.rawStatus),
          priority: task.priorityEnum,
          startDate: task.startDate?.toLocal(),
          dueDate: task.dueAt?.toLocal(),
        );
        _resolveAssignee(task.assignedTo);
      }
      ref.read(createTaskSubmittingProvider.notifier).set(false);
    });
  }

  /// Selects the task's current assignee once `GET /users` has loaded. The
  /// dropdown compares by instance, so the value must come from that same list.
  Future<void> _resolveAssignee(int? assignedTo) async {
    if (assignedTo == null) return;
    try {
      final users = await ref.read(assignableUsersProvider.future);
      if (!mounted) return;
      for (final u in users) {
        if (u.id == assignedTo) {
          ref.read(createTaskDraftProvider.notifier).setAssignee(u);
          return;
        }
      }
    } catch (_) {
      // Users failed to load; the dropdown shows its own error state.
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(createTaskDraftProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _label('Title'),
                  _textField(_title, hint: 'Task title'),
                  const SizedBox(height: 14),
                  _label('Description'),
                  _textField(_description,
                      hint: 'What needs to be done?', maxLines: 3),
                  const SizedBox(height: 14),
                  _label('Assigned To'),
                  _buildAssigneeDropdown(draft.assignee),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Status'),
                            _buildStatusDropdown(draft.status),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Priority'),
                            _buildPriorityDropdown(draft.priority),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Start Date'),
                            _dateField(
                              value: draft.startDate,
                              hint: 'Pick date',
                              onTap: () => _pickDate(isStart: true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Due Date'),
                            _dateField(
                              value: draft.dueDate,
                              hint: 'Pick date',
                              onTap: () => _pickDate(isStart: false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _saveButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ──
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 20, color: AppColors.textPrimary),
            ),
          ),
          Text(
            _isEdit ? 'Edit Task' : 'Add Task',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
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
      {String? hint, int maxLines = 1}) {
    return TextField(
      controller: controller,
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

  // ── Assigned To (GET /users) ──
  Widget _buildAssigneeDropdown(AssignableUser? selected) {
    final usersAsync = ref.watch(assignableUsersProvider);
    return usersAsync.when(
      loading: () => _shell(
        Icons.person_outline_rounded,
        const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => _shell(
        Icons.person_outline_rounded,
        Text('Could not load users',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary)),
      ),
      data: (users) {
        // Keep the selected value valid against the freshly-loaded list.
        final value =
            users.any((u) => u.id == selected?.id) ? selected : null;
        return _shell(
          Icons.person_outline_rounded,
          DropdownButtonHideUnderline(
            child: DropdownButton<AssignableUser?>(
              value: value,
              isExpanded: true,
              // Two-line items (name + designation) need room to breathe.
              itemHeight: 56,
              hint: Text('Select user',
                  style: GoogleFonts.poppins(
                      fontSize: 13.5, color: AppColors.textLight)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary),
              style:
                  const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
              // The button itself stays single-line (just the name); the
              // designation only shows in the opened menu.
              selectedItemBuilder: (context) => [
                _selectedName('Unassigned'),
                ...users.map((u) => _selectedName(u.name)),
              ],
              items: [
                const DropdownMenuItem<AssignableUser?>(
                  value: null,
                  child: Text('Unassigned'),
                ),
                ...users.map(
                  (u) => DropdownMenuItem<AssignableUser?>(
                    value: u,
                    child: _assigneeItem(u),
                  ),
                ),
              ],
              onChanged: (u) =>
                  ref.read(createTaskDraftProvider.notifier).setAssignee(u),
            ),
          ),
        );
      },
    );
  }

  /// Menu row for a user: name on top, designation as a muted sub-label.
  Widget _assigneeItem(AssignableUser u) {
    final designation = u.designation?.trim() ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          u.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (designation.isNotEmpty)
          Text(
            designation,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  /// Single-line name shown in the collapsed dropdown button.
  Widget _selectedName(String name) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
      ),
    );
  }

  // ── Status ──
  Widget _buildStatusDropdown(NewTaskStatus selected) {
    return _shell(
      Icons.flag_outlined,
      DropdownButtonHideUnderline(
        child: DropdownButton<NewTaskStatus>(
          value: selected,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
          items: NewTaskStatus.values
              .map((s) => DropdownMenuItem<NewTaskStatus>(
                    value: s,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                              color: s.color, shape: BoxShape.circle),
                        ),
                        Flexible(
                          child:
                              Text(s.label, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (s) {
            if (s != null) {
              ref.read(createTaskDraftProvider.notifier).setStatus(s);
            }
          },
        ),
      ),
    );
  }

  // ── Priority ──
  Widget _buildPriorityDropdown(TaskPriority selected) {
    return _shell(
      Icons.outlined_flag_rounded,
      DropdownButtonHideUnderline(
        child: DropdownButton<TaskPriority>(
          value: selected,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
          items: kCreateTaskPriorities
              .map((p) => DropdownMenuItem<TaskPriority>(
                    value: p,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                              color: p.color, shape: BoxShape.circle),
                        ),
                        Flexible(
                          child:
                              Text(p.label, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (p) {
            if (p != null) {
              ref.read(createTaskDraftProvider.notifier).setPriority(p);
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

  // ── Date field ──
  Widget _dateField({
    required DateTime? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasValue ? _shortDate(value) : hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: hasValue ? AppColors.textPrimary : AppColors.textLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveButton() {
    final submitting = ref.watch(createTaskSubmittingProvider);
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: submitting ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.2, color: Colors.white),
              )
            : Text(
                _isEdit ? 'Update Task' : 'Create Task',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // ── Actions ──
  Future<void> _pickDate({required bool isStart}) async {
    final draft = ref.read(createTaskDraftProvider);
    final initial =
        (isStart ? draft.startDate : draft.dueDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked == null) return;
    final notifier = ref.read(createTaskDraftProvider.notifier);
    if (isStart) {
      notifier.setStartDate(picked);
    } else {
      notifier.setDueDate(picked);
    }
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      _toast('Title is required', isError: true);
      return;
    }

    final draft = ref.read(createTaskDraftProvider);
    final submitting = ref.read(createTaskSubmittingProvider.notifier);
    submitting.set(true);

    final api = ref.read(taskListApiProvider.notifier);
    final task = widget.task;
    final error = task == null
        ? await api.createTask(
            title: title,
            description: _description.text.trim(),
            assignedTo: draft.assignee?.id,
            status: draft.status.apiValue,
            priority: draft.priority.label.toLowerCase(),
            startDate: _apiDate(draft.startDate),
            dueDate: _apiDate(draft.dueDate),
          )
        : await api.updateTask(
            id: task.id,
            title: title,
            description: _description.text.trim(),
            assignedTo: draft.assignee?.id,
            status: draft.status.apiValue,
            priority: draft.priority.label.toLowerCase(),
            startDate: _apiDate(draft.startDate),
            dueDate: _apiDate(draft.dueDate),
          );

    if (!mounted) return;
    submitting.set(false);

    if (error != null) {
      _toast(error, isError: true);
      return;
    }

    Navigator.maybePop(context);
    _toast(_isEdit ? 'Task updated' : 'Task created');
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

  /// Backend date format (`yyyy-MM-dd`), or null when unset.
  String? _apiDate(DateTime? d) {
    if (d == null) return null;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
