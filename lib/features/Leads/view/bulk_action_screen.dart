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
                  // Nine filters are a lot of rows: cap the panel and let it
                  // scroll so the lead list underneath never gets squeezed out.
                  ? ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.42,
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: _buildFilters(state),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            if (state.items.isNotEmpty) _buildSelectAllRow(state, selected),
            // Resolved here rather than per row: `ref.watch` belongs in build,
            // not in a ListView.builder callback that runs during layout.
            Expanded(child: _buildBody(state, selected, _readLookups())),
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
  /// The nine filters of `POST /leads/filter`, two to a row.
  Widget _buildFilters(BulkLeadsState state) {
    final f = state.filters;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filterRow(
            _buildDateFilter(f, isFrom: true),
            _buildDateFilter(f, isFrom: false),
          ),
          const SizedBox(height: 10),
          _filterRow(
            _lookupFilter<LeadSourceOption>(
              icon: Icons.hub_outlined,
              options: ref.watch(leadSourcesProvider),
              selected: f.leadSourceId,
              allLabel: 'All Source',
              idOf: (s) => s.id,
              nameOf: (s) => s.label,
              onPicked: (id) => _apply(f.copyWith(leadSourceId: id)),
            ),
            _lookupFilter<StatusOption>(
              icon: Icons.flag_outlined,
              options: ref.watch(leadStatusesProvider),
              selected: f.statusId,
              allLabel: 'All Status',
              idOf: (s) => s.id,
              nameOf: (s) => s.name,
              onPicked: (id) => _apply(f.copyWith(statusId: id)),
            ),
          ),
          const SizedBox(height: 10),
          _filterRow(
            _buildPriorityFilter(f),
            _lookupFilter<AssignableUser>(
              icon: Icons.person_outline_rounded,
              options: ref.watch(assignableUsersProvider),
              selected: f.assigneeId,
              allLabel: 'All Assignee',
              idOf: (u) => u.id,
              nameOf: (u) => u.name,
              onPicked: (id) => _apply(f.copyWith(assigneeId: id)),
            ),
          ),
          const SizedBox(height: 10),
          _filterRow(
            _lookupFilter<NamedLookup>(
              icon: Icons.category_outlined,
              options: ref.watch(leadTypesProvider),
              selected: f.leadTypeId,
              allLabel: 'All Lead Type',
              idOf: (t) => t.id,
              nameOf: (t) => t.name,
              onPicked: (id) => _apply(f.copyWith(leadTypeId: id)),
            ),
            _lookupFilter<NamedLookup>(
              icon: Icons.map_outlined,
              options: ref.watch(territoriesProvider),
              selected: f.territoryId,
              allLabel: 'All Territory',
              idOf: (t) => t.id,
              nameOf: (t) => t.name,
              // A branch belonging to the old territory would keep filtering
              // everything out, so it goes with it.
              onPicked: (id) =>
                  _apply(f.copyWith(territoryId: id, branchId: null)),
            ),
          ),
          const SizedBox(height: 10),
          _filterRow(
            // Scoped to the chosen territory when there is one.
            _lookupFilter<NamedLookup>(
              icon: Icons.apartment_outlined,
              options: ref.watch(branchesProvider(f.territoryId)),
              selected: f.branchId,
              allLabel: 'All Branch',
              idOf: (b) => b.id,
              nameOf: (b) => b.name,
              onPicked: (id) => _apply(f.copyWith(branchId: id)),
            ),
            null,
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

  /// Two filters side by side; [right] may be null to leave a gap on the last,
  /// odd row.
  Widget _filterRow(Widget left, Widget? right) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right ?? const SizedBox.shrink()),
      ],
    );
  }

  /// One dropdown over an API-loaded option list, with an "All …" entry that
  /// maps to null. Options still loading (or failed) just show the "All …"
  /// entry, so one broken lookup can't take the panel down with it.
  Widget _lookupFilter<T>({
    required IconData icon,
    required AsyncValue<List<T>> options,
    required int? selected,
    required String allLabel,
    required int Function(T) idOf,
    required String Function(T) nameOf,
    required ValueChanged<int?> onPicked,
  }) {
    final items = options.value ?? const [];
    // A stale id (an option the backend no longer returns) would make
    // DropdownButton assert — fall back to "All …".
    final value = items.any((o) => idOf(o) == selected) ? selected : null;
    return _filterShell(
      icon: icon,
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
          DropdownMenuItem<int?>(value: null, child: Text(allLabel)),
          ...items.map(
            (o) => DropdownMenuItem<int?>(
              value: idOf(o),
              child: Text(nameOf(o), overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onPicked,
      ),
    );
  }

  Widget _buildPriorityFilter(BulkLeadsFilters f) {
    return _filterShell(
      icon: Icons.local_fire_department_outlined,
      active: f.priority != null,
      child: DropdownButton<String?>(
        value: f.priority,
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
        onChanged: (p) => _apply(f.copyWith(priority: p)),
      ),
    );
  }

  /// The `from_date` / `to_date` pickers. Tapping the × on a set date clears it
  /// without opening the calendar.
  Widget _buildDateFilter(BulkLeadsFilters f, {required bool isFrom}) {
    final value = isFrom ? f.fromDate : f.toDate;
    final active = value != null;
    return GestureDetector(
      onTap: () => _pickDate(f, isFrom: isFrom),
      behavior: HitTestBehavior.opaque,
      child: Container(
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
              Icons.event_rounded,
              size: 15,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value == null
                    ? (isFrom ? 'From date' : 'To date')
                    : _fmtDate(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: active ? AppColors.textPrimary : AppColors.textLight,
                ),
              ),
            ),
            if (active)
              GestureDetector(
                onTap: () => _apply(
                  isFrom ? f.copyWith(fromDate: null) : f.copyWith(toDate: null),
                ),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(
    BulkLeadsFilters f, {
    required bool isFrom,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? f.fromDate : f.toDate) ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null || !mounted) return;
    // Keep the range coherent rather than sending from > to.
    if (isFrom) {
      final to = f.toDate;
      _apply(
        f.copyWith(
          fromDate: picked,
          toDate: to != null && to.isBefore(picked) ? picked : to,
        ),
      );
    } else {
      final from = f.fromDate;
      _apply(
        f.copyWith(
          toDate: picked,
          fromDate: from != null && from.isAfter(picked) ? picked : from,
        ),
      );
    }
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Pushes an edited filter set to the notifier, which refetches page 1.
  void _apply(BulkLeadsFilters filters) =>
      ref.read(bulkLeadsProvider.notifier).applyFilters(filters);

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
  /// Snapshots the option lists as `id → name` maps, so a row can name the
  /// classification a lead only carries the id of. Everything the API already
  /// resolved (`lead_type_name`, `territory_name`, …) wins over these.
  _LeadLookups _readLookups() {
    Map<int, String> asMap<T>(
      List<T>? items,
      int Function(T) idOf,
      String Function(T) nameOf,
    ) => {for (final item in items ?? <T>[]) idOf(item): nameOf(item)};

    return _LeadLookups(
      statuses: asMap(
        ref.watch(leadStatusesProvider).value,
        (s) => s.id,
        (s) => s.name,
      ),
      sources: asMap(
        ref.watch(leadSourcesProvider).value,
        (s) => s.id,
        (s) => s.label,
      ),
      types: asMap(
        ref.watch(leadTypesProvider).value,
        (t) => t.id,
        (t) => t.name,
      ),
      territories: asMap(
        ref.watch(territoriesProvider).value,
        (t) => t.id,
        (t) => t.name,
      ),
      branches: asMap(
        ref.watch(branchesProvider(null)).value,
        (b) => b.id,
        (b) => b.name,
      ),
    );
  }

  Widget _buildBody(
    BulkLeadsState state,
    Set<String> selected,
    _LeadLookups lookups,
  ) {
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
          return _buildLeadRow(lead, selected.contains(lead.id), lookups);
        },
      ),
    );
  }

  /// One selectable lead, showing everything the bulk update might change:
  /// lead no, title/name, status, source, type, territory, branch, priority,
  /// assignee and created date.
  Widget _buildLeadRow(
    LeadModel lead,
    bool isSelected,
    _LeadLookups lookups,
  ) {
    final title = lead.title.trim().isNotEmpty
        ? lead.title.trim()
        : lead.contactName.trim();
    final subtitle = [
      if (lead.contactName.trim().isNotEmpty &&
          lead.contactName.trim() != title)
        lead.contactName.trim(),
      if (lead.companyName?.trim().isNotEmpty ?? false)
        lead.companyName!.trim(),
    ].join(' · ');

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _checkbox(isSelected),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.leadNo?.trim().isNotEmpty ?? false
                        ? lead.leadNo!.trim()
                        : '#${lead.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _badge(
                        lookups.statuses[lead.statusId] ??
                            _statusLabel(lead.status),
                        _statusColor(lead.status),
                      ),
                      if (lead.priority?.trim().isNotEmpty ?? false)
                        _badge(
                          bulkPriorityLabel(lead.priority!),
                          _priorityColor(lead.priority!),
                        ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Container(height: 0.8, color: AppColors.divider),
                  const SizedBox(height: 8),
                  // Two per line; every field is shown even when empty, so the
                  // cards stay aligned and a blank one reads as "not set".
                  _detailRow(
                    'Source',
                    lookups.sourceOf(lead),
                    'Type',
                    lead.leadTypeName ?? lookups.types[lead.leadTypeId],
                  ),
                  const SizedBox(height: 6),
                  _detailRow(
                    'Territory',
                    lead.territoryName ?? lookups.territories[lead.territoryId],
                    'Branch',
                    lead.branchName ?? lookups.branches[lead.branchId],
                  ),
                  const SizedBox(height: 6),
                  _detailRow(
                    'Assignee',
                    lead.assigneeNames.isNotEmpty
                        ? lead.assigneeNames.join(', ')
                        : lead.assigneeName,
                    'Created',
                    _fmtDate(lead.createdAt),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Two `label: value` cells side by side.
  Widget _detailRow(
    String leftLabel,
    String? leftValue,
    String rightLabel,
    String? rightValue,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _detailCell(leftLabel, leftValue)),
        const SizedBox(width: 10),
        Expanded(child: _detailCell(rightLabel, rightValue)),
      ],
    );
  }

  Widget _detailCell(String label, String? value) {
    final text = value?.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text?.isNotEmpty ?? false ? text! : '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: text?.isNotEmpty ?? false
                  ? AppColors.textPrimary
                  : AppColors.textLight,
            ),
          ),
        ),
      ],
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
        '${outcome.succeeded == 1 ? 'lead' : 'leads'} ${outcome.verb}',
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
              outcome.deleted ? 'Partly deleted' : 'Partly updated',
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
                '${outcome.succeeded} ${outcome.verb} · '
                '${outcome.failures.length} failed',
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

/// `id → name` snapshots of the option lists, so a lead row can show the name
/// behind `lead_type_id`, `territory_id`, … when the list response only carried
/// the id. Built once per build in [_BulkActionScreenState._readLookups].
class _LeadLookups {
  final Map<int, String> statuses;
  final Map<int, String> sources;
  final Map<int, String> types;
  final Map<int, String> territories;
  final Map<int, String> branches;

  const _LeadLookups({
    required this.statuses,
    required this.sources,
    required this.types,
    required this.territories,
    required this.branches,
  });

  /// The lead's source by name: what the API labelled it, else the matching
  /// `/lead-sources` option, else the recognized enum's own name.
  String? sourceOf(LeadModel lead) {
    final raw = lead.sourceName?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    final mapped = sources[lead.leadSourceId];
    if (mapped != null) return mapped;
    if (!lead.sourceKnown) return null;
    final name = lead.source.name;
    return name[0].toUpperCase() + name.substring(1);
  }
}
