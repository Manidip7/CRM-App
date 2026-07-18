import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/AppColors.dart';
import '../../../routes/app_routes.dart';
import '../model/opportunity_model.dart';
import '../provider/opportunities_provider.dart';

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────

class OpportunitiesScreen extends ConsumerStatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  ConsumerState<OpportunitiesScreen> createState() =>
      _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends ConsumerState<OpportunitiesScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Loads the next page when scrolled near the bottom.
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(opportunitiesProvider.notifier).loadMore();
    }
  }

  int _countByStage(OpportunityStage s) =>
      ref.read(opportunitiesProvider.notifier).countByStage(s);

  // Accent color — red theme when viewing the backlog.
  Color get _accent =>
      ref.watch(opportunitiesProvider.select((s) => s.showBacklog))
          ? AppColors.red
          : AppColors.green;

  // Total count: API total for the live pipeline, list length for the backlog.
  int get _activeTotal => ref.watch(opportunitiesProvider
      .select((s) => s.showBacklog ? s.backlogItems.length : s.total));

  // ── Formatting ──
  /// The full deal amount with Indian digit grouping, e.g. 54545 → "₹54,545"
  /// and 1234567.5 → "₹12,34,567.50". Paise are shown only when non-zero.
  String _formatValue(double v) {
    final isWhole = v == v.roundToDouble();
    final str = isWhole ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    final dot = str.indexOf('.');
    var intPart = dot == -1 ? str : str.substring(0, dot);
    final fraction = dot == -1 ? '' : str.substring(dot); // includes the '.'

    final neg = intPart.startsWith('-');
    if (neg) intPart = intPart.substring(1);

    String grouped;
    if (intPart.length <= 3) {
      grouped = intPart;
    } else {
      final last3 = intPart.substring(intPart.length - 3);
      final rest = intPart.substring(0, intPart.length - 3);
      final buf = StringBuffer();
      for (var i = 0; i < rest.length; i++) {
        buf.write(rest[i]);
        final fromRight = rest.length - i;
        if (fromRight > 1 && (fromRight - 1) % 2 == 0) buf.write(',');
      }
      grouped = '$buf,$last3';
    }
    return '${neg ? '-' : ''}₹$grouped$fraction';
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(filteredOpportunitiesProvider);
    final oppState = ref.watch(opportunitiesProvider);
    final showBacklog = oppState.showBacklog;
    // First-load and error states — both lists are API-backed.
    final firstLoading = showBacklog
        ? oppState.backlogLoading && oppState.backlogItems.isEmpty
        : oppState.isLoading && oppState.items.isEmpty;
    final loadError = showBacklog
        ? oppState.backlogError != null && oppState.backlogItems.isEmpty
        : oppState.error != null && oppState.items.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: RefreshIndicator(
                    color: _accent,
                    onRefresh: () =>
                        ref.read(opportunitiesProvider.notifier).refresh(),
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      slivers: [
                        SliverToBoxAdapter(child: _buildStatCards()),
                        SliverToBoxAdapter(child: _buildSearchBar()),
                        SliverToBoxAdapter(child: _buildFilterTabs()),
                        SliverToBoxAdapter(child: _buildListHeader()),
                        if (firstLoading)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child:
                                  CircularProgressIndicator(color: _accent),
                            ),
                          )
                        else if (loadError)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildErrorState(),
                          )
                        else if (list.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(),
                          )
                        else
                          SliverPadding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) {
                                  if (i == list.length) {
                                    return _buildLoadMoreIndicator(oppState);
                                  }
                                  return _buildCard(list[i]);
                                },
                                childCount: list.length + 1,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  /// Footer under the list: a spinner while the next page loads, else nothing.
  Widget _buildLoadMoreIndicator(OpportunitiesState s) {
    if (s.isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.4, color: _accent),
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 46, color: AppColors.red),
          const SizedBox(height: 12),
          const Text(
            'Could not load opportunities',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () =>
                ref.read(opportunitiesProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    final showBacklog =
        ref.watch(opportunitiesProvider.select((s) => s.showBacklog));
    final total = _activeTotal;
    final accent = _accent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        showBacklog ? 'Backlog' : 'Opportunities',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$total',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  showBacklog
                      ? 'Overdue deals needing attention'
                      : 'Track and grow your pipeline',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildBacklogButton(showBacklog),
        ],
      ),
    );
  }

  Widget _buildBacklogButton(bool active) {
    return GestureDetector(
      onTap: () {
        _searchController.clear();
        ref.read(opportunitiesProvider.notifier).toggleBacklog();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.red : AppColors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.red, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.work_outline_rounded : Icons.history_rounded,
              size: 16,
              color: active ? Colors.white : AppColors.red,
            ),
            const SizedBox(width: 5),
            Text(
              active ? 'Pipeline' : 'Backlog',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  STAT CARDS
  // ─────────────────────────────────────────────
  Widget _buildStatCards() {
    final total = _activeTotal;
    final showBacklog =
        ref.watch(opportunitiesProvider.select((s) => s.showBacklog));
    // In the backlog every stat reads red; in the pipeline each keeps its own.
    final stats = [
      _StatCard(value: '$total', label: 'Total', color: _accent),
      _StatCard(
          value: '${_countByStage(OpportunityStage.proposal)}',
          label: 'Proposal',
          color: showBacklog ? AppColors.red : AppColors.greenLight),
      _StatCard(
          value: '${_countByStage(OpportunityStage.negotiation)}',
          label: 'Negotiation',
          color: showBacklog ? AppColors.red : const Color(0xFF4CAF9A)),
      _StatCard(
          value: '${_countByStage(OpportunityStage.won)}',
          label: 'Won',
          color: showBacklog ? AppColors.red : AppColors.leadFunnelWon),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: stats
            .map((s) => Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  s.value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: s.color,
                  ),
                ),
                Text(
                  s.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ))
            .toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  SEARCH BAR
  // ─────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) =>
              ref.read(opportunitiesProvider.notifier).setSearch(v),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Search title, name, phone, email...',
            hintStyle:
            TextStyle(color: AppColors.textLight, fontSize: 13.5),
            prefixIcon: Icon(Icons.search_rounded,
                color: AppColors.textLight, size: 20),
            border: InputBorder.none,
            contentPadding:
            EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  FILTER TABS
  // ─────────────────────────────────────────────
  Widget _buildFilterTabs() {
    final selectedStage =
        ref.watch(opportunitiesProvider.select((s) => s.selectedStage));
    final showBacklog =
        ref.watch(opportunitiesProvider.select((s) => s.showBacklog));
    final stages = [null, ...OpportunityStage.values];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          // Filter icon
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.tune_rounded,
                size: 18, color: AppColors.textSecondary),
          ),
          ...stages.map((stage) {
            final isSelected = selectedStage == stage;
            final label = stage == null ? 'All' : stage.label;
            // In the backlog all chips read red, matching the screen accent.
            final activeColor = showBacklog
                ? AppColors.red
                : (stage == null ? AppColors.green : stage.color);
            return GestureDetector(
              onTap: () =>
                  ref.read(opportunitiesProvider.notifier).setStage(stage),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withOpacity(0.12)
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? activeColor : AppColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color:
                        isSelected ? activeColor : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  LIST HEADER
  // ─────────────────────────────────────────────
  Widget _buildListHeader() {
    final list = ref.watch(filteredOpportunitiesProvider);
    final sortLabel =
        ref.watch(opportunitiesProvider.select((s) => s.sortLabel));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${list.length} opportunit${list.length == 1 ? 'y' : 'ies'}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Row(
              children: [
                const Icon(Icons.swap_vert_rounded,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  sortLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  LIST
  // ─────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline_rounded,
              size: 48, color: AppColors.textLight),
          const SizedBox(height: 12),
          const Text(
            'No opportunities found',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  OPPORTUNITY CARD
  // ─────────────────────────────────────────────
  Widget _buildCard(OpportunityModel opp) {
    // In the backlog, paint cards red so the screen reads as "overdue",
    // not the green pipeline accent.
    final showBacklog =
        ref.watch(opportunitiesProvider.select((s) => s.showBacklog));
    final cardAccent = showBacklog ? AppColors.red : opp.stage.color;
    final avatarColor = showBacklog ? AppColors.red : opp.avatarColor;
    return GestureDetector(
      onTap: () => _openDetail(opp),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(color: cardAccent, width: 3.5),
        ),
        boxShadow: [
          BoxShadow(
            color: cardAccent.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: avatarColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Text(
                      opp.avatarInitials,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: avatarColor,
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
                        opp.title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              opp.contactName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: AppColors.textLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatValue(opp.value),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: _accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      opp.timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(Icons.more_vert_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Tags row ──
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTag(opp.stage.label, opp.stage.color,
                            opp.stage.bgColor, null),
                        const SizedBox(width: 8),
                        _buildProbTag(opp.probability),
                        const SizedBox(width: 8),
                        _buildTag(opp.source.label, opp.source.color,
                            opp.source.color.withOpacity(0.1), opp.source.icon),
                      ],
                    ),
                  ),
                ),
                // Assignee initials (overlapping circles for multiple).
                if (opp.assigneeNames.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _assigneeStack(opp.assigneeNames),
                ],
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: AppColors.divider, height: 1),
            ),

            // ── Bottom row ──
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 5),
                Text(
                  'Next: ${opp.nextFollowUp}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.phone_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 5),
                Text(
                  opp.phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _openDetail(OpportunityModel opp) {
    context.push(AppRoutes.opportunityDetail, extra: opp);
  }

  Widget _buildTag(
      String label, Color textColor, Color bgColor, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProbTag(int prob) {
    final color = prob >= 70
        ? AppColors.green
        : prob >= 50
        ? AppColors.greenLight
        : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$prob% PROB',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  ASSIGNEE AVATARS (matches the Leads screen)
  // ─────────────────────────────────────────────

  /// Two-letter initials from an employee name (e.g. "John Doe" → "JD"). Falls
  /// back to a single letter for one-word names, or "?" when empty.
  String _assigneeInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// A single circular initials avatar for an assignee.
  Widget _assigneeCircle(String name) {
    final accent = _accent;
    return Tooltip(
      message: name,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cardBackground, width: 1.5),
        ),
        child: Text(
          _assigneeInitials(name),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ),
    );
  }

  /// An overlapping stack of assignee initials circles — each circle layered on
  /// top of the previous (shows up to 3, then a "+N" bubble for the rest).
  /// Empty when the opportunity has no assignees.
  Widget _assigneeStack(List<String> names) {
    if (names.isEmpty) return const SizedBox.shrink();
    const maxVisible = 3;
    final visible = names.take(maxVisible).toList();
    final extra = names.length - visible.length;
    const circle = 26.0;
    // Each circle is shifted left so it overlaps the previous one by this much.
    const step = 16.0;

    // Build the bubbles back-to-front so earlier circles sit on top.
    final children = <Widget>[];
    final count = visible.length + (extra > 0 ? 1 : 0);
    for (var i = count - 1; i >= 0; i--) {
      final isExtra = extra > 0 && i == visible.length;
      children.add(Positioned(
        left: i * step,
        child: isExtra
            ? Container(
                width: circle,
                height: circle,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.cardBackground, width: 1.5),
                ),
                child: Text(
                  '+$extra',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            : _assigneeCircle(visible[i]),
      ));
    }

    final width = (count - 1) * step + circle;
    return SizedBox(
      width: width,
      height: circle,
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }

  // ─────────────────────────────────────────────
  //  FAB
  // ─────────────────────────────────────────────
  Widget _buildFAB() {
    final accent = _accent;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, accent.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 26),
    );
  }
}

// ─────────────────────────────────────────────
//  HELPER DATA CLASS
// ─────────────────────────────────────────────
class _StatCard {
  final String value;
  final String label;
  final Color color;
  const _StatCard(
      {required this.value, required this.label, required this.color});
}
