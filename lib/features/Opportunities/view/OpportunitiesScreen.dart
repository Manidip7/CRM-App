import 'package:flutter/material.dart';

import '../../../core/utils/AppColors.dart';

// ─────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────

enum OpportunityStage { proposal, negotiation, qualified, won, lost }

extension OpportunityStageName on OpportunityStage {
  String get label {
    switch (this) {
      case OpportunityStage.proposal:
        return 'PROPOSAL';
      case OpportunityStage.negotiation:
        return 'NEGOTIATION';
      case OpportunityStage.qualified:
        return 'QUALIFIED';
      case OpportunityStage.won:
        return 'WON';
      case OpportunityStage.lost:
        return 'LOST';
    }
  }

  Color get color {
    switch (this) {
      case OpportunityStage.proposal:
        return AppColors.green;
      case OpportunityStage.negotiation:
        return AppColors.greenLight;
      case OpportunityStage.qualified:
        return const Color(0xFF4CAF9A);
      case OpportunityStage.won:
        return AppColors.leadFunnelWon;
      case OpportunityStage.lost:
        return AppColors.lossRed;
    }
  }

  Color get bgColor {
    switch (this) {
      case OpportunityStage.proposal:
        return AppColors.green.withOpacity(0.12);
      case OpportunityStage.negotiation:
        return AppColors.greenLight.withOpacity(0.12);
      case OpportunityStage.qualified:
        return const Color(0xFF4CAF9A).withOpacity(0.12);
      case OpportunityStage.won:
        return AppColors.leadFunnelWon.withOpacity(0.12);
      case OpportunityStage.lost:
        return AppColors.redLight;
    }
  }
}

enum SourceType { manual, facebook, website, referral, email }

extension SourceTypeName on SourceType {
  String get label {
    switch (this) {
      case SourceType.manual:
        return 'MANUAL';
      case SourceType.facebook:
        return 'FACEBOOK';
      case SourceType.website:
        return 'WEBSITE';
      case SourceType.referral:
        return 'REFERRAL';
      case SourceType.email:
        return 'EMAIL';
    }
  }

  Color get color {
    switch (this) {
      case SourceType.manual:
        return const Color(0xFFB39DDB);
      case SourceType.facebook:
        return const Color(0xFF1877F2);
      case SourceType.website:
        return AppColors.primary;
      case SourceType.referral:
        return AppColors.donutTeal;
      case SourceType.email:
        return AppColors.accent;
    }
  }

  IconData get icon {
    switch (this) {
      case SourceType.manual:
        return Icons.edit_outlined;
      case SourceType.facebook:
        return Icons.facebook_rounded;
      case SourceType.website:
        return Icons.language_rounded;
      case SourceType.referral:
        return Icons.people_outline_rounded;
      case SourceType.email:
        return Icons.email_outlined;
    }
  }
}

class OpportunityModel {
  final String id;
  final String title;
  final String contactName;
  final double value;
  final int probability;
  final OpportunityStage stage;
  final SourceType source;
  final String timeAgo;
  final String nextFollowUp;
  final String phone;
  final String avatarInitials;
  final Color avatarColor;

  const OpportunityModel({
    required this.id,
    required this.title,
    required this.contactName,
    required this.value,
    required this.probability,
    required this.stage,
    required this.source,
    required this.timeAgo,
    required this.nextFollowUp,
    required this.phone,
    required this.avatarInitials,
    required this.avatarColor,
  });
}

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────

class OpportunitiesScreen extends StatefulWidget {
  /// Optional opportunity created by converting a lead. When provided it is
  /// inserted at the top of the list and briefly highlighted.
  final OpportunityModel? convertedLead;

  const OpportunitiesScreen({super.key, this.convertedLead});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  OpportunityStage? _selectedStage; // null = All
  String _sortLabel = 'Newest first';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Sample data ──
  late final List<OpportunityModel> _allOpportunities = [
    if (widget.convertedLead != null) widget.convertedLead!,
    ..._seedOpportunities,
  ];

