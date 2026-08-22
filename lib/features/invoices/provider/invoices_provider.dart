import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/invoices_repository.dart';
import '../data/items_repository.dart';
import '../model/catalog_item.dart';
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

/// State of the API-backed invoice list: the loaded pages, paginator info,
/// the server-side summary and the loading / error flags.
class InvoicesState {
  final List<InvoiceModel> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  /// Server-wide totals from the response's `summary` block. Null until the
  /// first successful load (or when the API sends none).
  final InvoiceSummary? summary;

  /// Invoice number currently being deleted, so its card can show a spinner.
  final String? deletingId;

  /// Invoice number a payment is currently being recorded against, so the
  /// payment sheet can show a spinner and block a double tap.
  final String? payingId;

  const InvoicesState({
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
    this.summary,
    this.deletingId,
    this.payingId,
  });

  bool get hasMore => currentPage < lastPage;

  InvoicesState copyWith({
    List<InvoiceModel>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
    InvoiceSummary? summary,
    String? deletingId,
    bool clearDeleting = false,
    String? payingId,
    bool clearPaying = false,
  }) {
    return InvoicesState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      summary: summary ?? this.summary,
      deletingId: clearDeleting ? null : (deletingId ?? this.deletingId),
      payingId: clearPaying ? null : (payingId ?? this.payingId),
    );
  }
}

/// Loads `GET /invoices` page by page (replace on page 1, append after) and
/// holds the list so cards can be deleted / updated locally.
class InvoicesNotifier extends Notifier<InvoicesState> {
  @override
  InvoicesState build() {
    Future.microtask(() => _load(1));
    return const InvoicesState(isLoading: true);
  }

  Future<void> _load(int page) async {
    final result =
        await ref.read(invoicesRepositoryProvider).getInvoices(page: page);
    result.when(
      success: (data) {
        state = state.copyWith(
          items: page == 1 ? data.items : [...state.items, ...data.items],
          currentPage: data.currentPage,
          lastPage: data.lastPage,
          total: data.total,
          summary: data.summary,
          isLoading: false,
          isLoadingMore: false,
          clearError: true,
        );
      },
      failure: (e) {
        state =
            state.copyWith(isLoading: false, isLoadingMore: false, error: e);
      },
    );
  }

  /// Fetches and appends the next page. No-op while loading or on the last page.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    await _load(state.currentPage + 1);
  }

  /// Reloads from page 1.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: state.items.isEmpty, clearError: true);
    await _load(1);
  }

  /// Deletes [invoice] via `DELETE /invoices/{id}`, then drops it from the
  /// loaded list. Returns null on success, or an error message to show.
  Future<String?> delete(InvoiceModel invoice) async {
    final serverId = invoice.serverId;
    if (serverId == null) {
      // Never saved to the backend — just drop it locally.
      state = state.copyWith(
        items: state.items.where((inv) => inv.id != invoice.id).toList(),
      );
      return null;
    }
    if (state.deletingId != null) return null; // one delete at a time

    state = state.copyWith(deletingId: invoice.id);
    final result = await ref
        .read(invoicesRepositoryProvider)
        .deleteInvoice('$serverId');
    state = state.copyWith(clearDeleting: true);

    return result.when(
      success: (_) {
        state = state.copyWith(
          items: state.items.where((inv) => inv.id != invoice.id).toList(),
          total: state.total > 0 ? state.total - 1 : 0,
        );
        // The cached summary no longer matches; pull fresh totals.
        refresh();
        return null;
      },
      failure: (error) => error.message,
    );
  }

  /// Records a payment of [amount] against [invoice], then reloads the list so
  /// the paid figure, balance and status all come back from the server.
  /// Returns null on success, or a message to show.
  Future<String?> addPayment(
    InvoiceModel invoice,
    double amount, {
    DateTime? paidAt,
    String notes = '',
    double? dueBalance,
  }) async {
    final serverId = invoice.serverId;
    if (serverId == null) {
      return 'This invoice has not been saved to the server yet.';
    }
    if (amount <= 0) return 'Enter an amount greater than zero';

    // Prefer the ledger's figure when the sheet has one — it's fresher than the
    // list row.
    final due = dueBalance ?? invoice.outstanding;
    if (amount > due) {
      return 'Amount cannot exceed the due balance of ${formatMoney(due)}';
    }
    if (state.payingId != null) return null; // one payment at a time

    state = state.copyWith(payingId: invoice.id);
    final result = await ref
        .read(invoicesRepositoryProvider)
        .addPayment('$serverId', amount, paidAt: paidAt, notes: notes);
    state = state.copyWith(clearPaying: true);

    return result.when(
      success: (_) {
        // Both the list row and the invoice's ledger are now stale.
        ref.invalidate(invoicePaymentsProvider(serverId));
        refresh();
        return null;
      },
      failure: (error) => error.message,
    );
  }

  /// Replaces the invoice sharing [updated]'s number, or prepends it when no
  /// match exists. Local only, for optimistic edits — creation goes through
  /// `POST /invoices` and then [refresh].
  void upsert(InvoiceModel updated) {
    final exists = state.items.any((inv) => inv.id == updated.id);
    state = exists
        ? state.copyWith(items: [
            for (final inv in state.items)
              if (inv.id == updated.id) updated else inv,
          ])
        : state.copyWith(
            items: [updated, ...state.items],
            total: state.total + 1,
          );
  }
}

