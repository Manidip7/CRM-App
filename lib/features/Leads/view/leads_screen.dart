import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/AppColors.dart';
import '../model/lead_model.dart';
import '../provider/leads_provider.dart';
import 'lead_detail_screen.dart';

class LeadsScreen extends ConsumerStatefulWidget {
  const LeadsScreen({super.key});

  @override
  ConsumerState<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends ConsumerState<LeadsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animController;

  // Accent color — red theme when viewing backlog leads
  Color get _accent =>
      ref.watch(leadsFilterProvider.select((s) => s.showBacklog))
          ? AppColors.red
          : AppColors.primary;

  // Avatar colors matching your brand palette
  static const List<Color> _avatarColors = [
    Color(0xFF4B3FC7),
    Color(0xFF2DD4A0),
    Color(0xFFFF4D6A),
    Color(0xFFFFB547),
    Color(0xFF7B72E9),
    Color(0xFF4CAF9A),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _searchController.addListener(
        () => ref.read(leadsFilterProvider.notifier)
            .setSearch(_searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leads = ref.watch(filteredLeadsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildStatsRow()),
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  SliverToBoxAdapter(child: _buildFilterChips()),
                  SliverToBoxAdapter(child: _buildListHeader(leads.length)),
                  if (leads.isEmpty)
                    SliverFillRemaining(child: _buildEmptyState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final lead = leads[i];
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration:
                                  Duration(milliseconds: 300 + i * 60),
                              curve: Curves.easeOut,
                              builder: (_, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: child,
                                ),
                              ),
                              child: _LeadCard(
                                lead: lead,
                                avatarColor:
                                    _avatarColors[lead.avatarColorIndex %
                                        _avatarColors.length],
                                accent: _accent,
                                onTap: () => _openDetail(lead),
                                onMenuAction: (action) =>
                                    _handleAction(action, lead),
                              ),
                            );
                          },
                          childCount: leads.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLead,
        backgroundColor: _accent,
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildHeader() {
    final showBacklog =
        ref.watch(leadsFilterProvider.select((s) => s.showBacklog));
    final totalLeads = ref.watch(leadsSourceProvider).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: AppColors.background,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    showBacklog ? 'Backlog Leads' : 'Leads',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalLeads',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                showBacklog
                    ? 'Overdue leads needing follow-up'
                    : 'Track and manage your pipeline',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildBacklogButton(showBacklog),
        ],
      ),
    );
  }

  Widget _buildBacklogButton(bool active) {
    return GestureDetector(
      onTap: () {
        // Toggle resets search/filters in the provider; clear the controller too.
        _searchController.clear();
        ref.read(leadsFilterProvider.notifier).toggleBacklog();
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
              active ? Icons.list_alt_rounded : Icons.history_rounded,
              size: 16,
              color: active ? Colors.white : AppColors.red,
            ),
            const SizedBox(width: 5),
            Text(
              active ? 'Leads' : 'Backlog',
              style: GoogleFonts.poppins(
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

  Widget _buildStatsRow() {
    final source = ref.watch(leadsSourceProvider);
    final total = source.length;
    final newCount =
        source.where((l) => l.status == LeadStatus.newLead).length;
    final qualifiedCount =
        source.where((l) => l.status == LeadStatus.qualified).length;
    final wonCount = source.where((l) => l.status == LeadStatus.won).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          _MiniStat(label: 'Total', value: '$total', color: _accent),
          const SizedBox(width: 8),
          _MiniStat(label: 'New', value: '$newCount', color: AppColors.leadFunnelNew),
          const SizedBox(width: 8),
          _MiniStat(label: 'Qualified', value: '$qualifiedCount', color: AppColors.green),
          const SizedBox(width: 8),
          _MiniStat(label: 'Won', value: '$wonCount', color: Color(0xFFFFB547)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 14),
              child: Icon(Icons.search_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search name, ID, phone, email...',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textLight),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (ref.watch(
                leadsFilterProvider.select((s) => s.searchQuery)).isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  ref.read(leadsFilterProvider.notifier).clearSearch();
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.close_rounded,
                      color: AppColors.textSecondary, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filter = ref.watch(leadsFilterProvider);
    final notifier = ref.read(leadsFilterProvider.notifier);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
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
                color: AppColors.textSecondary, size: 18),
          ),
          _FilterChip(
            label: 'All',
            isSelected:
                filter.filterStatus == null && filter.filterSource == null,
            onTap: () => notifier.clearFilters(),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'New',
            isSelected: filter.filterStatus == LeadStatus.newLead,
            color: AppColors.leadFunnelNew,
            onTap: () => notifier.toggleStatus(LeadStatus.newLead),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Contacted',
            isSelected: filter.filterStatus == LeadStatus.contacted,
            color: AppColors.leadFunnelContacted,
            onTap: () => notifier.toggleStatus(LeadStatus.contacted),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Qualified',
            isSelected: filter.filterStatus == LeadStatus.qualified,
            color: AppColors.green,
            onTap: () => notifier.toggleStatus(LeadStatus.qualified),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Won',
            isSelected: filter.filterStatus == LeadStatus.won,
            color: const Color(0xFFFFB547),
            onTap: () => notifier.toggleStatus(LeadStatus.won),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Facebook',
            isSelected: filter.filterSource == LeadSource.facebook,
            color: const Color(0xFF1877F2),
            onTap: () => notifier.toggleSource(LeadSource.facebook),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Referral',
            isSelected: filter.filterSource == LeadSource.referral,
            color: AppColors.leadFunnelQualified,
            onTap: () => notifier.toggleSource(LeadSource.referral),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Text(
            '$count lead${count != 1 ? 's' : ''}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          const Icon(Icons.swap_vert_rounded,
              color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 4),
          Text(
            'Newest first',
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_search_rounded,
                color: AppColors.primary, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            'No leads found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your search or filters',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _openDetail(LeadModel lead) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LeadDetailScreen(lead: lead)),
    );
  }

  void _handleAction(String action, LeadModel lead) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action: ${lead.contactName}'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _addLead() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Add Lead coming soon'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─── Lead Card ────────────────────────────────────────────────────────────────

class _LeadCard extends StatelessWidget {
  final LeadModel lead;
  final Color avatarColor;
  final Color accent;
  final VoidCallback onTap;
  final ValueChanged<String> onMenuAction;

  const _LeadCard({
    required this.lead,
    required this.avatarColor,
    required this.accent,
    required this.onTap,
    required this.onMenuAction,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left status accent strip
                Container(width: 4, color: _statusColor(lead.status)),
                Expanded(
                  child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: avatarColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        lead.displayInitials,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                lead.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _timeAgo(lead.createdAt),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 12,
                                color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Text(
                              lead.contactName,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (lead.dealValue != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: AppColors.textLight,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.currency_rupee,
                                  size: 11,
                                  color: AppColors.green),
                              Text(
                                _formatValue(lead.dealValue!),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        color: AppColors.textSecondary, size: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.zero,
                    itemBuilder: (_) => [
                      _menuItem(Icons.phone_outlined, 'Call', AppColors.green),
                      _menuItem(Icons.mail_outline_rounded, 'Email',
                          AppColors.primary),
                      _menuItem(Icons.task_alt_rounded, 'Add Task',
                          AppColors.leadFunnelContacted),
                      _menuItem(Icons.delete_outline_rounded, 'Delete',
                          AppColors.red),
                    ],
                    onSelected: onMenuAction,
                  ),
                ],
              ),
            ),
            // Tags row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                children: [
                  _StatusBadge(status: lead.status),
                  const SizedBox(width: 6),
                  _SourceBadge(source: lead.source),
                  const Spacer(),
                ],
              ),
            ),
            // Divider
            Container(
              height: 0.8,
              color: AppColors.divider,
            ),
            // Next follow-up footer
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 13, color: accent),
                  const SizedBox(width: 5),
                  Text(
                    'Next: ${_formatDate(lead.nextFollowUp)}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (lead.phone != null) ...[
                    const Icon(Icons.phone_outlined,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      lead.phone!,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(LeadStatus s) {
    switch (s) {
      case LeadStatus.newLead:
        return AppColors.leadFunnelNew;
      case LeadStatus.contacted:
        return AppColors.leadFunnelContacted;
      case LeadStatus.qualified:
        return AppColors.green;
      case LeadStatus.won:
        return const Color(0xFFFFB547);
      case LeadStatus.lost:
        return AppColors.red;
    }
  }

  PopupMenuItem<String> _menuItem(
      IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: label,
      height: 40,
      child: Row(children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 10),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textPrimary)),
      ]),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7) return '${diff.inDays ~/ 7}w';
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    return 'now';
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $h:$min $ampm';
  }

  String _formatValue(double val) {
    if (val >= 100000) return '${(val / 100000).toStringAsFixed(1)}L';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(0)}k';
    return val.toStringAsFixed(0);
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final LeadStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final cfg = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: cfg.$1.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cfg.$1.withOpacity(0.25), width: 0.8),
      ),
      child: Text(
        cfg.$2,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cfg.$1,
        ),
      ),
    );
  }

  (Color, String) _statusConfig(LeadStatus s) {
    switch (s) {
      case LeadStatus.newLead:
        return (AppColors.leadFunnelNew, 'NEW');
      case LeadStatus.contacted:
        return (AppColors.leadFunnelContacted, 'CONTACTED');
      case LeadStatus.qualified:
        return (AppColors.green, 'QUALIFIED');
      case LeadStatus.won:
        return (const Color(0xFFFFB547), 'WON');
      case LeadStatus.lost:
        return (AppColors.red, 'LOST');
    }
  }
}

