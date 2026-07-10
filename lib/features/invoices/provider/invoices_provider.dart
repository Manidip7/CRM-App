import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/invoice_model.dart';

/// Search text applied to the invoice list.
class InvoiceFilterNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setSearch(String q) => state = q;
  void clear() => state = '';
}

final invoiceFilterProvider =
    NotifierProvider<InvoiceFilterNotifier, String>(InvoiceFilterNotifier.new);

/// Holds the invoice list. Seeded with sample data so the screen renders
/// immediately; swap [_seed] for a repository call (`GET /invoices`) once the
/// endpoint is available. Delete/update mutate the list locally.
class InvoicesNotifier extends Notifier<List<InvoiceModel>> {
  @override
  List<InvoiceModel> build() => _seed();

  void delete(String id) =>
      state = state.where((inv) => inv.id != id).toList();

  void upsert(InvoiceModel updated) {
    final exists = state.any((inv) => inv.id == updated.id);
    state = exists
        ? [for (final inv in state) if (inv.id == updated.id) updated else inv]
        : [updated, ...state];
  }
}

final invoicesProvider =
    NotifierProvider<InvoicesNotifier, List<InvoiceModel>>(
        InvoicesNotifier.new);

/// Invoices after applying the search text, newest first.
final filteredInvoicesProvider = Provider<List<InvoiceModel>>((ref) {
  final all = ref.watch(invoicesProvider);
  final q = ref.watch(invoiceFilterProvider).trim().toLowerCase();

  final result = all.where((inv) {
    if (q.isEmpty) return true;
    return inv.id.toLowerCase().contains(q) ||
        inv.customer.toLowerCase().contains(q) ||
        inv.createdBy.toLowerCase().contains(q) ||
        inv.status.label.toLowerCase().contains(q);
  }).toList();

  result.sort((a, b) => b.createdDate.compareTo(a.createdDate));
  return result;
});

/// Aggregate totals (over the full, unfiltered list) for the summary row.
final invoiceSummaryProvider = Provider<InvoiceSummary>((ref) {
  return InvoiceSummary.from(ref.watch(invoicesProvider));
});

// ─────────────────────────────────────────────
//  Create-invoice draft
// ─────────────────────────────────────────────

/// A selectable product/service for the line-item dropdown. [defaultPrice]
/// pre-fills the row's unit price when the item is picked.
class CatalogItem {
  final String name;
  final double defaultPrice;

  const CatalogItem(this.name, this.defaultPrice);
}

/// Sample product catalogue powering the line-item dropdown. Swap for a
/// repository call (`GET /products`) once the endpoint exists.
final productCatalogProvider = Provider<List<CatalogItem>>((ref) => const [
      CatalogItem('Annual License', 120000),
      CatalogItem('Implementation Service', 85000),
      CatalogItem('Premium Support Plan', 45000),
      CatalogItem('User Seat Add-on', 1500),
      CatalogItem('Onboarding & Training', 30000),
      CatalogItem('Custom Integration', 60000),
      CatalogItem('Data Migration', 40000),
      CatalogItem('Consulting (per day)', 15000),
    ]);

/// A single editable line on the "New Invoice" form.
///
/// Money maths per line:
///   gross     = qty × unitPrice
///   discount  = gross × discPercent%
///   taxable   = gross − discount
///   tax       = taxable × taxPercent%
///   amount    = taxable + tax        (shown in the row's AMOUNT column)
class InvoiceLineItem {
  final String id;
  final String item;
  final double qty;
  final double unitPrice;
  final double taxPercent;
  final double discPercent;

  const InvoiceLineItem({
    required this.id,
    this.item = '',
    this.qty = 1,
    this.unitPrice = 0,
    this.taxPercent = 0,
    this.discPercent = 0,
  });

  double get gross => qty * unitPrice;
  double get discountAmount => gross * discPercent / 100;
  double get taxable => gross - discountAmount;
  double get taxAmount => taxable * taxPercent / 100;
  double get amount => taxable + taxAmount;

  InvoiceLineItem copyWith({
    String? item,
    double? qty,
    double? unitPrice,
    double? taxPercent,
    double? discPercent,
  }) {
    return InvoiceLineItem(
      id: id,
      item: item ?? this.item,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      taxPercent: taxPercent ?? this.taxPercent,
      discPercent: discPercent ?? this.discPercent,
    );
  }
}

/// Full state of the "New Invoice" form. Kept in Riverpod (not [setState]) so
/// every field — including the dynamic line-item list — drives the UI and the
/// live price summary reactively.
class InvoiceDraft {
  final String invoiceNo;
  final String? customer;
  final InvoiceStatus status;
  final DateTime? dueDate;
  final List<InvoiceLineItem> items;
  final double overallDiscount; // manually-entered flat amount
  final String notes;

  const InvoiceDraft({
    this.invoiceNo = '',
    this.customer,
    this.status = InvoiceStatus.pending,
    this.dueDate,
    this.items = const [],
    this.overallDiscount = 0,
    this.notes = '',
  });

  /// Σ (qty × unitPrice) before any discount or tax.
  double get subtotal =>
      items.fold(0, (sum, it) => sum + it.gross);

