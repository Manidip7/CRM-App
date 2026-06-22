import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/AppColors.dart';
import '../../Opportunities/model/opportunity_model.dart';
import '../../Opportunities/provider/opportunities_provider.dart';
import '../model/quotation_model.dart';
import '../provider/edit_quotation_provider.dart';
import '../provider/quotations_provider.dart';

/// Full-screen form to edit an existing [QuotationModel]. Lets the user pick a
/// linked opportunity, edit quotation details (dates, tax, customer), manage
/// line items and add notes, then save the changes back into state.
///
/// All reactive state (opportunity, dates, tax, items, totals) lives in
/// [editQuotationFormProvider]; only the plain text fields that drive nothing
/// else keep their own controllers.
class EditQuotationScreen extends ConsumerStatefulWidget {
  final QuotationModel quotation;

  const EditQuotationScreen({super.key, required this.quotation});

  @override
  ConsumerState<EditQuotationScreen> createState() =>
      _EditQuotationScreenState();
}

class _EditQuotationScreenState extends ConsumerState<EditQuotationScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _customerNameController;
  late final TextEditingController _customerCompanyController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final q = widget.quotation;
    _titleController = TextEditingController(text: q.title);
    _customerNameController = TextEditingController(text: q.clientName);
    _customerCompanyController =
        TextEditingController(text: q.companyName ?? '');
    _notesController = TextEditingController(text: q.notes);
    // Seed the reactive form state from the quotation being edited.
    ref.read(editQuotationFormProvider.notifier).seed(q);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customerNameController.dispose();
    _customerCompanyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  EditQuotationForm get _form =>
      ref.read(editQuotationFormProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final opportunities = ref.watch(opportunitiesProvider).items;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                children: [
                  _buildSelectOpportunity(opportunities),
                  const SizedBox(height: 16),
                  _buildQuotationDetails(),
                  const SizedBox(height: 16),
                  _buildItemsSection(),
                  const SizedBox(height: 16),
                  _buildNotesSection(),
                  const SizedBox(height: 16),
                  _buildTotalsCard(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildSaveBar(),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
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
                const Text(
                  'Edit Quotation',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.quotation.number,
                  style: const TextStyle(
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

  // ── Select Opportunity ──
  Widget _buildSelectOpportunity(List<OpportunityModel> opportunities) {
    final selectedId = ref.watch(
        editQuotationFormProvider.select((s) => s.opportunityId));
    return _card(
      title: 'Select Opportunity',
      icon: Icons.trending_up_rounded,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.work_outline_rounded,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: selectedId,
                  isExpanded: true,
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary),
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textPrimary),
                  hint: const Text('Select an opportunity',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textLight)),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No opportunity'),
                    ),
                    ...opportunities.map(
                      (o) => DropdownMenuItem<String?>(
                        value: o.id,
                        child: Text(
                          o.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (id) => _onOpportunitySelected(id, opportunities),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onOpportunitySelected(
      String? id, List<OpportunityModel> opportunities) {
    _form.setOpportunity(id);
    if (id == null) return;
    final opp = opportunities.firstWhere((o) => o.id == id);
    // Pre-fill the customer name / title from the opportunity if still blank.
    if (_customerNameController.text.trim().isEmpty) {
      _customerNameController.text = opp.contactName;
    }
    if (_titleController.text.trim().isEmpty) {
      _titleController.text = opp.title;
    }
  }

  // ── Quotation Details ──
  Widget _buildQuotationDetails() {
    final date = ref.watch(editQuotationFormProvider.select((s) => s.date));
    final validUntil =
        ref.watch(editQuotationFormProvider.select((s) => s.validUntil));
    return _card(
      title: 'Quotation Details',
      icon: Icons.description_outlined,
      child: Column(
        children: [
          _field(
            label: 'Title',
            child: _controllerField(_titleController, hint: 'Quotation title'),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'Date',
                  child: _dateButton(
                    value: date,
                    onTap: () => _pickDate(isValidUntil: false),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  label: 'Valid Until',
                  child: _dateButton(
                    value: validUntil,
                    onTap: () => _pickDate(isValidUntil: true),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _field(
            label: 'Tax / GST (%)',
            child: _formField(
              initialValue: _trimZeros(widget.quotation.taxPercent),
              hint: '0',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              prefixIcon: Icons.percent_rounded,
              onChanged: (v) => _form.setTax(double.tryParse(v.trim()) ?? 0),
            ),
          ),
          const SizedBox(height: 14),
          _field(
            label: 'Customer Name',
            child: _controllerField(
              _customerNameController,
              hint: 'Customer name',
              prefixIcon: Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(height: 14),
          _field(
            label: 'Customer Company',
            child: _controllerField(
              _customerCompanyController,
              hint: 'Company name',
              prefixIcon: Icons.business_outlined,
            ),
          ),
        ],
      ),
    );
  }

  // ── Quotation Items ──
  Widget _buildItemsSection() {
    final items = ref.watch(editQuotationFormProvider.select((s) => s.items));
    return _card(
      title: 'Quotation Items',
      icon: Icons.inventory_2_outlined,
      trailing: GestureDetector(
        onTap: _form.addItem,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 4),
              Text(
                'Add Item',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildItemRow(items[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(EditItem item) {
    return Container(
      key: ValueKey('item-${item.key}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _formField(
                  fieldKey: ValueKey('name-${item.key}'),
                  initialValue: item.name,
                  hint: 'Item / service name',
                  onChanged: (v) => _form.setItemName(item.key, v),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _form.removeItem(item.key),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.redLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _formField(
                  fieldKey: ValueKey('qty-${item.key}'),
                  initialValue: item.quantity.toString(),
                  hint: 'Qty',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  prefixLabel: 'Qty',
                  onChanged: (v) =>
                      _form.setItemQuantity(item.key, int.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _formField(
                  fieldKey: ValueKey('price-${item.key}'),
                  initialValue: item.price == 0 ? '' : _trimZeros(item.price),
                  hint: 'Price',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  prefixIcon: Icons.attach_money_rounded,
                  onChanged: (v) =>
                      _form.setItemPrice(item.key, double.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Line total: ${_money(item.total)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Notes ──
  Widget _buildNotesSection() {
    return _card(
      title: 'Notes',
      icon: Icons.sticky_note_2_outlined,
      child: TextField(
        controller: _notesController,
        maxLines: 4,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Add notes, terms or payment details...',
          hintStyle:
              const TextStyle(color: AppColors.textLight, fontSize: 13.5),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  // ── Totals summary ──
  Widget _buildTotalsCard() {
    final form = ref.watch(editQuotationFormProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _totalRow('Subtotal', _money(form.subtotal)),
          const SizedBox(height: 8),
          _totalRow('Tax / GST (${_trimZeros(form.taxPercent)}%)',
              _money(form.taxAmount)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.divider, height: 1),
          ),
          _totalRow('Total', _money(form.grandTotal), emphasize: true),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool emphasize = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: emphasize ? 15 : 13.5,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            color:
                emphasize ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 16 : 13.5,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            color: emphasize ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ── Save bar ──
  Widget _buildSaveBar() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
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
            child: GestureDetector(
              onTap: _save,
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Reusable building blocks
  // ─────────────────────────────────────────────
  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _field({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  /// A text field backed by an external [TextEditingController] (plain inputs
  /// that are only read on save).
  Widget _controllerField(
    TextEditingController controller, {
    String? hint,
    IconData? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: _inputDecoration(hint: hint, prefixIcon: prefixIcon),
    );
  }

  /// A self-managed text field that pushes every change into the form provider.
  /// Uses [initialValue] (seeded once) so totals stay reactive without a
  /// controller — and never resets the cursor on rebuild.
  Widget _formField({
    Key? fieldKey,
    String? initialValue,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    IconData? prefixIcon,
    String? prefixLabel,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      key: fieldKey,
      initialValue: initialValue,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: _inputDecoration(
        hint: hint,
        prefixIcon: prefixIcon,
        prefixLabel: prefixLabel,
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    IconData? prefixIcon,
    String? prefixLabel,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13.5),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: AppColors.textSecondary)
          : null,
      prefix: prefixLabel != null
          ? Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(prefixLabel,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            )
          : null,
      isDense: true,
      filled: true,
      fillColor: AppColors.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    );
  }

  Widget _dateButton({required DateTime value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
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
                _shortDate(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Actions
  // ─────────────────────────────────────────────
  Future<void> _pickDate({required bool isValidUntil}) async {
    final form = ref.read(editQuotationFormProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: isValidUntil ? form.validUntil : form.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked == null) return;
    if (isValidUntil) {
      _form.setValidUntil(picked);
    } else {
      _form.setDate(picked);
    }
  }

  void _save() {
    final name = _customerNameController.text.trim();
    if (name.isEmpty) {
      _toast('Customer name is required');
      return;
    }

    final form = ref.read(editQuotationFormProvider);
    final items = form.items
        .where((r) => r.name.trim().isNotEmpty)
        .map((r) => QuotationItem(
              name: r.name.trim(),
              quantity: r.quantity,
              price: r.price,
            ))
        .toList();

    final company = _customerCompanyController.text.trim();
    final updated = widget.quotation.copyWith(
      title: _titleController.text.trim().isEmpty
          ? widget.quotation.title
          : _titleController.text.trim(),
      clientName: name,
      companyName: company.isEmpty ? null : company,
      amount: form.grandTotal,
      itemCount: items.length,
      taxPercent: form.taxPercent,
      notes: _notesController.text.trim(),
      items: items,
      createdDate: form.date,
      validUntil: form.validUntil,
      opportunityId: form.opportunityId,
      status: form.status,
    );

    ref.read(quotationsProvider.notifier).update(updated);
    _toast('${updated.number} updated');
    context.pop();
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

  // ── Formatting helpers ──
  String _money(double v) {
    final whole = v.round();
    final digits = whole.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '${widget.quotation.currency}$buffer';
  }

  String _trimZeros(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
