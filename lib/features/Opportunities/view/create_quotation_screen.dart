import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';
import '../../quotations/model/quotation_model.dart';
import '../../quotations/provider/quotations_provider.dart';
import '../model/opportunity_model.dart';
import '../provider/create_quotation_provider.dart';

/// Full-screen form to create a quotation for an opportunity. Collects the
/// "from" (our company), the "to" (customer) details, dates, tax, editable line
/// items and notes, then assembles a [QuotationModel] on Generate.
class CreateQuotationScreen extends ConsumerStatefulWidget {
  final String opportunityId;
  final Color accent;
  final String? customerName;
  final String? customerCompany;
  final String? customerAddress;
  final List<OpportunityProduct> initialItems;

  const CreateQuotationScreen({
    super.key,
    required this.opportunityId,
    required this.accent,
    this.customerName,
    this.customerCompany,
    this.customerAddress,
    this.initialItems = const [],
  });

  @override
  ConsumerState<CreateQuotationScreen> createState() =>
      _CreateQuotationScreenState();
}

class _CreateQuotationScreenState extends ConsumerState<CreateQuotationScreen> {
  // From (our details)
  final _companyNameC = TextEditingController();
  final _companyAddressC = TextEditingController();

  // To (customer details)
  late final _customerNameC =
      TextEditingController(text: widget.customerName ?? '');
  late final _customerCompanyC =
      TextEditingController(text: widget.customerCompany ?? '');
  late final _customerAddressC =
      TextEditingController(text: widget.customerAddress ?? '');

  // Notes
  final _notesC = TextEditingController();

  Color get _accent => widget.accent;

  /// Dates, tax, line items and the validation message all live in Riverpod —
  /// see [createQuotationFormProvider].
  CreateQuotationFormState get _form =>
      ref.watch(createQuotationFormProvider(widget.opportunityId));
  CreateQuotationForm get _formNotifier =>
      ref.read(createQuotationFormProvider(widget.opportunityId).notifier);

