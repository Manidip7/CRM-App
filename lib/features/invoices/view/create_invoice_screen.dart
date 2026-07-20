import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';
import '../../customers/model/customer_list_item.dart';
import '../../customers/provider/customers_api_provider.dart';
import '../model/invoice_model.dart';
import '../provider/invoices_provider.dart';

/// Form to create a new invoice. All state (header fields, the dynamic line-item
/// list and the live price summary) is held in [invoiceDraftProvider] so the
/// screen needs no [setState].
class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _invoiceNo = TextEditingController();
  final _overallDiscount = TextEditingController();
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Seed a fresh draft (suggested number + one empty line) once the list is
    // available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final suggested =
          suggestInvoiceNumber(ref.read(invoicesProvider));
      _invoiceNo.text = suggested;
      ref.read(invoiceDraftProvider.notifier).reset(suggested);
    });
  }

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
            'New Invoice',
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
    final selected =
        ref.watch(invoiceDraftProvider.select((d) => d.customer));
    final value = customers.any((c) => c.name == selected) ? selected : null;
    return _labeledField(
      'Bill To (Customer)',
      _dropdownShell(
        DropdownButton<String>(
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
              .map((c) => DropdownMenuItem<String>(
                    value: c.name,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) =>
              ref.read(invoiceDraftProvider.notifier).setCustomer(v),
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
          items: InvoiceStatus.values
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
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.maybePop(context),
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
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Save Invoice',
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

  void _save() {
    final draft = ref.read(invoiceDraftProvider);
    final invoiceNo = draft.invoiceNo.trim();

    if (invoiceNo.isEmpty) {
      _toast('Invoice number is required');
      return;
    }
    if (draft.customer == null || draft.customer!.trim().isEmpty) {
      _toast('Please select a customer');
      return;
    }
    final hasLine = draft.items.any((it) => it.item.trim().isNotEmpty);
    if (!hasLine) {
      _toast('Add at least one line item');
      return;
    }

    final now = DateTime.now();
    final invoice = InvoiceModel(
      id: invoiceNo,
      customer: draft.customer!.trim(),
      dueDate: draft.dueDate ?? now.add(const Duration(days: 30)),
      createdDate: now,
      status: draft.status,
      amount: draft.grandTotal,
      paidAmount: 0,
      createdBy: 'Admin Owner',
    );

    ref.read(invoicesProvider.notifier).upsert(invoice);
    Navigator.maybePop(context);
    _toast('$invoiceNo created');
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
    final catalog = ref.watch(productCatalogProvider);
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
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: item.item.isEmpty ? null : item.item,
                      isExpanded: true,
                      hint: Text('Select item',
                          style: GoogleFonts.poppins(
                              fontSize: 13.5, color: AppColors.textLight)),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary),
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary),
                      items: catalog
                          .map((c) => DropdownMenuItem<String>(
                                value: c.name,
                                child: Text(c.name,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (name) {
                        if (name == null) return;
                        final match = catalog.firstWhere((c) => c.name == name);
                        notifier.updateItem(
                          widget.itemId,
                          (it) => it.copyWith(
                              item: name, unitPrice: match.defaultPrice),
                        );
                        // Keep the unit-price field in sync with the pick.
                        _unitPrice.text = _numText(match.defaultPrice);
                      },
                    ),
                  ),
                ),
              ),
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

  Widget _numCell({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
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
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_decimalFormatter],
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
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
