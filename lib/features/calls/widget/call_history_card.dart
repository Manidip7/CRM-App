import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/AppColors.dart';
import '../model/call_record.dart';
import '../provider/call_providers.dart';
import 'log_call_sheet.dart';

/// A card that shows the captured call history for a lead or an opportunity,
/// and surfaces the call-log permission state. Drop it into a detail screen:
///
/// ```dart
/// CallHistoryCard(entityId: lead.id, isLead: true)
/// ```
class CallHistoryCard extends ConsumerWidget {
  final String entityId;

  /// `true` → lead history, `false` → opportunity history.
  final bool isLead;

  const CallHistoryCard({
    super.key,
    required this.entityId,
    required this.isLead,
  });

  FutureProvider<List<CallRecord>> get _historyProvider => isLead
      ? leadCallHistoryProvider(entityId)
      : opportunityCallHistoryProvider(entityId);

  /// Opens the manual Log-Call sheet. On success it invalidates the history so
  /// the new entry shows.
  Future<void> _openLogCall(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LogCallSheet(leadId: entityId),
    );
  }

  Future<void> _enable(WidgetRef ref) async {
    // Requests permission, syncs, and refreshes the permission state — all via
    // Riverpod. syncNow() already invalidates the history list on a successful
    // upload, so the new calls appear automatically.
    await ref.read(callPermissionProvider.notifier).enable();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permission = ref.watch(callPermissionProvider);
    final granted = permission.asData?.value.granted ?? false;
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
                  'Call History',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // Manual "Log Call" — leads only (uses /leads/{id}/call-logs).
                // Available even without call-log permission since it's typed in.
                if (isLead)
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
                if (granted)
                  GestureDetector(
                    onTap: () async {
                      await ref
                          .read(callSyncControllerProvider.notifier)
                          .syncNow();
                      ref.invalidate(_historyProvider);
                    },
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
            child: _buildBody(context, ref, permission),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref,
      AsyncValue<CallPermissionState> permission) {
    return permission.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _note(
        Icons.info_outline_rounded,
        'Could not check call-log permission.',
      ),
      data: (perm) {
        if (!perm.supported) {
          return _note(
            Icons.info_outline_rounded,
            'Call logging is available on Android only.',
          );
        }
        if (!perm.granted) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _note(
                Icons.lock_outline_rounded,
                'Allow call-log access to automatically capture calls made to '
                'this contact — from the app or the phone dialer.',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => _enable(ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: Text(
                    'Enable call logging',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          );
        }
        // Permission granted → show the history from the backend.
        return _buildHistory(ref);
      },
    );
  }

  Widget _buildHistory(WidgetRef ref) {
    final async = ref.watch(_historyProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _buildError(ref, e),
      data: (calls) {
        if (calls.isEmpty) {
          return _note(
            Icons.call_missed_outgoing_rounded,
            'No calls recorded yet. Calls you make to this contact will appear '
            'here automatically.',
          );
        }
        return Column(
          children: [
            for (var i = 0; i < calls.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, color: AppColors.divider),
              _buildCallRow(calls[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCallRow(CallRecord call) {
    final cfg = _typeConfig(call.type);
    final title = (call.contactName != null && call.contactName!.isNotEmpty)
        ? call.contactName!
        : call.phone;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
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
                Text(
                  '${call.type.label} · $title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _timeAgo(call.calledAt) +
                      (call.userName != null && call.userName!.isNotEmpty
                          ? ' · ${call.userName}'
                          : ''),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
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
        error is ApiException ? error.message : 'Could not load call history.';
    return Column(
      children: [
        _note(Icons.cloud_off_rounded, message),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => ref.invalidate(_historyProvider),
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

  /// (color, icon) for a call type.
  (Color, IconData) _typeConfig(AppCallType type) {
    switch (type) {
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
        return (AppColors.textSecondary, Icons.call_rounded);
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
