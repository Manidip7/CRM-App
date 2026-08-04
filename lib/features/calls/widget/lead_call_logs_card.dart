import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/AppColors.dart';
import '../../Leads/provider/lead_detail_provider.dart';
import '../model/call_record.dart';
import 'log_call_sheet.dart';

/// Shows a lead's CRM-recorded calls — the `call_logs` array from
/// `GET /leads/{id}` — as a "Call Logs" section on the Lead Details screen.
///
/// Unlike [CallHistoryCard] (device-captured history, gated behind the Android
/// call-log permission), these come straight from the detail response, so they
/// display for everyone. The "Log Call" button writes a new entry through
/// `POST /leads/{id}/call-logs` and refreshes the detail so it appears.
///
/// ```dart
/// LeadCallLogsCard(leadId: lead.id)
/// ```
class LeadCallLogsCard extends ConsumerWidget {
  final String leadId;

  const LeadCallLogsCard({super.key, required this.leadId});

  /// Opens the manual Log-Call sheet. On return it invalidates the lead detail
  /// so a newly-logged call shows in the list.
  Future<void> _openLogCall(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogCallSheet(leadId: leadId),
    );
    ref.invalidate(leadDetailProvider(leadId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(leadDetailProvider(leadId));
    return CallLogsCardFrame(
      count: async.asData?.value.callLogs.length,
      onLogCall: () => _openLogCall(context, ref),
      onRefresh: () => ref.invalidate(leadDetailProvider(leadId)),
      child: async.when(
        loading: () => const CallLogsLoading(),
        error: (e, _) => _buildError(ref, e),
        data: (detail) => CallLogsList(logs: detail.callLogs),
      ),
    );
  }

  Widget _buildError(WidgetRef ref, Object error) {
    final message =
        error is ApiException ? error.message : 'Could not load call logs.';
    return Column(
      children: [
        CallLogsNote(icon: Icons.cloud_off_rounded, text: message),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => ref.invalidate(leadDetailProvider(leadId)),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text('Retry', style: GoogleFonts.poppins(fontSize: 13)),
        ),
      ],
    );
  }
}

/// The card chrome shared by [LeadCallLogsCard] and its opportunity twin: the
/// rounded container, the "Call Logs" heading with its count badge, the
/// "Log Call" button and the refresh button. [child] fills the body.
class CallLogsCardFrame extends StatelessWidget {
  /// Number shown in the badge; hidden when null or zero.
  final int? count;

  /// Omit to hide the "Log Call" button (nothing to log against).
  final VoidCallback? onLogCall;
  final VoidCallback onRefresh;
  final Widget child;

  const CallLogsCardFrame({
    super.key,
    this.count,
    this.onLogCall,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.call_rounded,
                      size: 17, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  'Call Logs',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                // Count badge once the logs load.
                if ((count ?? 0) > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
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
                ],
                const Spacer(),
                if (onLogCall != null)
                  GestureDetector(
                    onTap: onLogCall,
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add_call,
                              size: 15, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Text(
                            'Log Call',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: onRefresh,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        size: 17, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// The body spinner used while a call-logs card loads.
class CallLogsLoading extends StatelessWidget {
  const CallLogsLoading({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
}

/// The list of call rows, or the empty-state note when there are none.
class CallLogsList extends StatelessWidget {
  final List<LeadCallLog> logs;

  /// Shown when [logs] is empty.
  final String emptyText;

  const CallLogsList({
    super.key,
    required this.logs,
    this.emptyText = 'No calls logged yet. Tap "Log Call" to record one.',
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return CallLogsNote(
        icon: Icons.call_missed_outgoing_rounded,
        text: emptyText,
      );
    }
    return Column(
      children: [
        for (var i = 0; i < logs.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.divider),
          _buildCallRow(logs[i]),
        ],
      ],
    );
  }

  Widget _buildCallRow(LeadCallLog call) {
    final cfg = _typeConfig(call);

    // `called_at` arrives as a UTC ISO string, so it has to be converted before
    // any of its calendar fields are read — otherwise a call placed at 2:45 PM
    // IST renders as 9:15 AM, and one made late in the evening shows the wrong
    // day entirely.
    final calledAt = call.calledAt?.toLocal();

    // Who logged it, plus how long ago — the supporting line under the
    // date/time.
    final trailingBits = <String>[
      if (calledAt != null) timeAgo(calledAt),
      if (call.userName != null && call.userName!.isNotEmpty) call.userName!,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cfg.$1.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(cfg.$2, size: 18, color: cfg.$1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      call.directionLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (call.outcomeLabel != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: cfg.$1.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          call.outcomeLabel!,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: cfg.$1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // When the call happened — the date and the clock time, shown
                // outright rather than only as "2h ago", so a log can be
                // matched against a real diary entry.
                if (calledAt != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.event_rounded,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          formatCallDate(calledAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        formatCallTime(calledAt),
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                if (trailingBits.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    trailingBits.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
                if (call.description != null &&
                    call.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    call.description!.trim(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 3),
              Text(
                call.durationLabel,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// (color, icon) for a call log's direction/type.
  (Color, IconData) _typeConfig(LeadCallLog call) {
    switch (call.type) {
      case AppCallType.incoming:
        return (AppColors.green, Icons.call_received_rounded);
      case AppCallType.outgoing:
        return (AppColors.primary, Icons.call_made_rounded);
      case AppCallType.missed:
        return (AppColors.red, Icons.call_missed_rounded);
      case AppCallType.rejected:
      case AppCallType.blocked:
        return (AppColors.red, Icons.call_end_rounded);
      case AppCallType.unknown:
        return call.isOutbound
            ? (AppColors.primary, Icons.call_made_rounded)
            : (AppColors.green, Icons.call_received_rounded);
    }
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// The calendar date of a call: `Today` / `Yesterday` for the two most recent
  /// days, `Mon, 3 Aug` within the past week, and `3 Aug 2026` beyond that —
  /// the year only appears once it stops being obvious.
  ///
  /// Pass a **local** [time]; callers convert before formatting.
  static String formatCallDate(DateTime time, {DateTime? now}) {
    final today = _dayOf(now ?? DateTime.now());
    final day = _dayOf(time);
    final diffDays = today.difference(day).inDays;

    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';

    final label = '${time.day} ${_months[time.month - 1]}';
    // Within the last week the weekday is the useful part; older calls only
    // need the date, plus the year when it isn't the current one.
    if (diffDays > 1 && diffDays < 7) return '${_weekday(time)}, $label';
    return time.year == today.year ? label : '$label ${time.year}';
  }

  /// The clock time of a call in 12-hour form, e.g. `2:45 PM`. Midnight and
  /// noon read as `12:00 AM` / `12:00 PM` rather than `0:00`.
  ///
  /// Pass a **local** [time]; callers convert before formatting.
  static String formatCallTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${time.hour < 12 ? 'AM' : 'PM'}';
  }

  /// Relative age, for the supporting line under the date/time.
  static String timeAgo(DateTime time, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);
    // A clock skew between device and server can put a call slightly in the
    // future; "in -3m" would be nonsense, so clamp it.
    if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}mo ago';
    return '${diff.inDays ~/ 365}y ago';
  }

  static DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

  static String _weekday(DateTime t) => const [
        'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
      ][t.weekday - 1];
}

/// An icon + muted text line used for the empty / error states inside a
/// [CallLogsCardFrame].
class CallLogsNote extends StatelessWidget {
  final IconData icon;
  final String text;

  const CallLogsNote({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