  /// Σ per-line discount amounts.
  double get lineDiscount =>
      items.fold(0, (sum, it) => sum + it.discountAmount);

  /// Σ per-line tax amounts.
  double get tax => items.fold(0, (sum, it) => sum + it.taxAmount);

  /// Line discounts + the manual overall discount.
  double get totalDiscount => lineDiscount + overallDiscount;

  double get grandTotal =>
      (subtotal - lineDiscount + tax - overallDiscount)
          .clamp(0, double.infinity);

  InvoiceDraft copyWith({
    String? invoiceNo,
    String? customer,
    InvoiceStatus? status,
    DateTime? dueDate,
    List<InvoiceLineItem>? items,
    double? overallDiscount,
    String? notes,
  }) {
    return InvoiceDraft(
      invoiceNo: invoiceNo ?? this.invoiceNo,
      customer: customer ?? this.customer,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      overallDiscount: overallDiscount ?? this.overallDiscount,
      notes: notes ?? this.notes,
    );
  }
}

class InvoiceDraftNotifier extends Notifier<InvoiceDraft> {
  int _idSeq = 0;

  @override
  InvoiceDraft build() => const InvoiceDraft();

  String _nextId() => 'li-${_idSeq++}';

  /// Clears the form and seeds it with a suggested invoice number plus one
  /// empty line. Call when the create screen opens.
  void reset(String invoiceNo) {
    state = InvoiceDraft(
      invoiceNo: invoiceNo,
      items: [InvoiceLineItem(id: _nextId())],
    );
  }

  void setInvoiceNo(String v) => state = state.copyWith(invoiceNo: v);
  void setCustomer(String? v) => state = state.copyWith(customer: v);
  void setStatus(InvoiceStatus v) => state = state.copyWith(status: v);
  void setDueDate(DateTime v) => state = state.copyWith(dueDate: v);
  void setNotes(String v) => state = state.copyWith(notes: v);
  void setOverallDiscount(double v) =>
      state = state.copyWith(overallDiscount: v);

  void addItem() => state = state.copyWith(
        items: [...state.items, InvoiceLineItem(id: _nextId())],
      );

  void removeItem(String id) => state = state.copyWith(
        items: state.items.where((it) => it.id != id).toList(),
      );

  void updateItem(String id, InvoiceLineItem Function(InvoiceLineItem) apply) {
    state = state.copyWith(
      items: [
        for (final it in state.items) if (it.id == id) apply(it) else it,
      ],
    );
  }
}

final invoiceDraftProvider =
    NotifierProvider<InvoiceDraftNotifier, InvoiceDraft>(
        InvoiceDraftNotifier.new);

/// Suggests the next invoice number based on the highest existing sequence
/// for the current year, e.g. `INV-2026-0008`.
String suggestInvoiceNumber(List<InvoiceModel> existing) {
  final year = DateTime.now().year;
  final prefix = 'INV-$year-';
  var max = 0;
  for (final inv in existing) {
    if (!inv.id.startsWith(prefix)) continue;
    final n = int.tryParse(inv.id.substring(prefix.length));
    if (n != null && n > max) max = n;
  }
  return '$prefix${(max + 1).toString().padLeft(4, '0')}';
}

/// Sample data. Remove when wiring a real API.
List<InvoiceModel> _seed() {
  final now = DateTime.now();
  DateTime d(int days) => now.add(Duration(days: days));
  return [
    InvoiceModel(
      id: 'INV-2026-0007',
      customer: 'Acme Industries',
      createdDate: d(-2),
      dueDate: d(12),
      status: InvoiceStatus.pending,
      amount: 185000,
      paidAmount: 0,
      createdBy: 'Priya Sharma',
    ),
    InvoiceModel(
      id: 'INV-2026-0006',
      customer: 'Nova Retail Pvt Ltd',
      createdDate: d(-6),
      dueDate: d(-1),
      status: InvoiceStatus.overdue,
      amount: 94500,
      paidAmount: 20000,
      createdBy: 'Rahul Verma',
    ),
    InvoiceModel(
      id: 'INV-2026-0005',
      customer: 'BlueSky Solutions',
      createdDate: d(-9),
      dueDate: d(6),
      status: InvoiceStatus.partial,
      amount: 260000,
      paidAmount: 130000,
      createdBy: 'Priya Sharma',
    ),
    InvoiceModel(
      id: 'INV-2026-0004',
      customer: 'Greenfield Traders',
      createdDate: d(-14),
      dueDate: d(-4),
      status: InvoiceStatus.paid,
      amount: 47800,
      paidAmount: 47800,
      createdBy: 'Ankit Gupta',
    ),
    InvoiceModel(
      id: 'INV-2026-0003',
      customer: 'Sterling Corp',
      createdDate: d(-20),
      dueDate: d(-8),
      status: InvoiceStatus.paid,
      amount: 312000,
      paidAmount: 312000,
      createdBy: 'Rahul Verma',
    ),
    InvoiceModel(
      id: 'INV-2026-0002',
      customer: 'Horizon Media',
      createdDate: d(-3),
      dueDate: d(21),
      status: InvoiceStatus.draft,
      amount: 68000,
      paidAmount: 0,
      createdBy: 'Ankit Gupta',
    ),
  ];
}
