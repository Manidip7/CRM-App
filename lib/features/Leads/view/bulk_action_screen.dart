import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/AppColors.dart';
import '../model/lead_model.dart';
import '../provider/assign_providers.dart';
import '../provider/bulk_action_provider.dart';
import '../provider/leads_provider.dart';
import 'bulk_update_dialog.dart';

/// Bulk Action: filter the leads down, tick the ones to change, then apply one
/// field update to all of them through [BulkUpdateDialog].
///
/// Runs on its own [bulkLeadsProvider] slice of `GET /leads` so filtering here
/// leaves the Leads screen's own list untouched. All screen state lives in
/// Riverpod (no [setState]).
class BulkActionScreen extends ConsumerStatefulWidget {
  const BulkActionScreen({super.key});

  @override
  ConsumerState<BulkActionScreen> createState() => _BulkActionScreenState();
}

class _BulkActionScreenState extends ConsumerState<BulkActionScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Nothing carried over from a previous visit.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bulkSelectionProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(bulkLeadsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bulkLeadsProvider);
    final selected = ref.watch(bulkSelectionProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _buildApplyBar(state, selected),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(state),
            _buildSearchRow(),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: ref.watch(bulkFiltersExpandedProvider)
                  ? _buildFilters(state)
                  : const SizedBox(width: double.infinity),
            ),
            if (state.items.isNotEmpty) _buildSelectAllRow(state, selected),
            Expanded(child: _buildBody(state, selected)),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(BulkLeadsState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bulk Action',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.total > 0
                      ? 'Select leads to update · ${state.total} total'
                      : 'Select leads to update together',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildFilterToggle(state),
        ],
      ),
    );
  }

  Widget _buildFilterToggle(BulkLeadsState state) {
    final expanded = ref.watch(bulkFiltersExpandedProvider);
    final hasFilters = state.activeFilterCount > 0;
    final active = expanded || hasFilters;
    return GestureDetector(
      onTap: () => ref.read(bulkFiltersExpandedProvider.notifier).toggle(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 19,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
            if (hasFilters && !expanded)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Search ──
  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => ref.read(bulkLeadsProvider.notifier).setSearch(v),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search leads...',
            hintStyle: const TextStyle(
              color: AppColors.textLight,
              fontSize: 13.5,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textLight,
              size: 20,
            ),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textLight,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(bulkLeadsProvider.notifier).setSearch('');
                    },
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ── Filters ──
  Widget _buildFilters(BulkLeadsState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildStatusFilter(state)),
              const SizedBox(width: 10),
              Expanded(child: _buildPriorityFilter(state)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildSourceFilter(state)),
              const SizedBox(width: 10),
              Expanded(child: _buildAssigneeFilter(state)),
            ],
          ),
          if (state.activeFilterCount > 0)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () =>
                    ref.read(bulkLeadsProvider.notifier).clearFilters(),
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: Text(
                  'Clear filters',
                  style: GoogleFonts.poppins(fontSize: 12.5),
                ),
                style: TextButton.styleFrom(foregroundColor: AppColors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(BulkLeadsState state) {
    final statusesAsync = ref.watch(leadStatusesProvider);
    final statuses = statusesAsync.value ?? const <StatusOption>[];
    final value = statuses.any((s) => s.id == state.statusId)
        ? state.statusId
        : null;
    return _filterShell(
      icon: Icons.flag_outlined,
      active: value != null,
      child: DropdownButton<int?>(
        value: value,
        isExpanded: true,
        isDense: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textSecondary,
        ),
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('All Status')),
          ...statuses.map(
            (s) => DropdownMenuItem<int?>(
              value: s.id,
              child: Text(s.name, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (id) =>
            _applyFilters(state, statusId: id, clearStatus: id == null),
      ),
    );
  }

  Widget _buildPriorityFilter(BulkLeadsState state) {
    return _filterShell(
      icon: Icons.local_fire_department_outlined,
      active: state.priority != null,
      child: DropdownButton<String?>(
        value: state.priority,
        isExpanded: true,
        isDense: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textSecondary,
        ),
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('All Priority'),
          ),
          ...kBulkPriorities.map(
            (p) => DropdownMenuItem<String?>(
              value: p,
              child: Text(
                bulkPriorityLabel(p),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: (p) =>
            _applyFilters(state, priority: p, clearPriority: p == null),
      ),
    );
  }

  Widget _buildSourceFilter(BulkLeadsState state) {
    final sourcesAsync = ref.watch(leadSourcesProvider);
    final sources = sourcesAsync.value ?? const <LeadSourceOption>[];
    final value = sources.any((s) => s.id == state.leadSourceId)
        ? state.leadSourceId
        : null;
    return _filterShell(
      icon: Icons.hub_outlined,
      active: value != null,
      child: DropdownButton<int?>(
        value: value,
        isExpanded: true,
        isDense: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textSecondary,
        ),
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('All Source')),
          ...sources.map(
            (s) => DropdownMenuItem<int?>(
              value: s.id,
              child: Text(s.label, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (id) =>
            _applyFilters(state, leadSourceId: id, clearSource: id == null),
      ),
    );
  }

  Widget _buildAssigneeFilter(BulkLeadsState state) {
    final usersAsync = ref.watch(assignableUsersProvider);
    final users = usersAsync.value ?? const <AssignableUser>[];
    final value = users.any((u) => u.id == state.assignedTo)
        ? state.assignedTo
        : null;
    return _filterShell(
      icon: Icons.person_outline_rounded,
      active: value != null,
      child: DropdownButton<int?>(
        value: value,
        isExpanded: true,
        isDense: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textSecondary,
        ),
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('All Owners')),
          ...users.map(
            (u) => DropdownMenuItem<int?>(
              value: u.id,
              child: Text(u.name, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (id) =>
            _applyFilters(state, assignedTo: id, clearAssignee: id == null),
      ),
    );
  }

  /// Re-applies the whole filter set with one dropdown changed. The notifier
  /// takes every filter at once (null = "All …"), so the untouched ones have to
  /// be passed through explicitly.
  void _applyFilters(
    BulkLeadsState state, {
    int? statusId,
    int? leadSourceId,
    String? priority,
    int? assignedTo,
    bool clearStatus = false,
    bool clearSource = false,
    bool clearPriority = false,
    bool clearAssignee = false,
  }) {
    ref
        .read(bulkLeadsProvider.notifier)
        .applyFilters(
          statusId: clearStatus ? null : (statusId ?? state.statusId),
          leadSourceId: clearSource
              ? null
              : (leadSourceId ?? state.leadSourceId),
          priority: clearPriority ? null : (priority ?? state.priority),
          assignedTo: clearAssignee ? null : (assignedTo ?? state.assignedTo),
        );
  }

  Widget _filterShell({
    required IconData icon,
    required bool active,
    required Widget child,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? AppColors.primary : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: active ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(child: DropdownButtonHideUnderline(child: child)),
        ],
      ),
    );
  }

  // ── Select all ──
  Widget _buildSelectAllRow(BulkLeadsState state, Set<String> selected) {
    final ids = state.items.map((l) => l.id).toList();
    final allSelected = ids.isNotEmpty && ids.every(selected.contains);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                ref.read(bulkSelectionProvider.notifier).toggleAll(ids),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                _checkbox(allSelected),
                const SizedBox(width: 8),
                Text(
                  allSelected ? 'Unselect all' : 'Select all (${ids.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (selected.isNotEmpty)
            GestureDetector(
              onTap: () => ref.read(bulkSelectionProvider.notifier).clear(),
              behavior: HitTestBehavior.opaque,
              child: Text(
                'Clear (${selected.length})',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── List ──
  Widget _buildBody(BulkLeadsState state, Set<String> selected) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return _buildError(state.error!);
    }
    if (state.items.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(bulkLeadsProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final lead = state.items[i];
          return _buildLeadRow(lead, selected.contains(lead.id));
        },
      ),
    );
  }

  Widget _buildLeadRow(LeadModel lead, bool isSelected) {
    return GestureDetector(
      onTap: () => ref.read(bulkSelectionProvider.notifier).toggle(lead.id),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _checkbox(isSelected),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.contactName.trim().isNotEmpty
                        ? lead.contactName
                        : lead.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (lead.companyName != null &&
                      lead.companyName!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      lead.companyName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _badge(
                        _statusLabel(lead.status),
                        _statusColor(lead.status),
                      ),
                      if (lead.priority != null &&
                          lead.priority!.trim().isNotEmpty)
                        _badge(
                          bulkPriorityLabel(lead.priority!),
                          _priorityColor(lead.priority!),
                        ),
                      if (lead.assigneeName != null &&
                          lead.assigneeName!.trim().isNotEmpty)
                        _badge(lead.assigneeName!, AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkbox(bool checked) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: checked ? AppColors.primary : AppColors.textLight,
          width: 1.6,
        ),
      ),
      child: checked
          ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
          : null,
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.filter_alt_off_rounded,
            size: 46,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 12),
          Text(
            'No leads match your filters',
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object error) {
    final message = error is ApiException
        ? error.message
        : 'Could not load leads.';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.red, size: 40),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => ref.read(bulkLeadsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('Retry', style: GoogleFonts.poppins(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // ── Apply bar ──
  Widget _buildApplyBar(BulkLeadsState state, Set<String> selected) {
    if (selected.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: const Border(top: BorderSide(color: AppColors.divider)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${selected.length} selected',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Ready to update',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => _openUpdateDialog(state, selected),
                icon: const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  'Apply',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ──
  Future<void> _openUpdateDialog(
    BulkLeadsState state,
    Set<String> selected,
  ) async {
    final leads = state.items
        .where((l) => selected.contains(l.id))
        .toList(growable: false);
    if (leads.isEmpty) return;

    final outcome = await BulkUpdateDialog.show(context, leads: leads);
    if (!mounted || outcome == null) return;

    if (outcome.succeeded > 0) {
      ref.read(bulkSelectionProvider.notifier).clear();
    }
    if (outcome.allSucceeded) {
      _toast(
        '${outcome.succeeded} '
        '${outcome.succeeded == 1 ? 'lead' : 'leads'} updated',
      );
    } else {
      _showFailures(outcome);
    }
  }

  /// Partial failures deserve more than a snackbar — the user needs to know
  /// which leads did not take the change.
  void _showFailures(BulkUpdateOutcome outcome) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.red,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Partly updated',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${outcome.succeeded} updated · ${outcome.failures.length} failed',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ...outcome.failures.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• $f',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: GoogleFonts.poppins(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Display helpers ──
  String _statusLabel(LeadStatus s) {
    switch (s) {
      case LeadStatus.newLead:
        return 'New';
      case LeadStatus.contacted:
        return 'In Progress';
      case LeadStatus.qualified:
        return 'Interested';
      case LeadStatus.won:
        return 'Won';
      case LeadStatus.lost:
        return 'Lost';
    }
  }

  Color _statusColor(LeadStatus s) {
    switch (s) {
      case LeadStatus.newLead:
        return AppColors.leadFunnelNew;
      case LeadStatus.contacted:
        return AppColors.leadFunnelContacted;
      case LeadStatus.qualified:
        return AppColors.green;
      case LeadStatus.won:
        return const Color(0xFFFFB547);
      case LeadStatus.lost:
        return AppColors.red;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'hot':
        return AppColors.red;
      case 'warm':
        return const Color(0xFFFFB547);
      default:
        return AppColors.primary;
    }
  }
}
