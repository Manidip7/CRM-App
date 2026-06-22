import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';
import '../../../routes/app_routes.dart';
import '../model/TaskStatus.dart';
import '../provider/task_provider.dart';


class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key});

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  List<TaskModel> get _tasks => ref.read(taskListProvider).tasks;

  List<TaskModel> get _overdue =>
      _tasks.where((t) => t.status == TaskStatus.overdue).toList();
  List<TaskModel> get _dueToday =>
      _tasks.where((t) => t.status == TaskStatus.dueToday).toList();
  List<TaskModel> get _upcoming =>
      _tasks.where((t) => t.status == TaskStatus.upcoming).toList();
  List<TaskModel> get _completed =>
      _tasks.where((t) => t.status == TaskStatus.completed).toList();

  int get _total => _tasks.length;

  int get _selectedTab => ref.read(taskListProvider).selectedTab;

  void _openCreateTask() async {
    // final result = await Navigator.push<TaskModel>(
    //   context,
    //   MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
    // );
    // if (result != null) {
    //   ref.read(taskListProvider.notifier).addTask(result);
    // }
  }

  void _markComplete(TaskModel task) =>
      ref.read(taskListProvider.notifier).markComplete(task);

  void _deleteTask(TaskModel task) =>
      ref.read(taskListProvider.notifier).deleteTask(task);

  @override
  Widget build(BuildContext context) {
    // Watch so the whole subtree rebuilds when tasks/tab change.
    ref.watch(taskListProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildTabToggle(),
                    const SizedBox(height: 16),
                    _buildTaskListButton(),
                    const SizedBox(height: 16),
                    _buildTaskOverviewCard(),
                    const SizedBox(height: 20),
                    if (_overdue.isNotEmpty) ...[
                      _buildSectionHeader(
                        'ATTENTION NEEDED (OVERDUE)',
                        AppColors.red,
                      ),
                      const SizedBox(height: 10),
                      ..._overdue.map((t) => _buildTaskCard(t)),
                      const SizedBox(height: 20),
                    ],
                    _buildSectionHeader('DUE TODAY', AppColors.primary),
                    const SizedBox(height: 10),
                    if (_dueToday.isEmpty)
                      _buildEmptyState()
                    else
                      ..._dueToday.map((t) => _buildTaskCard(t)),
                    const SizedBox(height: 20),
                    if (_upcoming.isNotEmpty) ...[
                      _buildSectionHeader('UPCOMING', AppColors.green),
                      const SizedBox(height: 10),
                      ..._upcoming.map((t) => _buildTaskCard(t)),
                      const SizedBox(height: 20),
                    ],
                    if (_completed.isNotEmpty) ...[
                      _buildSectionHeader(
                          'COMPLETED', AppColors.textSecondary),
                      const SizedBox(height: 10),
                      ..._completed.map((t) => _buildTaskCard(t)),
                      const SizedBox(height: 20),
                    ],
                    _buildProTipCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateTask,
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
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

  Widget _buildTabToggle() {
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
            isSelected: _selectedTab == 0,
            onTap: () => ref.read(taskListProvider.notifier).selectTab(0),
          ),
          _TabButton(
            label: 'Team View',
            isSelected: _selectedTab == 1,
            onTap: () => ref.read(taskListProvider.notifier).selectTab(1),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskOverviewCard() {
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
                  'Total: $_total',
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
          _buildStackedBar(),
          const SizedBox(height: 16),
          // Legend grid
          Row(
            children: [
              Expanded(
                child: _LegendItem(
                  color: AppColors.red,
                  label: 'Overdue',
                  count: _overdue.length,
                ),
              ),
              Expanded(
                child: _LegendItem(
                  color: AppColors.primary,
                  label: 'Due Today',
                  count: _dueToday.length,
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
                  count: _upcoming.length,
                ),
              ),
              Expanded(
                child: _LegendItem(
                  color: AppColors.textLight,
                  label: 'Completed',
                  count: _completed.length,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStackedBar() {
    final total = _total == 0 ? 1 : _total;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 14,
        child: Row(
          children: [
            if (_overdue.isNotEmpty)
              Flexible(
                flex: _overdue.length * 100 ~/ total,
                child: Container(color: AppColors.red),
              ),
            if (_dueToday.isNotEmpty)
              Flexible(
                flex: _dueToday.length * 100 ~/ total,
                child: Container(color: AppColors.primary),
              ),
            if (_upcoming.isNotEmpty)
              Flexible(
                flex: _upcoming.length * 100 ~/ total,
                child: Container(color: AppColors.green),
              ),
            if (_completed.isNotEmpty)
              Flexible(
                flex: _completed.length * 100 ~/ total,
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

  Widget _buildTaskCard(TaskModel task) {
    final isOverdue = task.status == TaskStatus.overdue;
    final isCompleted = task.status == TaskStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: isOverdue
                ? AppColors.red
                : isCompleted
                    ? AppColors.green
                    : AppColors.primary,
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textSecondary, size: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'complete',
                      child: Row(children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppColors.green, size: 18),
                        const SizedBox(width: 8),
                        Text('Mark Complete',
                            style: GoogleFonts.poppins(fontSize: 13)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        const Icon(Icons.delete_outline,
                            color: AppColors.red, size: 18),
                        const SizedBox(width: 8),
                        Text('Delete',
                            style: GoogleFonts.poppins(fontSize: 13)),
                      ]),
                    ),
                  ],
                  onSelected: (val) {
                    if (val == 'complete') _markComplete(task);
                    if (val == 'delete') _deleteTask(task);
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Next Action: ${task.nextAction}. Remark: ${task.remark}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
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
                  _formatDate(task.dueDate),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isOverdue ? AppColors.red : AppColors.textSecondary,
                  ),
                ),
                if (task.leadName != null) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {},
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
                          Text(
                            'Lead: ${task.leadName}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
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

  String _formatDate(DateTime dt) {
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