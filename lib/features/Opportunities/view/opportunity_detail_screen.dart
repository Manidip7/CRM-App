import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';
import '../model/opportunity_model.dart';
import '../provider/opportunities_provider.dart';
import '../provider/opportunity_detail_provider.dart';

class OpportunityDetailScreen extends ConsumerStatefulWidget {
  final OpportunityModel opportunity;

  const OpportunityDetailScreen({super.key, required this.opportunity});

  @override
  ConsumerState<OpportunityDetailScreen> createState() =>
      _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState
    extends ConsumerState<OpportunityDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  OpportunityModel get _opp => widget.opportunity;

  // Provider keyed by this opportunity's id, seeded with its own stage /
  // probability so the screen renders the correct values on first build.
  OpportunityDetailControllerProvider get _detailProvider =>
      opportunityDetailControllerProvider(
        _opp.id,
        initialStage: _opp.stage,
        initialProbability: _opp.probability,
      );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildHeroCard(),
                    const SizedBox(height: 12),
                    _buildDealCard(),
                    const SizedBox(height: 12),
                    _buildQuickActions(),
                    const SizedBox(height: 12),
                    _buildContactDetailsCard(),
                    const SizedBox(height: 16),
                    _buildTabBar(),
                    const SizedBox(height: 12),
                    _buildTabContent(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        backgroundColor: AppColors.green,
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 17),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Opportunity Details',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          _buildStageDropdown(),
        ],
      ),
    );
  }

  // Stage dropdown shown on the top bar (header) right side
  Widget _buildStageDropdown() {
    final stage = ref.watch(_detailProvider.select((s) => s.stage));
    final color = stage.color;
    return PopupMenuButton<OpportunityStage>(
      tooltip: 'Change stage',
      offset: const Offset(0, 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.cardBackground,
      onSelected: (s) {
        ref.read(_detailProvider.notifier).setStage(s);
        ref
            .read(opportunitiesProvider.notifier)
            .updateOpportunity(_opp.id, stage: s);
      },
      itemBuilder: (_) => OpportunityStage.values.map((s) {
        final selected = s == stage;
        return PopupMenuItem<OpportunityStage>(
          value: s,
          height: 42,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: s.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _stageLabel(s),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (selected) Icon(Icons.check_rounded, size: 16, color: s.color),
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              _stageLabel(stage),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }

  // ── Hero Card ────────────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    final opp = _opp;
    final stage = ref.watch(_detailProvider.select((s) => s.stage));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(color: opp.avatarColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: opp.avatarColor.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      opp.avatarInitials,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: opp.avatarColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title (primary)
                      Text(
                        opp.title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Contact
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            opp.contactName,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Deal value
                      Row(
                        children: [
                          const Icon(Icons.payments_rounded,
                              size: 13, color: AppColors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Value: ',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _formatValue(opp.value),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 3-dot menu
                GestureDetector(
                  onTap: () => _showCardMenu(context),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 4, top: 2),
                    child: Icon(Icons.more_vert,
                        color: AppColors.textSecondary, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Badges row
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // Opportunity ID
                _Chip(
                  label: 'OPP-${opp.id}',
                  color: AppColors.green,
                  icon: Icons.tag_rounded,
                  filled: true,
                ),
                // Stage
                _Chip(label: _stageLabel(stage), color: stage.color),
                // Source
                _Chip(
                  label: opp.source.label,
                  color: opp.source.color,
                  icon: opp.source.icon,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Probability / Mark Won Card ───────────────────────────────────────────────
  Widget _buildDealCard() {
    final probability =
        ref.watch(_detailProvider.select((s) => s.probability));
    final closedWon = ref.watch(_detailProvider.select((s) => s.closedWon));
    final probColor = _probabilityColor(probability);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
              Text(
                'WIN PROBABILITY',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: probColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$probability%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: probColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: probColor,
              inactiveTrackColor: probColor.withOpacity(0.15),
              thumbColor: probColor,
              overlayColor: probColor.withOpacity(0.15),
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(
              value: probability.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: closedWon
                  ? null
                  : (v) {
                      ref
                          .read(_detailProvider.notifier)
                          .setProbability(v.round());
                      ref
                          .read(opportunitiesProvider.notifier)
                          .updateOpportunity(_opp.id,
                              probability: v.round());
                    },
            ),
          ),
          const SizedBox(height: 12),
          // ── Mark as Won ──
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: closedWon ? null : _markWon,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                disabledBackgroundColor: AppColors.green.withOpacity(0.5),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(
                closedWon
                    ? Icons.emoji_events_rounded
                    : Icons.check_circle_outline_rounded,
                size: 19,
              ),
              label: Text(
                closedWon ? 'Deal Won' : 'Mark as Won',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _markWon() {
    ref.read(_detailProvider.notifier).markWon();
    ref.read(opportunitiesProvider.notifier).updateOpportunity(
          _opp.id,
          stage: OpportunityStage.won,
          probability: 100,
        );
    _showSnack('Opportunity marked as won 🎉');
  }

  Color _probabilityColor(int prob) => prob >= 70
      ? AppColors.green
      : prob >= 50
          ? AppColors.greenLight
          : AppColors.textSecondary;

  // ── Quick Actions ─────────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.phone_rounded,
            label: 'Call',
            bgColor: AppColors.primary.withOpacity(0.1),
            iconColor: AppColors.primary,
            onTap: () => _showSnack('Calling ${_opp.contactName}...'),
          ),
          const SizedBox(width: 10),
          _ActionButton(
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            bgColor: const Color(0xFF25D366).withOpacity(0.1),
            iconColor: const Color(0xFF25D366),
            onTap: () => _showSnack('Opening WhatsApp...'),
          ),
          const SizedBox(width: 10),
          _ActionButton(
            icon: Icons.mail_rounded,
            label: 'Email',
            bgColor: AppColors.leadFunnelContacted.withOpacity(0.1),
            iconColor: AppColors.leadFunnelContacted,
            onTap: () => _showSnack('Composing email...'),
          ),
          const SizedBox(width: 10),
          _ActionButton(
            icon: Icons.sms_rounded,
            label: 'SMS',
            bgColor: AppColors.red.withOpacity(0.1),
            iconColor: AppColors.red,
            onTap: () => _showSnack('Opening SMS...'),
          ),
        ],
      ),
    );
  }

  // ── Contact Details Card ─────────────────────────────────────────────────────
  Widget _buildContactDetailsCard() {
    final opp = _opp;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
            child: Row(
              children: [
                Text(
                  'Contact Details',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showSnack('Edit contact details'),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        size: 16, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0, color: AppColors.divider),
          // Contact name
          _ContactRow(
            icon: Icons.person_outline_rounded,
            iconBg: AppColors.green.withOpacity(0.1),
            iconColor: AppColors.green,
            label: 'Contact',
            value: opp.contactName,
            isLink: false,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 0, color: AppColors.divider),
          ),
          // Phone
          _ContactRow(
            icon: Icons.phone_outlined,
            iconBg: AppColors.primary.withOpacity(0.1),
            iconColor: AppColors.primary,
            label: 'Phone',
            value: opp.phone,
            isLink: true,
            onTap: () => _showSnack('Calling ${opp.phone}'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 0, color: AppColors.divider),
          ),
          // Assigned To
          _ContactRow(
            icon: Icons.person_pin_rounded,
            iconBg: AppColors.leadFunnelContacted.withOpacity(0.1),
            iconColor: AppColors.leadFunnelContacted,
            label: 'Assigned To',
            value: 'Admin Owner',
            subValue: 'Sales Manager',
            isLink: false,
          ),
          const SizedBox(height: 4),
          // Follow-up Schedule
          _buildFollowUpBanner(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildFollowUpBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withOpacity(0.2), width: 0.8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'FOLLOW-UP SCHEDULE',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _opp.nextFollowUp,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _showSnack('Schedule follow-up'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.calendar_month_rounded, size: 17),
              label: Text(
                'Schedule Next Follow-up',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    final tabs = ['Information', 'Product', 'Timeline', 'Notes', 'Tasks'];
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
        labelColor: AppColors.green,
        unselectedLabelColor: AppColors.textSecondary,
        indicator: BoxDecoration(
          color: AppColors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: AppColors.green.withOpacity(0.3), width: 0.8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        labelStyle:
            GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400),
        labelPadding: const EdgeInsets.symmetric(horizontal: 14),
        padding: const EdgeInsets.all(3),
        tabs: tabs.map((t) => Tab(text: t, height: 34)).toList(),
      ),
    );
  }

  // ── Tab Content ───────────────────────────────────────────────────────────────
  Widget _buildTabContent() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (_, __) {
        switch (_tabController.index) {
          case 0:
            return _buildInformationTab();
          case 1:
            return _buildProductTab();
          case 2:
            return _buildTimelineTab();
          case 3:
            return _buildNotesTab();
          case 4:
            return _buildTasksTab();
          default:
            return _buildInformationTab();
        }
      },
    );
  }

  Widget _buildInformationTab() {
    final stage = ref.watch(_detailProvider.select((s) => s.stage));
    final probability =
        ref.watch(_detailProvider.select((s) => s.probability));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Opportunity Description
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_rounded,
                        color: AppColors.green, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Opportunity Description',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'No description provided for this opportunity record.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Deal Details
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DEAL DETAILS',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),
              _InfoField(label: 'DEAL VALUE', value: _formatValue(_opp.value)),
              const SizedBox(height: 12),
              _InfoField(label: 'WIN PROBABILITY', value: '$probability%'),
              const SizedBox(height: 12),
              _InfoField(label: 'STAGE', value: _stageLabel(stage)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Classification
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CLASSIFICATION',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),
              _InfoField(label: 'SOURCE', value: _opp.source.label),
              const SizedBox(height: 12),
              _InfoField(label: 'OWNER', value: 'Admin Owner'),
              const SizedBox(height: 12),
              _InfoField(label: 'NEXT FOLLOW-UP', value: _opp.nextFollowUp),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Location Card
        _buildLocationCard(),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C4A52), Color(0xFF3A6065)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CustomPaint(painter: _MapGridPainter()),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: AppColors.green, size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  'Location Details Unavailable',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
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

  // ── Product Tab ───────────────────────────────────────────────────────────────
  Widget _buildProductTab() {
    final products = ref.watch(_detailProvider.select((s) => s.products));
    final total = products.fold<double>(0, (sum, p) => sum + p.total);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    color: AppColors.green, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Products',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _showAddProductSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add,
                            color: AppColors.green, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Add Product',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (products.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        color: AppColors.textLight, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'No products added yet.\nTap Add Product to get started.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              )
            else ...[
              ...List.generate(products.length, (i) {
                return _buildProductRow(products[i], i);
              }),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Divider(height: 1, color: AppColors.divider),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatValue(total),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductRow(OpportunityProduct p, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2_rounded,
                color: AppColors.green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${p.quantity} × ${_formatValue(p.price)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatValue(p.total),
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () =>
                ref.read(_detailProvider.notifier).removeProduct(index),
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddProductSheet() async {
    final product = await showModalBottomSheet<OpportunityProduct>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddProductSheet(),
    );
    if (product != null) {
      ref.read(_detailProvider.notifier).addProduct(product);
      _showSnack('Product added');
    }
  }

  Widget _buildTimelineTab() {
    final events = [
      _TimelineEvent(
        icon: Icons.add_circle_outline_rounded,
        title: 'Opportunity Created',
        subtitle: 'Created from ${_opp.source.label} source',
        time: '${_opp.timeAgo} ago',
        color: AppColors.green,
      ),
      _TimelineEvent(
        icon: Icons.assignment_ind_rounded,
        title: 'Assigned',
        subtitle: 'Assigned to Admin Owner',
        time: '${_opp.timeAgo} ago',
        color: AppColors.primary,
      ),
      _TimelineEvent(
        icon: Icons.access_time_rounded,
        title: 'Follow-up Scheduled',
        subtitle: 'Next follow-up set for ${_opp.nextFollowUp}',
        time: 'upcoming',
        color: AppColors.leadFunnelContacted,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(events.length, (i) {
          final e = events[i];
          final isLast = i == events.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: e.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(e.icon, color: e.color, size: 17),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: AppColors.divider,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.divider, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              e.title,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              e.time,
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: AppColors.textLight),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e.subtitle,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildNotesTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sticky_note_2_outlined,
                    color: AppColors.green, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Notes',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showSnack('Add note'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add,
                            color: AppColors.green, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Add Note',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(Icons.notes_rounded,
                      color: AppColors.textLight, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'No notes yet. Tap Add Note to get started.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 0.8),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.task_alt_rounded,
                    color: AppColors.green, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Tasks',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showSnack('Add task'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add,
                            color: AppColors.green, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Add Task',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(Icons.assignment_outlined,
                      color: AppColors.textLight, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'No tasks linked to this opportunity.',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  String _stageLabel(OpportunityStage s) {
    final raw = s.label; // e.g. PROPOSAL
    return raw[0] + raw.substring(1).toLowerCase();
  }

  String _formatValue(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}k';
    return '₹${v.toStringAsFixed(2)}';
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCardMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MenuSheet(
        items: [
          _MenuItem(Icons.edit_rounded, 'Edit Opportunity', AppColors.green),
          _MenuItem(Icons.person_add_outlined, 'Reassign', AppColors.primary),
          _MenuItem(
              Icons.archive_outlined, 'Archive', AppColors.textSecondary),
          _MenuItem(
              Icons.delete_outline_rounded, 'Delete Opportunity', AppColors.red),
        ],
        onSelected: (label) => _showSnack(label),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MenuSheet(
        items: [
          _MenuItem(Icons.task_alt_rounded, 'Add Task', AppColors.green),
          _MenuItem(
              Icons.sticky_note_2_outlined, 'Add Note', AppColors.primary),
          _MenuItem(Icons.calendar_month_rounded, 'Schedule Follow-up',
              AppColors.leadFunnelContacted),
        ],
        onSelected: (label) => _showSnack(label),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Reusable Sub-Widgets
// ══════════════════════════════════════════════════════════════════════════════

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  const _Chip({
    required this.label,
    required this.color,
    this.icon,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: filled ? color : color.withOpacity(0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String? subValue;
  final bool isLink;
  final VoidCallback? onTap;

  const _ContactRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subValue,
    required this.isLink,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isLink ? AppColors.green : AppColors.textPrimary,
                      fontWeight: isLink ? FontWeight.w600 : FontWeight.w500,
                      decoration: isLink
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: AppColors.green,
                    ),
                  ),
                  if (subValue != null)
                    Text(
                      subValue!,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (isLink)
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String? value;

  const _InfoField({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value ?? '—',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: value != null ? AppColors.textPrimary : AppColors.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: child,
    );
  }
}

// ── Timeline Event ────────────────────────────────────────────────────────────

class _TimelineEvent {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  _TimelineEvent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });
}

// ── Menu Sheet ────────────────────────────────────────────────────────────────

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  _MenuItem(this.icon, this.label, this.color);
}

class _MenuSheet extends StatelessWidget {
  final List<_MenuItem> items;
  final ValueChanged<String> onSelected;

  const _MenuSheet({required this.items, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => GestureDetector(
              onTap: () {
                Navigator.pop(context);
                onSelected(item.label);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, color: item.color, size: 20),
                    const SizedBox(width: 14),
                    Text(
                      item.label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Product Sheet ─────────────────────────────────────────────────────────

/// Ephemeral validation message for the Add Product sheet.
class _AddProductError extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? message) => state = message;
}

final _addProductErrorProvider =
    NotifierProvider<_AddProductError, String?>(_AddProductError.new);

class _AddProductSheet extends ConsumerStatefulWidget {
  const _AddProductSheet();

  @override
  ConsumerState<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<_AddProductSheet> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Clear any error left over from a previous time the sheet was opened.
    ref.read(_addProductErrorProvider.notifier).set(null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final qty = int.tryParse(_qtyController.text.trim());
    final price = double.tryParse(_priceController.text.trim());

    final errorNotifier = ref.read(_addProductErrorProvider.notifier);
    if (name.isEmpty) {
      errorNotifier.set('Please enter a product name');
      return;
    }
    if (qty == null || qty <= 0) {
      errorNotifier.set('Please enter a valid quantity');
      return;
    }
    if (price == null || price < 0) {
      errorNotifier.set('Please enter a valid price');
      return;
    }

    Navigator.pop(
      context,
      OpportunityProduct(name: name, quantity: qty, price: price),
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(_addProductErrorProvider);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Add Product',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _label('PRODUCT NAME'),
            const SizedBox(height: 6),
            _field(
              controller: _nameController,
              hint: 'e.g. Annual License',
              icon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('QUANTITY'),
                      const SizedBox(height: 6),
                      _field(
                        controller: _qtyController,
                        hint: '1',
                        icon: Icons.tag_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('UNIT PRICE (₹)'),
                      const SizedBox(height: 6),
                      _field(
                        controller: _priceController,
                        hint: '0.00',
                        icon: Icons.payments_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 15, color: AppColors.red),
                  const SizedBox(width: 6),
                  Text(
                    error,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_rounded, size: 19),
                label: Text(
                  'Add Product',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
            fontSize: 13.5, color: AppColors.textLight),
        prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          borderSide: const BorderSide(color: AppColors.green, width: 1.4),
        ),
      ),
    );
  }
}

// ── Map Grid Painter ──────────────────────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;

    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
