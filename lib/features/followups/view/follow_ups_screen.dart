import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/AppColors.dart';
import '../../../routes/app_routes.dart';
import '../../dashbord/provider/dashboard_provider.dart';
import '../model/next_followup_model.dart';
import '../provider/follow_ups_provider.dart';
import '../provider/next_followups_api_provider.dart';

/// Lists upcoming follow-ups from `GET /next-followups` with search, a from/to
/// date range (sent to the server) and a status dropdown / All-Lead-Opportunity
/// source filter (applied over the loaded pages). Scrolling to the bottom
/// fetches the next page. Cards open the matching lead detail screen.
class FollowUpsScreen extends ConsumerStatefulWidget {
  const FollowUpsScreen({super.key});

  @override
  ConsumerState<FollowUpsScreen> createState() => _FollowUpsScreenState();
}

class _FollowUpsScreenState extends ConsumerState<FollowUpsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
      ref.read(followUpsApiProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiState = ref.watch(followUpsApiProvider);
    final list = ref.watch(filteredFollowUpsProvider);

    // Back button → return to the Dashboard overview tab instead of exiting.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        ref.read(dashboardNavProvider.notifier).select(0);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(list, apiState.total),
              _buildSearchRow(),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: ref.watch(followUpFiltersExpandedProvider)
                    ? _buildDateAndStatusRow()
                    : const SizedBox(width: double.infinity),
              ),
              _buildFilterTabs(),
              Expanded(child: _buildBody(apiState, list)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(FollowUpsApiState apiState, List<NextFollowUp> list) {
    // First-page load.
    if (apiState.isLoading && apiState.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    // First-page error.
    if (apiState.error != null && apiState.items.isEmpty) {
      return _buildError(apiState.error!);
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(followUpsApiProvider.notifier).refresh(),
      child: list.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _buildEmptyState(),
                ),
              ],
            )
          : ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              itemCount: list.length + (apiState.hasMore ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i >= list.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _buildCard(list[i]);
              },
            ),
    );
  }

  Widget _buildError(Object error) {
    final message =
        error is ApiException ? error.message : 'Could not load follow-ups.';
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
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => ref.read(followUpsApiProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(List<NextFollowUp> list, int total) {
    final overdue = list.where((i) => i.isOverdue).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ref.read(dashboardNavProvider.notifier).select(0),
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 20, color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Next Follow-ups',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        total > 0 ? '$total' : '${list.length}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Review upcoming follow-ups.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color:
                        overdue > 0 ? AppColors.textLight : AppColors.textSecondary,
                    fontWeight:
                        overdue > 0 ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildFilterToggle(),
        ],
      ),
    );
  }

  // ── Filter toggle — expands/collapses the date + status filters ──
  Widget _buildFilterToggle() {
    final f = ref.watch(followUpFilterProvider);
    final showFilters = ref.watch(followUpFiltersExpandedProvider);
    final notifier = ref.read(followUpsApiProvider.notifier);
    final hasActiveFilters = f.status != null ||
        notifier.dateFrom != null ||
        notifier.dateTo != null;
    final active = showFilters || hasActiveFilters;
    return GestureDetector(
      onTap: () =>
          ref.read(followUpFiltersExpandedProvider.notifier).toggle(),
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
            if (hasActiveFilters && !showFilters)
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

  // ── Search bar (name / company / phone) — filters the loaded pages ──
  Widget _buildSearchRow() {
    final hasQuery =
        ref.watch(followUpFilterProvider.select((f) => f.search.isNotEmpty));
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
          onChanged: (v) =>
              ref.read(followUpFilterProvider.notifier).setSearch(v),
          style:
              const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search name, company or phone...',
            hintStyle:
                const TextStyle(color: AppColors.textLight, fontSize: 13.5),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textLight, size: 20),
            suffixIcon: !hasQuery
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textLight),
                    onPressed: () {
                      _searchController.clear();
                      ref
                          .read(followUpFilterProvider.notifier)
                          .setSearch('');
                    },
                  ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── From / To date pickers (server-side) + status dropdown ──
  Widget _buildDateAndStatusRow() {
    final notifier = ref.watch(followUpsApiProvider.notifier);
    final from = notifier.dateFrom;
    final to = notifier.dateTo;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _dateField(
                  label: 'From',
                  value: from,
                  onTap: () => _pickDate(isFrom: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateField(
                  label: 'To',
                  value: to,
                  onTap: () => _pickDate(isFrom: false),
                ),
              ),
              if (from != null || to != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () =>
                      ref.read(followUpsApiProvider.notifier).clearDates(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.redLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.event_busy_rounded,
                        size: 18, color: AppColors.red),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _buildStatusDropdown(),
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasValue ? _shortDate(value) : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: hasValue
                      ? AppColors.textPrimary
                      : AppColors.textLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    final selected = ref.watch(followUpFilterProvider).status;
    final options = ref.watch(followUpStatusOptionsProvider);
    // Guard: the selected status may not be present in the freshly-loaded list.
    final value = options.contains(selected) ? selected : null;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_outlined,
              size: 16,
              color: value == null
                  ? AppColors.textSecondary
                  : AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: value,
                isExpanded: true,
                isDense: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary),
                style: const TextStyle(
                    fontSize: 13.5, color: AppColors.textPrimary),
                hint: const Text('All Status',
                    style: TextStyle(
                        fontSize: 13.5, color: AppColors.textPrimary)),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Status'),
                  ),
                  ...options.map(
                    (s) => DropdownMenuItem<String?>(
                      value: s,
                      child: Text(s, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (s) =>
                    ref.read(followUpFilterProvider.notifier).setStatus(s),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter tabs: All / Lead / Opportunity ──
  Widget _buildFilterTabs() {
    final selected = ref.watch(followUpFilterProvider).type;
    const types = <String?>[null, 'Lead', 'Opportunity'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: types.map((t) {
          final isSelected = selected == t;
          final label = t ?? 'All';
          final activeColor =
              t == 'Opportunity' ? AppColors.green : AppColors.primary;
          final icon = t == 'Opportunity'
              ? Icons.trending_up_rounded
              : Icons.person_outline_rounded;
          return GestureDetector(
            onTap: () =>
                ref.read(followUpFilterProvider.notifier).setType(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withOpacity(0.12)
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? activeColor : AppColors.divider,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (t != null) ...[
                    Icon(icon,
                        size: 14,
                        color: isSelected
                            ? activeColor
                            : AppColors.textSecondary),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          isSelected ? activeColor : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Empty state ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.event_available_rounded,
              size: 48, color: AppColors.textLight),
          SizedBox(height: 12),
          Text(
            'No follow-ups match your filters',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Follow-up card ──
  Widget _buildCard(NextFollowUp item) {
    final isOpportunity = item.itemType.toLowerCase() == 'opportunity';
    final accent = isOpportunity ? AppColors.green : AppColors.primary;
    final statusColor = item.statusColor ?? AppColors.textSecondary;
    final avatarColor = accent;
    return GestureDetector(
      onTap: () => _openDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border(left: BorderSide(color: accent, width: 3.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: avatar + title + type badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: avatarColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: Text(
                        item.initials,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: avatarColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item.contactName.isEmpty
                                    ? (item.lead.leadNo ?? '—')
                                    : item.contactName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (item.company != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.business_rounded,
                                  size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  item.company!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildTag(item.itemType.toUpperCase(), accent,
                      accent.withOpacity(0.12)),
                ],
              ),

              const SizedBox(height: 10),

              // Status tag
              Row(
                children: [
                  _buildTag(item.statusLabel.toUpperCase(), statusColor,
                      statusColor.withOpacity(0.12)),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: AppColors.divider, height: 1),
              ),

              // Bottom row: due date + phone
              Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 14,
                      color: item.isOverdue
                          ? AppColors.red
                          : AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    _dueLabel(item.nextFollowUpAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: item.isOverdue
                          ? AppColors.red
                          : AppColors.textSecondary,
                      fontWeight:
                          item.isOverdue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  if (item.phone != null) ...[
                    const Icon(Icons.phone_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      item.phone!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Actions
  // ─────────────────────────────────────────────
  Future<void> _pickDate({required bool isFrom}) async {
    final notifier = ref.read(followUpsApiProvider.notifier);
    final initial =
        (isFrom ? notifier.dateFrom : notifier.dateTo) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked == null) return;
    notifier.setDateRange(
      from: isFrom ? picked : notifier.dateFrom,
      to: isFrom ? notifier.dateTo : picked,
    );
  }

  void _openDetail(NextFollowUp item) {
    if (item.isLead) {
      context.push(AppRoutes.leadDetail, extra: item.lead);
    }
  }

  String _shortDate(DateTime d) {
    return '${_months[d.month - 1]} ${d.day}, ${d.year}';
  }

  /// Human-readable due text shown on the card, e.g. "Jun 15, 2026 05:07 PM".
  String _dueLabel(DateTime? utc) {
    if (utc == null) return 'No date';
    final d = utc.toLocal();
    final hour12 = (d.hour % 12 == 0 ? 12 : d.hour % 12).toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour < 12 ? 'AM' : 'PM';
    return '${_months[d.month - 1]} ${d.day}, ${d.year} $hour12:$minute $period';
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}
