import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/AppColors.dart';
import '../../customers/model/customer_list_item.dart';
import '../../customers/provider/customers_api_provider.dart';
import '../model/catalog_item.dart';
import '../model/invoice_model.dart';
import '../provider/invoices_provider.dart';


class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key, this.invoice});

  /// The invoice being edited (`PUT /invoices/{id}`), or null for a new one.
  final InvoiceModel? invoice;

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _invoiceNo = TextEditingController();
  final _overallDiscount = TextEditingController();
  final _notes = TextEditingController();

  bool get _isEditing => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    // Either prefill from the invoice being edited, or seed a fresh draft
    // (suggested number + one empty line) once the list is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existing = widget.invoice;
      final notifier = ref.read(invoiceDraftProvider.notifier);

      if (existing != null) {
        notifier.loadFrom(existing);
        final draft = ref.read(invoiceDraftProvider);
        _invoiceNo.text = existing.id;
        _notes.text = draft.notes;
        _overallDiscount.text = draft.overallDiscount > 0
            ? _plainNumber(draft.overallDiscount)
            : '';
        return;
      }

      final suggested = suggestInvoiceNumber(ref.read(invoicesProvider).items);
      _invoiceNo.text = suggested;
      notifier.reset(suggested);
    });
  }

  String _plainNumber(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _invoiceNo.dispose();
    _overallDiscount.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items =
        ref.watch(invoiceDraftProvider.select((d) => d.items));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _sectionLabel('Invoice Details'),
                  _invoiceNoField(),
                  _customerField(),
                  _statusField(),
                  _dueDateField(),
                  const SizedBox(height: 8),
                  _lineItemsHeader(),
                  for (final it in items)
                    _LineItemCard(key: ValueKey(it.id), itemId: it.id),
                  _addItemButton(),
                  const SizedBox(height: 16),
                  _sectionLabel('Price Summary'),
                  _priceSummary(),
                  const SizedBox(height: 16),
                  _sectionLabel('Notes'),
                  _notesField(),
                  const SizedBox(height: 20),
                  _actionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ──
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
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
              child: const Icon(Icons.arrow_back_rounded,
                  size: 20, color: AppColors.textPrimary),
            ),
          ),
          Text(
            _isEditing ? 'Update Invoice' : 'New Invoice',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ── Header fields ──
  Widget _invoiceNoField() {
    return _labeledField(
      'Invoice No',
      TextField(
        controller: _invoiceNo,
        onChanged: (v) =>
            ref.read(invoiceDraftProvider.notifier).setInvoiceNo(v),
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: _inputDecoration('INV-2026-0001'),
      ),
    );
  }

  Widget _customerField() {
    final customersAsync = ref.watch(customerOptionsProvider);
    final customers = customersAsync.asData?.value ?? const <CustomerListItem>[];
    final selectedId =
        ref.watch(invoiceDraftProvider.select((d) => d.customerId));
    // Key the dropdown on the customer id, not the name: `customer_id` is what
    // the API wants, and two customers may share a name.
    final value = customers.any((c) => c.id == selectedId) ? selectedId : null;
    return _labeledField(
      'Bill To (Customer)',
      _dropdownShell(
        DropdownButton<int>(
          value: value,
          isExpanded: true,
          hint: Text(
            customersAsync.isLoading
                ? 'Loading customers…'
                : customersAsync.hasError
                    ? 'Could not load customers'
                    : 'Select customer',
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textLight),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          items: customers
              .map((c) => DropdownMenuItem<int>(
                    value: c.id,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (id) {
            if (id == null) return;
            final picked = customers.firstWhere((c) => c.id == id);
            ref
                .read(invoiceDraftProvider.notifier)
                .setCustomer(id: picked.id, name: picked.name);
          },
        ),
      ),
    );
  }

  Widget _statusField() {
    final status = ref.watch(invoiceDraftProvider.select((d) => d.status));
    return _labeledField(
      'Status',
      _dropdownShell(
        DropdownButton<InvoiceStatus>(
          value: status,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          items: InvoiceStatus.formOptions
              .map((s) => DropdownMenuItem<InvoiceStatus>(
                    value: s,
                    child: Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                              color: s.color, shape: BoxShape.circle),
                        ),
                        Text(s.label),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (s) {
            if (s != null) {
              ref.read(invoiceDraftProvider.notifier).setStatus(s);
            }
          },
        ),
      ),
    );
  }

  Widget _dueDateField() {
    final dueDate =
        ref.watch(invoiceDraftProvider.select((d) => d.dueDate));
    return _labeledField(
      'Due Date',
      GestureDetector(
        onTap: _pickDueDate,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.event_rounded,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Text(
                dueDate == null ? 'Select due date' : _shortDate(dueDate),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: dueDate == null
                      ? AppColors.textLight
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final current =
        ref.read(invoiceDraftProvider).dueDate ?? now.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(invoiceDraftProvider.notifier).setDueDate(picked);
    }
  }

  // ── Line items ──
  Widget _lineItemsHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Text(
            'LINE ITEMS',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addItemButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: GestureDetector(
        onTap: () => ref.read(invoiceDraftProvider.notifier).addItem(),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.35),
                style: BorderStyle.solid),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Add Line Item',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Price summary ──
  Widget _priceSummary() {
    final draft = ref.watch(invoiceDraftProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', formatMoney(draft.subtotal)),
          _summaryRow('Tax', formatMoney(draft.tax)),
          _summaryRow('Line Discount', '- ${formatMoney(draft.lineDiscount)}'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Overall Discount',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  height: 40,
                  child: TextField(
                    controller: _overallDiscount,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [_decimalFormatter],
                    onChanged: (v) => ref
                        .read(invoiceDraftProvider.notifier)
                        .setOverallDiscount(double.tryParse(v) ?? 0),
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary),
                    decoration: _inputDecoration('0'),
                  ),
                ),
              ],
            ),
          ),
          _summaryRow('Discount', '- ${formatMoney(draft.totalDiscount)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(color: AppColors.divider, height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Grand Total',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                formatMoney(draft.grandTotal),
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _notesField() {
    return TextField(
      controller: _notes,
      maxLines: 4,
      onChanged: (v) => ref.read(invoiceDraftProvider.notifier).setNotes(v),
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: _inputDecoration('Add a note for this invoice...'),
    );
  }

  // ── Cancel / Save ──
  Widget _actionButtons() {
    final isSaving = ref.watch(invoiceDraftProvider.select((d) => d.isSaving));
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: isSaving ? null : () => Navigator.maybePop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 15,
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
            height: 50,
            child: ElevatedButton(
              onPressed: isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: Colors.white),
                    )
                  : Text(
                      _isEditing ? 'Update Invoice' : 'Save Invoice',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
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

  /// POSTs the draft to `/invoices`. Validation lives in the notifier so the
  /// same rules apply wherever submit is called from; it returns null on
  /// success or the message to show.
  Future<void> _save() async {
    final error = await ref.read(invoiceDraftProvider.notifier).submit();
    if (!mounted) return;
    if (error != null) {
      _toast(error, isError: true);
      return;
    }
    Navigator.maybePop(context);
    _toast(_isEditing ? 'Invoice updated' : 'Invoice created');
  }

  // ── Shared field helpers ──
  Widget _labeledField(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _dropdownShell(Widget dropdown) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(child: dropdown),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textLight, fontSize: 13.5),
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: _border(AppColors.divider),
        enabledBorder: _border(AppColors.divider),
        focusedBorder: _border(AppColors.primary),
      );

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontSize: 13, color: Colors.white)),
        backgroundColor: isError ? AppColors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: isError ? 4 : 2),
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

/// Only digits and a single decimal point.
final _decimalFormatter =
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'));

/// One editable line-item card. Owns its [TextEditingController]s so typing
/// never resets the cursor, and pushes every change into [invoiceDraftProvider].
class _LineItemCard extends ConsumerStatefulWidget {
  const _LineItemCard({super.key, required this.itemId});

  final String itemId;

  @override
  ConsumerState<_LineItemCard> createState() => _LineItemCardState();
}

class _LineItemCardState extends ConsumerState<_LineItemCard> {
  late final TextEditingController _qty;
  late final TextEditingController _unitPrice;
  late final TextEditingController _tax;
  late final TextEditingController _disc;

  @override
  void initState() {
    super.initState();
    final it = _current();
    _qty = TextEditingController(text: _numText(it?.qty ?? 1));
    _unitPrice = TextEditingController(text: _numText(it?.unitPrice ?? 0));
    _tax = TextEditingController(text: _numText(it?.taxPercent ?? 0));
    _disc = TextEditingController(text: _numText(it?.discPercent ?? 0));
  }

  InvoiceLineItem? _current() {
    final items = ref.read(invoiceDraftProvider).items;
    for (final it in items) {
      if (it.id == widget.itemId) return it;
    }
    return null;
  }

  String _numText(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _qty.dispose();
    _unitPrice.dispose();
    _tax.dispose();
    _disc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch this whole line so both the item dropdown value and the AMOUNT
    // column stay live. Returns the same instance when other rows change, so
    // this card only rebuilds on its own edits.
    final item = ref.watch(invoiceDraftProvider.select((d) {
      for (final it in d.items) {
        if (it.id == widget.itemId) return it;
      }
      return null;
    }));
    if (item == null) return const SizedBox.shrink();
    final amount = item.amount;
    final catalog = ref.watch(catalogItemsProvider);
    final notifier = ref.read(invoiceDraftProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item dropdown + delete
          Row(
            children: [
              Expanded(child: _itemDropdown(item, catalog)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => notifier.removeItem(widget.itemId),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Qty / Unit price / Tax% / Disc%
          Row(
            children: [
              Expanded(
                child: _numCell(
                  label: 'QTY',
                  controller: _qty,
                  onChanged: (v) => notifier.updateItem(widget.itemId,
                      (it) => it.copyWith(qty: double.tryParse(v) ?? 0)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numCell(
                  label: 'UNIT PRICE',
                  controller: _unitPrice,
                  onChanged: (v) => notifier.updateItem(widget.itemId,
                      (it) => it.copyWith(unitPrice: double.tryParse(v) ?? 0)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _numCell(
                  label: 'TAX %',
                  controller: _tax,
                  onChanged: (v) => notifier.updateItem(widget.itemId,
                      (it) => it.copyWith(taxPercent: double.tryParse(v) ?? 0)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numCell(
                  label: 'DISC %',
                  controller: _disc,
                  // Locked when the catalogue says the item takes no discount.
                  enabled: item.discountAllowed,
                  onChanged: (v) => notifier.updateItem(widget.itemId,
                      (it) => it.copyWith(discPercent: double.tryParse(v) ?? 0)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'AMOUNT',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              Text(
                formatMoney(amount),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The item picker, driven by `GET /items` via [catalogItemsProvider]. Shows
  /// a spinner while the catalogue loads and a tappable retry when it fails, so
  /// a network hiccup never leaves an empty, silent dropdown.
  Widget _itemDropdown(InvoiceLineItem line, AsyncValue<List<CatalogItem>> catalog) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: catalog.when(
        loading: () => Row(
          children: [
            const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text('Loading items...',
                style: GoogleFonts.poppins(
                    fontSize: 13.5, color: AppColors.textLight)),
          ],
        ),
        error: (e, _) => InkWell(
          onTap: () => ref.invalidate(catalogItemsProvider),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 16, color: AppColors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  e is ApiException ? e.message : 'Could not load items',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 12.5, color: AppColors.red),
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
        data: (items) {
          if (items.isEmpty) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text('No items available',
                  style: GoogleFonts.poppins(
                      fontSize: 13.5, color: AppColors.textLight)),
            );
          }
          // Guard the dropdown's value: a row whose item is no longer in the
          // catalogue must fall back to null, or DropdownButton asserts.
          final selectedId =
              items.any((c) => c.id == line.itemId) ? line.itemId : null;

          return DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedId,
              isExpanded: true,
              hint: Text('Select item',
                  style: GoogleFonts.poppins(
                      fontSize: 13.5, color: AppColors.textLight)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary),
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              // The collapsed field shows just the name; the open menu adds the
              // SKU/unit and price lines.
              selectedItemBuilder: (ctx) => items
                  .map((c) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(c.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              items: items
                  .map((c) => DropdownMenuItem<int>(
                        value: c.id,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          GoogleFonts.poppins(fontSize: 13.5)),
                                  if (c.subtitle != null)
                                    Text(c.subtitle!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              formatMoney(c.sellingPrice),
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                _onItemPicked(items.firstWhere((c) => c.id == id));
              },
            ),
          );
        },
      ),
    );
  }

  /// Applies a catalogue pick to the row and syncs the text controllers, so the
  /// UNIT PRICE / TAX% / DISC% fields show the item's own figures.
  void _onItemPicked(CatalogItem picked) {
    ref
        .read(invoiceDraftProvider.notifier)
        .updateItem(widget.itemId, (it) => it.fromCatalog(picked));

    final line = _current();
    _unitPrice.text = _numText(picked.sellingPrice);
    _tax.text = _numText(picked.taxPercent);
    _qty.text = _numText(line?.qty ?? 1);
    if (!picked.discountAllowed) _disc.text = '0';
  }

  Widget _numCell({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 5, left: 2),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
        ),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_decimalFormatter],
          onChanged: onChanged,
          style: TextStyle(
              fontSize: 14,
              color: enabled ? AppColors.textPrimary : AppColors.textLight),
          decoration: _cellDecoration('0'),
        ),
      ],
    );
  }

  InputDecoration _cellDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textLight, fontSize: 13),
        isDense: true,
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: _cellBorder(AppColors.divider),
        enabledBorder: _cellBorder(AppColors.divider),
        focusedBorder: _cellBorder(AppColors.primary),
      );

  OutlineInputBorder _cellBorder(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color),
      );
}
