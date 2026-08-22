import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/utils/AppColors.dart';
import '../model/project_detail_models.dart';
import '../model/project_model.dart';
import '../provider/project_detail_provider.dart';

/// Everything the detail screen renders now comes straight from
/// `GET /projects/{id}` — every tab writes through the API, so there is no
/// local state to merge in.
typedef _Detail = ProjectDetailBundle;

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final ProjectModel project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Sheet form fields: the controllers live on the State (not inside the bottom
  // sheet) so dismissing the sheet mid-animation can't dispose them too early —
  // the sheet keeps rebuilding until its exit animation ends.
  final _noteController = TextEditingController();
  final _taskTitleController = TextEditingController();
  final _taskDescController = TextEditingController();

  String get _id => widget.project.id;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    _taskTitleController.dispose();
    _taskDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(projectBundleProvider(_id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: switch (async) {
          AsyncError(:final error) => _buildErrorScreen(error),
          AsyncData(:final value) => _buildLoaded(value),
          // A refresh keeps the loaded screen; only the first load blocks.
          _ => async.hasValue
              ? _buildLoaded(async.value!)
              : _buildLoadingScreen(),
        },
      ),
    );
  }

  Widget _buildLoaded(_Detail detail) {
    return Column(
      children: [
        _buildTopBar(detail.project),
        _buildHeroCard(detail),
        const SizedBox(height: 12),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(detail),
              _buildTasksTab(detail),
              _buildFilesTab(detail),
              _buildNotesTab(detail),
              _buildActivityTab(detail),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Column(
      children: [
        _buildTopBar(widget.project),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorScreen(Object error) {
    final message =
        error is ApiException ? error.message : 'Could not load this project.';
    return Column(
      children: [
        _buildTopBar(widget.project),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      size: 44, color: AppColors.red),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 13.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: () => ref.invalidate(projectBundleProvider(_id)),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text('Retry',
                        style: GoogleFonts.poppins(fontSize: 13.5)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────────
  Widget _buildTopBar(ProjectModel project) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 17, color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            child: Text(
              'Project Details',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _chip(project.status.label, project.status.color),
        ],
      ),
    );
  }

  // ── Hero card ────────────────────────────────────────────────────────────────
  Widget _buildHeroCard(_Detail detail) {
    final project = detail.project;
    final accent = project.status.color;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: accent, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(
                project.displayInitials,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.business_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        project.customer.isEmpty ? '—' : project.customer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _progressBar(detail.progress),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Progress bar shared by the hero card and the Overview tab. The percentage
  /// is the server's own `project_progress_percentage`, not a local count.
  Widget _progressBar(ProjectProgress progress) {
    final percent = progress.percentage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Progress',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '$percent%',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.fraction,
            minHeight: 6,
            backgroundColor: AppColors.divider,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  // ── Tab bar ──────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    const tabs = ['Overview', 'Tasks', 'Files', 'Notes', 'Activity'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicator: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle:
            GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400),
        padding: const EdgeInsets.all(3),
        tabs: [for (final t in tabs) Tab(text: t, height: 34)],
      ),
    );
  }

  // ── Overview tab ─────────────────────────────────────────────────────────────
  Widget _buildOverviewTab(_Detail detail) {
    final project = detail.project;
    final progress = detail.progress;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(projectBundleProvider(_id)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Stat tiles: progress / completed tasks / total rate
          Row(
            children: [
              Expanded(
                child: _statTile(
                  label: 'Progress',
                  value: '${progress.percentage}%',
                  icon: Icons.donut_large_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  label: 'Completed Tasks',
                  value: '${progress.completedTasks}/${progress.totalTasks}',
                  icon: Icons.task_alt_rounded,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  label: 'Total Rate',
                  value: _money(project.totalRate),
                  icon: Icons.payments_outlined,
                  color: const Color(0xFFF5A623),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _card(
            icon: Icons.info_outline_rounded,
            title: 'Project Details',
            child: Column(
              children: [
                _infoRow('Project ID', project.id),
                _infoRow('Customer', project.customer),
                _infoRow('Billing Type', project.billingType.label),
                _infoRow('Total Rate', _money(project.totalRate)),
                _infoRow('Status', project.status.label,
                    valueColor: project.status.color),
                _infoRow('Date Created', _fmtDate(project.createdAt)),
                _infoRow('Start Date', _fmtDate(project.startDate)),
                _infoRow(
                  'Deadline',
                  _fmtDate(project.deadline),
                  valueColor: project.isOverdue ? AppColors.red : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            icon: Icons.donut_large_rounded,
            title: 'Project Progress',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _progressBar(progress),
                const SizedBox(height: 12),
                Text(
                  progress.totalTasks == 0
                      ? 'No tasks yet — progress is tracked from the Tasks tab.'
                      : '${progress.completedTasks} of ${progress.totalTasks} tasks completed.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            icon: Icons.sell_outlined,
            title: 'Tags',
            child: project.tags.isEmpty
                ? _mutedText('No tags on this project.')
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in project.tags)
                        _chip(t, AppColors.primary),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          _card(
            icon: Icons.description_outlined,
            title: 'Description',
            child: project.description.trim().isEmpty
                ? _mutedText('No description provided for this project.')
                : Text(
                    project.description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Tasks tab ────────────────────────────────────────────────────────────────
  Widget _buildTasksTab(_Detail detail) {
    return Column(
      children: [
        _tabActionBar(
          label: 'Tasks',
          count: detail.tasks.length,
          actionLabel: 'Add Task',
          actionIcon: Icons.add_rounded,
          onAction: () => _showAddTaskSheet(detail.members),
        ),
        Expanded(
          child: detail.tasks.isEmpty
              ? _emptyState(Icons.checklist_rounded,
                  'No tasks yet.', 'Tap Add Task to create the first one.')
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: detail.tasks.length,
                  itemBuilder: (_, i) => _taskCard(detail.tasks[i]),
                ),
        ),
      ],
    );
  }

  Widget _taskCard(ProjectTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tapping the box would cycle the task done / back to open.
              GestureDetector(
                onTap: () => _setTaskState(
                  task.state.isDone ? TaskState.open : TaskState.done,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 1, right: 10),
                  child: Icon(
                    task.state.isDone
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: task.state.isDone
                        ? AppColors.green
                        : AppColors.textLight,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  task.title,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    decoration: task.state.isDone
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: AppColors.textSecondary,
                  ),
                ),
              ),
              _taskMenu(task),
            ],
          ),
          // The task's own description, when it has one.
          if (task.description?.trim().isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 4, right: 8),
              child: Text(
                task.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          const SizedBox(height: 10),
          // Assigned to / Due date
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  task.assignedTo ?? 'Unassigned',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Icon(Icons.event_rounded,
                  size: 13,
                  color:
                      task.isOverdue ? AppColors.red : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                task.dueDate == null ? 'No due date' : _fmtDate(task.dueDate),
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: task.isOverdue ? FontWeight.w600 : FontWeight.w400,
                  color: task.isOverdue ? AppColors.red : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 10),
          // Priority / Status
          Row(
            children: [
              _chip(task.priority.label, task.priority.color),
              const SizedBox(width: 6),
              _chip(task.state.label, task.state.color),
            ],
          ),
        ],
      ),
    );
  }

  /// The task's "Actions": move it between states, or delete it.
  Widget _taskMenu(ProjectTask task) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      icon: const Icon(Icons.more_vert_rounded,
          size: 18, color: AppColors.textSecondary),
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'delete') {
          _deleteTask();
          return;
        }
        _setTaskState(TaskState.values.firstWhere((s) => s.name == value));
      },
      itemBuilder: (_) => [
        for (final s in TaskState.selectable)
          PopupMenuItem<String>(
            value: s.name,
            height: 40,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: s.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(
                  'Mark ${s.label}',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight:
                        task.state == s ? FontWeight.w600 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (task.state == s) ...[
                  const Spacer(),
                  Icon(Icons.check_rounded, size: 15, color: s.color),
                ],
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'delete',
          height: 40,
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded,
                  size: 16, color: AppColors.red),
              const SizedBox(width: 10),
              Text(
                'Delete',
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.red),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Saved tasks are read-only until there is a task update endpoint — changing
  /// one locally would silently disagree with the backend on the next refresh.
  void _setTaskState(TaskState _) =>
      _toast('Changing a task needs the task update endpoint.');

  void _deleteTask() =>
      _toast('Deleting a task needs the task delete endpoint.');

  // ── Files tab ────────────────────────────────────────────────────────────────
  Widget _buildFilesTab(_Detail detail) {
    final uploading = ref.watch(uploadProjectFileProvider);
    return Column(
      children: [
        _tabActionBar(
          label: 'Files',
          count: detail.files.length,
          actionLabel: uploading ? 'Uploading…' : 'Upload File',
          actionIcon: Icons.upload_rounded,
          onAction: uploading ? null : _pickAndUploadFile,
        ),
        // A thin bar while the multipart request is in flight — the upload can
        // take a while on a big file, so the tab shouldn't look idle.
        if (uploading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        Expanded(
          child: detail.files.isEmpty
              ? _emptyState(Icons.folder_open_rounded, 'No files yet.',
                  'Tap Upload File to attach one.')
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: detail.files.length,
                  itemBuilder: (_, i) => _fileCard(detail.files[i]),
                ),
        ),
      ],
    );
  }

  Widget _fileCard(ProjectFile file) {
    return GestureDetector(
      onTap: () => _openFile(file),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 0.8),
        ),
        child: Row(
          children: [
            // Image files get a thumbnail; everything else an extension badge.
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 42,
                height: 42,
                child: _fileThumbnail(file),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${file.readableSize} • ${_timeAgo(file.uploadedAt)}'
                    '${file.uploadedBy == null ? '' : ' • ${file.uploadedBy}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded,
                size: 16, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  /// Origin of the server this device was set up against — stored files live
  /// there, not on the compiled-in fallback host.
  String get _serverOrigin =>
      ref.read(serverConfigProvider)?.origin ?? ApiConstants.baseUrl;

  /// An image renders its stored thumbnail; anything else gets an extension
  /// badge.
  Widget _fileThumbnail(ProjectFile file) {
    final url = file.downloadUrl(_serverOrigin);
    if (!file.isImage || url == null) return _fileBadge(file);
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fileBadge(file),
    );
  }

  Widget _fileBadge(ProjectFile file) {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      alignment: Alignment.center,
      child: Text(
        file.extension.isEmpty ? 'FILE' : file.extension.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  /// Opens a stored file by URL. The browser handles the download and the
  /// PDF/doc viewer, so the app doesn't need a viewer of its own.
  Future<void> _openFile(ProjectFile file) async {
    final url = file.downloadUrl(_serverOrigin);
    if (url == null) return _toast('This file has no location.');
    try {
      final ok = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      if (!ok && mounted) _toast('Could not open ${file.name}');
    } catch (_) {
      if (mounted) _toast('Could not open ${file.name}');
    }
  }

  /// Picks any file and uploads it via `POST /projects/{id}/files`. On success
  /// the project refetches, so the stored file and its activity entry both come
  /// back from the server.
  Future<void> _pickAndUploadFile() async {
    if (ref.read(uploadProjectFileProvider)) return; // upload already running

    final FilePickerResult? picked;
    try {
      // file_picker 11 exposes pickFiles as a static — there is no `.platform`.
      picked = await FilePicker.pickFiles();
    } catch (_) {
      if (mounted) _toast('Could not open the file picker');
      return;
    }
    if (picked == null || !mounted) return;

    final file = picked.files.single;
    final path = file.path;
    if (path == null) {
      _toast('That file has no readable path');
      return;
    }

    final error = await ref.read(uploadProjectFileProvider.notifier).submit(
          _id,
          path: path,
          filename: file.name,
        );
    if (!mounted) return;
    _toast(error ?? 'File uploaded', isError: error != null);
  }

  // ── Notes tab ────────────────────────────────────────────────────────────────
  Widget _buildNotesTab(_Detail detail) {
    return Column(
      children: [
        _tabActionBar(
          label: 'Notes',
          count: detail.notes.length,
          actionLabel: 'Add Note',
          actionIcon: Icons.add_rounded,
          onAction: _showAddNoteSheet,
        ),
        Expanded(
          child: detail.notes.isEmpty
              ? _emptyState(Icons.sticky_note_2_outlined, 'No notes yet.',
                  'Tap Add Note to write the first one.')
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: detail.notes.length,
                  itemBuilder: (_, i) => _noteCard(detail.notes[i]),
                ),
        ),
      ],
    );
  }

  Widget _noteCard(ProjectNote note) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 12, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(
                note.author ?? 'Unknown',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                _timeAgo(note.createdAt),
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Writes a note via `POST /projects/{id}/notes`. The sheet stays open while
  /// the request is in flight and only closes once the server has it, so a
  /// failure never silently loses what was typed.
  Future<void> _showAddNoteSheet() async {
    _noteController.clear();
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        // Scrollable so the content can never overflow the space left once the
        // keyboard is up.
        child: SingleChildScrollView(
          child: Consumer(
            builder: (ctx, ref, _) {
              final saving = ref.watch(addProjectNoteProvider);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sheetGrabber(),
                  _sheetTitle('Add Note'),
                  TextField(
                    controller: _noteController,
                    autofocus: true,
                    enabled: !saving,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.poppins(
                        fontSize: 13.5, color: AppColors.textPrimary),
                    decoration:
                        _inputDecoration('Write a note about this project…'),
                  ),
                  const SizedBox(height: 16),
                  _primaryButton(
                    'Add Note',
                    saving
                        ? null
                        : () async {
                            final error = await ref
                                .read(addProjectNoteProvider.notifier)
                                .submit(_id, _noteController.text);
                            if (!ctx.mounted) return;
                            if (error == null) {
                              Navigator.pop(ctx, true);
                            } else {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(error,
                                      style: GoogleFonts.poppins(
                                          fontSize: 13, color: Colors.white)),
                                  backgroundColor: AppColors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          },
                    busy: saving,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    if (added == true && mounted) _toast('Note added');
  }

  // ── Activity tab ─────────────────────────────────────────────────────────────
  Widget _buildActivityTab(_Detail detail) {
    if (detail.activities.isEmpty) {
      return _emptyState(Icons.history_rounded, 'No activity yet.',
          'Actions on this project will show up here.');
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(projectBundleProvider(_id)),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        itemCount: detail.activities.length,
        itemBuilder: (_, i) => _activityRow(
          detail.activities[i],
          isLast: i == detail.activities.length - 1,
        ),
      ),
    );
  }

  Widget _activityRow(ProjectActivity a, {required bool isLast}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: a.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(a.icon, size: 16, color: a.color),
            ),
            if (!isLast)
              Container(width: 2, height: 38, color: AppColors.divider),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          a.label,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _timeAgo(a.at),
                        style: GoogleFonts.poppins(
                            fontSize: 10.5, color: AppColors.textLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    a.description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  if (a.user != null) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 11, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text(
                          a.user!,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Add Task sheet ───────────────────────────────────────────────────────────
  /// [members] is the project's team, used for the Assigned To dropdown.
  Future<void> _showAddTaskSheet(List<ProjectMember> members) async {
    ref.read(projectTaskDraftProvider.notifier).reset();
    _taskTitleController.clear();
    _taskDescController.clear();

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Consumer(
            builder: (ctx, ref, _) {
              final draft = ref.watch(projectTaskDraftProvider);
              final notifier = ref.read(projectTaskDraftProvider.notifier);

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sheetGrabber(),
                  _sheetTitle('Add Task'),
                  _fieldLabel('Task Title'),
                  TextField(
                    controller: _taskTitleController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.poppins(
                        fontSize: 13.5, color: AppColors.textPrimary),
                    decoration: _inputDecoration('What needs doing?'),
                  ),
                  const SizedBox(height: 14),
                  _fieldLabel('Description'),
                  TextField(
                    controller: _taskDescController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.poppins(
                        fontSize: 13.5, color: AppColors.textPrimary),
                    decoration: _inputDecoration('Add more detail (optional)'),
                  ),
                  const SizedBox(height: 14),
                  _fieldLabel('Assigned To'),
                  // The project's own team, from `members[]` on the detail
                  // response — not a global user list.
                  if (members.isEmpty)
                    Container(
                      height: 46,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.divider, width: 0.8),
                      ),
                      child: Text(
                        'No members on this project',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.textLight),
                      ),
                    )
                  else
                    DropdownButtonFormField<int?>(
                      initialValue: draft.assignedToId,
                      isExpanded: true,
                      style: GoogleFonts.poppins(
                          fontSize: 13.5, color: AppColors.textPrimary),
                      dropdownColor: AppColors.cardBackground,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary),
                      decoration: _inputDecoration('Unassigned'),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Unassigned',
                              style: GoogleFonts.poppins(
                                  fontSize: 13.5, color: AppColors.textLight)),
                        ),
                        for (final m in members)
                          DropdownMenuItem<int?>(
                            value: m.id,
                            child: _memberRow(m),
                          ),
                      ],
                      onChanged: notifier.setAssignedToId,
                    ),
                  const SizedBox(height: 14),
                  _fieldLabel('Due Date'),
                  GestureDetector(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: draft.dueDate ?? now,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 5),
                      );
                      if (picked != null) notifier.setDueDate(picked);
                    },
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppColors.divider, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_rounded,
                              size: 17, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Text(
                            draft.dueDate == null
                                ? 'Select a due date'
                                : _fmtDate(draft.dueDate),
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              color: draft.dueDate == null
                                  ? AppColors.textLight
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _fieldLabel('Priority'),
                  Row(
                    children: [
                      for (final p in TaskPriority.values) ...[
                        _selectableChip(
                          label: p.label,
                          color: p.color,
                          selected: draft.priority == p,
                          onTap: () => notifier.setPriority(p),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  // No Status picker: `POST /projects/{id}/tasks` doesn't take
                  // one, so a new task lands on the backend's default state.
                  const SizedBox(height: 18),
                  _primaryButton(
                    'Add Task',
                    draft.saving
                        ? null
                        : () async {
                            final error = await ref
                                .read(projectTaskDraftProvider.notifier)
                                .submit(
                                  _id,
                                  title: _taskTitleController.text,
                                  description: _taskDescController.text,
                                );
                            if (!ctx.mounted) return;
                            if (error == null) {
                              Navigator.pop(ctx, true);
                            } else {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(error,
                                      style: GoogleFonts.poppins(
                                          fontSize: 13, color: Colors.white)),
                                  backgroundColor: AppColors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          },
                    busy: draft.saving,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    if (added == true && mounted) _toast('Task added');
  }

  // ── Shared pieces ────────────────────────────────────────────────────────────

  /// The row above each list tab: a title with a count, and the tab's one
  /// action (Add Task / Upload File / Add Note).
  Widget _tabActionBar({
    required String label,
    required int count,
    required String actionLabel,
    required IconData actionIcon,
    /// Null disables the action (e.g. while an upload is in flight).
    required VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onAction,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: onAction == null
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(actionIcon, size: 16, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    actionLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A member in the Assigned To dropdown: initial bubble, name, and their
  /// designation as a muted suffix.
  Widget _memberRow(ProjectMember member) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              member.initial,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            member.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
                fontSize: 13.5, color: AppColors.textPrimary),
          ),
        ),
        if (member.designation != null) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '· ${member.designation}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 11.5, color: AppColors.textLight),
            ),
          ),
        ],
      ],
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(height: 9),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
                fontSize: 10.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mutedText(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      );

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _selectableChip({
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.14) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.divider,
            width: selected ? 1.4 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 12.5, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetGrabber() => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _sheetTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      );

  Widget _fieldLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 6),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      );

  InputDecoration _inputDecoration(String hint) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
      filled: true,
      fillColor: AppColors.background,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: border(AppColors.divider, 0.8),
      border: border(AppColors.divider, 0.8),
      focusedBorder: border(AppColors.primary, 1.4),
    );
  }

  /// A full-width primary action. Pass a null [onPressed] to disable it, and
  /// [busy] to swap the label for a spinner while a request is in flight.
  Widget _primaryButton(
    String label,
    VoidCallback? onPressed, {
    bool busy = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: isError ? AppColors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Formatting ───────────────────────────────────────────────────────────────
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _fmtDate(DateTime? d) =>
      d == null ? '—' : '${_months[d.month - 1]} ${d.day}, ${d.year}';

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays >= 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays >= 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays >= 7) return '${diff.inDays ~/ 7}w ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  /// Formats a rate with thousands separators, e.g. `₹1,20,000` → `₹120,000`.
  String _money(double value) {
    if (value <= 0) return '—';
    final whole = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
      buffer.write(whole[i]);
    }
    return '₹$buffer';
  }
}
