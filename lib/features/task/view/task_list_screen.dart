import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';
import '../model/TaskStatus.dart';
import '../provider/task_filter_provider.dart';
import '../provider/task_provider.dart';

/// Full task list with search, status & assignee dropdowns, a from/to date
/// range and per-row edit / delete actions. Reached from the "Task List"
/// button on the Task (Today's Agenda) screen.
class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(filteredTasksProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(tasks.length),
            _buildSearchRow(),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: ref.watch(taskFiltersExpandedProvider)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusAssigneeRow(),
                        _buildDateRow(),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: tasks.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      itemCount: tasks.length,
                      itemBuilder: (ctx, i) => _buildTaskCard(tasks[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Task List',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'All your tasks in one place',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildFilterToggle(),
        ],
      ),
    );
  }

  /// Header button that expands / collapses the status, assignee and date
  /// filters. Shows a dot when any of those filters is active.
  Widget _buildFilterToggle() {
    final f = ref.watch(taskFilterProvider);
    final showFilters = ref.watch(taskFiltersExpandedProvider);
    final hasActiveFilters = f.status != null ||
        f.assignee != null ||
        f.fromDate != null ||
        f.toDate != null;
    final active = showFilters || hasActiveFilters;
    return GestureDetector(
      onTap: () => ref.read(taskFiltersExpandedProvider.notifier).toggle(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 19,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
            if (hasActiveFilters && !showFilters)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Search ──
  Widget _buildSearchRow() {
    final hasQuery =
        ref.watch(taskFilterProvider.select((f) => f.search.isNotEmpty));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => ref.read(taskFilterProvider.notifier).setSearch(v),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search tasks...',
            hintStyle:
                const TextStyle(color: AppColors.textLight, fontSize: 13.5),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textLight, size: 20),
            suffixIcon: !hasQuery
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textLight),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(taskFilterProvider.notifier).setSearch('');
                    },
                  ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── Status + Assignee dropdowns ──
  Widget _buildStatusAssigneeRow() {
    final f = ref.watch(taskFilterProvider);
    final assignees = ref.watch(taskAssigneesProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Expanded(child: _buildStatusDropdown(f.status)),
          const SizedBox(width: 10),
          Expanded(child: _buildAssigneeDropdown(f.assignee, assignees)),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(TaskStatus? selected) {
    final accent = selected?.color ?? AppColors.textSecondary;
    return _dropdownShell(
      icon: Icons.flag_outlined,
      accent: accent,
      child: DropdownButton<TaskStatus?>(
        value: selected,
        isExpanded: true,
        isDense: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary),
        style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
        items: [
          const DropdownMenuItem<TaskStatus?>(
            value: null,
            child: Text('All Statuses'),
          ),
          ...TaskStatus.values.map(
            (s) => DropdownMenuItem<TaskStatus?>(
              value: s,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration:
                        BoxDecoration(color: s.color, shape: BoxShape.circle),
                  ),
                  Flexible(
                    child: Text(s.label, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        ],
        onChanged: (s) => ref.read(taskFilterProvider.notifier).setStatus(s),
      ),
    );
  }

  Widget _buildAssigneeDropdown(String? selected, List<String> assignees) {
    return _dropdownShell(
      icon: Icons.person_outline_rounded,
      accent: selected == null ? AppColors.textSecondary : AppColors.primary,
      child: DropdownButton<String?>(
        value: selected,
        isExpanded: true,
        isDense: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary),
        style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('All Assignees'),
          ),
          ...assignees.map(
            (a) => DropdownMenuItem<String?>(
              value: a,
              child: Text(a, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (a) => ref.read(taskFilterProvider.notifier).setAssignee(a),
      ),
    );
  }

  Widget _dropdownShell({
    required IconData icon,
    required Color accent,
    required Widget child,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(child: DropdownButtonHideUnderline(child: child)),
        ],
      ),
    );
  }

  // ── From / To dates ──
  Widget _buildDateRow() {
    final f = ref.watch(taskFilterProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _dateField(
              label: 'From date',
              value: f.fromDate,
              onTap: () => _pickDate(isFrom: true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _dateField(
              label: 'To date',
              value: f.toDate,
              onTap: () => _pickDate(isFrom: false),
            ),
          ),
          if (f.fromDate != null || f.toDate != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => ref.read(taskFilterProvider.notifier).clearDates(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_busy_rounded,
                    size: 18, color: AppColors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
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
                hasValue ? _shortDate(value) : label,
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

  // ── Task card ──
  Widget _buildTaskCard(TaskModel task) {
    final accent = task.status.color;
    final isCompleted = task.status == TaskStatus.completed;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accent, width: 3.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + status tag
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _tag(task.status.label, accent),
              ],
            ),
            const SizedBox(height: 4),
            // Details
            Text(
              '${task.nextAction} · ${task.remark}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            // Priority + assignee chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip(
                  Icons.outlined_flag_rounded,
                  '${task.priority.label} priority',
                  task.priority.color,
                ),
                _chip(
                  Icons.person_outline_rounded,
                  task.assignee,
                  AppColors.textSecondary,
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.divider, height: 1),
            ),
            // Due date + actions
            Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  size: 14,
                  color: task.status == TaskStatus.overdue
                      ? AppColors.red
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  'Due ${_formatDate(task.dueDate)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: task.status == TaskStatus.overdue
                        ? AppColors.red
                        : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                _actionIcon(
                  icon: Icons.edit_outlined,
                  color: AppColors.green,
                  tooltip: 'Edit',
                  onTap: () => _onEdit(task),
                ),
                const SizedBox(width: 6),
                _actionIcon(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.red,
                  tooltip: 'Delete',
                  onTap: () => _onDelete(task),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.checklist_rtl_rounded,
              size: 48, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(
            'No tasks match your filters',
            style: GoogleFonts.poppins(
                fontSize: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Actions
  // ─────────────────────────────────────────────
  Future<void> _pickDate({required bool isFrom}) async {
    final f = ref.read(taskFilterProvider);
    final initial = (isFrom ? f.fromDate : f.toDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked == null) return;
    final notifier = ref.read(taskFilterProvider.notifier);
    if (isFrom) {
      notifier.setFromDate(picked);
    } else {
      notifier.setToDate(picked);
    }
  }

  void _onEdit(TaskModel task) {
    ref.read(taskEditProvider.notifier).start(task);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditTaskSheet(
        task: task,
        onSave: (updated) {
          ref.read(taskListProvider.notifier).updateTask(updated);
          _toast('Task updated');
        },
      ),
    );
  }

  Future<void> _onDelete(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete task?',
            style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Text(
          '"${task.title}" will be permanently removed.',
          style: GoogleFonts.poppins(
              fontSize: 13.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(taskListProvider.notifier).deleteTask(task);
    _toast('Task deleted');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontSize: 13, color: Colors.white)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $hour:$min $ampm';
  }
}

/// Bottom sheet used to edit a task's title, status, priority, assignee and
/// due date. Selection state lives in [taskEditProvider] (Riverpod), so the
/// dropdowns and date picker drive the UI without any local [setState].
class _EditTaskSheet extends ConsumerStatefulWidget {
  final TaskModel task;
  final ValueChanged<TaskModel> onSave;

  const _EditTaskSheet({required this.task, required this.onSave});

  @override
  ConsumerState<_EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends ConsumerState<_EditTaskSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _assigneeController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _assigneeController = TextEditingController(text: widget.task.assignee);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _assigneeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Falls back to the original task if the draft was somehow not seeded.
    final draft = ref.watch(taskEditProvider);
    final status = draft?.status ?? widget.task.status;
    final priority = draft?.priority ?? widget.task.priority;
    final dueDate = draft?.dueDate ?? widget.task.dueDate;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                'Edit Task',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _label('Title'),
              _textField(_titleController, 'Task title'),
              const SizedBox(height: 14),
              _label('Assignee'),
              _textField(_assigneeController, 'Assignee name'),
              const SizedBox(height: 14),
              _label('Status'),
              _sheetDropdown<TaskStatus>(
                value: status,
                items: TaskStatus.values,
                labelOf: (s) => s.label,
                colorOf: (s) => s.color,
                onChanged: (s) =>
                    ref.read(taskEditProvider.notifier).setStatus(s),
              ),
              const SizedBox(height: 14),
              _label('Priority'),
              _sheetDropdown<TaskPriority>(
                value: priority,
                items: TaskPriority.values,
                labelOf: (p) => p.label,
                colorOf: (p) => p.color,
                onChanged: (p) =>
                    ref.read(taskEditProvider.notifier).setPriority(p),
              ),
              const SizedBox(height: 14),
              _label('Due date'),
              GestureDetector(
                onTap: _pickDueDate,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Text(
                        _dueLabel(dueDate),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Save Changes',
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

  Widget _label(String text) => Padding(
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

  Widget _textField(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13.5),
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _sheetDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelOf,
    required Color Function(T) colorOf,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          items: items
              .map((it) => DropdownMenuItem<T>(
                    value: it,
                    child: Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                              color: colorOf(it), shape: BoxShape.circle),
                        ),
                        Text(labelOf(it)),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final current = ref.read(taskEditProvider)?.dueDate ?? widget.task.dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked == null) return;
    ref.read(taskEditProvider.notifier).setDueDate(
          DateTime(picked.year, picked.month, picked.day, current.hour,
              current.minute),
        );
  }

  void _save() {
    final draft = ref.read(taskEditProvider);
    final title = _titleController.text.trim();
    final assignee = _assigneeController.text.trim();
    widget.onSave(
      widget.task.copyWith(
        title: title.isEmpty ? widget.task.title : title,
        assignee: assignee.isEmpty ? widget.task.assignee : assignee,
        status: draft?.status ?? widget.task.status,
        priority: draft?.priority ?? widget.task.priority,
        dueDate: draft?.dueDate ?? widget.task.dueDate,
      ),
    );
    Navigator.pop(context);
  }

  String _dueLabel(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
