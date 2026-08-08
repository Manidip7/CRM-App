import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';
import '../model/lead_model.dart';
import '../provider/assign_providers.dart';
import '../provider/bulk_action_provider.dart';
import '../provider/leads_provider.dart';

/// The "Bulk Update" popup: pick a field, pick its new value, apply it to every
/// selected lead. Pops with the [BulkUpdateOutcome] once the run finishes, or
/// with `null` if the user backs out.
///
/// Dropdown state lives in [bulkUpdateDraftProvider] (no [setState]).
class BulkUpdateDialog extends ConsumerStatefulWidget {
  final List<LeadModel> leads;

  const BulkUpdateDialog({super.key, required this.leads});

  /// Shows the popup and returns the outcome, or null if it was dismissed.
  static Future<BulkUpdateOutcome?> show(
    BuildContext context, {
    required List<LeadModel> leads,
  }) {
    return showDialog<BulkUpdateOutcome>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BulkUpdateDialog(leads: leads),
    );
  }

  @override
  ConsumerState<BulkUpdateDialog> createState() => _BulkUpdateDialogState();
}

class _BulkUpdateDialogState extends ConsumerState<BulkUpdateDialog> {
  @override
  void initState() {
    super.initState();
    // Both dropdowns start empty every time the popup opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bulkUpdateDraftProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(bulkUpdateDraftProvider);
    final progress = ref.watch(bulkUpdateRunnerProvider);
    final count = widget.leads.length;

    return PopScope(
      // A run in flight keeps going even if the dialog closes, so don't let the
      // back gesture strand it — the user would never see the outcome.
      canPop: !progress.running,
      child: Dialog(
        backgroundColor: AppColors.cardBackground,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(count, progress.running),
                const SizedBox(height: 18),
                _label('Update Field'),
                _buildFieldDropdown(draft.field, enabled: !progress.running),
                const SizedBox(height: 14),
                // Delete takes no value — it gets a warning panel instead of a
                // second dropdown.
                if (draft.field == BulkUpdateField.delete)
                  _buildDeleteWarning(count)
                else ...[
                  _label('New Value'),
                  _buildValueDropdown(draft, enabled: !progress.running),
                ],
                const SizedBox(height: 22),
                _buildActions(draft, progress),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(int count, bool running) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.edit_note_rounded,
            size: 21,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bulk Update',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count ${count == 1 ? 'lead' : 'leads'} selected',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (!running)
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.close_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  // ── Dropdown 1: which field ──
  Widget _buildFieldDropdown(
    BulkUpdateField? selected, {
    required bool enabled,
  }) {
    return _shell(
      Icons.tune_rounded,
      DropdownButtonHideUnderline(
        child: DropdownButton<BulkUpdateField>(
          value: selected,
          isExpanded: true,
          isDense: true,
          hint: Text(
            'Select field',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: AppColors.textLight,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
          items: BulkUpdateField.values
              .map(
                (f) => DropdownMenuItem<BulkUpdateField>(
                  value: f,
                  child: Row(
                    children: [
                      if (f.isDestructive) ...[
                        const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: AppColors.red,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          f.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: f.isDestructive
                                ? AppColors.red
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: !enabled
              ? null
              : (f) {
                  if (f != null) {
                    ref.read(bulkUpdateDraftProvider.notifier).setField(f);
                  }
                },
        ),
      ),
    );
  }

  // ── Dropdown 2: the new value for that field ──
  Widget _buildValueDropdown(BulkUpdateDraft draft, {required bool enabled}) {
    switch (draft.field) {
      case null:
        return _shell(
          Icons.arrow_drop_down_circle_outlined,
          Text(
            'Pick a field first',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: AppColors.textLight,
            ),
          ),
        );
      case BulkUpdateField.status:
        return _buildOptionsValue<StatusOption>(
          icon: Icons.flag_outlined,
          options: ref.watch(leadStatusesProvider),
          selected: draft.statusId,
          hint: 'Select status',
          errorMessage: 'Could not load statuses',
          idOf: (s) => s.id,
          nameOf: (s) => s.name,
          onPicked: (id) =>
              ref.read(bulkUpdateDraftProvider.notifier).setStatus(id),
          enabled: enabled,
        );
      case BulkUpdateField.priority:
        return _buildPriorityValue(draft.priority, enabled: enabled);
      case BulkUpdateField.leadSource:
        return _buildOptionsValue<LeadSourceOption>(
          icon: Icons.hub_outlined,
          options: ref.watch(leadSourcesProvider),
          selected: draft.leadSourceId,
          hint: 'Select lead source',
          errorMessage: 'Could not load lead sources',
          idOf: (s) => s.id,
          nameOf: (s) => s.label,
          onPicked: (id) =>
              ref.read(bulkUpdateDraftProvider.notifier).setLeadSource(id),
          enabled: enabled,
        );
      case BulkUpdateField.leadType:
        return _buildOptionsValue<NamedLookup>(
          icon: Icons.category_outlined,
          options: ref.watch(leadTypesProvider),
          selected: draft.leadTypeId,
          hint: 'Select lead type',
          errorMessage: 'Could not load lead types',
          idOf: (t) => t.id,
          nameOf: (t) => t.name,
          onPicked: (id) =>
              ref.read(bulkUpdateDraftProvider.notifier).setLeadType(id),
          enabled: enabled,
        );
      case BulkUpdateField.territory:
        return _buildOptionsValue<NamedLookup>(
          icon: Icons.map_outlined,
          options: ref.watch(territoriesProvider),
          selected: draft.territoryId,
          hint: 'Select territory',
          errorMessage: 'Could not load territories',
          idOf: (t) => t.id,
          nameOf: (t) => t.name,
          onPicked: (id) =>
              ref.read(bulkUpdateDraftProvider.notifier).setTerritory(id),
          enabled: enabled,
        );
      case BulkUpdateField.branch:
        // Not scoped to a territory here — the selected leads can sit in
        // different ones, so every branch has to stay pickable.
        return _buildOptionsValue<NamedLookup>(
          icon: Icons.apartment_outlined,
          options: ref.watch(branchesProvider(null)),
          selected: draft.branchId,
          hint: 'Select branch',
          errorMessage: 'Could not load branches',
          idOf: (b) => b.id,
          nameOf: (b) => b.name,
          onPicked: (id) =>
              ref.read(bulkUpdateDraftProvider.notifier).setBranch(id),
          enabled: enabled,
        );
      case BulkUpdateField.assignee:
        return _buildAssigneeValue(draft.assigneeId, enabled: enabled);
      case BulkUpdateField.delete:
        // Handled by the warning panel in build(); no value to pick.
        return const SizedBox.shrink();
    }
  }

  /// One dropdown over an `id → name` option list loaded from the API — used by
  /// every lookup-backed field (status, lead source, lead type, territory,
  /// branch), which differ only in icon, wording and where the pick is stored.
  Widget _buildOptionsValue<T>({
    required IconData icon,
    required AsyncValue<List<T>> options,
    required int? selected,
    required String hint,
    required String errorMessage,
    required int Function(T) idOf,
    required String Function(T) nameOf,
    required void Function(int) onPicked,
    required bool enabled,
  }) {
    return options.when(
      loading: () => _loadingShell(icon),
      error: (_, __) => _errorShell(icon, errorMessage),
      data: (items) {
        final value = items.any((o) => idOf(o) == selected) ? selected : null;
        return _shell(
          icon,
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              isDense: true,
              hint: Text(
                hint,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: AppColors.textLight,
                ),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
              ),
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
              items: items
                  .map(
                    (o) => DropdownMenuItem<int>(
                      value: idOf(o),
                      child: Text(nameOf(o), overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: !enabled
                  ? null
                  : (id) {
                      if (id != null) onPicked(id);
                    },
            ),
          ),
        );
      },
    );
  }

  /// Stands in for the "New Value" dropdown when Delete Leads is picked.
  Widget _buildDeleteWarning(int count) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 19,
            color: AppColors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This cannot be undone',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count ${count == 1 ? 'lead' : 'leads'} will be permanently '
                  'deleted, along with their notes and tasks.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityValue(String? selected, {required bool enabled}) {
    return _shell(
      Icons.local_fire_department_outlined,
      DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          isDense: true,
          hint: Text(
            'Select priority',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: AppColors.textLight,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
          items: kBulkPriorities
              .map(
                (p) => DropdownMenuItem<String>(
                  value: p,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _priorityColor(p),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          bulkPriorityLabel(p),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: !enabled
              ? null
              : (p) {
                  if (p != null) {
                    ref.read(bulkUpdateDraftProvider.notifier).setPriority(p);
                  }
                },
        ),
      ),
    );
  }

  Widget _buildAssigneeValue(int? selected, {required bool enabled}) {
    final usersAsync = ref.watch(assignableUsersProvider);
    return usersAsync.when(
      loading: () => _loadingShell(Icons.person_outline_rounded),
      error: (_, __) =>
          _errorShell(Icons.person_outline_rounded, 'Could not load users'),
      data: (users) {
        final value = users.any((u) => u.id == selected) ? selected : null;
        return _shell(
          Icons.person_outline_rounded,
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              itemHeight: 56,
              hint: Text(
                'Select user',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: AppColors.textLight,
                ),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
              ),
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
              // The collapsed button shows just the name; the designation is
              // only worth the extra line inside the opened menu.
              selectedItemBuilder: (context) => users
                  .map(
                    (u) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        u.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              items: users
                  .map(
                    (u) =>
                        DropdownMenuItem<int>(value: u.id, child: _userItem(u)),
                  )
                  .toList(),
              onChanged: !enabled
                  ? null
                  : (id) {
                      if (id != null) {
                        ref
                            .read(bulkUpdateDraftProvider.notifier)
                            .setAssignee(id);
                      }
                    },
            ),
          ),
        );
      },
    );
  }

  Widget _userItem(AssignableUser u) {
    final designation = u.designation?.trim() ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          u.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (designation.isNotEmpty)
          Text(
            designation,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  // ── Footer ──
  Widget _buildActions(BulkUpdateDraft draft, BulkUpdateProgress progress) {
    final canApply = draft.isReady && !progress.running;
    final destructive = draft.field?.isDestructive ?? false;
    final actionColor = destructive ? AppColors.red : AppColors.primary;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: TextButton(
              onPressed: progress.running
                  ? null
                  : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                  side: const BorderSide(color: AppColors.divider),
                ),
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
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: canApply ? _apply : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                disabledBackgroundColor: actionColor.withOpacity(0.35),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: progress.running
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          destructive ? 'Deleting…' : 'Updating…',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      destructive ? 'Delete Leads' : 'Apply Update',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Shared field shells ──
  Widget _shell(IconData icon, Widget child) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _loadingShell(IconData icon) => _shell(
    icon,
    const SizedBox(
      height: 18,
      width: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );

  Widget _errorShell(IconData icon, String message) => _shell(
    icon,
    Text(
      message,
      style: GoogleFonts.poppins(
        fontSize: 12.5,
        color: AppColors.textSecondary,
      ),
    ),
  );

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'hot':
        return AppColors.red;
      case 'warm':
        return const Color(0xFFFFB547);
      default:
        return AppColors.primary;
    }
  }

  // ── Action ──
  Future<void> _apply() async {
    final draft = ref.read(bulkUpdateDraftProvider);
    final field = draft.field;
    if (field == null || !draft.isReady) return;

    // Deleting is the one action the user can't walk back, so it gets a second
    // tap before anything is sent.
    if (field.isDestructive && !await _confirmDelete()) return;
    if (!mounted) return;

    final outcome = await ref
        .read(bulkUpdateRunnerProvider.notifier)
        .apply(
          leads: widget.leads,
          field: field,
          statusId: draft.statusId,
          priority: draft.priority,
          leadSourceId: draft.leadSourceId,
          leadTypeId: draft.leadTypeId,
          territoryId: draft.territoryId,
          branchId: draft.branchId,
          assigneeId: draft.assigneeId,
        );

    if (!mounted) return;
    Navigator.of(context).pop(outcome);
  }

  Future<bool> _confirmDelete() async {
    final count = widget.leads.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete $count ${count == 1 ? 'lead' : 'leads'}?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This permanently removes the selected '
          '${count == 1 ? 'lead' : 'leads'}. This cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.red,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
