import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/AppColors.dart';
import '../../../routes/app_routes.dart';
import '../model/lead_model.dart';
import '../provider/lead_detail_provider.dart';
import '../../Opportunities/model/opportunity_model.dart';
import '../../Opportunities/provider/opportunities_provider.dart';

class LeadDetailScreen extends ConsumerStatefulWidget {
  final LeadModel lead;

  const LeadDetailScreen({super.key, required this.lead});

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late LeadDetailModel _detail;

  // Provider keyed by this lead's id, seeded with the temperature derived from
  // the lead's `priority` (cold/warm/hot).
  LeadDetailControllerProvider get _detailProvider =>
      leadDetailControllerProvider(
        widget.lead.id,
        initialTemperature:
            _temperatureFromPriority(widget.lead.priority) ??
                LeadTemperature.warm,
      );

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
    _tabController = TabController(length: 4, vsync: this);
    _detail = LeadDetailModel.fromLead(widget.lead);
  }

  /// Maps the backend `priority` string to the [LeadTemperature] enum.
  LeadTemperature? _temperatureFromPriority(String? priority) {
    switch (priority?.toLowerCase().trim()) {
      case 'hot':
        return LeadTemperature.hot;
      case 'warm':
        return LeadTemperature.warm;
      case 'cold':
        return LeadTemperature.cold;
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color get _avatarColor =>
      _avatarColors[widget.lead.avatarColorIndex % _avatarColors.length];

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
                    _buildStatusCard(),
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
        backgroundColor: AppColors.primary,
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
            'Lead Details',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          _buildStatusDropdown(),
        ],
      ),
    );
  }

  // Status dropdown shown on the top bar (header) right side
  Widget _buildStatusDropdown() {
    final pipelineStatus =
        ref.watch(_detailProvider.select((s) => s.pipelineStatus));
    final cfg = _pipelineConfig(pipelineStatus);
    return PopupMenuButton<LeadPipelineStatus>(
      tooltip: 'Change status',
      offset: const Offset(0, 46),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      color: AppColors.cardBackground,
      onSelected: (s) =>
          ref.read(_detailProvider.notifier).setStatus(s),
      itemBuilder: (_) => LeadPipelineStatus.values.map((s) {
        final c = _pipelineConfig(s);
        final selected = s == pipelineStatus;
        return PopupMenuItem<LeadPipelineStatus>(
          value: s,
          height: 42,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: c.$1,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                c.$2,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (selected)
                Icon(Icons.check_rounded, size: 16, color: c.$1),
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: cfg.$1.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cfg.$1, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: cfg.$1,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              cfg.$2,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cfg.$1,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: cfg.$1),
          ],
        ),
      ),
    );
  }

  // ── Hero Card ────────────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    final lead = widget.lead;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(color: _avatarColor, width: 4),
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
                // Avatar circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _avatarColor.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      lead.displayInitials,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _avatarColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contact name (primary)
                      Text(
                        lead.contactName,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      // Organization
                      if (lead.companyName != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.business_rounded,
                                size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              lead.companyName!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      // Source of lead
                      Row(
                        children: [
                          const Icon(Icons.track_changes_rounded,
                              size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Source: ',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _sourceLabel(lead.source),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
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
                // Lead ID
                _Chip(
                  label: _detail.leadId,
                  color: AppColors.primary,
                  icon: Icons.tag_rounded,
                  filled: true,
                ),
                // Status
                _statusChip(lead.status),
                // Source
                _sourceChip(lead.source),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Status / Temperature / Convert Card ───────────────────────────────────────
  Widget _buildStatusCard() {
    final temperature =
        ref.watch(_detailProvider.select((s) => s.temperature));
    final converted = ref.watch(_detailProvider.select((s) => s.converted));
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
          // ── Lead Temperature ──
          Text(
            'LEAD TEMPERATURE',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: LeadTemperature.values.map((t) {
              final cfg = _temperatureConfig(t);
              final selected = temperature == t;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(_detailProvider.notifier).setTemperature(t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? cfg.$1.withOpacity(0.12)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? cfg.$1 : AppColors.divider,
                          width: selected ? 1.5 : 0.8,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(cfg.$3,
                              size: 22,
                              color: selected
                                  ? cfg.$1
                                  : AppColors.textSecondary),
                          const SizedBox(height: 4),
                          Text(
                            cfg.$2,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: selected
                                  ? cfg.$1
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          // ── Convert to Opportunity ──
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: converted ? null : _convertToOpportunity,
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
                converted
                    ? Icons.check_circle_rounded
                    : Icons.swap_horiz_rounded,
                size: 19,
              ),
              label: Text(
                converted
                    ? 'Converted to Opportunity'
                    : 'Convert to Opportunity',
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

  // (Color, label) for pipeline status
  (Color, String) _pipelineConfig(LeadPipelineStatus s) {
    switch (s) {
      case LeadPipelineStatus.newLead:
        return (AppColors.leadFunnelNew, 'New');
      case LeadPipelineStatus.inProgress:
        return (AppColors.primary, 'In Progress');
      case LeadPipelineStatus.interested:
        return (AppColors.green, 'Interested');
      case LeadPipelineStatus.lost:
        return (AppColors.red, 'Lost');
    }
  }

  // (Color, label, icon) for temperature
  (Color, String, IconData) _temperatureConfig(LeadTemperature t) {
    switch (t) {
      case LeadTemperature.hot:
        return (AppColors.red, 'Hot Lead', Icons.local_fire_department_rounded);
      case LeadTemperature.warm:
        return (const Color(0xFFFFB547), 'Warm Lead', Icons.wb_sunny_rounded);
      case LeadTemperature.cold:
        return (const Color(0xFF42A5F5), 'Cold Lead', Icons.ac_unit_rounded);
    }
  }

  void _convertToOpportunity() {
    final lead = widget.lead;
    final pipelineStatus = ref.read(_detailProvider).pipelineStatus;
    final opp = OpportunityModel(
      id: 'OPP-${lead.id}',
      title: lead.companyName != null
          ? '${lead.companyName} Deal'
          : '${lead.contactName} Opportunity',
      contactName: lead.contactName,
      value: lead.dealValue ?? 0,
      probability: pipelineStatus == LeadPipelineStatus.interested ? 70 : 50,
      stage: OpportunityStage.qualified,
      source: _mapSource(lead.source),
      timeAgo: 'now',
      nextFollowUp: _fmtDate(lead.nextFollowUp),
      phone: lead.phone ?? '—',
      avatarInitials: lead.displayInitials,
      avatarColor: _avatarColor,
    );

    // Add to the shared opportunities store and mark this lead converted.
    ref.read(opportunitiesProvider.notifier).addOpportunity(opp);
    ref.read(_detailProvider.notifier).markConverted();
    _showSnack('Lead converted to opportunity');
    context.push(AppRoutes.opportunities);
  }

  SourceType _mapSource(LeadSource s) {
    switch (s) {
      case LeadSource.facebook:
        return SourceType.facebook;
      case LeadSource.manual:
        return SourceType.manual;
      case LeadSource.referral:
        return SourceType.referral;
      case LeadSource.email:
        return SourceType.email;
      case LeadSource.website:
        return SourceType.website;
      case LeadSource.cold:
        return SourceType.manual;
    }
  }

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
            onTap: _callLead,
          ),
          const SizedBox(width: 10),
          _ActionButton(
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            bgColor: const Color(0xFF25D366).withOpacity(0.1),
            iconColor: const Color(0xFF25D366),
            onTap: _whatsappLead,
          ),
          const SizedBox(width: 10),
          _ActionButton(
            icon: Icons.mail_rounded,
            label: 'Email',
            bgColor: AppColors.leadFunnelContacted.withOpacity(0.1),
            iconColor: AppColors.leadFunnelContacted,
            onTap: _emailLead,
          ),
          const SizedBox(width: 10),
          _ActionButton(
            icon: Icons.sms_rounded,
            label: 'SMS',
            bgColor: AppColors.red.withOpacity(0.1),
            iconColor: AppColors.red,
            onTap: _smsLead,
          ),
        ],
      ),
    );
  }

  // ── Quick Action handlers ─────────────────────────────────────────────────────

  /// Strips a phone string to digits/`+`, returning null if empty.
  String? _digits(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    return digits.isEmpty ? null : digits;
  }

  /// Digits-only primary phone number, suitable for tel:/sms:/wa.me URIs.
  String? get _phoneDigits => _digits(widget.lead.phone);

  /// Dials an arbitrary number (used by the primary and alternate phone).
  Future<void> _callNumber(String? raw) async {
    final phone = _digits(raw);
    if (phone == null) return _showSnack('No phone number for this lead.');
    await _launch(Uri(scheme: 'tel', path: phone), 'phone dialer');
  }

  Future<void> _callLead() => _callNumber(widget.lead.phone);

  Future<void> _smsLead() async {
    final phone = _phoneDigits;
    if (phone == null) return _showSnack('No phone number for this lead.');
    await _launch(Uri(scheme: 'sms', path: phone), 'messaging app');
  }

  Future<void> _whatsappLead() async {
    final phone = _phoneDigits;
    if (phone == null) return _showSnack('No phone number for this lead.');
    // wa.me requires the number without a leading '+' or spaces.
    final waNumber = phone.replaceAll('+', '');
    await _launch(
      Uri.parse('https://wa.me/$waNumber'),
      'WhatsApp',
    );
  }

  Future<void> _emailLead() async {
    final email = widget.lead.email;
    if (email == null || email.trim().isEmpty) {
      return _showSnack('No email address for this lead.');
    }
    await _launch(Uri(scheme: 'mailto', path: email), 'email app');
  }

  /// Launches [uri] externally, showing a friendly message if it can't open.
  /// Tries the external-application mode first, then falls back to the platform
  /// default (helps on devices where the strict mode reports failure).
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
    final lead = widget.lead;
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
          // Email
          _ContactRow(
            icon: Icons.alternate_email_rounded,
            iconBg: AppColors.leadFunnelContacted.withOpacity(0.1),
            iconColor: AppColors.leadFunnelContacted,
            label: 'Email',
            value: lead.email ?? '—',
            isLink: lead.email != null,
            onTap: lead.email != null ? _emailLead : null,
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
            value: lead.phone ?? '—',
            isLink: lead.phone != null,
            onTap: lead.phone != null ? _callLead : null,
          ),
          // Alternate Phone (only when present)
          if (lead.alternatePhone != null &&
              lead.alternatePhone!.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 0, color: AppColors.divider),
            ),
            _ContactRow(
              icon: Icons.phone_forwarded_outlined,
              iconBg: AppColors.primary.withOpacity(0.1),
              iconColor: AppColors.primary,
              label: 'Alternate Phone',
              value: lead.alternatePhone!,
              isLink: true,
              onTap: () => _callNumber(lead.alternatePhone),
            ),
          ],
          // Interested In (only when present)
          if (lead.interestedIn != null &&
              lead.interestedIn!.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 0, color: AppColors.divider),
            ),
            _ContactRow(
              icon: Icons.interests_outlined,
              iconBg: const Color(0xFFFFB547).withOpacity(0.12),
              iconColor: const Color(0xFFFFB547),
              label: 'Interested In',
              value: lead.interestedIn!,
              isLink: false,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 0, color: AppColors.divider),
          ),
          // Assigned To
          _ContactRow(
            icon: Icons.person_pin_rounded,
            iconBg: AppColors.green.withOpacity(0.1),
            iconColor: AppColors.green,
            label: 'Assigned To',
            value: lead.assigneeName ?? _detail.assignedToName ?? '—',
            subValue: lead.assigneeDesignation ?? _detail.assignedToRole,
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
    final months = [
      'JAN','FEB','MAR','APR','MAY','JUN',
      'JUL','AUG','SEP','OCT','NOV','DEC'
    ];
    final dt = widget.lead.nextFollowUp;
    final dateStr =
        '${months[dt.month - 1]} ${dt.day}, ${dt.year}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.2), width: 0.8),
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
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dateStr,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          // Current Update / Next Action / Remarks (shown when present).
          if (widget.lead.currentUpdate != null &&
              widget.lead.currentUpdate!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _followUpRow(
                Icons.update_rounded, 'Current Update', widget.lead.currentUpdate!),
          ],
          if (widget.lead.nextAction != null &&
              widget.lead.nextAction!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _followUpRow(Icons.bolt_rounded, 'Next Action',
                widget.lead.nextAction!),
          ],
          if (widget.lead.followupRemarks != null &&
              widget.lead.followupRemarks!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _followUpRow(Icons.notes_rounded, 'Remarks',
                widget.lead.followupRemarks!),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _showSnack('Schedule follow-up'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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

  /// A labelled value row inside the follow-up banner.
  Widget _followUpRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    final tabs = ['Information', 'Timeline', 'Notes', 'Tasks'];
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
          border: Border.all(
              color: AppColors.primary.withOpacity(0.3), width: 0.8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w400),
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
            return _buildTimelineTab();
          case 2:
            return _buildNotesTab();
          case 3:
            return _buildTasksTab();
          default:
            return _buildInformationTab();
        }
      },
    );
  }

  Widget _buildInformationTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lead Description
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
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_rounded,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Lead Description',
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
                _detail.description ??
                    'No description provided for this lead record.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: _detail.description != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontStyle: _detail.description != null
                      ? FontStyle.normal
                      : FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Professional Details
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROFESSIONAL DETAILS',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),
              _InfoField(
                  label: 'DESIGNATION',
                  value: widget.lead.designation ?? _detail.designation),
              const SizedBox(height: 12),
              _InfoField(
                  label: 'WEBSITE',
                  value: widget.lead.website ?? _detail.website),
              const SizedBox(height: 12),
              _InfoField(
                  label: 'ALT PHONE',
                  value: widget.lead.alternatePhone ?? _detail.altPhone),
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
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 14),
              _InfoField(label: 'LEAD TYPE', value: _detail.leadType),
              const SizedBox(height: 12),
              _InfoField(label: 'TERRITORY', value: _detail.territory),
              const SizedBox(height: 12),
              _InfoField(label: 'BRANCH', value: _detail.branch),
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
          // Map grid pattern
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
                      color: AppColors.primary, size: 28),
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

  Widget _buildTimelineTab() {
    final detailAsync = ref.watch(leadDetailProvider(widget.lead.id));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: detailAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => _buildTimelineError(e),
        data: (detail) {
          final activities = detail.activities;
          if (activities.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No activity yet for this lead.',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic),
                ),
              ),
            );
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
                                      size: 12,
                                      color: AppColors.textLight),
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

  Widget _buildTimelineError(Object error) {
    final message = error is ApiException
        ? error.message
        : 'Could not load activity timeline.';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.red, size: 34),
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
                  ref.invalidate(leadDetailProvider(widget.lead.id)),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Retry', style: GoogleFonts.poppins(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  /// Picks an icon + color for an activity based on its action code.
  (Color, IconData) _activityConfig(String action) {
    switch (action) {
      case 'created':
        return (AppColors.green, Icons.add_circle_outline_rounded);
      case 'assignment':
        return (AppColors.primary, Icons.assignment_ind_rounded);
      case 'followup_scheduled':
        return (AppColors.leadFunnelContacted, Icons.access_time_rounded);
      case 'note_added':
        return (const Color(0xFFFFB547), Icons.sticky_note_2_outlined);
      case 'priority_changed':
        return (AppColors.red, Icons.local_fire_department_rounded);
      case 'updated':
      case 'edit_lead':
        return (AppColors.primary, Icons.edit_outlined);
      default:
        return (AppColors.textSecondary, Icons.circle_notifications_outlined);
    }
  }

  Widget _buildNotesTab() {
    final detailAsync = ref.watch(leadDetailProvider(widget.lead.id));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: detailAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => _buildTimelineError(e),
        data: (detail) {
          final notes = detail.notes;
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

  Widget _buildNoteCard(LeadNote note) {
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
              const SizedBox(width: 6),
              _TaskActionIcon(
                icon: Icons.delete_outline_rounded,
                color: AppColors.red,
                tooltip: 'Delete note',
                onTap: () => _deleteNote(note),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote(LeadNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete note?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this note?',
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
    if (confirmed == true) {
      _showSnack('Deleted note');
    }
  }

  Widget _buildTasksTab() {
    final detailAsync = ref.watch(leadDetailProvider(widget.lead.id));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: detailAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => _buildTimelineError(e),
        data: (detail) {
          final tasks = detail.tasks;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tabSectionHeader(
                  Icons.task_alt_rounded, 'Tasks', tasks.length,
                  addLabel: 'Add Task', onAdd: () => _showSnack('Add task')),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                _emptyTabState(Icons.assignment_outlined,
                    'No tasks linked to this lead.')
              else
                ...tasks.map(_buildTaskCard),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(LeadTask task) {
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
                    fontSize: 13,
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
                    fontWeight: FontWeight.w600,
                    color: cfg.$1,
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
              if (task.assigneeName != null) ...[
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
              const Spacer(),
              if (task.dueAt != null) ...[
                const Icon(Icons.event_outlined,
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
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 4),
          // Action icons: Done / Edit / Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _TaskActionIcon(
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.green,
                tooltip: 'Mark as done',
                onTap: () => _markTaskDone(task),
              ),
              const SizedBox(width: 4),
              _TaskActionIcon(
                icon: Icons.edit_outlined,
                color: AppColors.primary,
                tooltip: 'Edit task',
                onTap: () => _editTask(task),
              ),
              const SizedBox(width: 4),
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
    );
  }

  void _markTaskDone(LeadTask task) {
    _showSnack('Marked "${task.title}" as done');
  }

  void _editTask(LeadTask task) {
    _showSnack('Edit "${task.title}"');
  }

  Future<void> _deleteTask(LeadTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    if (confirmed == true) {
      _showSnack('Deleted "${task.title}"');
    }
  }

  /// Header row used by the Notes/Tasks tabs (title + count + add button).
  Widget _tabSectionHeader(IconData icon, String title, int count,
      {required String addLabel, required VoidCallback onAdd}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          '$title ($count)',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.add, color: AppColors.primary, size: 14),
                const SizedBox(width: 4),
                Text(
                  addLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.primary,
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

  Widget _emptyTabState(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
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
    );
  }

  /// (color, label) for a task status string.
  (Color, String) _taskStatusConfig(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return (AppColors.primary, 'OPEN');
      case 'in_progress':
        return (AppColors.leadFunnelContacted, 'IN PROGRESS');
      case 'completed':
      case 'done':
        return (AppColors.green, 'DONE');
      case 'backlog':
        return (AppColors.red, 'BACKLOG');
      default:
        return (AppColors.textSecondary, (status ?? 'TASK').toUpperCase());
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  Widget _statusChip(LeadStatus s) {
    final cfg = _statusConfig(s);
    return _Chip(label: cfg.$2, color: cfg.$1);
  }

  Widget _sourceChip(LeadSource s) {
    final cfg = _sourceConfig(s);
    return _Chip(label: cfg.$2, color: cfg.$1, icon: cfg.$3);
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

  (Color, String, IconData) _sourceConfig(LeadSource s) {
    switch (s) {
      case LeadSource.facebook:
        return (
          const Color(0xFF1877F2),
          'FACEBOOK',
          Icons.facebook_rounded
        );
      case LeadSource.manual:
        return (AppColors.accent, 'MANUAL', Icons.edit_rounded);
      case LeadSource.referral:
        return (
          AppColors.leadFunnelQualified,
          'REFERRAL',
          Icons.people_outline_rounded
        );
      case LeadSource.email:
        return (
          AppColors.leadFunnelContacted,
          'EMAIL',
          Icons.mail_outline_rounded
        );
      case LeadSource.website:
        return (AppColors.primary, 'WEBSITE', Icons.language_rounded);
      case LeadSource.cold:
        return (AppColors.textSecondary, 'COLD CALL', Icons.phone_outlined);
    }
  }

  String _sourceLabel(LeadSource s) => _sourceConfig(s).$2;

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          _MenuItem(Icons.edit_rounded, 'Edit Lead', AppColors.primary),
          _MenuItem(Icons.person_add_outlined, 'Reassign', AppColors.green),
          _MenuItem(Icons.archive_outlined, 'Archive', AppColors.textSecondary),
          _MenuItem(Icons.delete_outline_rounded, 'Delete Lead', AppColors.red),
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
          _MenuItem(Icons.task_alt_rounded, 'Add Task', AppColors.primary),
          _MenuItem(Icons.sticky_note_2_outlined, 'Add Note', AppColors.green),
          _MenuItem(
              Icons.calendar_month_rounded, 'Schedule Follow-up', AppColors.leadFunnelContacted),
        ],
        onSelected: (label) => _showSnack(label),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7) return '${diff.inDays ~/ 7}w ago';
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return 'just now';
  }

  String _fmtDate(DateTime dt) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $h:$min $ampm';
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

/// Small circular icon button used for per-task actions (done/edit/delete).
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
                      color: isLink ? AppColors.primary : AppColors.textPrimary,
                      fontWeight:
                          isLink ? FontWeight.w600 : FontWeight.w500,
                      decoration: isLink
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: AppColors.primary,
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
            color: value != null
                ? AppColors.textPrimary
                : AppColors.textLight,
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
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