  @override
  void initState() {
    super.initState();
    // Seed the rows from the products this screen was opened with. Deferred to
    // after the first frame — modifying a provider synchronously during
    // initState/build is disallowed by Riverpod.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _formNotifier.seed(widget.initialItems);
    });
  }

  @override
  void dispose() {
    _companyNameC.dispose();
    _companyAddressC.dispose();
    _customerNameC.dispose();
    _customerCompanyC.dispose();
    _customerAddressC.dispose();
    _notesC.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isValidUntil}) async {
    final form = ref.read(createQuotationFormProvider(widget.opportunityId));
    final picked = await showDatePicker(
      context: context,
      initialDate: isValidUntil ? form.validUntil : form.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked == null) return;
    if (isValidUntil) {
      _formNotifier.setValidUntil(picked);
    } else {
      _formNotifier.setDate(picked);
    }
  }

  void _generate() {
    final form = ref.read(createQuotationFormProvider(widget.opportunityId));
    final name = _customerNameC.text.trim();
    if (name.isEmpty) {
      _formNotifier.setError('Customer / Contact name is required');
      return;
    }
    final items = form.lines
        .where((l) => l.description.trim().isNotEmpty)
        .map((l) => QuotationItem(
              name: l.description.trim(),
              quantity: l.quantity,
              price: l.price,
            ))
        .toList();
    if (items.isEmpty) {
      _formNotifier.setError('Add at least one item with a description');
      return;
    }

    final now = DateTime.now();
    final model = QuotationModel(
      id: 'new-${now.millisecondsSinceEpoch}',
      number: 'QT-DRAFT-${now.millisecondsSinceEpoch % 100000}',
      title: name,
      clientName: name,
      companyName: _customerCompanyC.text.trim().isEmpty
          ? null
          : _customerCompanyC.text.trim(),
      amount: form.grandTotal,
      itemCount: items.length,
      status: QuotationStatus.draft,
      createdDate: form.date,
      validUntil: form.validUntil,
      currency: '₹',
      taxPercent: form.taxPercent,
      notes: _composeNotes(),
      items: items,
      opportunityId: widget.opportunityId,
    );

    ref.read(quotationsProvider.notifier).update(model);
    Navigator.pop(context, model);
  }

  /// Folds the from-company / address details (which the [QuotationModel] has no
  /// dedicated fields for yet) into the notes so nothing entered is lost.
  String _composeNotes() {
    final parts = <String>[];
    final notes = _notesC.text.trim();
    if (notes.isNotEmpty) parts.add(notes);

    final from = [
      _companyNameC.text.trim(),
      _companyAddressC.text.trim(),
    ].where((s) => s.isNotEmpty).join(', ');
    if (from.isNotEmpty) parts.add('From: $from');

    final custAddress = _customerAddressC.text.trim();
    if (custAddress.isNotEmpty) parts.add('Customer Address: $custAddress');

    return parts.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final form = _form;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Quotation',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // From (our details)
                    _sectionCard(
                      title: 'From (Our Details)',
                      icon: Icons.business_rounded,
                      children: [
                        _label('COMPANY NAME'),
                        const SizedBox(height: 6),
                        _field(
                          controller: _companyNameC,
                          hint: 'Your company name',
                          icon: Icons.apartment_rounded,
                        ),
                        const SizedBox(height: 12),
                        _label('COMPANY ADDRESS'),
                        const SizedBox(height: 6),
                        _field(
                          controller: _companyAddressC,
                          hint: 'Your company address',
                          icon: Icons.location_on_outlined,
                          maxLines: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // To (customer details)
                    _sectionCard(
                      title: 'To (Customer Details)',
                      icon: Icons.person_pin_rounded,
                      children: [
                        _label('CUSTOMER / CONTACT NAME'),
                        const SizedBox(height: 6),
                        _field(
                          controller: _customerNameC,
                          hint: 'Customer or contact name',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 12),
                        _label('CUSTOMER COMPANY'),
                        const SizedBox(height: 6),
                        _field(
                          controller: _customerCompanyC,
                          hint: 'Customer company',
                          icon: Icons.apartment_rounded,
                        ),
                        const SizedBox(height: 12),
                        _label('CUSTOMER ADDRESS'),
                        const SizedBox(height: 6),
                        _field(
                          controller: _customerAddressC,
                          hint: 'Customer address',
                          icon: Icons.location_on_outlined,
                          maxLines: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Dates + Tax
                    _sectionCard(
                      title: 'Quotation Details',
                      icon: Icons.receipt_long_rounded,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('QUOTATION DATE'),
                                  const SizedBox(height: 6),
                                  _dateField(
                                      value: form.date,
                                      onTap: () =>
                                          _pickDate(isValidUntil: false)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('VALID UNTIL'),
                                  const SizedBox(height: 6),
                                  _dateField(
                                      value: form.validUntil,
                                      onTap: () =>
                                          _pickDate(isValidUntil: true)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _label('TAX / GST (%)'),
                        const SizedBox(height: 6),
                        _valueField(
                          fieldKey: const ValueKey('tax'),
                          initialValue: _trimZeros(form.taxPercent),
                          hint: '18',
                          icon: Icons.percent_rounded,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (v) => _formNotifier
                              .setTaxPercent(double.tryParse(v.trim()) ?? 0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Items
                    _buildItemsCard(),
                    const SizedBox(height: 12),
                    // Notes
                    _sectionCard(
                      title: 'Additional Notes',
                      icon: Icons.notes_rounded,
                      children: [
                        _field(
                          controller: _notesC,
                          hint: 'Any terms, remarks or notes...',
                          icon: Icons.edit_note_rounded,
                          maxLines: 3,
                        ),
                      ],
                    ),
                    if (form.error != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 16, color: AppColors.red),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              form.error!,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                color: AppColors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Items card ──
  Widget _buildItemsCard() {
    final form = _form;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag_outlined, size: 18, color: _accent),
              const SizedBox(width: 8),
              Text(
                'Quotation Items',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _formNotifier.addLine,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 14, color: _accent),
                      const SizedBox(width: 4),
                      Text(
                        'Add Item',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < form.lines.length; i++)
            _buildItemRow(i, form.lines[i]),
          const Divider(height: 20, color: AppColors.divider),
          _totalRow('Subtotal', _money(form.subtotal)),
          const SizedBox(height: 6),
          _totalRow(
              'Tax (${_trimZeros(form.taxPercent)}%)', _money(form.taxAmount)),
          const SizedBox(height: 8),
          _totalRow('Grand Total', _money(form.grandTotal), bold: true),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index, QuotationLineDraft row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Item ${index + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _formNotifier.removeLine(row.id),
                child: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textLight),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _valueField(
            fieldKey: ValueKey('desc-${row.id}'),
            initialValue: row.description,
            hint: 'Item description',
            icon: Icons.inventory_2_outlined,
            onChanged: (v) => _formNotifier.setLineDescription(row.id, v),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _valueField(
                  fieldKey: ValueKey('qty-${row.id}'),
                  initialValue: '${row.quantity}',
                  hint: 'Qty',
                  icon: Icons.tag_rounded,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _formNotifier.setLineQuantity(
                      row.id, int.tryParse(v.trim()) ?? 0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _valueField(
                  fieldKey: ValueKey('price-${row.id}'),
                  initialValue: row.price > 0 ? _trimZeros(row.price) : '',
                  hint: 'Unit price',
                  icon: Icons.payments_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => _formNotifier.setLinePrice(
                      row.id, double.tryParse(v.trim()) ?? 0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ──
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
              child: ElevatedButton.icon(
                onPressed: _generate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.description_rounded, size: 18),
                label: Text(
                  'Generate Quotation',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Building blocks ──
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.poppins(fontSize: 13.5, color: AppColors.textLight),
        prefixIcon: maxLines > 1
            ? null
            : Icon(icon, size: 18, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          borderSide: BorderSide(color: _accent, width: 1.4),
        ),
      ),
    );
  }

  /// A text field whose value is owned by Riverpod rather than a controller.
  /// [fieldKey] must be stable for the life of the field (line rows key on the
  /// row id) — it is what keeps [initialValue] from clobbering what the user
  /// has typed on later rebuilds.
  Widget _valueField({
    required Key fieldKey,
    required String initialValue,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      key: fieldKey,
      initialValue: initialValue,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.poppins(fontSize: 13.5, color: AppColors.textLight),
        prefixIcon: maxLines > 1
            ? null
            : Icon(icon, size: 18, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          borderSide: BorderSide(color: _accent, width: 1.4),
        ),
      ),
    );
  }

  Widget _dateField({required DateTime value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
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
            const Icon(Icons.calendar_today_rounded,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              _fmtDate(value),
              style: GoogleFonts.poppins(
                  fontSize: 13.5, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false}) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: bold ? 14 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: bold ? _accent : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ── Formatting ──
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _fmtDate(DateTime dt) =>
      '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';

  String _trimZeros(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  /// Full amount with Indian digit grouping, e.g. 54545 → "₹54,545".
  String _money(double v) {
    final isWhole = v == v.roundToDouble();
    final str = isWhole ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    final dot = str.indexOf('.');
    var intPart = dot == -1 ? str : str.substring(0, dot);
    final fraction = dot == -1 ? '' : str.substring(dot);
    final neg = intPart.startsWith('-');
    if (neg) intPart = intPart.substring(1);
    String grouped;
    if (intPart.length <= 3) {
      grouped = intPart;
    } else {
      final last3 = intPart.substring(intPart.length - 3);
      final rest = intPart.substring(0, intPart.length - 3);
      final buf = StringBuffer();
      for (var i = 0; i < rest.length; i++) {
        buf.write(rest[i]);
        final fromRight = rest.length - i;
        if (fromRight > 1 && (fromRight - 1) % 2 == 0) buf.write(',');
      }
      grouped = '$buf,$last3';
    }
    return '${neg ? '-' : ''}₹$grouped$fraction';
  }
}

/// One editable line-item row in the create-quotation form.
