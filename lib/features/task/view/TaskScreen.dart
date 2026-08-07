import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/AppColors.dart';
import '../../../routes/app_routes.dart';
import '../model/TaskStatus.dart';
import '../model/agenda_model.dart';
import '../provider/agenda_provider.dart';


class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key});

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  @override
  Widget build(BuildContext context) {
    final view = ref.watch(agendaViewProvider);
    final agendaAsync = ref.watch(agendaProvider(view));
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.refresh(agendaProvider(view).future),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildTabToggle(view),
                      const SizedBox(height: 16),
                      _buildTaskListButton(),
                      const SizedBox(height: 16),
                      agendaAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => _buildError(e, view),
                        data: _buildAgenda,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Agenda content (data state) ───────────────────────────────────────────────
  Widget _buildAgenda(AgendaBundle bundle) {
    final overdue = bundle.overdue;
    final today = bundle.today;
    final upcoming = bundle.upcoming;
    final completed = bundle.completed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTaskOverviewCard(bundle),
        const SizedBox(height: 20),
        if (overdue.isNotEmpty) ...[
          _buildSectionHeader('ATTENTION NEEDED (OVERDUE)', AppColors.red),
          const SizedBox(height: 10),
          ...overdue.map(_buildTaskCard),
          const SizedBox(height: 20),
        ],
        _buildSectionHeader('DUE TODAY', AppColors.primary),
        const SizedBox(height: 10),
        if (today.isEmpty)
          _buildEmptyState()
        else
          ...today.map(_buildTaskCard),
        const SizedBox(height: 20),
        if (upcoming.isNotEmpty) ...[
          _buildSectionHeader('UPCOMING', AppColors.green),
          const SizedBox(height: 10),
          ...upcoming.map(_buildTaskCard),
          const SizedBox(height: 20),
        ],
        if (completed.isNotEmpty) ...[
          _buildSectionHeader('COMPLETED', AppColors.textSecondary),
          const SizedBox(height: 10),
          ...completed.map(_buildTaskCard),
          const SizedBox(height: 20),
        ],
        _buildProTipCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildError(Object error, String view) {
    final message =
        error is ApiException ? error.message : 'Could not load agenda.';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.red, size: 36),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => ref.invalidate(agendaProvider(view)),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Retry', style: GoogleFonts.poppins(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: AppColors.background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Agenda",
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Focus on what matters most. Here's your task breakdown for today.",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(Icons.search,
                color: AppColors.textPrimary, size: 20),
          ),
        ],
      ),
    );
  }

  /// Full-width button that opens the searchable / filterable Task List.
  Widget _buildTaskListButton() {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.taskList),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.format_list_bulleted_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Task List',
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabToggle(String view) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabButton(
            label: 'My Tasks',
            isSelected: view == 'my',
            onTap: () => ref.read(agendaViewProvider.notifier).set('my'),
          ),
          _TabButton(
            label: 'Team View',
            isSelected: view == 'team',
            onTap: () => ref.read(agendaViewProvider.notifier).set('team'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskOverviewCard(AgendaBundle bundle) {
    final counts = bundle.counts;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Task Overview',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total: ${counts.total}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Stacked progress bar
          _buildStackedBar(counts),
          const SizedBox(height: 16),
          // Legend grid
          Row(
            children: [
              Expanded(
                child: _LegendItem(
                  color: AppColors.red,
                  label: 'Overdue',
                  count: counts.overdue,
                ),
              ),
              Expanded(
                child: _LegendItem(
                  color: AppColors.primary,
                  label: 'Due Today',
                  count: counts.today,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LegendItem(
                  color: AppColors.green,
                  label: 'Upcoming',
                  count: counts.upcoming,
                ),
              ),
              Expanded(
                child: _LegendItem(
                  color: AppColors.textLight,
                  label: 'Completed',
                  count: counts.completed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStackedBar(AgendaCounts counts) {
    final total = counts.total == 0 ? 1 : counts.total;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 14,
        child: Row(
          children: [
            if (counts.overdue > 0)
              Flexible(
                flex: counts.overdue * 100 ~/ total,
                child: Container(color: AppColors.red),
              ),
            if (counts.today > 0)
              Flexible(
                flex: counts.today * 100 ~/ total,
                child: Container(color: AppColors.primary),
              ),
            if (counts.upcoming > 0)
              Flexible(
                flex: counts.upcoming * 100 ~/ total,
                child: Container(color: AppColors.green),
              ),
            if (counts.completed > 0)
              Flexible(
                flex: counts.completed * 100 ~/ total,
                child: Container(color: AppColors.textLight),
              ),
            // Fill remainder
            Flexible(
              flex: 1,
              child: Container(color: AppColors.textLight.withOpacity(0.3)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color dotColor) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(AgendaTask task) {
    final isOverdue = task.group == TaskStatus.overdue;
    final isCompleted = task.group == TaskStatus.completed;
    final deleting = ref.watch(deleteTaskProvider) == task.id;
    final markingDone = ref.watch(markTaskDoneProvider) == task.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: task.group.color,
            width: 3.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
                if (task.priority != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _priorityColor(task.priority!).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.priority!.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _priorityColor(task.priority!),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: isOverdue ? AppColors.red : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  task.dueAt != null ? _formatDate(task.dueAt!) : 'No due date',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isOverdue ? AppColors.red : AppColors.textSecondary,
                  ),
                ),
                if (task.taskableTitle != null &&
                    task.taskableTitle!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.open_in_new,
                              size: 11, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${task.linkedLabel}: ${task.taskableTitle}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (task.assigneeName != null &&
                task.assigneeName!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 12, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(
                    task.assigneeName!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Already-completed tasks have nothing left to mark.
                if (!isCompleted) ...[
                  if (markingDone)
                    const Padding(
                      padding: EdgeInsets.all(7),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.green),
                      ),
                    )
                  else
                    _TaskActionIcon(
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.green,
                      tooltip: 'Mark as done',
                      onTap: () => _markTaskDone(task),
                    ),
                  const SizedBox(width: 4),
                ],
                if (deleting)
                  const Padding(
                    padding: EdgeInsets.all(7),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.red),
                    ),
                  )
                else
                  _TaskActionIcon(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.red,
                    tooltip: 'Delete task',
                    onTap: () => _deleteTask(task),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Marks the task complete via `PUT /tasks/{id}/mark-done`. The provider
  /// refreshes both agenda views, so the card moves to Completed on success.
  Future<void> _markTaskDone(AgendaTask task) async {
    final error =
        await ref.read(markTaskDoneProvider.notifier).markDone(task.id);
    if (!mounted) return;
    _showSnack(error ?? 'Marked "${task.title}" as done',
        isError: error != null);
  }

  /// Confirms, then deletes the task via `DELETE /tasks/{id}`. The provider
  /// refreshes both agenda views, so the card disappears on success.
  Future<void> _deleteTask(AgendaTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete task?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${task.title}"?',
          style: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await ref.read(deleteTaskProvider.notifier).delete(task.id);
    if (!mounted) return;
    _showSnack(error ?? 'Deleted "${task.title}"', isError: error != null);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: isError ? AppColors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.divider,
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_busy_rounded,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            'No tasks scheduled for today.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProTipCard() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C4A52), Color(0xFF3A6B7A)],
        ),
      ),
      child: Stack(
        children: [
          // Background calendar illustration
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              child: Container(
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 35,
                  itemBuilder: (_, i) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                          i % 7 == 0 || i % 7 == 6 ? 0.04 : 0.08),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Text content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PRO TIP',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Batch similar tasks to save mental energy.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.red;
      case 'medium':
        return AppColors.primary;
      case 'low':
        return AppColors.green;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime dtUtc) {
    final dt = dtUtc.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $hour:$min $ampm';
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendItem(
      {required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Small circular icon button used for per-task actions on the agenda cards.
class _TaskActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _TaskActionIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
