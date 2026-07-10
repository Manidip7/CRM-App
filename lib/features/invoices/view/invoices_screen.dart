import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';
import '../../../routes/app_routes.dart';
import '../../dashbord/provider/dashboard_provider.dart';
import '../model/invoice_model.dart';
import '../provider/invoices_provider.dart';

/// Invoices section: a search field, a summary row (Total Invoices, Total
/// Amount, Collection, Pending, Overdue) and the full list of invoice cards.
/// Each card exposes view / update / delete / download actions.
class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(filteredInvoicesProvider);
    final summary = ref.watch(invoiceSummaryProvider);

    // Back button returns to the Dashboard overview tab.
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
              _buildHeader(summary.totalInvoices),
              _buildSearchRow(),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {},
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    slivers: [
                      SliverToBoxAdapter(child: _buildSummaryRow(summary)),
                      if (list.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          sliver: SliverList.builder(
                            itemCount: list.length,
                            itemBuilder: (ctx, i) => _buildCard(list[i]),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.createInvoice),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'New Invoice',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(int count) {
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
                    Text(
                      'Invoices',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
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
                        '$count',
                        style: GoogleFonts.poppins(
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
                  'Track and manage your invoices',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
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

  // ── Search bar ──
  Widget _buildSearchRow() {
    final hasQuery =
        ref.watch(invoiceFilterProvider.select((s) => s.isNotEmpty));
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
              ref.read(invoiceFilterProvider.notifier).setSearch(v),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search invoice no, customer, status...',
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
                      ref.read(invoiceFilterProvider.notifier).clear();
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

  // ── Summary row ──
  Widget _buildSummaryRow(InvoiceSummary s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  label: 'Total Invoices',
                  value: '${s.totalInvoices}',
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryTile(
                  label: 'Total Amount',
                  value: formatMoney(s.totalAmount),
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  label: 'Collection',
                  value: formatMoney(s.collection),
                  icon: Icons.trending_up_rounded,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryTile(
                  label: 'Pending',
                  value: formatMoney(s.pending),
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFFF5A623),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryTile(
                  label: 'Overdue',
                  value: formatMoney(s.overdue),
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Invoice card ──
  Widget _buildCard(InvoiceModel inv) {
    final accent = inv.status.color;
    return GestureDetector(
      onTap: () => _onView(inv),
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
              // Top row: avatar + invoice id / customer + status badge
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
                        inv.displayInitials,
                        style: GoogleFonts.poppins(
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
                          inv.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
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
                                inv.customer,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
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
                  _buildTag(inv.status.label, accent),
                ],
              ),

              const SizedBox(height: 12),

              // Amount row: total + paid
              Row(
                children: [
                  Expanded(
                    child: _amountBlock('Total', inv.amountLabel,
                        AppColors.textPrimary),
                  ),
                  Expanded(
                    child: _amountBlock('Paid', inv.paidLabel, AppColors.green),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: AppColors.divider, height: 1),
              ),

              // Meta row: due date + created by
              Row(
                children: [
                  Icon(Icons.event_rounded,
                      size: 14,
                      color: inv.isOverdue
                          ? AppColors.red
                          : AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    'Due ${_shortDate(inv.dueDate)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight:
                          inv.isOverdue ? FontWeight.w600 : FontWeight.w400,
                      color: inv.isOverdue
                          ? AppColors.red
                          : AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.badge_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      inv.createdBy,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action row: view / update / delete / download
              Row(
                children: [
                  _actionIcon(
                    icon: Icons.visibility_outlined,
                    color: AppColors.primary,
                    tooltip: 'View',
                    onTap: () => _onView(inv),
                  ),
                  const SizedBox(width: 6),
                  _actionIcon(
                    icon: Icons.edit_outlined,
                    color: AppColors.accent,
                    tooltip: 'Update',
                    onTap: () => _onUpdate(inv),
                  ),
                  const SizedBox(width: 6),
                  _actionIcon(
                    icon: Icons.download_rounded,
                    color: AppColors.green,
                    tooltip: 'Download',
                    onTap: () => _onDownload(inv),
                  ),
                  const Spacer(),
                  _actionIcon(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.red,
                    tooltip: 'Delete',
                    onTap: () => _onDelete(inv),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountBlock(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
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

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 48, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(
            'No invoices found',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Actions
  // ─────────────────────────────────────────────
  void _onView(InvoiceModel inv) => _showDetailSheet(inv);

  void _onUpdate(InvoiceModel inv) => _toast('Update ${inv.id} coming soon');

  void _onDownload(InvoiceModel inv) => _toast('Downloading ${inv.id}...');

  Future<void> _onDelete(InvoiceModel inv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete invoice?',
            style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Text(
          '${inv.id} — ${inv.customer} will be permanently removed.',
          style: GoogleFonts.poppins(
              fontSize: 13.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: AppColors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(invoicesProvider.notifier).delete(inv.id);
    _toast('${inv.id} deleted');
  }

  void _showDetailSheet(InvoiceModel inv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    inv.id,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildTag(inv.status.label, inv.status.color),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow('Customer', inv.customer),
            _detailRow('Total Amount', inv.amountLabel),
            _detailRow('Paid Amount', inv.paidLabel),
            _detailRow('Outstanding', formatMoney(inv.outstanding)),
            _detailRow('Due Date', _shortDate(inv.dueDate)),
            _detailRow('Created', _shortDate(inv.createdDate)),
            _detailRow('Created By', inv.createdBy),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontSize: 13, color: Colors.white)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
