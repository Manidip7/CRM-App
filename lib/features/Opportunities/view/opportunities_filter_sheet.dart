import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';
import '../../Leads/model/lead_model.dart' show StatusOption, AssignableUser;
import '../../Leads/provider/assign_providers.dart';
import '../provider/opportunities_provider.dart';
import '../provider/opportunity_detail_provider.dart';

/// The advanced filter panel behind the tune button on the Opportunities
/// screen — the same shape as the Leads one, wired to this endpoint's params:
///
/// | Control        | Param                    | Source of options          |
/// |----------------|--------------------------|----------------------------|
/// | All Statuses   | `status_id`              | `GET /statuses`            |
/// | All Assignees  | `assigned_to`            | `GET /users`               |
/// | All Time       | `date_range`, or `from_date`/`to_date` when custom | presets |
/// | Active only    | `category=active`        | switch                     |
/// | My deals only  | `quick_filter=my_opportunities` | switch              |
///
/// Selections are staged locally and only pushed into [Opportunities] when the
/// user taps Apply, so the list refetches **once** instead of on every tap.
///
/// Opened via [showOpportunitiesFilterSheet].
class OpportunitiesFilterSheet extends ConsumerStatefulWidget {
  /// Tint for the action button — red while the backlog view is active, to
  /// match the rest of that screen.
  final Color accent;

  const OpportunitiesFilterSheet({super.key, required this.accent});

  @override
  ConsumerState<OpportunitiesFilterSheet> createState() =>
      _OpportunitiesFilterSheetState();
}

