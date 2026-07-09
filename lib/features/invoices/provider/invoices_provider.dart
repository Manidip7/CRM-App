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