final invoicesProvider =
    NotifierProvider<InvoicesNotifier, InvoicesState>(InvoicesNotifier.new);

/// Invoices after applying the search text, newest first.
final filteredInvoicesProvider = Provider<List<InvoiceModel>>((ref) {
  final all = ref.watch(invoicesProvider).items;
  final q = ref.watch(invoiceFilterProvider).trim().toLowerCase();

  final result = all.where((inv) {
    if (q.isEmpty) return true;
    return inv.id.toLowerCase().contains(q) ||
        inv.customer.toLowerCase().contains(q) ||
        inv.createdBy.toLowerCase().contains(q) ||
        inv.displayStatus.toLowerCase().contains(q) ||
        inv.items.any((it) => it.name.toLowerCase().contains(q));
  }).toList();

  result.sort((a, b) => b.createdDate.compareTo(a.createdDate));
  return result;
});

/// Aggregate totals for the summary row: the server's own `summary` block when
/// the API sent one, else totals computed from the loaded rows.
final invoiceSummaryProvider = Provider<InvoiceSummary>((ref) {
  final state = ref.watch(invoicesProvider);
  return state.summary ?? InvoiceSummary.from(state.items);
});

/// Payment ledger for one invoice (`GET /invoices/{id}/payments`), keyed by the
/// invoice's server id. The payment sheet watches it for the history and the
/// authoritative total / paid / due figures; recording a payment invalidates it.
final invoicePaymentsProvider =
    FutureProvider.family<InvoicePaymentHistory, int>((ref, invoiceId) async {
  final result =
      await ref.watch(invoicesRepositoryProvider).getPayments('$invoiceId');
  return result.when(
    success: (history) => history,
    failure: (error) => throw error,
  );
});

// ─────────────────────────────────────────────
//  Create-invoice draft
// ─────────────────────────────────────────────

