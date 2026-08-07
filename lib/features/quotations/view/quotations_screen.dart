import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/platform/downloads_saver.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/utils/AppColors.dart';
import '../../../routes/app_routes.dart';
import '../data/quotations_repository.dart';
import '../../Opportunities/model/opportunity_model.dart';
import '../../Opportunities/provider/opportunities_provider.dart';
import '../../dashbord/provider/dashboard_provider.dart';
import '../model/quotation_model.dart';
import '../provider/quotations_provider.dart';

/// Lists every quotation with a search field, a from/to date range and a status
/// dropdown (All Status, Final Only and every individual status). Each card
/// exposes download, edit and delete actions.
class QuotationsScreen extends ConsumerStatefulWidget {
  const QuotationsScreen({super.key});

  @override
  ConsumerState<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends ConsumerState<QuotationsScreen> {
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
      ref.read(quotationsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiState = ref.watch(quotationsProvider);
    final list = ref.watch(filteredQuotationsProvider);

    // Back button → return to the Dashboard overview tab instead of exiting.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        ref.read(dashboardNavProvider.notifier).select(0);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: Can(
          permission: AppPermissions.quotationsAdd,
          child: FloatingActionButton.extended(
            onPressed: _onAdd,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'New Quote',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(apiState.total),
              _buildSearchRow(),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: ref.watch(quotationFiltersExpandedProvider)
                    ? _buildDateAndStatusRow()
                    : const SizedBox(width: double.infinity),
              ),
              Expanded(child: _buildBody(apiState, list)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(QuotationsState apiState, List<QuotationModel> list) {
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
      onRefresh: () => ref.read(quotationsProvider.notifier).refresh(),
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
        error is ApiException ? error.message : 'Could not load quotations.';
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
            onPressed: () => ref.read(quotationsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(int total) {
    final list = ref.watch(filteredQuotationsProvider);
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
                        'Quotations',
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
                const Text(
                  'Manage and track your quotes',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
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
    final f = ref.watch(quotationFilterProvider);
    final showFilters = ref.watch(quotationFiltersExpandedProvider);
    final hasActiveFilters = f.statusFilter != QuotationStatusFilter.all ||
        f.fromDate != null ||
        f.toDate != null;
    final active = showFilters || hasActiveFilters;
    return GestureDetector(
      onTap: () =>
          ref.read(quotationFiltersExpandedProvider.notifier).toggle(),
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

  // ── Search bar (number / client / company) ──
  Widget _buildSearchRow() {
    final hasQuery =
        ref.watch(quotationFilterProvider.select((f) => f.search.isNotEmpty));
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
              ref.read(quotationFilterProvider.notifier).setSearch(v),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search quote no, client or title...',
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
                          .read(quotationFilterProvider.notifier)
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
    final f = ref.watch(quotationFilterProvider);
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
                      ref.read(quotationFilterProvider.notifier).clearDates(),
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
          _buildStatusDropdown(f.statusFilter),
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
                  color:
                      hasValue ? AppColors.textPrimary : AppColors.textLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(QuotationStatusFilter selected) {
    final accent = selected.finalOnly
        ? AppColors.green
        : selected.status?.color ?? AppColors.textSecondary;
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
          Icon(Icons.flag_outlined, size: 16, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<QuotationStatusFilter>(
                value: selected,
                isExpanded: true,
                isDense: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary),
                style: const TextStyle(
                    fontSize: 13.5, color: AppColors.textPrimary),
                items: [
                  const DropdownMenuItem<QuotationStatusFilter>(
                    value: QuotationStatusFilter.all,
                    child: Text('All Status'),
                  ),
                  DropdownMenuItem<QuotationStatusFilter>(
                    value: QuotationStatusFilter.onlyFinal,
                    child: Row(
                      children: const [
                        Icon(Icons.verified_rounded,
                            size: 14, color: AppColors.green),
                        SizedBox(width: 8),
                        Text('Final Only'),
                      ],
                    ),
                  ),
                  ...QuotationStatus.values.map(
                    (s) => DropdownMenuItem<QuotationStatusFilter>(
                      value: QuotationStatusFilter(status: s),
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
                onChanged: (filter) {
                  if (filter == null) return;
                  ref
                      .read(quotationFilterProvider.notifier)
                      .setStatusFilter(filter);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.request_quote_outlined,
              size: 48, color: AppColors.textLight),
          SizedBox(height: 12),
          Text(
            'No quotations match your filters',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Quotation card ──
  Widget _buildCard(QuotationModel item) {
    final accent = item.status.color;
    final perms = ref.watch(permissionsProvider);
    return GestureDetector(
      onTap: () => _openOpportunity(item),
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
            // Top row: avatar + title + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Text(
                      item.displayInitials,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: accent,
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
                                  ? item.clientName
                                  : '${item.clientName} · ${item.companyName}',
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
                _buildTag(item.status.tagLabel, accent,
                    accent.withOpacity(0.12)),
              ],
            ),

            const SizedBox(height: 12),

            // Meta row: quote number + amount + item count
            Row(
              children: [
                _metaChip(Icons.tag_rounded, item.number),
                const SizedBox(width: 8),
                // _metaChip(Icons.inventory_2_outlined,
                //     '${item.effectiveItemCount} item${item.effectiveItemCount == 1 ? '' : 's'}'),
                const Spacer(),
                Text(
                  item.amountLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.divider, height: 1),
            ),

            // Bottom row: dates + action icons
            Row(
              children: [
                const Icon(Icons.event_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 5),
                Text(
                  'Valid till ${_shortDate(item.validUntil)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                // Each row action carries its own permission, so a role with
                // only `quotations.download` sees exactly one icon here.
                if (perms.can(AppPermissions.quotationsDownload)) ...[
                  _actionIcon(
                    icon: Icons.download_rounded,
                    color: AppColors.primary,
                    tooltip: 'Download',
                    onTap: () => _onDownload(item),
                  ),
                  const SizedBox(width: 6),
                ],
                if (perms.can(AppPermissions.quotationsEdit)) ...[
                  _actionIcon(
                    icon: Icons.edit_outlined,
                    color: AppColors.green,
                    tooltip: 'Edit',
                    onTap: () => _onEdit(item),
                  ),
                  const SizedBox(width: 6),
                ],
                if (perms.can(AppPermissions.quotationsDelete))
                  if (ref.watch(quotationsProvider).deletingId == item.id)
                    const Padding(
                      padding: EdgeInsets.all(6),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.red),
                      ),
                    )
                  else
                    _actionIcon(
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.red,
                      tooltip: 'Delete',
                      onTap: () => _onDelete(item),
                    ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
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
  /// Opens the quotation form with a fresh, blank quote to create a new one.
  void _onAdd() {
    final now = DateTime.now();
    final blank = QuotationModel(
      id: 'new-${now.millisecondsSinceEpoch}',
      number: '',
      title: '',
      clientName: '',
      amount: 0,
      itemCount: 0,
      status: QuotationStatus.draft,
      createdDate: now,
      validUntil: now.add(const Duration(days: 30)),
      currency: '₹',
      taxPercent: QuotationModel.defaultGstPercent,
    );
    context.push('${AppRoutes.editQuotation}?create=1', extra: blank);
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final f = ref.read(quotationFilterProvider);
    final initial = (isFrom ? f.fromDate : f.toDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked == null) return;
    final notifier = ref.read(quotationFilterProvider.notifier);
    if (isFrom) {
      notifier.setFromDate(picked);
    } else {
      notifier.setToDate(picked);
    }
  }

  Future<void> _onDownload(QuotationModel item) async {
    _toast('Downloading ${item.number}...');
    final result =
        await ref.read(quotationsRepositoryProvider).downloadQuotation(item.id);
    if (!mounted) return;
    await result.when(
      success: (file) async {
        if (file.bytes.isEmpty) {
          _toast('Downloaded file was empty');
          return;
        }
        final bytes = Uint8List.fromList(file.bytes);
        final filename = _ensurePdf(file.filename);

        // 1) Write a private copy and open it in the system PDF viewer.
        String? viewPath;
        try {
          viewPath = await _saveForViewing(bytes, filename);
          await OpenFilex.open(viewPath, type: 'application/pdf');
        } catch (_) {
          // Ignore — we still try to save a public copy and report below.
        }

        // 2) Save a copy to the public Downloads folder.
        String? publicPath;
        try {
          publicPath = await DownloadsSaver.saveToDownloads(
            bytes: bytes,
            filename: filename,
          );
        } on PlatformException catch (e) {
          publicPath = null;
          if (mounted) _toast('Could not save to Downloads: ${e.message}');
        }

        if (!mounted) return;
        if (publicPath != null) {
          _toast('Saved to $publicPath');
        } else if (viewPath != null) {
          _toast('Saved to $viewPath');
        } else {
          _toast('Could not save the file');
        }
      },
      failure: (e) async => _toast(e.message),
    );
  }

  /// Writes [bytes] to a private app directory so the file can be opened by the
  /// system PDF viewer, and returns the saved path.
  Future<String> _saveForViewing(Uint8List bytes, String filename) async {
    final dir = Platform.isAndroid
        ? (await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory())
        : await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Ensures the file name ends with `.pdf` so the viewer picks the right app.
  String _ensurePdf(String name) =>
      name.toLowerCase().endsWith('.pdf') ? name : '$name.pdf';

  void _onEdit(QuotationModel item) {
    context.push(AppRoutes.editQuotation, extra: item);
  }

  /// Opens the opportunity this quotation is linked to. Falls back to a toast
  /// when the quotation has no (or a stale) opportunity attached.
  void _openOpportunity(QuotationModel item) {
    final id = item.opportunityId;
    if (id == null) {
      _toast('No opportunity linked to ${item.number}');
      return;
    }
    final oppState = ref.read(opportunitiesProvider);
    final opp = [...oppState.items, ...oppState.backlogItems]
        .where((o) => o.id == id)
        .cast<OpportunityModel?>()
        .firstWhere((o) => o != null, orElse: () => null);
    if (opp == null) {
      _toast('Linked opportunity no longer exists');
      return;
    }
    context.push(AppRoutes.opportunityDetail, extra: opp);
  }

  Future<void> _onDelete(QuotationModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete quotation?',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Text(
          '${item.number} — ${item.title} will be permanently removed.',
          style: const TextStyle(
              fontSize: 13.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error = await ref.read(quotationsProvider.notifier).delete(item);
    if (!mounted) return;
    _toast(error ?? '${item.number} deleted', isError: error != null);
  }

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontSize: 13, color: Colors.white)),
        backgroundColor: isError ? AppColors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
