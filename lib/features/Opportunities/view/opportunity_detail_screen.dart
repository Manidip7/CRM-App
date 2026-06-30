import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/AppColors.dart';
import '../../Leads/view/schedule_follow_up_sheet.dart';
import '../data/opportunities_repository.dart';
import '../model/opportunity_detail_model.dart';
import '../model/opportunity_model.dart';
import '../provider/opportunities_provider.dart';
import '../provider/opportunity_detail_provider.dart';
import '../../calls/provider/call_providers.dart';
import '../../calls/widget/call_history_card.dart';

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

  /// Whether this screen was opened from the Backlog view. The backlog state
  /// persists on [opportunitiesProvider] across navigation, so we capture it
  /// once at open time and use it to tint the screen red (matching the red
  /// "overdue" treatment the backlog list uses) instead of the green pipeline
  /// accent.
  late final bool _fromBacklog =
      ref.read(opportunitiesProvider).showBacklog;

  /// The screen's brand accent: red in the backlog, green in the pipeline.
  Color get _accent => _fromBacklog ? AppColors.red : AppColors.green;

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
    _tabController = TabController(length: 6, vsync: this);
  }

  /// The full detail bundle from `GET /opportunities/{id}`, watched so the
  /// header and every tab fill in once it loads.
  AsyncValue<OpportunityDetailBundle> get _bundle =>
      ref.watch(opportunityDetailBundleProvider(_opp.id));

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
                    const SizedBox(height: 12),
                    CallHistoryCard(entityId: _opp.id, isLead: false),
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
    // Use the screen accent for the card border / avatar: green in the
    // pipeline, red in the backlog. (Not the per-opportunity avatar color,
    // which would show mixed red/blue/green.)
    final avatarColor = _accent;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(color: avatarColor, width: 4),
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
                    color: avatarColor.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      opp.avatarInitials,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: avatarColor,
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
                          Icon(Icons.payments_rounded,
                              size: 13, color: _accent),
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
                              color: _accent,
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
                  label: 'Lead-${opp.leadId}',
                  color: AppColors.primary,
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
                backgroundColor: _accent,
                disabledBackgroundColor: _accent.withOpacity(0.5),
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

  /// Opens the same Schedule Follow-up popup used on the Lead detail screen.
  /// Follow-ups are lead-scoped on the backend, so it's keyed by the
  /// opportunity's originating `lead_id`.
  Future<void> _showScheduleFollowUpSheet() async {
    final data = _bundle.asData?.value;

    final result = await showModalBottomSheet<FollowUpFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScheduleFollowUpSheet(
        id: _opp.id,
        color: _accent,
        initialCurrentUpdateId: data?.currentUpdateId,
        initialNextActionId: data?.nextActionId,
        initialRemark: data?.followupRemarks,
        initialDate: data?.nextFollowupAt?.toLocal() ?? DateTime.now(),
        onSubmit: ({
          int? currentUpdateId,
          int? nextActionId,
          String? followupRemarks,
          required String nextFollowUpAt,
          required int interestScore,
        }) =>
            ref.read(opportunitiesRepositoryProvider).scheduleFollowUp(
                  _opp.id,
                  currentUpdateId: currentUpdateId,
                  nextActionId: nextActionId,
                  followupRemarks: followupRemarks,
                  nextFollowUpAt: nextFollowUpAt,
                  interestScore: interestScore,
                ),
      ),
    );
    if (result == null || !mounted) return;

    // Reload the detail bundle so the new follow-up (and timeline entry) show.
    ref.invalidate(opportunityDetailBundleProvider(_opp.id));
    _showSnack('Follow-up scheduled for ${_fmtDate(result.scheduleDate)}');
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
            onTap: _call,
          ),
          const SizedBox(width: 10),
          _ActionButton(
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            bgColor: const Color(0xFF25D366).withOpacity(0.1),
            iconColor: const Color(0xFF25D366),
            onTap: _whatsapp,
          ),
          const SizedBox(width: 10),
          _ActionButton(
            icon: Icons.mail_rounded,
            label: 'Email',
            bgColor: AppColors.leadFunnelContacted.withOpacity(0.1),
            iconColor: AppColors.leadFunnelContacted,
            onTap: _email,
          ),
          const SizedBox(width: 10),
          _ActionButton(
            icon: Icons.sms_rounded,
            label: 'SMS',
            bgColor: AppColors.red.withOpacity(0.1),
            iconColor: AppColors.red,
            onTap: _sms,
          ),
        ],
      ),
    );
  }

  // ── Quick Action handlers ─────────────────────────────────────────────────────

  /// The contact phone: the server `lead.phone` when loaded, else the
  /// navigation model's phone.
  String? get _contactPhone {
    final phone = _bundle.asData?.value.phone;
    return (phone != null && phone.isNotEmpty) ? phone : _opp.phone;
  }

  /// The contact email from the loaded detail bundle.
  String? get _contactEmail => _bundle.asData?.value.email;

  /// Strips a phone string to digits/`+`, returning null if empty.
  String? _digits(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    return digits.isEmpty ? null : digits;
  }

  Future<void> _call() async {
    final phone = _digits(_contactPhone);
    if (phone == null) return _showSnack('No phone number for this contact.');
    // Tag this call with the opportunity so the captured call-log entry links
    // back to it (the resume-sync uploads it on return from the dialer).
    await ref.read(callSyncControllerProvider.notifier).recordDirectCall(
          number: phone,
          opportunityId: _opp.id,
        );
    await _launch(Uri(scheme: 'tel', path: phone), 'phone dialer');
  }

  Future<void> _sms() async {
    final phone = _digits(_contactPhone);
    if (phone == null) return _showSnack('No phone number for this contact.');
    await _launch(Uri(scheme: 'sms', path: phone), 'messaging app');
  }

  Future<void> _whatsapp() async {
    final phone = _digits(_contactPhone);
    if (phone == null) return _showSnack('No phone number for this contact.');
    // wa.me requires the number without a leading '+' or spaces.
    final waNumber = phone.replaceAll('+', '');
    await _launch(Uri.parse('https://wa.me/$waNumber'), 'WhatsApp');
  }

  Future<void> _email() async {
    final email = _contactEmail;
    if (email == null || email.trim().isEmpty) {
      return _showSnack('No email address for this contact.');
    }
    await _launch(Uri(scheme: 'mailto', path: email), 'email app');
  }

  /// Launches [uri] externally, showing a friendly message if it can't open.
  /// Tries the external-application mode first, then the platform default.
  Future<void> _launch(Uri uri, String target) async {
    try {
      var ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      if (!ok && mounted) _showSnack('Could not open $target.');
    } catch (_) {
      if (mounted) _showSnack('Could not open $target.');
    }
  }

  // ── Contact Details Card ─────────────────────────────────────────────────────
  Widget _buildContactDetailsCard() {
    final opp = _opp;
    final data = _bundle.asData?.value;
    final assignees = data?.assignees ?? const <OpportunityAssignee>[];
    final primaryAssignee = assignees.isNotEmpty ? assignees.first : null;
    final assignedLabel = primaryAssignee?.name ?? 'Admin Owner';
    final assignedSub = assignees.length > 1
        ? '+${assignees.length - 1} more'
        : (primaryAssignee?.designation ?? 'Sales Manager');
    final email = data?.email;
    final phone = (data?.phone?.isNotEmpty ?? false) ? data!.phone! : opp.phone;
    final contactName = (data?.contactName?.isNotEmpty ?? false)
        ? data!.contactName!
        : opp.contactName;
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
            iconBg: _accent.withOpacity(0.1),
            iconColor: _accent,
            label: 'Contact',
            value: contactName,
            isLink: false,
            accent: _accent,
          ),
          // Email (only when present)
          if (email != null && email.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 0, color: AppColors.divider),
            ),
            _ContactRow(
              icon: Icons.alternate_email_rounded,
              iconBg: AppColors.leadFunnelContacted.withOpacity(0.1),
              iconColor: AppColors.leadFunnelContacted,
              label: 'Email',
              value: email,
              isLink: true,
              onTap: _email,
              accent: _accent,
            ),
          ],
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
            value: phone,
            isLink: true,
            onTap: _call,
            copyValue: phone,
            accent: _accent,
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
            value: assignedLabel,
            subValue: assignedSub,
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
    final data = _bundle.asData?.value;
    final followUpLabel = data?.nextFollowupAt != null
        ? _fmtDate(data!.nextFollowupAt!)
        : _opp.nextFollowUp;
    final remarks = data?.followupRemarks;
    final score = data?.interestScore;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withOpacity(0.2), width: 0.8),
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
                  color: _accent,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  followUpLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _accent,
                  ),
                ),
              ),
            ],
          ),
          if (remarks != null && remarks.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes_rounded,
                    size: 14, color: _accent),
                const SizedBox(width: 8),
                Text(
                  'Remarks: ',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    remarks,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (score != null && score > 0) ...[
            const SizedBox(height: 10),
            _buildInterestScore(score),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _showScheduleFollowUpSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
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
    final tabs = [
      'Information',
      'Products',
      'Quotes',
      'Timeline',
      'Notes',
      'Tasks'
    ];
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
        labelColor: _accent,
        unselectedLabelColor: AppColors.textSecondary,
        indicator: BoxDecoration(
          color: _accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: _accent.withOpacity(0.3), width: 0.8),
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
            return _buildQuotesTab();
          case 3:
            return _buildTimelineTab();
          case 4:
            return _buildNotesTab();
          case 5:
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
    final data = _bundle.asData?.value;
    final dealValue = data?.expectedValue ?? _opp.value;
    final owner = data?.assignees.isNotEmpty ?? false
        ? data!.assignees.map((a) => a.name).join(', ')
        : 'Admin Owner';
    final nextFollowUp = data?.nextFollowupAt != null
        ? _fmtDate(data!.nextFollowupAt!)
        : _opp.nextFollowUp;
    final source = data?.sourceName ?? _opp.source.label;
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
                      color: _accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.description_rounded,
                        color: _accent, size: 18),
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
                  color: _accent,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),
              _InfoField(label: 'DEAL VALUE', value: _formatValue(dealValue)),
              const SizedBox(height: 12),
              _InfoField(label: 'WIN PROBABILITY', value: '$probability%'),
              const SizedBox(height: 12),
              _InfoField(label: 'STAGE', value: _stageLabel(stage)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Lead Info
        if (data != null) ...[
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LEAD INFO',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _accent,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),
                _InfoField(label: 'LEAD NO', value: data.leadNo),
                const SizedBox(height: 12),
                _InfoField(label: 'INTERESTED IN', value: data.interestedIn),
                const SizedBox(height: 12),
                _InfoField(label: 'CONTACT', value: data.contactName),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
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
                  color: _accent,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),
              _InfoField(label: 'SOURCE', value: source),
              const SizedBox(height: 12),
              _InfoField(label: 'OWNER', value: owner),
              const SizedBox(height: 12),
              _InfoField(label: 'NEXT FOLLOW-UP', value: nextFollowUp),
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
                  child: Icon(Icons.location_on_rounded,
                      color: _accent, size: 28),
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
    // Locally-added (UI-only) products, plus the server-side `items`.
    final localProducts = ref.watch(_detailProvider.select((s) => s.products));
    final items = _bundle.asData?.value.items ?? const <OpportunityItem>[];
    final localTotal = localProducts.fold<double>(0, (sum, p) => sum + p.total);
    final itemsTotal = items.fold<double>(0, (sum, i) => sum + i.total);
    final total = localTotal + itemsTotal;
    final isEmpty = localProducts.isEmpty && items.isEmpty;
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
                Icon(Icons.shopping_bag_outlined,
                    color: _accent, size: 18),
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
                      color: _accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add,
                            color: _accent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Add Product',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _accent,
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
            if (isEmpty)
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
              // Server-side line items.
              ...items.map(_buildItemRow),
              // Locally-added products (UI only).
              ...List.generate(localProducts.length, (i) {
                return _buildProductRow(localProducts[i], i);
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
                      color: _accent,
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

  /// A read-only line item from the server (`items` array). Labelled by item id
  /// since the API does not return a product name.
  Widget _buildItemRow(OpportunityItem item) {
    final qty = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.toInt().toString()
        : item.quantity.toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.inventory_2_rounded,
                color: _accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Item #${item.itemId}',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$qty × ${_formatValue(item.price)}',
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
            _formatValue(item.total),
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
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
              color: _accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.inventory_2_rounded,
                color: _accent, size: 18),
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

  // ── Shared async helpers (used by Quotes / Timeline / Notes / Tasks) ──────────
  Widget _tabLoading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );

  Widget _tabError(Object error) {
    final message = error is ApiException
        ? error.message
        : 'Could not load opportunity details.';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.red, size: 34),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () =>
                  ref.invalidate(opportunityDetailBundleProvider(_opp.id)),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Retry', style: GoogleFonts.poppins(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyTabState(IconData icon, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: AppColors.textLight, size: 40),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabSectionHeader(IconData icon, String title, int count,
      {String? addLabel, VoidCallback? onAdd}) {
    return Row(
      children: [
        Icon(icon, color: _accent, size: 18),
        const SizedBox(width: 8),
        Text(
          count > 0 ? '$title ($count)' : title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (addLabel != null)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.add, color: _accent, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    addLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── Quotes Tab ────────────────────────────────────────────────────────────────
  Widget _buildQuotesTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _bundle.when(
        loading: _tabLoading,
        error: (e, _) => _tabError(e),
        data: (data) {
          final quotes = data.quotations;
          if (quotes.isEmpty) {
            return _emptyTabState(Icons.request_quote_outlined,
                'No quotations for this opportunity.');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: quotes.map(_buildQuotationCard).toList(),
          );
        },
      ),
    );
  }

  Widget _buildQuotationCard(OpportunityQuotation q) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
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
              const Icon(Icons.request_quote_rounded,
                  color: AppColors.donutTeal, size: 18),
              const SizedBox(width: 8),
              Text(
                q.quotationNumber,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (q.isSelectedFinal)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'FINAL',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          if (q.customerName != null && q.customerName!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              q.customerName!,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          _quoteRow('Subtotal', _formatValue(q.subtotal)),
          const SizedBox(height: 6),
          _quoteRow('Tax', _formatValue(q.taxTotal)),
          const SizedBox(height: 6),
          _quoteRow('Grand Total', _formatValue(q.grandTotal), bold: true),
          if (q.date != null || q.validUntil != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.event_rounded,
                    size: 13, color: AppColors.textLight),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    [
                      if (q.date != null) 'Issued ${_fmtDate(q.date!)}',
                      if (q.validUntil != null)
                        'Valid till ${_fmtDate(q.validUntil!)}',
                    ].join('  •  '),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textLight),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _quoteRow(String label, String value, {bool bold = false}) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: bold ? 14 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: bold ? _accent : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ── Timeline Tab ──────────────────────────────────────────────────────────────
  Widget _buildTimelineTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _bundle.when(
        loading: _tabLoading,
        error: (e, _) => _tabError(e),
        data: (data) {
          final activities = data.activities;
          if (activities.isEmpty) {
            return _emptyTabState(Icons.history_rounded,
                'No activity yet for this opportunity.');
          }
          return Column(
            children: List.generate(activities.length, (i) {
              final a = activities[i];
              final isLast = i == activities.length - 1;
              final cfg = _activityConfig(a.action);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cfg.$1.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cfg.$2, color: cfg.$1, size: 17),
                      ),
                      if (!isLast)
                        Container(
                            width: 2, height: 40, color: AppColors.divider),
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
                          border: Border.all(
                              color: AppColors.divider, width: 0.8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    a.actionLabel,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (a.createdAt != null)
                                  Text(
                                    _timeAgo(a.createdAt!),
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppColors.textLight),
                                  ),
                              ],
                            ),
                            if (a.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                a.description,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.4),
                              ),
                            ],
                            if (a.userName != null &&
                                a.userName!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded,
                                      size: 12, color: AppColors.textLight),
                                  const SizedBox(width: 4),
                                  Text(
                                    a.userName!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
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
            }),
          );
        },
      ),
    );
  }

  // ── Notes Tab ─────────────────────────────────────────────────────────────────
  Widget _buildNotesTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _bundle.when(
        loading: _tabLoading,
        error: (e, _) => _tabError(e),
        data: (data) {
          final notes = data.notes;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tabSectionHeader(
                  Icons.sticky_note_2_outlined, 'Notes', notes.length,
                  addLabel: 'Add Note', onAdd: () => _showSnack('Add note')),
              const SizedBox(height: 12),
              if (notes.isEmpty)
                _emptyTabState(Icons.notes_rounded,
                    'No notes yet. Tap Add Note to get started.')
              else
                ...notes.map(_buildNoteCard),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoteCard(OpportunityNote note) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.content,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textPrimary, height: 1.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 12, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(
                note.userName ?? 'Unknown',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (note.createdAt != null)
                Text(
                  _timeAgo(note.createdAt!),
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textLight),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tasks Tab ─────────────────────────────────────────────────────────────────
  Widget _buildTasksTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _bundle.when(
        loading: _tabLoading,
        error: (e, _) => _tabError(e),
        data: (data) {
          final tasks = data.tasks;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tabSectionHeader(Icons.task_alt_rounded, 'Tasks', tasks.length,
                  addLabel: 'Add Task', onAdd: () => _showSnack('Add task')),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                _emptyTabState(Icons.assignment_outlined,
                    'No tasks linked to this opportunity.')
              else
                ...tasks.map(_buildTaskCard),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(OpportunityTask task) {
    final cfg = _taskStatusConfig(task.status);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cfg.$1.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  cfg.$2,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: cfg.$1,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              task.description!,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (task.priority != null) ...[
                Icon(Icons.flag_rounded,
                    size: 12, color: _priorityColor(task.priority!)),
                const SizedBox(width: 4),
                Text(
                  task.priority!.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _priorityColor(task.priority!),
                  ),
                ),
              ],
              const Spacer(),
              if (task.dueAt != null) ...[
                const Icon(Icons.event_rounded,
                    size: 12, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  'Due ${_fmtDate(task.dueAt!)}',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ],
          ),
          if (task.assigneeName != null && task.assigneeName!.isNotEmpty) ...[
            const SizedBox(height: 6),
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
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// (Color, label) for a task status code.
  (Color, String) _taskStatusConfig(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'done':
        return (AppColors.green, 'DONE');
      case 'in_progress':
        return (AppColors.primary, 'IN PROGRESS');
      case 'backlog':
        return (AppColors.textSecondary, 'BACKLOG');
      case 'todo':
        return (AppColors.leadFunnelContacted, 'TO DO');
      default:
        return (
          AppColors.textSecondary,
          (status ?? 'OPEN').toUpperCase(),
        );
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.red;
      case 'medium':
        return const Color(0xFFFFB547);
      case 'low':
        return AppColors.green;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Interest-score row: a label, a colour-coded percentage badge, and a thin
  /// progress bar. Mirrors the lead detail screen.
  Widget _buildInterestScore(int score) {
    final clamped = score.clamp(0, 100);
    final color = clamped < 40
        ? AppColors.red
        : clamped < 70
            ? const Color(0xFFFFB547)
            : AppColors.green;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.percent_rounded, size: 14, color: _accent),
            const SizedBox(width: 8),
            Text(
              'Interest Score: ',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$clamped%',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: clamped / 100,
            minHeight: 6,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
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

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// e.g. "Jun 24, 2026, 5:05 PM" — for the follow-up banner / quotation dates.
  String _fmtDate(DateTime dtUtc) {
    final dt = dtUtc.toLocal();
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}, $h:$min $ampm';
  }

  /// Short "x ago" label for timeline / note timestamps.
  String _timeAgo(DateTime dtUtc) {
    final diff = DateTime.now().difference(dtUtc.toLocal());
    if (diff.inDays >= 7) return '${diff.inDays ~/ 7}w ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  /// Picks an icon + color for an activity based on its action code.
  (Color, IconData) _activityConfig(String action) {
    switch (action) {
      case 'created':
      case 'created_from_conversion':
        return (AppColors.green, Icons.add_circle_outline_rounded);
      case 'assignment':
        return (AppColors.primary, Icons.assignment_ind_rounded);
      case 'followup_scheduled':
        return (AppColors.leadFunnelContacted, Icons.access_time_rounded);
      case 'note_added':
        return (const Color(0xFFFFB547), Icons.sticky_note_2_outlined);
      case 'priority_changed':
        return (AppColors.red, Icons.local_fire_department_rounded);
      case 'status_change':
      case 'stage_updated':
        return (AppColors.primary, Icons.swap_horiz_rounded);
      case 'won':
        return (AppColors.leadFunnelWon, Icons.emoji_events_rounded);
      case 'quotation_created':
        return (AppColors.donutTeal, Icons.request_quote_outlined);
      case 'updated':
        return (AppColors.primary, Icons.edit_outlined);
      default:
        return (AppColors.textSecondary, Icons.circle_notifications_outlined);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: _accent,
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
          _MenuItem(Icons.edit_rounded, 'Edit Opportunity', _accent),
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

  /// Accent used for the link text/underline (red in the backlog, green
  /// otherwise).
  final Color accent;

  /// When non-null, shows a copy button that copies this text to the clipboard
  /// (used for the phone row so the number can be copied without dialing).
  final String? copyValue;

  const _ContactRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subValue,
    required this.isLink,
    this.onTap,
    this.accent = AppColors.green,
    this.copyValue,
  });

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: copyValue!));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label copied',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

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
                      color: isLink ? accent : AppColors.textPrimary,
                      fontWeight: isLink ? FontWeight.w600 : FontWeight.w500,
                      decoration: isLink
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: accent,
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
            if (copyValue != null && copyValue!.isNotEmpty)
              GestureDetector(
                onTap: () => _copy(context),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.copy_rounded,
                      size: 15, color: AppColors.textSecondary),
                ),
              ),
            if (isLink)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    size: 13, color: AppColors.textLight),
              ),
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

  /// Match the detail screen's accent: red when launched from the backlog.
  Color get _accent =>
      ref.read(opportunitiesProvider).showBacklog
          ? AppColors.red
          : AppColors.green;

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
                  backgroundColor: _accent,
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
          borderSide: BorderSide(color: _accent, width: 1.4),
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