/// The product/service catalogue behind the line-item dropdown, loaded from
/// `GET /items`. The backend's own ordering is preserved; only items it flags
/// as inactive are dropped (that flag is absent from `/items` today, so in
/// practice every row shows).
///
/// It's a [FutureProvider], so the form can show a spinner while the catalogue
/// loads and a retry action if it fails (`ref.invalidate`).
final catalogItemsProvider = FutureProvider<List<CatalogItem>>((ref) async {
  final result = await ref.watch(itemsRepositoryProvider).getAllItems();
  return result.when(
    success: (items) => items.where((i) => i.isActive).toList(),
    failure: (error) => throw error,
  );
});

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

  /// Catalogue id of the picked item (`items.id`) — what the dropdown selects
  /// on and what a future `POST /invoices` sends as `item_id`. Null until the
  /// row's item is chosen.
  final int? itemId;

  final String item;
  final String? sku;
  final String? unit;

  /// False when the catalogue marks the item as `discount_allowed: false`; the
  /// row's DISC% field is then locked at 0.
  final bool discountAllowed;

  final double qty;
  final double unitPrice;
  final double taxPercent;
  final double discPercent;

  const InvoiceLineItem({
    required this.id,
    this.itemId,
    this.item = '',
    this.sku,
    this.unit,
    this.discountAllowed = true,
    this.qty = 1,
    this.unitPrice = 0,
    this.taxPercent = 0,
    this.discPercent = 0,
  });

  /// Fills this row from a catalogue pick: name, price, tax and discount rule
  /// all come from the item, and any existing discount is cleared when the item
  /// disallows one.
  InvoiceLineItem fromCatalog(CatalogItem c) {
    return InvoiceLineItem(
      id: id,
      itemId: c.id,
      item: c.name,
      sku: c.sku,
      unit: c.unit,
      discountAllowed: c.discountAllowed,
      qty: qty <= 0 ? (c.minQty > 0 ? c.minQty : 1) : qty,
      unitPrice: c.sellingPrice,
      taxPercent: c.taxPercent,
      discPercent: c.discountAllowed ? discPercent : 0,
    );
  }

  double get gross => qty * unitPrice;
  double get discountAmount => gross * discPercent / 100;
  double get taxable => gross - discountAmount;
  double get taxAmount => taxable * taxPercent / 100;
  double get amount => taxable + taxAmount;

  InvoiceLineItem copyWith({
    int? itemId,
    String? item,
    String? sku,
    String? unit,
    bool? discountAllowed,
    double? qty,
    double? unitPrice,
    double? taxPercent,
    double? discPercent,
  }) {
    return InvoiceLineItem(
      id: id,
      itemId: itemId ?? this.itemId,
      item: item ?? this.item,
      sku: sku ?? this.sku,
      unit: unit ?? this.unit,
      discountAllowed: discountAllowed ?? this.discountAllowed,
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
  /// `invoices.id` being edited — set when the form was opened from an existing
  /// invoice, null for a brand-new one. Decides POST vs PUT on [submit].
  final int? editingId;

  final String invoiceNo;

  /// Display name of the picked customer.
  final String? customer;

  /// `customers.id` of the picked customer — what `POST /invoices` sends as
  /// `customer_id`. Null until one is chosen.
  final int? customerId;

  final InvoiceStatus status;
  final DateTime? dueDate;
  final List<InvoiceLineItem> items;
  final double overallDiscount; // manually-entered flat amount
  final String notes;

  /// True while `POST /invoices` is in flight, so the Save button can show a
  /// spinner and refuse a second tap.
  final bool isSaving;

  const InvoiceDraft({
    this.editingId,
    this.invoiceNo = '',
    this.customer,
    this.customerId,
    this.status = InvoiceStatus.draft,
    this.dueDate,
    this.items = const [],
    this.overallDiscount = 0,
    this.notes = '',
    this.isSaving = false,
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

  /// True when this draft edits an existing invoice rather than creating one.
  bool get isEditing => editingId != null;

  InvoiceDraft copyWith({
    int? editingId,
    String? invoiceNo,
    String? customer,
    int? customerId,
    InvoiceStatus? status,
    DateTime? dueDate,
    List<InvoiceLineItem>? items,
    double? overallDiscount,
    String? notes,
    bool? isSaving,
  }) {
    return InvoiceDraft(
      editingId: editingId ?? this.editingId,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      customer: customer ?? this.customer,
      customerId: customerId ?? this.customerId,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      overallDiscount: overallDiscount ?? this.overallDiscount,
      notes: notes ?? this.notes,
      isSaving: isSaving ?? this.isSaving,
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

  /// Fills the form from an existing invoice so the update screen opens
  /// pre-populated, and marks the draft as editing [invoice].
  ///
  /// `overall_discount` isn't sent back as its own field, so it's recovered as
  /// whatever part of `discount_amount` the per-line discounts don't explain.
  void loadFrom(InvoiceModel invoice) {
    final items = invoice.items
        .map((it) => InvoiceLineItem(
              id: _nextId(),
              itemId: it.itemId,
              item: it.name,
              sku: it.sku,
              unit: it.unit,
              qty: it.qty,
              unitPrice: it.unitPrice,
              taxPercent: it.taxPercent,
              discPercent: it.discountPercent,
            ))
        .toList();

    final lineDiscount = items.fold<double>(0, (s, it) => s + it.discountAmount);
    final overall =
        (invoice.discountAmount - lineDiscount).clamp(0, double.infinity);

    state = InvoiceDraft(
      editingId: invoice.serverId,
      invoiceNo: invoice.id,
      customer: invoice.customer,
      customerId: invoice.customerDetail?.id,
      status: invoice.status,
      dueDate: invoice.dueDate,
      items: items.isEmpty ? [InvoiceLineItem(id: _nextId())] : items,
      overallDiscount: overall.toDouble(),
      notes: invoice.notes ?? '',
    );
  }

  void setInvoiceNo(String v) => state = state.copyWith(invoiceNo: v);

  /// Records both halves of the pick: the id goes to the API, the name is what
  /// the dropdown and the local card display.
  void setCustomer({int? id, String? name}) =>
      state = state.copyWith(customerId: id, customer: name);
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

  /// Validates the draft and saves it: `PUT /invoices/{id}` when the form was
  /// opened on an existing invoice, `POST /invoices` otherwise. Returns null on
  /// success, or a message to show the user.
  ///
  /// Empty rows (no item picked) are skipped, the due date defaults to 30 days
  /// out, and the invoice number is left to the backend — it assigns its own
  /// (`P/26-27/0001`), so the form's number is not sent.
  Future<String?> submit() async {
    if (state.isSaving) return null;

    final customerId = state.customerId;
    if (customerId == null) return 'Please select a customer';

    final lines = state.items
        .where((it) => it.item.trim().isNotEmpty && it.qty > 0)
        .map((it) => InvoiceRequestItem(
              name: it.item.trim(),
              sku: it.sku,
              unit: it.unit,
              qty: it.qty,
              unitPrice: it.unitPrice,
              taxPercent: it.taxPercent,
              discountPercent: it.discPercent,
            ))
        .toList();
    if (lines.isEmpty) return 'Add at least one line item';

    final request = InvoiceRequest(
      customerId: customerId,
      status: state.status.apiValue,
      dueDate: state.dueDate ?? DateTime.now().add(const Duration(days: 30)),
      notes: state.notes.trim(),
      overallDiscount: state.overallDiscount,
      items: lines,
    );

    state = state.copyWith(isSaving: true);
    final repo = ref.read(invoicesRepositoryProvider);
    final editingId = state.editingId;
    final result = editingId == null
        ? await repo.createInvoice(request)
        : await repo.updateInvoice('$editingId', request);
    state = state.copyWith(isSaving: false);

    return result.when(
      success: (_) {
        // Pull the server's version — it owns the invoice number and totals.
        ref.read(invoicesProvider.notifier).refresh();
        return null;
      },
      failure: (error) => error.message,
    );
  }
}

final invoiceDraftProvider =
    NotifierProvider<InvoiceDraftNotifier, InvoiceDraft>(
        InvoiceDraftNotifier.new);


/// Suggests the next invoice number by incrementing the trailing sequence of
/// the newest invoice the API returned (e.g. `P/26-27/0001` → `P/26-27/0002`).
/// Falls back to `INV-{year}-0001` when the list is empty or has no trailing
/// digits to bump.
String suggestInvoiceNumber(List<InvoiceModel> existing) {
  final trailing = RegExp(r'^(.*?)(\d+)$');
  for (final inv in existing) {
    final match = trailing.firstMatch(inv.id.trim());
    if (match == null) continue;
    final digits = match.group(2)!;
    final next = (int.tryParse(digits) ?? 0) + 1;
    return '${match.group(1)}${next.toString().padLeft(digits.length, '0')}';
  }
  return 'INV-${DateTime.now().year}-0001';
}
