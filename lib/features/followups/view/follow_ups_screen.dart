import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/AppColors.dart';
import '../../Leads/view/lead_detail_screen.dart';
import '../../Opportunities/view/opportunity_detail_screen.dart';
import '../../dashbord/provider/dashboard_provider.dart';
import '../model/follow_up_item.dart';
import '../provider/follow_ups_provider.dart';

/// Lists every upcoming follow-up (from Leads + Opportunities) with search,
/// a from/to date range, a status dropdown and an All / Lead / Opportunity
/// source filter. Cards open the matching lead/opportunity detail screen.
class FollowUpsScreen extends ConsumerStatefulWidget {
  const FollowUpsScreen({super.key});

  @override
  ConsumerState<FollowUpsScreen> createState() => _FollowUpsScreenState();
}

class _FollowUpsScreenState extends ConsumerState<FollowUpsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              _buildHeader(),
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
              Expanded(
                child: list.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) => _buildCard(list[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    final list = ref.watch(filteredFollowUpsProvider);
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
                        '${list.length}',
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
                  overdue > 0
                      ? '$overdue overdue · stay on top of your pipeline'
                      : 'Stay on top of your pipeline',
                  style: TextStyle(
                    fontSize: 12.5,
                    color:
                        overdue > 0 ? AppColors.red : AppColors.textSecondary,
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
    final hasActiveFilters =
        f.status != null || f.fromDate != null || f.toDate != null;
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

  // ── Search bar (name / company) ──
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
            hintText: 'Search name or company...',
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

  // ── From / To date pickers + status dropdown ──
  Widget _buildDateAndStatusRow() {
    final f = ref.watch(followUpFilterProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _dateField(
                  label: 'From',
                  value: f.fromDate,
                  onTap: () => _pickDate(isFrom: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateField(
                  label: 'To',
                  value: f.toDate,
                  onTap: () => _pickDate(isFrom: false),
                ),
              ),
              if (f.fromDate != null || f.toDate != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () =>
                      ref.read(followUpFilterProvider.notifier).clearDates(),
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
          _buildStatusDropdown(f.status),
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

  Widget _buildStatusDropdown(FollowUpStatus? selected) {
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
              color: selected?.color ?? AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<FollowUpStatus?>(
                value: selected,
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
                  const DropdownMenuItem<FollowUpStatus?>(
                    value: null,
                    child: Text('All Status'),
                  ),
                  ...FollowUpStatus.values.map(
                    (s) => DropdownMenuItem<FollowUpStatus?>(
                      value: s,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: s.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(s.label),
                        ],
                      ),
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
    final filters = <FollowUpType?>[null, ...FollowUpType.values];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: filters.map((f) {
          final isSelected = selected == f;
          final label = f == null ? 'All' : f.label;
          final activeColor = f == null ? AppColors.primary : f.color;
          return GestureDetector(
            onTap: () =>
                ref.read(followUpFilterProvider.notifier).setType(f),
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
                  if (f != null) ...[
                    Icon(f.icon,
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
  Widget _buildCard(FollowUpItem item) {
    final accent = item.type.color;
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
                      color: item.avatarColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Center(
                      child: Text(
                        item.avatarInitials,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: item.avatarColor,
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
                                item.companyName == null
                                    ? item.contactName
                                    : '${item.contactName} · ${item.companyName}',
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
                      ],
                    ),
                  ),
                  _buildTag(item.type.label.toUpperCase(), accent,
                      accent.withOpacity(0.12)),
                ],
              ),

              const SizedBox(height: 10),

              // Status tag
              Row(
                children: [
                  _buildTag(item.status.tagLabel, item.status.color,
                      item.status.color.withOpacity(0.12)),
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
                    'Next: ${item.dueLabel}',
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
    final f = ref.read(followUpFilterProvider);
    final initial = (isFrom ? f.fromDate : f.toDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked == null) return;
    final notifier = ref.read(followUpFilterProvider.notifier);
    if (isFrom) {
      notifier.setFromDate(picked);
    } else {
      notifier.setToDate(picked);
    }
  }

  void _openDetail(FollowUpItem item) {
    if (item.lead != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LeadDetailScreen(lead: item.lead!),
        ),
      );
    } else if (item.opportunity != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OpportunityDetailScreen(opportunity: item.opportunity!),
        ),
      );
    }
  }

  String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
