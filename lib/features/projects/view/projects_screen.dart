import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/AppColors.dart';
import '../../../routes/app_routes.dart';
import '../../dashbord/provider/dashboard_provider.dart';
import '../model/project_model.dart';
import '../provider/projects_provider.dart';

/// Projects section: a summary row (Total Projects, Pending Tasks, Uncompleted
/// Projects), a search field, and the full list of project cards. Each card
/// shows name, customer, status, members and deadline.
class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    // Search runs server-side, so wait for a pause in typing before refetching.
    _searchController.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 450), () {
        ref.read(projectFilterProvider.notifier).setSearch(_searchController.text);
      });
    });
    // Infinite scroll: load the next page as we approach the bottom.
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      ref.read(projectsProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final summary = ref.watch(projectSummaryProvider);

    // Back button returns to the Dashboard overview tab.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        ref.read(dashboardNavProvider.notifier).select(0);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(summary.totalProjects),
              _buildSummaryRow(summary),
              _buildSearchRow(),
              _buildStatusFilterRow(),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      ref.read(projectsProvider.notifier).refresh(),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    slivers: _buildSlivers(projects),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.createProject),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'New Project',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  /// The scrolling body: a spinner on first load, an error state with Retry if
  /// the fetch failed, otherwise the cards plus a trailing "loading more"
  /// spinner while the next page is in flight.
  List<Widget> _buildSlivers(AsyncValue<List<ProjectModel>> projects) {
    return switch (projects) {
      AsyncError(:final error) => [
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildErrorState(error),
          ),
        ],
      // A refetch (filter change) keeps the old list on screen; only show the
      // full-screen spinner when there is nothing to show yet.
      AsyncLoading() when !projects.hasValue => const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        ],
      _ => _buildListSlivers(projects.value ?? const []),
    };
  }

  List<Widget> _buildListSlivers(List<ProjectModel> list) {
    if (list.isEmpty) {
      return [
        SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState()),
      ];
    }
    final loadingMore =
        ref.watch(projectsPaginationProvider.select((p) => p.isLoadingMore));
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        sliver: SliverList.builder(
          itemCount: list.length,
          itemBuilder: (ctx, i) => _buildCard(list[i]),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          child: loadingMore
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    ];
  }

  Widget _buildErrorState(Object error) {
    final message = error is ApiException
        ? error.message
        : 'Could not load projects.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () => ref.read(projectsProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Retry', style: GoogleFonts.poppins(fontSize: 13.5)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Status filter ──
  /// Chips driving the `status` query param. Tapping the active chip clears it.
  Widget _buildStatusFilterRow() {
    final selected = ref.watch(projectFilterProvider.select((f) => f.status));
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        physics: const BouncingScrollPhysics(),
        children: [
          for (final s in ProjectStatus.values) ...[
            _statusChip(s, selected == s),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(ProjectStatus status, bool active) {
    return GestureDetector(
      onTap: () => ref.read(projectFilterProvider.notifier).toggleStatus(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? status.color.withOpacity(0.14)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? status.color : AppColors.divider,
            width: active ? 1.4 : 0.8,
          ),
        ),
        child: Text(
          status.label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? status.color : AppColors.textSecondary,
          ),
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
            onTap: () => ref.read(dashboardNavProvider.notifier).select(0),
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
                      'Projects',
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
                  'Track and manage your projects',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary row ──
  Widget _buildSummaryRow(ProjectSummary s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _summaryTile(
              label: 'Total Projects',
              value: '${s.totalProjects}',
              icon: Icons.folder_open_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryTile(
              label: 'Pending Tasks',
              value: '${s.totalPendingTasks}',
              icon: Icons.pending_actions_rounded,
              color: const Color(0xFFF5A623),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryTile(
              label: 'Uncompleted',
              value: '${s.uncompletedProjects}',
              icon: Icons.hourglass_bottom_rounded,
              color: AppColors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
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
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
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
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ──
  Widget _buildSearchRow() {
    final hasQuery =
        ref.watch(projectFilterProvider.select((f) => f.search.isNotEmpty));
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
          // No onChanged — the controller listener debounces before refetching.
          controller: _searchController,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search project, customer, member...',
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
                      ref.read(projectFilterProvider.notifier).clearSearch();
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

  // ── Project card ──
  Widget _buildCard(ProjectModel p) {
    final accent = p.status.color;
    return GestureDetector(
      onTap: () => _openDetail(p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: avatar + name / customer + status badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: Text(
                        p.displayInitials,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
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
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.business_outlined,
                                size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                p.customer,
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
                      ],
                    ),
                  ),
                  _buildTag(p.status.label, accent),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: AppColors.divider, height: 1),
              ),

              // Members + deadline row
              Row(
                children: [
                  _buildMembers(p.members),
                  const Spacer(),
                  Icon(Icons.event_rounded,
                      size: 14,
                      color:
                          p.isOverdue ? AppColors.red : AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    _shortDate(p.deadline),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight:
                          p.isOverdue ? FontWeight.w600 : FontWeight.w400,
                      color:
                          p.isOverdue ? AppColors.red : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action row: view / edit / delete
              Row(
                children: [
                  _actionIcon(
                    icon: Icons.visibility_outlined,
                    color: AppColors.primary,
                    tooltip: 'View',
                    onTap: () => _openDetail(p),
                  ),
                  const SizedBox(width: 6),
                  _actionIcon(
                    icon: Icons.edit_outlined,
                    color: AppColors.accent,
                    tooltip: 'Edit',
                    onTap: () => _onEdit(p),
                  ),
                  const Spacer(),
                  _actionIcon(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.red,
                    tooltip: 'Delete',
                    onTap: () => _onDelete(p),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  /// Overlapping avatar stack for the project members, with a "+N" chip when
  /// there are more members than fit.
  Widget _buildMembers(List<String> members) {
    const maxVisible = 3;
    final visible = members.take(maxVisible).toList();
    final extra = members.length - visible.length;
    const size = 26.0;
    const overlap = 8.0;

    final avatars = <Widget>[];
    for (var i = 0; i < visible.length; i++) {
      avatars.add(Positioned(
        left: i * (size - overlap),
        child: _memberAvatar(visible[i], size),
      ));
    }
    if (extra > 0) {
      avatars.add(Positioned(
        left: visible.length * (size - overlap),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cardBackground, width: 1.5),
          ),
          child: Center(
            child: Text(
              '+$extra',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ));
    }

    final count = visible.length + (extra > 0 ? 1 : 0);
    final width = count == 0 ? 0.0 : size + (count - 1) * (size - overlap);

    return SizedBox(
      height: size,
      width: width,
      child: Stack(clipBehavior: Clip.none, children: avatars),
    );
  }

  Widget _memberAvatar(String name, double size) {
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cardBackground, width: 1.5),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_off_outlined,
              size: 48, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(
            'No projects found',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Actions
  // ─────────────────────────────────────────────

  /// Opens the full project detail screen (Overview / Tasks / Files / Notes /
  /// Activity), replacing the old summary bottom sheet.
  void _openDetail(ProjectModel p) =>
      context.push(AppRoutes.projectDetail, extra: p);
  void _onEdit(ProjectModel p) => context.push(AppRoutes.createProject);

  Future<void> _onDelete(ProjectModel p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete project?',
            style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Text(
          '${p.name} — ${p.customer} will be permanently removed.',
          style: GoogleFonts.poppins(
              fontSize: 13.5, color: AppColors.textSecondary),
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
    if (confirmed != true) return;

    final error = await ref.read(projectsProvider.notifier).deleteProject(p.id);
    if (!mounted) return;
    _toast(error ?? '${p.name} deleted', isError: error != null);
  }

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontSize: 13, color: Colors.white)),
        backgroundColor: isError ? AppColors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _shortDate(DateTime? d) {
    if (d == null) return 'No deadline';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