// ─── Source Badge ─────────────────────────────────────────────────────────────

class _SourceBadge extends StatelessWidget {
  final LeadSource source;
  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final cfg = _sourceConfig(source);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: cfg.$1.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cfg.$1.withOpacity(0.2), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.$3, size: 11, color: cfg.$1),
          const SizedBox(width: 4),
          Text(
            cfg.$2,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cfg.$1,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String, IconData) _sourceConfig(LeadSource s) {
    switch (s) {
      case LeadSource.facebook:
        return (const Color(0xFF1877F2), 'FACEBOOK', Icons.facebook_rounded);
      case LeadSource.manual:
        return (AppColors.accent, 'MANUAL', Icons.edit_rounded);
      case LeadSource.referral:
        return (AppColors.leadFunnelQualified, 'REFERRAL',
            Icons.people_outline_rounded);
      case LeadSource.email:
        return (AppColors.leadFunnelContacted, 'EMAIL',
            Icons.mail_outline_rounded);
      case LeadSource.website:
        return (AppColors.primary, 'WEBSITE', Icons.language_rounded);
      case LeadSource.cold:
        return (AppColors.textSecondary, 'COLD CALL',
            Icons.phone_outlined);
    }
  }
}

// ─── Mini Stat ────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? c.withOpacity(0.12) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? c : AppColors.divider,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? c : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── View Toggle Button ───────────────────────────────────────────────────────

class _ViewToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ViewToggleBtn(
      {required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 18,
            color:
                selected ? AppColors.primary : AppColors.navUnselected),
      ),
    );
  }
}