class _OpportunitiesFilterSheetState
    extends ConsumerState<OpportunitiesFilterSheet> {
  // Staged selections, seeded from whatever is currently applied.
  int? _statusId;
  int? _assignedTo;
  late OpportunityDateRange _dateRange;
  DateTime? _fromDate;
  DateTime? _toDate;
  late bool _activeOnly;
  late bool _myOnly;

  @override
  void initState() {
    super.initState();
    final s = ref.read(opportunitiesProvider);
    _statusId = s.statusId;
    _assignedTo = s.assignedTo;
    _dateRange = s.dateRange;
    _fromDate = s.fromDate;
    _toDate = s.toDate;
    _activeOnly = s.activeOnly;
    _myOnly = s.myOpportunitiesOnly;
  }

  bool get _anySelected =>
      _statusId != null ||
      _assignedTo != null ||
      _dateRange != OpportunityDateRange.allTime ||
      _activeOnly ||
      _myOnly;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Padding(
      // viewInsets = keyboard, viewPadding = system nav / gesture bar. Without
      // the latter the action buttons sit under the Android nav buttons.
      padding: EdgeInsets.only(
        bottom: media.viewInsets.bottom + media.viewPadding.bottom,
      ),
      child: ConstrainedBox(
        // Never taller than most of the screen — the body scrolls instead, so
        // the Apply row stays reachable on short devices.
        constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            _buildHeader(),
            const Divider(height: 1, color: AppColors.divider),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusDropdown(),
                    const SizedBox(height: 14),
                    _buildAssigneeDropdown(),
                    const SizedBox(height: 14),
                    _buildDateRangeDropdown(),
                    // The custom range's two date fields only make sense once
                    // that preset is picked.
                    if (_dateRange == OpportunityDateRange.custom) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _dateField('From', _fromDate,
                                () => _pickDate(isFrom: true)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _dateField('To', _toDate,
                                () => _pickDate(isFrom: false)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    _buildSwitch(
                      label: 'Active only',
                      hint: 'Hide closed and archived deals',
                      value: _activeOnly,
                      onChanged: (v) => setState(() => _activeOnly = v),
                    ),
                    const SizedBox(height: 4),
                    _buildSwitch(
                      label: 'My opportunities only',
                      hint: 'Just the deals assigned to you',
                      value: _myOnly,
                      onChanged: (v) => setState(() => _myOnly = v),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 12),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 14),
      child: Row(
        children: [
          Icon(Icons.tune_rounded, size: 20, color: widget.accent),
          const SizedBox(width: 10),
          Text(
            'Filters',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded,
                size: 20, color: AppColors.textSecondary),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  // ── Dropdowns ──────────────────────────────────────────────────────────────

  Widget _buildStatusDropdown() {
    return _AsyncDropdown<StatusOption, int>(
      label: 'Status',
      allLabel: 'All Statuses',
      icon: Icons.flag_outlined,
      accent: widget.accent,
      options: ref.watch(opportunityStatusesProvider),
      selected: _statusId,
      valueOf: (s) => s.id,
      labelOf: (s) => s.name,
      onChanged: (id) => setState(() => _statusId = id),
    );
  }

  Widget _buildAssigneeDropdown() {
    return _AsyncDropdown<AssignableUser, int>(
      label: 'Assigned To',
      allLabel: 'All Assignees',
      icon: Icons.person_outline_rounded,
      accent: widget.accent,
      options: ref.watch(assignableUsersProvider),
      selected: _assignedTo,
      valueOf: (u) => u.id,
      labelOf: (u) => u.name,
      onChanged: (id) => setState(() => _assignedTo = id),
    );
  }

  /// The one dropdown with no API behind it — the presets are keywords the
  /// server resolves.
  Widget _buildDateRangeDropdown() {
    return _FieldShell(
      label: 'Date Range',
      icon: Icons.calendar_today_rounded,
      accent: widget.accent,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<OpportunityDateRange>(
          value: _dateRange,
          isExpanded: true,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary, size: 20),
          style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500),
          items: [
            for (final range in OpportunityDateRange.values)
              DropdownMenuItem(
                value: range,
                child: Text(range.label, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _dateRange = value;
              // Leaving Custom drops the hand-picked bounds; a preset sends its
              // keyword instead.
              if (value != OpportunityDateRange.custom) {
                _fromDate = null;
                _toDate = null;
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildSwitch({
    required String label,
    required String hint,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    hint,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: widget.accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 0.8),
        ),
        child: Row(
          children: [
            Icon(Icons.event_rounded, size: 15, color: widget.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value == null ? label : _fmtDate(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: value == null
                      ? AppColors.textLight
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _fromDate : _toDate) ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
        // Keep the range coherent rather than silently sending from > to.
        if (_toDate != null && _toDate!.isBefore(picked)) _toDate = picked;
      } else {
        _toDate = picked;
        if (_fromDate != null && _fromDate!.isAfter(picked)) _fromDate = picked;
      }
    });
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Actions ────────────────────────────────────────────────────────────────

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              // Nothing to reset → leave the button visibly inert rather than
              // firing a pointless refetch.
              onPressed: _anySelected
                  ? () {
                      ref
                          .read(opportunitiesProvider.notifier)
                          .clearAdvanced();
                      Navigator.pop(context);
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Reset',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Apply Filters',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _apply() {
    ref.read(opportunitiesProvider.notifier).applyAdvanced(
          statusId: _statusId,
          assignedTo: _assignedTo,
          dateRange: _dateRange,
          fromDate: _fromDate,
          toDate: _toDate,
          activeOnly: _activeOnly,
          myOpportunitiesOnly: _myOnly,
        );
    Navigator.pop(context);
  }
}

/// Opens the advanced filter panel. Returns when it closes; the opportunities
/// notifier already carries any change by then.
Future<void> showOpportunitiesFilterSheet(
  BuildContext context, {
  required Color accent,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => OpportunitiesFilterSheet(accent: accent),
  );
}

// ── Building blocks ──────────────────────────────────────────────────────────

/// A labelled dropdown fed by a [FutureProvider]'s [AsyncValue].
///
/// [V] is the type of the value sent to the API — `int` for an id, `String` for
/// a stage key. Handles the three async states in place so each filter row
/// degrades on its own: a spinner while the lookup loads, a quiet "unavailable"
/// note if it fails (the other dropdowns still work), and the options once they
/// arrive. The "All …" entry is always present and maps to `null`.
class _AsyncDropdown<T, V> extends StatelessWidget {
  final String label;
  final String allLabel;
  final IconData icon;
  final Color accent;
  final AsyncValue<List<T>> options;
  final V? selected;
  final V Function(T) valueOf;
  final String Function(T) labelOf;
  final ValueChanged<V?> onChanged;

  const _AsyncDropdown({
    required this.label,
    required this.allLabel,
    required this.icon,
    required this.accent,
    required this.options,
    required this.selected,
    required this.valueOf,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: label,
      icon: icon,
      accent: accent,
      child: switch (options) {
        AsyncData(:final value) => _buildDropdown(value),
        AsyncError() => Text(
            'Unavailable',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        _ => Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                'Loading…',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
      },
    );
  }

  Widget _buildDropdown(List<T> items) {
    // A stale selection (an option the backend no longer returns) would make
    // DropdownButton assert on a value with no matching item — fall back to
    // "All …" instead of crashing the sheet.
    final values = items.map(valueOf).toSet();
    final value = values.contains(selected) ? selected : null;

    return DropdownButtonHideUnderline(
      child: DropdownButton<V?>(
        value: value,
        isExpanded: true,
        isDense: true,
        borderRadius: BorderRadius.circular(12),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary, size: 20),
        style: GoogleFonts.poppins(
            fontSize: 13.5,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500),
        items: [
          DropdownMenuItem<V?>(
            value: null,
            child: Text(
              allLabel,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          for (final item in items)
            DropdownMenuItem<V?>(
              value: valueOf(item),
              child: Text(labelOf(item), overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

/// The bordered box + caption every filter row shares.
class _FieldShell extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final Widget child;

  const _FieldShell({
    required this.label,
    required this.icon,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider, width: 0.8),
          ),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      ],
    );
  }
}
