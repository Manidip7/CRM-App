import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/platform/downloads_saver.dart';
import '../data/invoices_repository.dart';
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

  /// Pulls the next page once the list is within 300px of the bottom.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      ref.read(invoicesProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoicesProvider);
    final list = ref.watch(filteredInvoicesProvider);
    final summary = ref.watch(invoiceSummaryProvider);
    final hasQuery =
        ref.watch(invoiceFilterProvider.select((s) => s.trim().isNotEmpty));

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
              _buildHeader(
                  state.total > 0 ? state.total : summary.totalInvoices),
              _buildSearchRow(),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      ref.read(invoicesProvider.notifier).refresh(),
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    slivers: [
                      SliverToBoxAdapter(child: _buildSummaryRow(summary)),
                      if (state.isLoading && state.items.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        )
                      else if (state.error != null && state.items.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildErrorState(state.error!),
                        )
                      else if (list.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(hasQuery),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          sliver: SliverList.builder(
                            itemCount: list.length,
                            itemBuilder: (ctx, i) =>
                                _buildCard(list[i], state.deletingId),
                          ),
                        ),
                      if (state.isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 90),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: AppColors.primary),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Can(
          permission: AppPermissions.invoicesAdd,
          child: FloatingActionButton.extended(
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
  Widget _buildCard(InvoiceModel inv, String? deletingId) {
    final accent = inv.status.color;
    final perms = ref.watch(permissionsProvider);
    final isDeleting = deletingId == inv.id;
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
                  _buildTag(inv.displayStatus, accent),
                ],
              ),

              const SizedBox(height: 12),

              // Amount row: total + paid + balance
              Row(
                children: [
                  Expanded(
                    child: _amountBlock('Total', inv.amountLabel,
                        AppColors.textPrimary),
                  ),
                  Expanded(
                    child: _amountBlock('Paid', inv.paidLabel, AppColors.green),
                  ),
                  Expanded(
                    child: _amountBlock(
                      'Balance',
                      formatMoney(inv.outstanding),
                      inv.outstanding > 0
                          ? (inv.isOverdue
                              ? AppColors.red
                              : const Color(0xFFF5A623))
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              if (inv.items.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        inv.items.length == 1
                            ? '${inv.items.first.name} · ${inv.items.first.quantityLabel}'
                            : '${inv.items.length} items · ${inv.items.first.name} +${inv.items.length - 1} more',
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
              ],

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
                  if (perms.can(AppPermissions.invoicesEdit)) ...[
                    const SizedBox(width: 6),
                    _actionIcon(
                      icon: Icons.edit_outlined,
                      color: AppColors.accent,
                      tooltip: 'Update',
                      onTap: () => _onUpdate(inv),
                    ),
                    const SizedBox(width: 6),
                    _actionIcon(
                      icon: Icons.payments_outlined,
                      color: const Color(0xFFF5A623),
                      tooltip: 'Payment',
                      onTap: () => _onPayment(inv),
                    ),
                  ],
                  const SizedBox(width: 6),
                  _actionIcon(
                    icon: Icons.download_rounded,
                    color: AppColors.green,
                    tooltip: 'Download',
                    onTap: () => _onDownload(inv),
                  ),
                  const Spacer(),
                  if (perms.can(AppPermissions.invoicesDelete))
                    isDeleting
                        ? const SizedBox(
                            width: 36,
                            height: 36,
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.red),
                              ),
                            ),
                          )
                        : _actionIcon(
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

  Widget _buildEmptyState(bool hasQuery) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 48, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(
            hasQuery ? 'No invoices match your search' : 'No invoices yet',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Shown when the first page failed to load and nothing is on screen.
  Widget _buildErrorState(Object error) {
    final message = error is ApiException
        ? error.message
        : 'Something went wrong while loading invoices.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(invoicesProvider.notifier).refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Retry',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Actions
  // ─────────────────────────────────────────────
  void _onView(InvoiceModel inv) => _showDetailSheet(inv);

  /// Opens the payment sheet for [inv] — balances, history and a Confirm
  /// Payment action that posts to `/invoices/{id}/payments`.
  void _onPayment(InvoiceModel inv) {
    if (inv.serverId == null) {
      _toast('This invoice has not been saved to the server yet.',
          isError: true);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        // Lift the sheet above the keyboard while the amount is being typed.
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _PaymentSheet(invoiceNumber: inv.id),
      ),
    );
  }

  /// Opens the invoice form prefilled, which saves via `PUT /invoices/{id}`.
  /// An invoice with no server id (never persisted) can't be updated.
  void _onUpdate(InvoiceModel inv) {
    if (inv.serverId == null) {
      _toast('This invoice has not been saved to the server yet.',
          isError: true);
      return;
    }
    context.push(AppRoutes.createInvoice, extra: inv);
  }

  /// Fetches the PDF from `GET /invoices/{id}/download`, opens it in the system
  /// viewer and saves a copy to the public Downloads folder — the same flow the
  /// quotations screen uses.
  Future<void> _onDownload(InvoiceModel inv) async {
    final serverId = inv.serverId;
    if (serverId == null) {
      _toast('This invoice has not been saved to the server yet.',
          isError: true);
      return;
    }

    _toast('Downloading ${inv.id}...');
    final result =
        await ref.read(invoicesRepositoryProvider).downloadInvoice('$serverId');
    if (!mounted) return;

    await result.when(
      success: (file) async {
        if (file.bytes.isEmpty) {
          _toast('Downloaded file was empty', isError: true);
          return;
        }
        final bytes = Uint8List.fromList(file.bytes);
        final filename = _ensurePdf(file.filename);

        // 1) Private copy, opened in the system PDF viewer.
        String? viewPath;
        try {
          viewPath = await _saveForViewing(bytes, filename);
          await OpenFilex.open(viewPath, type: 'application/pdf');
        } catch (_) {
          // Ignore — the public save below still gets a chance.
        }

        // 2) Copy into the public Downloads folder.
        String? publicPath;
        try {
          publicPath = await DownloadsSaver.saveToDownloads(
            bytes: bytes,
            filename: filename,
          );
        } on PlatformException catch (e) {
          publicPath = null;
          if (mounted) {
            _toast('Could not save to Downloads: ${e.message}', isError: true);
          }
        }

        if (!mounted) return;
        if (publicPath != null) {
          _toast('Saved to $publicPath');
        } else if (viewPath != null) {
          _toast('Saved to $viewPath');
        } else {
          _toast('Could not save the file', isError: true);
        }
      },
      failure: (e) async => _toast(e.message, isError: true),
    );
  }

  /// Writes [bytes] to a private app directory so the system PDF viewer can
  /// open it, and returns the saved path.
  Future<String> _saveForViewing(Uint8List bytes, String filename) async {
    final dir = Platform.isAndroid
        ? (await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory())
        : await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Ensures the name ends with `.pdf` so the viewer picks the right app.
  String _ensurePdf(String name) =>
      name.toLowerCase().endsWith('.pdf') ? name : '$name.pdf';

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
    final error = await ref.read(invoicesProvider.notifier).delete(inv);
    if (!mounted) return;
    _toast(error ?? '${inv.id} deleted', isError: error != null);
  }

  void _showDetailSheet(InvoiceModel inv) {
    final customer = inv.customerDetail;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
                _buildTag(inv.displayStatus, inv.status.color),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow('Customer', inv.customer),
            if (customer?.phone != null) _detailRow('Phone', customer!.phone!),
            if (customer?.email != null) _detailRow('Email', customer!.email!),
            if (customer?.address != null)
              _detailRow('Address', customer!.address!),
            if (customer?.location != null)
              _detailRow('Location', customer!.location!),
            if (customer?.pincode != null)
              _detailRow('Pincode', customer!.pincode!),
            _detailRow('Due Date', _shortDate(inv.dueDate)),
            _detailRow('Created', _shortDate(inv.createdDate)),
            _detailRow('Created By', inv.createdBy),

            if (inv.items.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionTitle('Items (${inv.items.length})'),
              const SizedBox(height: 8),
              ...inv.items.map(_itemTile),
            ],

            const SizedBox(height: 16),
            _sectionTitle('Amount'),
            const SizedBox(height: 8),
            _detailRow('Sub Total', formatMoney(inv.subTotal)),
            _detailRow('Tax', formatMoney(inv.taxTotal)),
            if (inv.discountAmount > 0)
              _detailRow('Discount', '- ${formatMoney(inv.discountAmount)}'),
            _detailRow('Total Amount', inv.amountLabel),
            _detailRow('Paid Amount', inv.paidLabel),
            _detailRow('Outstanding', formatMoney(inv.outstanding)),

            if (inv.payments.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionTitle('Payments (${inv.payments.length})'),
              const SizedBox(height: 8),
              ...inv.payments.map((p) => _detailRow(
                    p.date == null ? 'Payment' : _shortDateTime(p.date!),
                    [
                      formatMoney(p.amount),
                      if (p.method != null) p.method!,
                      if (p.reference != null) p.reference!,
                      if (p.notes != null) p.notes!,
                    ].join(' · '),
                  )),
            ],

            if (inv.notes != null && inv.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionTitle('Notes'),
              const SizedBox(height: 6),
              Text(
                inv.notes!,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  /// One line item inside the detail sheet: name + sku on the left, the
  /// qty × price maths and the line total on the right.
  Widget _itemTile(InvoiceItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    item.quantityLabel,
                    if (item.taxPercent > 0)
                      'GST ${item.taxPercent.toStringAsFixed(0)}%',
                    if (item.discountPercent > 0)
                      'Disc ${item.discountPercent.toStringAsFixed(0)}%',
                  ].join(' · '),
                  style: GoogleFonts.poppins(
                      fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatMoney(item.amount),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
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

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontSize: 13, color: Colors.white)),
        backgroundColor: isError ? AppColors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

}

/// `Aug 21, 2026`. Top-level so the payment sheet shares it with the list.
String _shortDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

/// `1:00 PM` — payments carry a time, so the history shows it.
String _shortTime(DateTime d) {
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// `Aug 21, 2026 · 1:00 PM`.
String _shortDateTime(DateTime d) => '${_shortDate(d)} · ${_shortTime(d)}';

/// Payment sheet for one invoice: the balances, the payment history, and an
/// editable amount that Confirm Payment posts to `/invoices/{id}/payments`.
///
/// It looks the invoice up by number on every build rather than holding a copy,
/// so the figures stay correct after the list refreshes.
class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({required this.invoiceNumber});

  final String invoiceNumber;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  late final TextEditingController _amount;
  final _notes = TextEditingController();

  /// When this payment is recorded — stamped once when the sheet opens so the
  /// time shown is the time sent.
  final DateTime _paidAt = DateTime.now();

  /// Set once the user types in the amount field, so the ledger's due balance
  /// never overwrites what they entered.
  bool _amountEdited = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with the full due balance — the common case is paying it off.
    final due = _invoice()?.outstanding ?? 0;
    _amount = TextEditingController(text: due > 0 ? _plain(due) : '');
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  InvoiceModel? _invoice() {
    for (final inv in ref.read(invoicesProvider).items) {
      if (inv.id == widget.invoiceNumber) return inv;
    }
    return null;
  }

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final inv = ref.watch(invoicesProvider.select((s) {
      for (final i in s.items) {
        if (i.id == widget.invoiceNumber) return i;
      }
      return null;
    }));
    // The invoice vanished (deleted elsewhere) — nothing left to pay.
    if (inv == null) return const SizedBox.shrink();

    final isPaying = ref.watch(
        invoicesProvider.select((s) => s.payingId == widget.invoiceNumber));

    // The ledger endpoint owns the live figures; the list row covers the gap
    // while it loads (and if it fails).
    final serverId = inv.serverId;
    final historyAsync = serverId == null
        ? const AsyncValue<InvoicePaymentHistory>.loading()
        : ref.watch(invoicePaymentsProvider(serverId));
    final history = historyAsync.asData?.value;

    final totalAmount = history?.totalAmount ?? inv.amount;
    final alreadyPaid = history?.alreadyPaid ?? inv.paidAmount;
    final dueBalance = history?.dueBalance ?? inv.outstanding;
    final currentStatus = history?.currentStatus ?? inv.displayStatus;

    // Once the real due balance arrives, re-prefill the amount — unless the
    // user has already typed something.
    if (serverId != null) {
      ref.listen<AsyncValue<InvoicePaymentHistory>>(
        invoicePaymentsProvider(serverId),
        (previous, next) {
          final due = next.asData?.value.dueBalance;
          if (due == null || _amountEdited) return;
          _amount.text = due > 0 ? _plain(due) : '';
        },
      );
    }

    return SafeArea(
      // Scrollable: with the keyboard up the sheet loses ~half its height, and
      // a plain Column would overflow.
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5A623).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.payments_outlined,
                      size: 19, color: Color(0xFFF5A623)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Record Payment',
                        style: GoogleFonts.poppins(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        inv.id,
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
            const SizedBox(height: 16),

            // ── Balances ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _row('Total Amount', formatMoney(totalAmount)),
                  _row('Already Paid', formatMoney(alreadyPaid),
                      color: AppColors.green),
                  _row('Due Balance', formatMoney(dueBalance),
                      color: dueBalance > 0
                          ? AppColors.red
                          : AppColors.textSecondary,
                      bold: true),
                  const Divider(color: AppColors.divider, height: 20),
                  _row('Customer', inv.customer),
                  _row('Due Date', _shortDate(inv.dueDate),
                      color: inv.isOverdue ? AppColors.red : null),
                  _row('Current Status', currentStatus,
                      color: InvoiceStatus.fromApi(currentStatus).color),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── History ──
            Row(
              children: [
                Text(
                  'Payment History',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                if (history != null && history.payments.isNotEmpty)
                  Text(
                    '${history.payments.length}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _historySection(historyAsync, serverId),
            const SizedBox(height: 16),

            // ── Amount to pay ──
            Text(
              'Payment Amount to Pay',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amount,
              enabled: !isPaying,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: (_) => _amountEdited = true,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
                hintText: '0',
                hintStyle: const TextStyle(color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.background,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                border: _border(AppColors.divider),
                enabledBorder: _border(AppColors.divider),
                focusedBorder: _border(AppColors.primary),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 13, color: AppColors.textLight),
                const SizedBox(width: 5),
                Text(
                  'Payment time: ${_shortDateTime(_paidAt)}',
                  style: GoogleFonts.poppins(
                      fontSize: 11.5, color: AppColors.textLight),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Notes ──
            Text(
              'Notes',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notes,
              enabled: !isPaying,
              maxLines: 2,
              minLines: 1,
              style: GoogleFonts.poppins(
                  fontSize: 13.5, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. Paid via UPI / Bank Transfer',
                hintStyle:
                    const TextStyle(color: AppColors.textLight, fontSize: 13),
                filled: true,
                fillColor: AppColors.background,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: _border(AppColors.divider),
                enabledBorder: _border(AppColors.divider),
                focusedBorder: _border(AppColors.primary),
              ),
            ),
            const SizedBox(height: 18),

            // ── Actions ──
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed:
                          isPaying ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed:
                          isPaying ? null : () => _confirm(inv, dueBalance),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        disabledBackgroundColor:
                            AppColors.green.withOpacity(0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)),
                      ),
                      child: isPaying
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2, color: Colors.white),
                            )
                          : Text(
                              'Confirm Payment',
                              style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                  fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: bold ? 15 : 13.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The ledger from `GET /invoices/{id}/payments`, with its own loading and
  /// error states so a slow or failed fetch doesn't block recording a payment.
  Widget _historySection(
      AsyncValue<InvoicePaymentHistory> async, int? serverId) {
    return async.when(
      loading: () => Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Text('Loading payments...',
              style: GoogleFonts.poppins(
                  fontSize: 12.5, color: AppColors.textLight)),
        ],
      ),
      error: (e, _) => InkWell(
        onTap: serverId == null
            ? null
            : () => ref.invalidate(invoicePaymentsProvider(serverId)),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 15, color: AppColors.red),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                e is ApiException ? e.message : 'Could not load payments',
                maxLines: 2,
                style:
                    GoogleFonts.poppins(fontSize: 12, color: AppColors.red),
              ),
            ),
            Text('Retry',
                style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ],
        ),
      ),
      data: (history) {
        if (history.payments.isEmpty) {
          return Text(
            'No payments recorded yet',
            style: GoogleFonts.poppins(
                fontSize: 12.5, color: AppColors.textLight),
          );
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 170),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: history.payments.length,
            itemBuilder: (ctx, i) => _historyTile(history.payments[i]),
          ),
        );
      },
    );
  }

  Widget _historyTile(InvoicePayment p) {
    // Date + time on the first line, whatever else the payment carries below.
    final when = p.date == null ? 'Payment' : _shortDateTime(p.date!);
    final meta = [
      if (p.method != null) p.method!,
      if (p.reference != null) p.reference!,
      if (p.notes != null) p.notes!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_rounded,
                size: 15, color: AppColors.green),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  when,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatMoney(p.amount),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  Future<void> _confirm(InvoiceModel inv, double dueBalance) async {
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    final error = await ref.read(invoicesProvider.notifier).addPayment(
          inv,
          amount,
          paidAt: _paidAt,
          notes: _notes.text.trim(),
          dueBalance: dueBalance,
        );
    if (!mounted) return;

    if (error != null) {
      _snack(error, isError: true);
      return;
    }
    Navigator.pop(context);
    _snack('Payment of ${formatMoney(amount)} recorded');
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontSize: 13, color: Colors.white)),
        backgroundColor: isError ? AppColors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }
}
