import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/AppColors.dart';
import '../../../routes/app_routes.dart';
import '../data/leads_repository.dart';
import '../model/lead_model.dart';
import '../provider/lead_detail_provider.dart';
import '../provider/leads_provider.dart';
import '../provider/assign_providers.dart';
import '../../Opportunities/model/opportunity_model.dart';
import '../../Opportunities/provider/opportunities_provider.dart';
import '../../calls/provider/call_providers.dart';
import '../../calls/widget/lead_call_logs_card.dart';

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

  /// The display lead, held in Riverpod ([leadViewProvider]) so follow-up edits
  /// and server-loaded values flow through state management — not `setState`.
  /// Falls back to the navigation lead until the provider is seeded.
  LeadModel get _lead =>
      ref.read(leadViewProvider(widget.lead.id)) ?? widget.lead;

  // Provider keyed by this lead's id, seeded with the temperature derived from
  // the lead's `priority` (cold/warm/hot) and the status id from the lead.
  // Seed values come from `widget.lead` (immutable) so the family key is stable.
  LeadDetailControllerProvider get _detailProvider =>
      leadDetailControllerProvider(
        widget.lead.id,
        initialTemperature:
            _temperatureFromPriority(widget.lead.priority) ??
                LeadTemperature.warm,
        initialStatusId: widget.lead.statusId ?? widget.lead.status.statusId,
      );

  static const List<Color> _avatarColors = [
    Color(0xFF4B3FC7),
    Color(0xFF2DD4A0),
    Color(0xFF3B82F6), // was red (0xFFFF4D6A) — red removed from avatar palette
    Color(0xFFFFB547),
    Color(0xFF7B72E9),
    Color(0xFF4CAF9A),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _detail = LeadDetailModel.fromLead(widget.lead);
    // Seed the Riverpod-held display lead from the navigation lead (once).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(leadViewProvider(widget.lead.id).notifier).seed(widget.lead);
      // Tie this lead's numbers to it for the resume-sync, so a call the user
      // places by copying the number into the dialer (or one the lead makes to
      // them) is still captured — the in-app Call button is not the only path.
      ref.read(callSyncControllerProvider.notifier).watchNumbers(
        [widget.lead.phone, widget.lead.alternatePhone],
        leadId: widget.lead.id,
      );
    });
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

  Color get _avatarColor => _fromBacklog
      ? AppColors.red
      : _avatarColors[widget.lead.avatarColorIndex % _avatarColors.length];

  /// Whether this screen was opened from the Backlog Leads view. The backlog
  /// state persists on [leadsFilterProvider], so we capture it once at open
  /// time and tint the screen red (matching the backlog list) instead of the
  /// normal blue accent.
  late final bool _fromBacklog =
      ref.read(leadsFilterProvider).showBacklog;

  /// The screen's brand accent: red from the backlog, blue otherwise.
  Color get _accent => _fromBacklog ? AppColors.red : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    // Seed the header from the server-authoritative lead once it loads, so
    // follow-up fields the list endpoint omits (e.g. next_action,
    // interest_score) show up. Optimistic edits from scheduling still win since
    // this only fires when the fetched value changes.
    ref.listen<AsyncValue<LeadModel>>(
      leadFullProvider(widget.lead.id),
      (prev, next) {
        final full = next.asData?.value;
        if (full == null) return;
        // Merge server-authoritative follow-up fields into the held lead.
        ref
            .read(leadViewProvider(widget.lead.id).notifier)
            .applyServerFollowUp(full);
        // Reflect the authoritative status from the detail endpoint (no API).
        if (full.statusId != null) {
          ref.read(_detailProvider.notifier).seedStatusId(full.statusId!);
        }
      },
    );
    // Subscribe so the screen rebuilds when the held lead changes.
    ref.watch(leadViewProvider(widget.lead.id));
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

  /// Parses a `#rrggbb` (or `#aarrggbb`) hex string into a [Color], falling
  /// back to the app primary when missing/invalid.
  Color _hexColor(String? hex) {
    if (hex == null) return AppColors.primary;
    var h = hex.replaceAll('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    final value = int.tryParse(h, radix: 16);
    return value == null ? AppColors.primary : Color(value);
  }

  // Status chip/menu shown on the top bar (header) right side, driven by
  // GET /statuses. The selected status id lives in the detail controller state.
  Widget _buildStatusDropdown() {
    final statuses =
        ref.watch(leadStatusesProvider).asData?.value ?? const <StatusOption>[];
    final statusId = ref.watch(_detailProvider.select((s) => s.statusId));

    StatusOption? current;
    for (final s in statuses) {
      if (s.id == statusId) {
        current = s;
        break;
      }
    }

    final color = _hexColor(current?.colorHex);
    final label = current?.name ?? 'Status';

    // While the options load (or none match), show a static chip.
    if (statuses.isEmpty) {
      return Container(
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
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return PopupMenuButton<int>(
      tooltip: 'Change status',
      offset: const Offset(0, 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.cardBackground,
      onSelected: _changeStatus,
      itemBuilder: (_) => statuses.map((s) {
        final c = _hexColor(s.colorHex);
        final selected = s.id == statusId;
        return PopupMenuItem<int>(
          value: s.id,
          height: 42,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(
                s.name,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (selected) Icon(Icons.check_rounded, size: 16, color: c),
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
              label,
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

  /// Persists a status change via the controller, showing an error and
  /// reverting (handled in the controller) if the API call fails.
  Future<void> _changeStatus(int id) async {
    final ok = await ref.read(_detailProvider.notifier).setStatusId(id);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update status',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ── Hero Card ────────────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    final lead = _lead;
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
                          Icon(Icons.track_changes_rounded,
                              size: 13, color: _accent),
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
                    onTap: () async {
                      final ok = await ref
                          .read(_detailProvider.notifier)
                          .setTemperature(t);
                      if (!ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Could not update priority'),
                            backgroundColor: AppColors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
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
              onPressed: converted ? null : _showConvertSheet,
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

  /// Opens the convert popup (expected value + probability). On a successful
  /// API conversion, mirrors the opportunity into the local store, marks the
  /// lead converted, and navigates to the Opportunities screen.
  Future<void> _showConvertSheet() async {
    final result = await showModalBottomSheet<({double expectedValue, int probability})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConvertSheet(
        leadId: _lead.id,
        initialValue: _lead.dealValue,
      ),
    );
    if (result == null || !mounted) return;
    _onConverted(result.expectedValue, result.probability);
  }

  void _onConverted(double expectedValue, int probability) {
    final lead = widget.lead;
    final opp = OpportunityModel(
      id: 'OPP-${lead.id}',
      leadId: lead.id,
      title: lead.companyName != null
          ? '${lead.companyName} Deal'
          : '${lead.contactName} Opportunity',
      contactName: lead.contactName,
      value: expectedValue,
      probability: probability,
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
  String? get _phoneDigits => _digits(_lead.phone);

  /// Dials an arbitrary number (used by the primary and alternate phone).
  Future<void> _callNumber(String? raw) async {
    final phone = _digits(raw);
    if (phone == null) return _showSnack('No phone number for this lead.');
    // Tag this call with the lead so the captured call-log entry links back to
    // it (the resume-sync uploads it once the user returns from the dialer).
    await ref.read(callSyncControllerProvider.notifier).recordDirectCall(
          number: phone,
          leadId: widget.lead.id,
        );
    await _launch(Uri(scheme: 'tel', path: phone), 'phone dialer');
  }

  Future<void> _callLead() => _callNumber(_lead.phone);

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
    final email = _lead.email;
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
    final lead = _lead;
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
            copyValue: lead.phone,
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
              copyValue: lead.alternatePhone,
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
          // Assigned To — shows every assignee when the lead has more than one.
          _ContactRow(
            icon: Icons.person_pin_rounded,
            iconBg: AppColors.green.withOpacity(0.1),
            iconColor: AppColors.green,
            label: 'Assigned To',
            value: lead.assigneeNames.isNotEmpty
                ? lead.assigneeNames.join(', ')
                : (lead.assigneeName ?? _detail.assignedToName ?? '—'),
            subValue: lead.assigneeNames.length > 1
                ? '${lead.assigneeNames.length} assignees'
                : (lead.assigneeDesignation ?? _detail.assignedToRole),
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

  /// Resolves a display label: the stored [name] when present, otherwise the
  /// option whose id matches [id] in [options] (so a lead that only carries
  /// `*_id` from the API still shows a readable label).
  String? _resolveLookupName(
      List<NamedLookup> options, int? id, String? name) {
    if (name != null && name.isNotEmpty) return name;
    if (id == null) return null;
    for (final o in options) {
      if (o.id == id) return o.name;
    }
    return null;
  }

  Widget _buildFollowUpBanner() {
    final months = [
      'JAN','FEB','MAR','APR','MAY','JUN',
      'JUL','AUG','SEP','OCT','NOV','DEC'
    ];
    // Resolve Current Update / Next Action labels from their option lists when
    // the lead only carries the id (the detail API may omit the name).
    final updateOpts =
        ref.watch(currentUpdatesProvider).asData?.value ?? const <NamedLookup>[];
    final actionOpts =
        ref.watch(nextActionsProvider).asData?.value ?? const <NamedLookup>[];
    final currentUpdateLabel = _resolveLookupName(
        updateOpts, _lead.currentUpdateId, _lead.currentUpdate);
    final nextActionLabel =
        _resolveLookupName(actionOpts, _lead.nextActionId, _lead.nextAction);
    final dt = _lead.nextFollowUp;
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
          if (currentUpdateLabel != null) ...[
            const SizedBox(height: 10),
            _followUpRow(
                Icons.update_rounded, 'Current Update', currentUpdateLabel),
          ],
          if (nextActionLabel != null) ...[
            const SizedBox(height: 8),
            _followUpRow(Icons.bolt_rounded, 'Next Action', nextActionLabel),
          ],
          if (_lead.followupRemarks != null &&
              _lead.followupRemarks!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _followUpRow(Icons.notes_rounded, 'Remarks',
                _lead.followupRemarks!),
          ],
          // Interest Score (shown only when a non-zero score is set).
          if (_lead.interestScore != null && _lead.interestScore! > 0) ...[
            const SizedBox(height: 10),
            _buildInterestScore(_lead.interestScore!),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _showScheduleFollowUpSheet,
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

  /// Interest-score row inside the follow-up banner: a label, a colour-coded
  /// percentage badge, and a thin progress bar.
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
            Icon(Icons.percent_rounded, size: 14, color: AppColors.primary),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
    final tabs = ['Information', 'Timeline', 'Notes', 'Tasks', 'Calls'];
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
          case 4:
            return _buildCallHistoryTab();
          default:
            return _buildInformationTab();
        }
      },
    );
  }

  Widget _buildCallHistoryTab() {
    // CRM-recorded calls from the lead detail's `call_logs` — shown for
    // everyone, no device permission required.
    return LeadCallLogsCard(leadId: widget.lead.id);
  }

  Widget _buildInformationTab() {
    // Prefer the lead's own values (kept current by the Edit-Lead form and the
    // detail fetch), falling back to the placeholder detail model.
    final description = _lead.description ?? _detail.description;
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
                description ?? 'No description provided for this lead record.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: description != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontStyle: description != null
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
                  value: _lead.designation ?? _detail.designation),
              const SizedBox(height: 12),
              _InfoField(
                  label: 'WEBSITE', value: _lead.website ?? _detail.website),
              const SizedBox(height: 12),
              _InfoField(
                  label: 'ALT PHONE',
                  value: _lead.alternatePhone ?? _detail.altPhone),
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
              _InfoField(
                  label: 'LEAD TYPE',
                  value: _lead.leadTypeName ?? _detail.leadType),
              const SizedBox(height: 12),
              _InfoField(
                  label: 'TERRITORY',
                  value: _lead.territoryName ?? _detail.territory),
              const SizedBox(height: 12),
              _InfoField(
                  label: 'BRANCH', value: _lead.branchName ?? _detail.branch),
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

  /// Opens the add-note sheet; shows a confirmation once a note is added (the
  /// notes list refreshes itself via the provider).
  Future<void> _showAddNoteSheet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddNoteSheet(leadId: _lead.id),
    );
    if (added == true && mounted) _showSnack('Note added');
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
                  addLabel: 'Add Note', onAdd: _showAddNoteSheet),
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

  /// Opens the add-task sheet; shows a confirmation once a task is added (the
  /// tasks list refreshes itself via the provider).
  Future<void> _showAddTaskSheet() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTaskSheet(leadId: _lead.id),
    );
    if (added == true && mounted) _showSnack('Task added');
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
                  addLabel: 'Add Task', onAdd: _showAddTaskSheet),
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
          _MenuItem(Icons.person_add_outlined, 'Assign Lead', AppColors.green),
          _MenuItem(Icons.archive_outlined, 'Archive', AppColors.textSecondary),
          _MenuItem(Icons.delete_outline_rounded, 'Delete Lead', AppColors.red),
        ],
        onSelected: (label) {
          if (label == 'Assign Lead') {
            _showAssignLeadSheet();
          } else if (label == 'Edit Lead') {
            _openEditLead();
          } else {
            _showSnack(label);
          }
        },
      ),
    );
  }

  /// Opens the full-screen Edit-Lead form. It saves via `PUT /leads/{id}` and
  /// pushes the result into [leadViewProvider] itself, so on return this screen
  /// already shows the edit — there is nothing to apply here.
  Future<void> _openEditLead() async {
    final saved = await context.push<bool>(AppRoutes.editLead, extra: _lead);
    if (saved == true && mounted) _showSnack('Lead updated');
  }

  /// Opens the "Assign Lead" popup. Routes the lead to one or more users
  /// (optionally scoped to a territory/branch) via `POST /leads/{id}/assign`.
  /// On success, refreshes the timeline and the leads list.
  Future<void> _showAssignLeadSheet() async {
    final assigned = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignLeadSheet(leadId: _lead.id),
    );
    if (assigned != true || !mounted) return;
    // Reload the timeline (a new assignment activity) and the list card.
    ref.invalidate(leadDetailProvider(_lead.id));
    ref.read(leadsListProvider.notifier).refresh();
    _showSnack('Lead assigned successfully');
  }

  /// Opens the "Schedule Next Follow-up" popup. Pre-fills its fields from the
  /// lead's current follow-up data. The sheet persists via the API itself and
  /// only pops with a result on success, so here we just refresh the timeline
  /// and confirm.
  Future<void> _showScheduleFollowUpSheet() async {
    final result = await showModalBottomSheet<FollowUpFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleFollowUpSheet(
        leadId: _lead.id,
        initialCurrentUpdate: _lead.currentUpdate,
        initialNextAction: _lead.nextAction,
        initialCurrentUpdateId: _lead.currentUpdateId,
        initialNextActionId: _lead.nextActionId,
        initialRemark: _lead.followupRemarks,
        initialDate: _lead.nextFollowUp,
      ),
    );
    if (result == null || !mounted) return;

    // Instantly reflect the new follow-up on this screen via Riverpod…
    ref.read(leadViewProvider(widget.lead.id).notifier).applyFollowUp(
          nextFollowUp: result.scheduleDate,
          currentUpdate: result.currentUpdate,
          nextAction: result.nextAction,
          followupRemarks: result.nextRemark,
          currentUpdateId: result.currentUpdateId,
          nextActionId: result.nextActionId,
          interestScore: result.score,
        );
    // …and patch it in the leads list so it's updated on return.
    ref.read(leadsListProvider.notifier).updateFollowUp(
          _lead.id,
          nextFollowUp: result.scheduleDate,
          currentUpdate: result.currentUpdate,
          nextAction: result.nextAction,
          followupRemarks: result.nextRemark,
          currentUpdateId: result.currentUpdateId,
          nextActionId: result.nextActionId,
          interestScore: result.score,
        );
    // Reload the activity timeline so the new follow-up entry shows up.
    ref.invalidate(leadDetailProvider(_lead.id));
    _showSnack('Follow-up scheduled for ${_fmtDate(result.scheduleDate)}');
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

  /// When non-null, shows a copy button that copies this text to the clipboard
  /// (used for the phone rows so the number can be copied without dialing).
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

// ── Schedule Follow-up Sheet ──────────────────────────────────────────────────

/// The values collected by the "Schedule Next Follow-up" popup, returned to the
/// caller via `Navigator.pop` when the user taps Save.
class FollowUpFormResult {
  final int? currentUpdateId;
  final String? currentUpdate;
  final int? nextActionId;
  final String? nextAction;
  final String? nextRemark;
  final DateTime scheduleDate;
  final int score;

  const FollowUpFormResult({
    required this.currentUpdateId,
    required this.currentUpdate,
    required this.nextActionId,
    required this.nextAction,
    required this.nextRemark,
    required this.scheduleDate,
    required this.score,
  });
}

/// Bottom-sheet form to schedule the next follow-up for a lead. Holds its own
/// local form state and returns a [FollowUpFormResult] when saved.
class _ScheduleFollowUpSheet extends ConsumerStatefulWidget {
  final String leadId;
  final String? initialCurrentUpdate;
  final String? initialNextAction;
  final int? initialCurrentUpdateId;
  final int? initialNextActionId;
  final String? initialRemark;
  final DateTime initialDate;

  const _ScheduleFollowUpSheet({
    required this.leadId,
    this.initialCurrentUpdate,
    this.initialNextAction,
    this.initialCurrentUpdateId,
    this.initialNextActionId,
    this.initialRemark,
    required this.initialDate,
  });

  @override
  ConsumerState<_ScheduleFollowUpSheet> createState() =>
      _ScheduleFollowUpSheetState();
}

class _ScheduleFollowUpSheetState
    extends ConsumerState<_ScheduleFollowUpSheet> {
  // Both "Current Update" and "Next Action" options are fetched from the API.
  static const List<String> _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  late final TextEditingController _remarkCtrl;

  /// The Riverpod notifier for this sheet's form state.
  FollowUpForm get _form =>
      ref.read(followUpFormProvider(widget.leadId).notifier);

  /// The current form state (read, no subscription).
  FollowUpFormState get _state =>
      ref.read(followUpFormProvider(widget.leadId));

  @override
  void initState() {
    super.initState();
    _remarkCtrl = TextEditingController(text: widget.initialRemark ?? '');
  }

  @override
  void dispose() {
    _remarkCtrl.dispose();
    super.dispose();
  }

  /// The currently-selected Current Update: the form value, or — if untouched —
  /// the option matching the lead's existing value.
  NamedLookup? _effectiveUpdate(List<NamedLookup> options) =>
      _state.currentUpdate ??
      _matchOption(options, widget.initialCurrentUpdateId,
          widget.initialCurrentUpdate);

  NamedLookup? _effectiveAction(List<NamedLookup> options) =>
      _state.nextAction ??
      _matchOption(
          options, widget.initialNextActionId, widget.initialNextAction);

  DateTime get _effectiveDate => _state.scheduleDate ?? widget.initialDate;

  /// Finds the option matching [id] (preferred) or [name]; null if none.
  NamedLookup? _matchOption(
      List<NamedLookup> options, int? id, String? name) {
    for (final o in options) {
      if (id != null && o.id == id) return o;
    }
    if (name != null) {
      for (final o in options) {
        if (o.name == name) return o;
      }
    }
    return null;
  }

  /// Colour for the score bar/label: red <40, amber <70, green otherwise.
  Color _scoreColor(double score) {
    if (score < 40) return AppColors.red;
    if (score < 70) return const Color(0xFFFFB547);
    return AppColors.green;
  }

  String _dateLabel(DateTime d) {
    final h = d.hour > 12
        ? d.hour - 12
        : d.hour == 0
            ? 12
            : d.hour;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final min = d.minute.toString().padLeft(2, '0');
    return '${_months[d.month - 1]} ${d.day}, ${d.year} · $h:$min $ampm';
  }

  /// `next_followup_at` in the API's `yyyy-MM-dd HH:mm:ss` format.
  String _apiDateTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  /// Themes the date/time pickers to match the app palette.
  Widget _pickerTheme(BuildContext ctx, Widget? child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      );

  /// Picks a date, then a time, and stores them via the form notifier.
  Future<void> _pickDate() async {
    final current = _effectiveDate;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: _pickerTheme,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      builder: _pickerTheme,
    );
    _form.setScheduleDate(DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? current.hour,
      time?.minute ?? current.minute,
    ));
  }

  /// Persists the follow-up via `POST /leads/{id}/followup`. Keeps the sheet
  /// open on error, and pops with the result on success.
  Future<void> _submit() async {
    if (_state.saving) return;

    // Resolve the effective selections/date/score from the form state.
    final updateOptions =
        ref.read(currentUpdatesProvider).asData?.value ?? const <NamedLookup>[];
    final actionOptions =
        ref.read(nextActionsProvider).asData?.value ?? const <NamedLookup>[];
    final selectedUpdate = _effectiveUpdate(updateOptions);
    final selectedAction = _effectiveAction(actionOptions);
    final scheduleDate = _effectiveDate;
    final score = _state.score.round();

    _form.setSaving(true);
    final result =
        await ref.read(leadsRepositoryProvider).scheduleFollowUp(
              widget.leadId,
              currentUpdateId: selectedUpdate?.id,
              nextActionId: selectedAction?.id,
              followupRemarks: _remarkCtrl.text.trim(),
              nextFollowUpAt: _apiDateTime(scheduleDate),
              interestScore: score,
            );
    if (!mounted) return;

    result.when(
      success: (_) {
        Navigator.pop(
          context,
          FollowUpFormResult(
            currentUpdateId: selectedUpdate?.id,
            currentUpdate: selectedUpdate?.name,
            nextActionId: selectedAction?.id,
            nextAction: selectedAction?.name,
            nextRemark: _remarkCtrl.text.trim().isEmpty
                ? null
                : _remarkCtrl.text.trim(),
            scheduleDate: scheduleDate,
            score: score,
          ),
        );
      },
      failure: (error) {
        _form.setSaving(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.message,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pad the sheet above the keyboard when the remark field is focused.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    // Form state (selections, date, score, saving) from Riverpod.
    final form = ref.watch(followUpFormProvider(widget.leadId));
    // "Current Update" options from GET /current-updates.
    final updatesAsync = ref.watch(currentUpdatesProvider);
    final updateOptions = updatesAsync.asData?.value ?? const <NamedLookup>[];
    final updateHint = updatesAsync.isLoading
        ? 'Loading updates…'
        : updatesAsync.hasError
            ? 'Could not load updates'
            : 'Select current update';
    // "Next Action" options from GET /next-actions.
    final actionsAsync = ref.watch(nextActionsProvider);
    final actionOptions = actionsAsync.asData?.value ?? const <NamedLookup>[];
    final actionHint = actionsAsync.isLoading
        ? 'Loading actions…'
        : actionsAsync.hasError
            ? 'Could not load actions'
            : 'Select next action';
    // Effective values: form selection, or fall back to the lead's existing.
    final selectedUpdate = form.currentUpdate ??
        _matchOption(updateOptions, widget.initialCurrentUpdateId,
            widget.initialCurrentUpdate);
    final selectedAction = form.nextAction ??
        _matchOption(actionOptions, widget.initialNextActionId,
            widget.initialNextAction);
    final scheduleDate = form.scheduleDate ?? widget.initialDate;
    final score = form.score;
    final scoreColor = _scoreColor(score);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.event_available_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule Follow-up',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Update progress and plan the next step',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Scrollable form body
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Update (dropdown, fetched from the API)
                    _FieldLabel('Current Update', Icons.update_rounded),
                    const SizedBox(height: 8),
                    _SheetDropdown<NamedLookup>(
                      hint: updateHint,
                      value: selectedUpdate,
                      options: updateOptions,
                      labelOf: (o) => o.name,
                      onChanged: _form.setCurrentUpdate,
                    ),
                    const SizedBox(height: 18),
                    // Next Remark (text field)
                    _FieldLabel('Next Remark', Icons.notes_rounded),
                    const SizedBox(height: 8),
                    _SheetTextField(
                      controller: _remarkCtrl,
                      hint: 'Add a remark for the next follow-up…',
                    ),
                    const SizedBox(height: 18),
                    // Next Action (dropdown, fetched from the API)
                    _FieldLabel('Next Action', Icons.bolt_rounded),
                    const SizedBox(height: 8),
                    _SheetDropdown<NamedLookup>(
                      hint: actionHint,
                      value: selectedAction,
                      options: actionOptions,
                      labelOf: (o) => o.name,
                      onChanged: _form.setNextAction,
                    ),
                    const SizedBox(height: 18),
                    // Schedule Date (picker)
                    _FieldLabel('Schedule Date', Icons.calendar_month_rounded),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.divider, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_rounded,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Text(
                              _dateLabel(scheduleDate),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Score (%) slider
                    Row(
                      children: [
                        _FieldLabel('Score', Icons.percent_rounded),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: scoreColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${score.round()}%',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: scoreColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: score / 100,
                        minHeight: 8,
                        backgroundColor: AppColors.divider,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: scoreColor,
                        inactiveTrackColor: AppColors.divider,
                        thumbColor: scoreColor,
                        overlayColor: scoreColor.withOpacity(0.15),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: score,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        onChanged: _form.setScore,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Save button (pinned to the bottom)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: form.saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withOpacity(0.6),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: form.saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 19),
                  label: Text(
                    form.saving ? 'Scheduling…' : 'Schedule Follow-up',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small label row (icon + text) used above each field in the follow-up sheet.
class _FieldLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  const _FieldLabel(this.text, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Styled dropdown matching the sheet's design language. Generic over the
/// option type [T]; [labelOf] maps an option to its display text.
class _SheetDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  const _SheetDropdown({
    required this.hint,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(
            hint,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          dropdownColor: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          items: options
              .map((o) => DropdownMenuItem<T>(
                    value: o,
                    child: Text(labelOf(o)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Styled multiline text field used for the "Next Remark" input.
class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _SheetTextField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      minLines: 2,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textLight,
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.divider, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.divider, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
    );
  }
}

// ── Add Note Sheet ────────────────────────────────────────────────────────────

/// Bottom sheet to add a note to a lead (`POST /leads/{id}/notes`). The saving
/// state is Riverpod-managed ([addNoteProvider]); the text field uses a local
/// controller. Pops `true` when the note is saved.
class _AddNoteSheet extends ConsumerStatefulWidget {
  final String leadId;
  const _AddNoteSheet({required this.leadId});

  @override
  ConsumerState<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends ConsumerState<_AddNoteSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok =
        await ref.read(addNoteProvider(widget.leadId).notifier).submit(_ctrl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else if (_ctrl.text.trim().isNotEmpty) {
      // Non-empty content but the request failed.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not add note',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(addNoteProvider(widget.leadId));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
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
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sticky_note_2_outlined,
                      color: AppColors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add Note',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _FieldLabel('Note', Icons.notes_rounded),
            const SizedBox(height: 8),
            _SheetTextField(
              controller: _ctrl,
              hint: 'Write a note about this lead…',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 19),
                label: Text(
                  saving ? 'Saving…' : 'Add Note',
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
}

// ── Add Task Sheet ────────────────────────────────────────────────────────────

/// Bottom sheet to add a task to a lead (`POST /leads/{id}/tasks`): a title, a
/// due date+time picker, and a priority dropdown. Form state (due date,
/// priority, saving) is Riverpod-managed ([addTaskProvider]); the title uses a
/// local controller. Pops `true` when the task is saved.
class _AddTaskSheet extends ConsumerStatefulWidget {
  final String leadId;
  const _AddTaskSheet({required this.leadId});

  @override
  ConsumerState<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<_AddTaskSheet> {
  static const List<String> _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  static const List<String> _priorities = ['high', 'medium', 'low'];

  late final TextEditingController _ctrl;

  AddTask get _form => ref.read(addTaskProvider(widget.leadId).notifier);

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _dateLabel(DateTime d) {
    final h = d.hour > 12
        ? d.hour - 12
        : d.hour == 0
            ? 12
            : d.hour;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final min = d.minute.toString().padLeft(2, '0');
    return '${_months[d.month - 1]} ${d.day}, ${d.year} · $h:$min $ampm';
  }

  Widget _pickerTheme(BuildContext ctx, Widget? child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      );

  Future<void> _pickDue() async {
    final current = ref.read(addTaskProvider(widget.leadId)).dueAt ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: _pickerTheme,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      builder: _pickerTheme,
    );
    _form.setDueAt(DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? current.hour,
      time?.minute ?? current.minute,
    ));
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submit() async {
    final state = ref.read(addTaskProvider(widget.leadId));
    if (_ctrl.text.trim().isEmpty) return _error('Enter a task title');
    if (state.dueAt == null) return _error('Pick a due date & time');

    final ok = await _form.submit(_ctrl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      _error('Could not add task');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addTaskProvider(widget.leadId));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.task_alt_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add Task',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const _FieldLabel('Title', Icons.title_rounded),
                    const SizedBox(height: 8),
                    _SheetTextField(
                      controller: _ctrl,
                      hint: 'e.g. Send Quotation',
                    ),
                    const SizedBox(height: 18),
                    // Due date + time
                    const _FieldLabel(
                        'Due Date & Time', Icons.event_rounded),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDue,
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.divider, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Text(
                              state.dueAt == null
                                  ? 'Select due date & time'
                                  : _dateLabel(state.dueAt!),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: state.dueAt == null
                                    ? AppColors.textLight
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Priority
                    const _FieldLabel('Priority', Icons.flag_rounded),
                    const SizedBox(height: 8),
                    _SheetDropdown<String>(
                      hint: 'Select priority',
                      value: state.priority,
                      options: _priorities,
                      labelOf: (p) =>
                          '${p[0].toUpperCase()}${p.substring(1)}',
                      onChanged: (v) {
                        if (v != null) _form.setPriority(v);
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: state.saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: state.saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 19),
                  label: Text(
                    state.saving ? 'Saving…' : 'Add Task',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Convert to Opportunity Sheet ──────────────────────────────────────────────

/// Bottom sheet to convert a lead to an opportunity (`POST /leads/{id}/convert`):
/// an expected value field and a probability slider. Form state (probability,
/// saving) is Riverpod-managed ([convertLeadProvider]); the value field uses a
/// local controller. Pops `(expectedValue, probability)` on success.
class _ConvertSheet extends ConsumerStatefulWidget {
  final String leadId;
  final double? initialValue;
  const _ConvertSheet({required this.leadId, this.initialValue});

  @override
  ConsumerState<_ConvertSheet> createState() => _ConvertSheetState();
}

class _ConvertSheetState extends ConsumerState<_ConvertSheet> {
  late final TextEditingController _valueCtrl;

  ConvertLead get _form => ref.read(convertLeadProvider(widget.leadId).notifier);

  @override
  void initState() {
    super.initState();
    _valueCtrl = TextEditingController(
      text: (widget.initialValue != null && widget.initialValue! > 0)
          ? widget.initialValue!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  Color _probColor(double p) {
    if (p < 40) return AppColors.red;
    if (p < 70) return const Color(0xFFFFB547);
    return AppColors.green;
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submit() async {
    final value = double.tryParse(_valueCtrl.text.trim().replaceAll(',', ''));
    if (value == null || value <= 0) {
      return _error('Enter a valid expected value');
    }
    final probability = ref.read(convertLeadProvider(widget.leadId)).probability;
    final ok = await _form.submit(value);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(
        context,
        (expectedValue: value, probability: probability.round()),
      );
    } else {
      _error('Could not convert lead');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(convertLeadProvider(widget.leadId));
    final probColor = _probColor(state.probability);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
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
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.swap_horiz_rounded,
                      color: AppColors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Convert to Opportunity',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Set the deal value and win probability',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Expected Value
            const _FieldLabel('Expected Value', Icons.attach_money_rounded),
            const SizedBox(height: 8),
            TextField(
              controller: _valueCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: GoogleFonts.poppins(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. 50000',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 14, color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.background,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.divider, width: 0.8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.divider, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Probability slider
            Row(
              children: [
                const _FieldLabel('Probability', Icons.percent_rounded),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: probColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${state.probability.round()}%',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: probColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: state.probability / 100,
                minHeight: 8,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(probColor),
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: probColor,
                inactiveTrackColor: AppColors.divider,
                thumbColor: probColor,
                overlayColor: probColor.withOpacity(0.15),
                trackHeight: 4,
              ),
              child: Slider(
                value: state.probability,
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: _form.setProbability,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: state.saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  disabledBackgroundColor: AppColors.green.withOpacity(0.6),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: state.saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 19),
                label: Text(
                  state.saving ? 'Converting…' : 'Convert',
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

// ── Assign Lead Sheet ─────────────────────────────────────────────────────────

/// Bottom sheet to assign a lead to one or more users, optionally scoped to a
/// territory/branch, with a remark and a privacy flag. Persists via
/// `POST /leads/{id}/assign` and pops `true` on success. Assignees are
/// mandatory.
class _AssignLeadSheet extends ConsumerStatefulWidget {
  final String leadId;
  const _AssignLeadSheet({required this.leadId});

  @override
  ConsumerState<_AssignLeadSheet> createState() => _AssignLeadSheetState();
}

class _AssignLeadSheetState extends ConsumerState<_AssignLeadSheet> {
  final TextEditingController _remarksCtrl = TextEditingController();

  /// The form's state lives in Riverpod — see [assignLeadFormProvider].
  AssignLeadFormState get _form =>
      ref.watch(assignLeadFormProvider(widget.leadId));
  AssignLeadForm get _formNotifier =>
      ref.read(assignLeadFormProvider(widget.leadId).notifier);

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  /// Assigns the lead via `POST /leads/{id}/assign`. Keeps the sheet open on
  /// error and pops `true` on success.
  Future<void> _submit() async {
    final form = ref.read(assignLeadFormProvider(widget.leadId));
    if (form.saving) return;
    if (form.selectedUserIds.isEmpty) {
      _formNotifier.flagAssigneeError();
      _snack('Please select at least one assignee', AppColors.red);
      return;
    }
    _formNotifier.setSaving(true);
    final result = await ref.read(leadsRepositoryProvider).assignLead(
          widget.leadId,
          territoryId: form.territory?.id,
          branchId: form.branch?.id,
          assigneeIds: form.selectedUserIds.toList(),
          remarks: _remarksCtrl.text.trim(),
          isPrivate: form.isPrivate,
        );
    if (!mounted) return;
    result.when(
      success: (_) => Navigator.pop(context, true),
      failure: (error) {
        _formNotifier.setSaving(false);
        _snack(error.message, AppColors.red);
      },
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final form = _form;

    final territoriesAsync = ref.watch(territoriesProvider);
    final territoryOptions =
        territoriesAsync.asData?.value ?? const <NamedLookup>[];
    final territoryHint = territoriesAsync.isLoading
        ? 'Loading territories…'
        : territoriesAsync.hasError
            ? 'Could not load territories'
            : 'Select territory';

    // Branches are territory-scoped: only load them once a territory is picked.
    final hasTerritory = form.territory != null;
    final branchesAsync = hasTerritory
        ? ref.watch(branchesProvider(form.territory!.id))
        : const AsyncValue<List<NamedLookup>>.data(<NamedLookup>[]);
    final branchOptions = branchesAsync.asData?.value ?? const <NamedLookup>[];
    final branchHint = !hasTerritory
        ? 'Select a territory first'
        : branchesAsync.isLoading
            ? 'Loading branches…'
            : branchesAsync.hasError
                ? 'Could not load branches'
                : 'Select branch';

    final usersAsync = ref.watch(assignableUsersProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded,
                        color: AppColors.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assign Lead',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Route this lead to your team',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Scrollable form body
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Territory (optional)
                    _FieldLabel('Territory', Icons.public_rounded),
                    const SizedBox(height: 8),
                    _SheetDropdown<NamedLookup>(
                      hint: territoryHint,
                      value: form.territory,
                      options: territoryOptions,
                      labelOf: (o) => o.name,
                      // The notifier also clears the now-stale branch.
                      onChanged: _formNotifier.setTerritory,
                    ),
                    const SizedBox(height: 18),
                    // Branch (scoped to the selected territory)
                    _FieldLabel('Branch', Icons.apartment_rounded),
                    const SizedBox(height: 8),
                    _SheetDropdown<NamedLookup>(
                      hint: branchHint,
                      value: form.branch,
                      options: branchOptions,
                      labelOf: (o) => o.name,
                      onChanged: _formNotifier.setBranch,
                    ),
                    const SizedBox(height: 18),
                    // Assignees (mandatory, multi-select)
                    Row(
                      children: [
                        _FieldLabel('Assignees', Icons.group_rounded),
                        Text(
                          ' *',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.red,
                          ),
                        ),
                        const Spacer(),
                        if (form.selectedUserIds.isNotEmpty)
                          Text(
                            '${form.selectedUserIds.length} selected',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.green,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildAssigneePicker(usersAsync),
                    if (form.assigneeError && form.selectedUserIds.isEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Select at least one assignee',
                        style: GoogleFonts.poppins(
                            fontSize: 11.5, color: AppColors.red),
                      ),
                    ],
                    const SizedBox(height: 18),
                    // Remarks (optional)
                    _FieldLabel('Remarks', Icons.notes_rounded),
                    const SizedBox(height: 8),
                    _SheetTextField(
                      controller: _remarksCtrl,
                      hint: 'Add a remark for this assignment…',
                    ),
                    const SizedBox(height: 18),
                    // Is Private
                    _buildPrivateToggle(),
                  ],
                ),
              ),
            ),
            // Footer: Cancel + Assign
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed:
                            form.saving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: form.saving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          disabledBackgroundColor:
                              AppColors.green.withOpacity(0.6),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: form.saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 19),
                        label: Text(
                          form.saving ? 'Assigning…' : 'Assign',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The assignee multi-select: loading / error / a wrap of toggleable user
  /// chips. The bordering shell turns red when the form's `assigneeError` is
  /// set.
  Widget _buildAssigneePicker(AsyncValue<List<AssignableUser>> usersAsync) {
    return usersAsync.when(
      loading: () => _pickerShell(
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (_, _) => _pickerShell(
        Row(
          children: [
            Expanded(
              child: Text(
                'Could not load users',
                style:
                    GoogleFonts.poppins(fontSize: 13, color: AppColors.red),
              ),
            ),
            GestureDetector(
              onTap: () => ref.invalidate(assignableUsersProvider),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
      data: (users) {
        if (users.isEmpty) {
          return _pickerShell(
            Text(
              'No users available',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          );
        }
        return _pickerShell(
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final u in users) _userChip(u)],
          ),
        );
      },
    );
  }

  Widget _pickerShell(Widget child) {
    final form = _form;
    final borderColor = (form.assigneeError && form.selectedUserIds.isEmpty)
        ? AppColors.red
        : AppColors.divider;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: child,
    );
  }

  Widget _userChip(AssignableUser u) {
    final selected = _form.selectedUserIds.contains(u.id);
    return GestureDetector(
      onTap: () => _formNotifier.toggleUser(u.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.green.withOpacity(0.12)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.green : AppColors.divider,
            width: selected ? 1.4 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.person_outline_rounded,
              size: 15,
              color: selected ? AppColors.green : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              u.name,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.green : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivateToggle() {
    final isPrivate = _form.isPrivate;
    return GestureDetector(
      onTap: () => _formNotifier.setPrivate(!isPrivate),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isPrivate,
                onChanged: (v) => _formNotifier.setPrivate(v ?? false),
                activeColor: AppColors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Is Private',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Private means this lead is visible only to the assigned '
                    "user. If unchecked, everyone in the assigned user's "
                    'branch can see it.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