  static const List<OpportunityModel> _seedOpportunities = [
    OpportunityModel(
      id: '1',
      title: 'Website Opportunity',
      contactName: 'Tanweer Khan',
      value: 76.58,
      probability: 70,
      stage: OpportunityStage.proposal,
      source: SourceType.manual,
      timeAgo: '1w',
      nextFollowUp: 'Jun 2, 10:00 AM',
      phone: '+91 98765 43210',
      avatarInitials: 'TK',
      avatarColor: Color(0xFFE53935),
    ),
    OpportunityModel(
      id: '2',
      title: 'Mindverge Software Deal',
      contactName: 'Rahul Sharma',
      value: 45000,
      probability: 85,
      stage: OpportunityStage.negotiation,
      source: SourceType.facebook,
      timeAgo: '1w',
      nextFollowUp: 'Jun 3, 9:00 AM',
      phone: '+91 98765 43210',
      avatarInitials: 'RS',
      avatarColor: Color(0xFF7B72E9),
    ),
    OpportunityModel(
      id: '3',
      title: 'PeploHr Enterprise Plan',
      contactName: 'Priya Menon',
      value: 28000,
      probability: 60,
      stage: OpportunityStage.qualified,
      source: SourceType.facebook,
      timeAgo: '2w',
      nextFollowUp: 'Jun 4, 2:00 PM',
      phone: '+91 87654 32109',
      avatarInitials: 'PM',
      avatarColor: Color(0xFF2DD4A0),
    ),
    OpportunityModel(
      id: '4',
      title: 'Cloud Migration Project',
      contactName: 'Arjun Patel',
      value: 120000,
      probability: 90,
      stage: OpportunityStage.won,
      source: SourceType.website,
      timeAgo: '3w',
      nextFollowUp: 'Jun 5, 11:00 AM',
      phone: '+91 76543 21098',
      avatarInitials: 'AP',
      avatarColor: Color(0xFFFF7043),
    ),
    OpportunityModel(
      id: '5',
      title: 'Annual Support Contract',
      contactName: 'Neha Singh',
      value: 55000,
      probability: 40,
      stage: OpportunityStage.proposal,
      source: SourceType.referral,
      timeAgo: '3d',
      nextFollowUp: 'Jun 6, 3:30 PM',
      phone: '+91 90123 45678',
      avatarInitials: 'NS',
      avatarColor: Color(0xFF26C6DA),
    ),
    OpportunityModel(
      id: '6',
      title: 'UI/UX Redesign',
      contactName: 'Vikram Iyer',
      value: 18500,
      probability: 55,
      stage: OpportunityStage.negotiation,
      source: SourceType.email,
      timeAgo: '5d',
      nextFollowUp: 'Jun 7, 4:00 PM',
      phone: '+91 81234 56789',
      avatarInitials: 'VI',
      avatarColor: Color(0xFFAB47BC),
    ),
  ];

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
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Derived lists ──
  List<OpportunityModel> get _filteredList {
    final query = _searchController.text.toLowerCase();
    return _allOpportunities.where((o) {
      final matchesSearch = query.isEmpty ||
          o.title.toLowerCase().contains(query) ||
          o.contactName.toLowerCase().contains(query) ||
          o.phone.contains(query);
      final matchesStage =
          _selectedStage == null || o.stage == _selectedStage;
      return matchesSearch && matchesStage;
    }).toList();
  }

  int _countByStage(OpportunityStage s) =>
      _allOpportunities.where((o) => o.stage == s).length;

  // ── Stat helpers ──
  double get _totalValue =>
      _allOpportunities.fold(0, (sum, o) => sum + o.value);

  int get _wonCount => _countByStage(OpportunityStage.won);

  // ── Formatting ──
  String _formatValue(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}k';
    return '₹${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredList;
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
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildStatCards()),
                      SliverToBoxAdapter(child: _buildSearchBar()),
                      SliverToBoxAdapter(child: _buildFilterTabs()),
                      SliverToBoxAdapter(child: _buildListHeader()),
                      if (list.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _buildCard(list[i]),
                              childCount: list.length,
                            ),
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
      floatingActionButton: _buildFAB(),
    );
  }

  // ─────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
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
                    const Text(
                      'Opportunities',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_allOpportunities.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Track and grow your pipeline',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Kanban view toggle icon (decorative)
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.view_column_outlined,
                size: 20, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.more_horiz_rounded,
                size: 20, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  STAT CARDS
  // ─────────────────────────────────────────────
  Widget _buildStatCards() {
    final stats = [
      _StatCard(
          value: '${_allOpportunities.length}',
          label: 'Total',
          color: AppColors.green),
      _StatCard(
          value: '${_countByStage(OpportunityStage.proposal)}',
          label: 'Proposal',
          color: AppColors.greenLight),
      _StatCard(
          value: '${_countByStage(OpportunityStage.negotiation)}',
          label: 'Negotiation',
          color: const Color(0xFF4CAF9A)),
      _StatCard(
          value: '$_wonCount', label: 'Won', color: AppColors.leadFunnelWon),
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
          onChanged: (_) => setState(() {}),
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
            final isSelected = _selectedStage == stage;
            final label = stage == null ? 'All' : stage.label;
            final activeColor =
                stage == null ? AppColors.green : stage.color;
            return GestureDetector(
              onTap: () => setState(() => _selectedStage = stage),
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
    final list = _filteredList;
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
                  _sortLabel,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(color: opp.stage.color, width: 3.5),
        ),
        boxShadow: [
          BoxShadow(
            color: opp.stage.color.withOpacity(0.06),
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
                    color: opp.avatarColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Text(
                      opp.avatarInitials,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: opp.avatarColor,
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
                          Text(
                            opp.contactName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
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
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.green,
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
                _buildTag(opp.stage.label, opp.stage.color,
                    opp.stage.bgColor, null),
                const SizedBox(width: 8),
                _buildProbTag(opp.probability),
                const SizedBox(width: 8),
                _buildTag(opp.source.label, opp.source.color,
                    opp.source.color.withOpacity(0.1), opp.source.icon),
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
    );
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
  //  FAB
  // ─────────────────────────────────────────────
  Widget _buildFAB() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.green, AppColors.leadFunnelWon],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withOpacity(0.4),
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