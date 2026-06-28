import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/AppColors.dart';
import '../model/TaskStatus.dart';
import '../model/task_item_model.dart';
import '../provider/task_filter_provider.dart';
import '../provider/task_list_api_provider.dart';

/// Full task list (API-backed, `GET /tasks`) with search, status & assignee
/// dropdowns and a from/to date range. Filters are applied over the pages
/// loaded so far; scrolling to the bottom fetches the next page. Reached from
/// the "Task List" button on the Task (Today's Agenda) screen.
class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(taskListApiProvider.notifier).loadMore();
    }
  }

  // ── Filtering over the loaded pages ──
  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _dayEnd(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

  List<TaskItem> _applyFilters(List<TaskItem> tasks, TaskFilterState f) {
    // Keep the API order (newest first); search is server-side (`?search=`),
    // so here we only apply status / assignee / date filters, no re-sort.
    final result = tasks.where((t) {
      if (f.status != null && t.derivedStatus != f.status) return false;
      if (f.assignee != null && t.assigneeName != f.assignee) return false;
      final due = t.dueAt?.toLocal();
      if (f.fromDate != null &&
          (due == null || due.isBefore(_dayStart(f.fromDate!)))) {
        return false;
      }
      if (f.toDate != null &&
          (due == null || due.isAfter(_dayEnd(f.toDate!)))) {
        return false;
      }
      return true;
    }).toList();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final apiState = ref.watch(taskListApiProvider);
    final filter = ref.watch(taskFilterProvider);
    final tasks = _applyFilters(apiState.items, filter);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(tasks.length, apiState.total),
            _buildSearchRow(),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: ref.watch(taskFiltersExpandedProvider)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusAssigneeRow(apiState.items),
                        _buildDateRow(),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: 4),
            Expanded(child: _buildBody(apiState, tasks)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(TaskListApiState apiState, List<TaskItem> tasks) {
    // First-page load.
    if (apiState.isLoading && apiState.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    // First-page error.
    if (apiState.error != null && apiState.items.isEmpty) {
      return _buildError(apiState.error!);
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(taskListApiProvider.notifier).refresh(),
      child: tasks.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              children: [
                SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: _buildEmptyState()),
              ],
            )
          : ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              itemCount: tasks.length + (apiState.hasMore ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i >= tasks.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _buildTaskCard(tasks[i]);
              },
            ),
    );
  }

  Widget _buildError(Object error) {
    final message =
        error is ApiException ? error.message : 'Could not load tasks.';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.red, size: 40),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => ref.read(taskListApiProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('Retry', style: GoogleFonts.poppins(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(int shownCount, int total) {
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
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  total > 0 ? 'All your tasks · $total total' : 'All your tasks',
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
          onChanged: (v) {
            // Track text for the clear button; fire the server-side search.
            ref.read(taskFilterProvider.notifier).setSearch(v);
            ref.read(taskListApiProvider.notifier).setSearch(v);
          },
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
                      ref.read(taskListApiProvider.notifier).setSearch('');
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
  Widget _buildStatusAssigneeRow(List<TaskItem> items) {
    final f = ref.watch(taskFilterProvider);
    final assignees = (items
            .map((t) => t.assigneeName)
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort());
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
    // Guard: the selected assignee may not exist in the freshly-loaded list.
    final value = assignees.contains(selected) ? selected : null;
    return _dropdownShell(
      icon: Icons.person_outline_rounded,
      accent: value == null ? AppColors.textSecondary : AppColors.primary,
      child: DropdownButton<String?>(
        value: value,
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
  Widget _buildTaskCard(TaskItem task) {
    final status = task.derivedStatus;
    final priority = task.priorityEnum;
    final accent = status.color;
    final isCompleted = status == TaskStatus.completed;
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
                _tag(status.label, accent),
              ],
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            // Priority + assignee + linked record chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip(
                  Icons.outlined_flag_rounded,
                  '${priority.label} priority',
                  priority.color,
                ),
                if (task.assigneeName != null && task.assigneeName!.isNotEmpty)
                  _chip(
                    Icons.person_outline_rounded,
                    task.assigneeName!,
                    AppColors.textSecondary,
                  ),
                if (task.taskableTitle != null &&
                    task.taskableTitle!.isNotEmpty)
                  _chip(
                    task.isOpportunity
                        ? Icons.workspaces_outline
                        : Icons.person_pin_circle_outlined,
                    '${task.linkedLabel}: ${task.taskableTitle}',
                    AppColors.primary,
                  ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.divider, height: 1),
            ),
            // Due date
            Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  size: 14,
                  color: status == TaskStatus.overdue
                      ? AppColors.red
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  task.dueAt != null
                      ? 'Due ${_formatDate(task.dueAt!)}'
                      : 'No due date',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: status == TaskStatus.overdue
                        ? AppColors.red
                        : AppColors.textSecondary,
                  ),
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
    return ConstrainedBox(
      // Keep a chip from exceeding the card width when its label is long
      // (e.g. a long linked Lead/Opportunity title) so the Wrap can lay it out.
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
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
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
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

  String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatDate(DateTime dtUtc) {
    final dt = dtUtc.toLocal();
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
