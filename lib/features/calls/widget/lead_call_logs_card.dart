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
                if (async.asData?.value.callLogs.isNotEmpty ?? false) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${async.asData!.value.callLogs.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: () => _openLogCall(context, ref),
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
                  onTap: () => ref.invalidate(leadDetailProvider(leadId)),
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
            child: async.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _buildError(ref, e),
              data: (detail) {
                final logs = detail.callLogs;
                if (logs.isEmpty) {
                  return _note(
                    Icons.call_missed_outgoing_rounded,
                    'No calls logged yet. Tap "Log Call" to record one.',
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < logs.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.divider),
                      _buildCallRow(logs[i]),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallRow(LeadCallLog call) {
    final cfg = _typeConfig(call);
    final subtitleBits = <String>[
      if (call.calledAt != null) _timeAgo(call.calledAt!),
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
                if (subtitleBits.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitleBits.join(' · '),
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

  Widget _buildError(WidgetRef ref, Object error) {
    final message =
        error is ApiException ? error.message : 'Could not load call logs.';
    return Column(
      children: [
        _note(Icons.cloud_off_rounded, message),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => ref.invalidate(leadDetailProvider(leadId)),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text('Retry', style: GoogleFonts.poppins(fontSize: 13)),
        ),
      ],
    );
  }

  Widget _note(IconData icon, String text) {
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

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[time.month - 1]} ${time.day}, ${time.year}';
  }
}
