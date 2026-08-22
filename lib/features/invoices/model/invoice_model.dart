import 'package:flutter/material.dart';

import '../../../core/utils/AppColors.dart';

/// Lifecycle state of an invoice. Colours map onto the shared [AppColors]
/// palette so cards/badges stay visually consistent with the rest of the app.
///
/// The backend sends free-text labels (`"Saved"`, `"Paid"`, `"Partially Paid"`,
/// …); [InvoiceStatus.fromApi] folds them into these buckets, while the raw
/// label is kept on [InvoiceModel.statusLabel] for display.
enum InvoiceStatus {
  paid,
  partial,
  pending,
  overdue,
  saved,
  cancelled,
  draft;

  /// The choices offered on the New Invoice form, in the order they appear in
  /// the dropdown. The remaining values ([partial], [pending]) are read-only —
  /// they only ever arrive from the API.
  static const formOptions = <InvoiceStatus>[
    InvoiceStatus.draft,
    InvoiceStatus.saved,
    InvoiceStatus.paid,
    InvoiceStatus.overdue,
    InvoiceStatus.cancelled,
  ];

  String get label {
    switch (this) {
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.partial:
        return 'Partial';
      case InvoiceStatus.pending:
        return 'Pending';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.saved:
        return 'Saved';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
      case InvoiceStatus.draft:
        return 'Draft';
    }
  }

  Color get color {
    switch (this) {
      case InvoiceStatus.paid:
        return AppColors.green;
      case InvoiceStatus.partial:
        return AppColors.primaryLight;
      case InvoiceStatus.pending:
        return const Color(0xFFF5A623); // amber
      case InvoiceStatus.overdue:
        return AppColors.red;
      case InvoiceStatus.saved:
        return AppColors.primary;
      case InvoiceStatus.cancelled:
        return AppColors.lossPink;
      case InvoiceStatus.draft:
        return AppColors.textSecondary;
    }
  }

  /// The value sent back to the API on create/update.
  String get apiValue => label;

  /// Maps an API status string onto a bucket. Unknown labels fall back to
  /// [InvoiceStatus.saved] so the raw text still renders with a neutral colour.
  static InvoiceStatus fromApi(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    switch (v) {
      case 'paid':
      case 'fully paid':
      case 'completed':
        return InvoiceStatus.paid;
      case 'partial':
      case 'partially paid':
      case 'part paid':
        return InvoiceStatus.partial;
      case 'pending':
      case 'unpaid':
      case 'sent':
      case 'due':
        return InvoiceStatus.pending;
      case 'overdue':
      case 'late':
        return InvoiceStatus.overdue;
      case 'cancelled':
      case 'canceled':
      case 'void':
        return InvoiceStatus.cancelled;
      case 'draft':
        return InvoiceStatus.draft;
      case 'saved':
        return InvoiceStatus.saved;
      default:
        return v.isEmpty ? InvoiceStatus.draft : InvoiceStatus.saved;
    }
  }
}

/// Customer block embedded in an invoice row (`invoice.customer`).
class InvoiceCustomer {
  final int? id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? country;

  const InvoiceCustomer({
    this.id,
    this.name = '',
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.country,
  });

  factory InvoiceCustomer.fromJson(Map<String, dynamic> json) {
    return InvoiceCustomer(
      id: _asInt(json['id']),
      name: _asString(json['name']) ?? '',
      email: _asString(json['email']),
      phone: _asString(json['phone']),
      address: _asString(json['address']),
      city: _asString(json['city']),
      state: _asString(json['state']),
      pincode: _asString(json['pincode']),
      country: _asString(json['country']),
    );
  }

  /// `City, State` (whichever parts exist) for the detail sheet.
  String? get location {
    final parts = [city, state].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? null : parts.join(', ');
  }
}

/// One line on an invoice (`invoice.items[]`).
class InvoiceItem {
  final int? id;
  final int? itemId;
  final String name;
  final String? sku;
  final String? unit;
  final double qty;
  final double unitPrice;
  final double taxPercent;
  final double discountPercent;
  final double amount;

  const InvoiceItem({
    this.id,
    this.itemId,
    this.name = '',
    this.sku,
    this.unit,
    this.qty = 0,
    this.unitPrice = 0,
    this.taxPercent = 0,
    this.discountPercent = 0,
    this.amount = 0,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    final product = (json['item'] as Map?)?.cast<String, dynamic>();
    return InvoiceItem(
      id: _asInt(json['id']),
      itemId: _asInt(json['item_id']),
      name: _asString(json['item_name']) ??
          _asString(product?['name']) ??
          'Item',
      sku: _asString(json['sku']) ?? _asString(product?['sku']),
      unit: _asString(json['unit']) ?? _asString(product?['unit']),
      qty: _asDouble(json['qty']),
      unitPrice: _asDouble(json['unit_price']),
      taxPercent: _asDouble(json['tax_percent']),
      discountPercent: _asDouble(json['discount_percent']),
      amount: _asDouble(json['amount']),
    );
  }

  /// `10 × ₹3,600` — the compact line shown under the item name.
  String get quantityLabel {
    final q = qty == qty.roundToDouble()
        ? qty.toStringAsFixed(0)
        : qty.toStringAsFixed(2);
    final suffix = (unit != null && unit!.isNotEmpty) ? ' $unit' : '';
    return '$q$suffix × ${formatMoney(unitPrice)}';
  }
}

/// A payment recorded against an invoice (`invoice.payments[]`). The backend
/// shape is not fixed yet, so every field is looked up defensively.
class InvoicePayment {
  final int? id;
  final double amount;
  final DateTime? date;
  final String? method;
  final String? reference;
  final String? notes;

  const InvoicePayment({
    this.id,
    this.amount = 0,
    this.date,
    this.method,
    this.reference,
    this.notes,
  });

  factory InvoicePayment.fromJson(Map<String, dynamic> json) {
    return InvoicePayment(
      id: _asInt(json['id']),
      amount: _asDouble(json['amount'] ?? json['paid_amount']),
      // Wall-clock: the payer's chosen time, not a UTC instant.
      date: _asWallClockDate(
          json['payment_date'] ?? json['date'] ?? json['created_at']),
      method: _asString(json['payment_mode'] ??
          json['payment_method'] ??
          json['method'] ??
          json['mode']),
      reference: _asString(json['reference'] ?? json['reference_no'] ??
          json['transaction_id']),
      notes: _asString(json['notes'] ?? json['remarks']),
    );
  }
}

/// `GET /invoices/{id}/payments` — the payment ledger for one invoice plus the
/// balances the backend computes from it.
class InvoicePaymentHistory {
  final int? invoiceId;
  final String? invoiceNumber;
  final double totalAmount;
  final double alreadyPaid;
  final double dueBalance;
  final String? currentStatus;
  final List<InvoicePayment> payments;

  const InvoicePaymentHistory({
    this.invoiceId,
    this.invoiceNumber,
    this.totalAmount = 0,
    this.alreadyPaid = 0,
    this.dueBalance = 0,
    this.currentStatus,
    this.payments = const [],
  });

  /// Payments newest first. The API returns them unordered, so they're sorted
  /// by payment date and then id (several can share a midnight timestamp).
  factory InvoicePaymentHistory.fromJson(Map<String, dynamic> json) {
    final payments = (json['payments'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => InvoicePayment.fromJson(e.cast<String, dynamic>()))
        .toList();

    payments.sort((a, b) {
      final byDate = (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0));
      return byDate != 0 ? byDate : (b.id ?? 0).compareTo(a.id ?? 0);
    });

    return InvoicePaymentHistory(
      invoiceId: _asInt(json['invoice_id']),
      invoiceNumber: _asString(json['invoice_number']),
      totalAmount: _asDouble(json['total_amount']),
      alreadyPaid: _asDouble(json['already_paid']),
      dueBalance: _asDouble(json['due_balance']),
      currentStatus: _asString(json['current_status'] ?? json['status']),
      payments: payments,
    );
  }
}

/// A single invoice. Amounts are stored as plain numbers; use [amountLabel] /
/// [paidLabel] for the `₹`-formatted display strings.
class InvoiceModel {
  /// Numeric primary key from the API — needed for `/invoices/{id}` calls.
  /// Null for invoices built locally before they have been saved.
  final int? serverId;

  final String id; // invoice number, e.g. P/26-27/0001
  final String customer;
  final DateTime dueDate;
  final DateTime createdDate;
  final InvoiceStatus status;

  /// Raw status text from the API, so labels the enum doesn't know about
  /// ("Partially Paid", "Cancelled", …) still show exactly as sent.
  final String? statusLabel;

  final double amount; // total invoice amount
  final double paidAmount;
  final double subTotal;
  final double taxTotal;
  final double discountAmount;
  final String createdBy;
  final String? notes;
  final String currency;
  final InvoiceCustomer? customerDetail;
  final List<InvoiceItem> items;
  final List<InvoicePayment> payments;

  const InvoiceModel({
    required this.id,
    required this.customer,
    required this.dueDate,
    required this.createdDate,
    required this.status,
    required this.amount,
    required this.paidAmount,
    required this.createdBy,
    this.serverId,
    this.statusLabel,
    this.subTotal = 0,
    this.taxTotal = 0,
    this.discountAmount = 0,
    this.notes,
    this.customerDetail,
    this.items = const [],
    this.payments = const [],
    this.currency = '₹',
  });

  /// Builds an invoice from one `GET /invoices` row.
  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final customerJson = (json['customer'] as Map?)?.cast<String, dynamic>();
    final creator = (json['creator'] as Map?)?.cast<String, dynamic>();
    final customer =
        customerJson == null ? null : InvoiceCustomer.fromJson(customerJson);

    final total = _asDouble(json['total_amount']);
    final paid = _asDouble(json['paid_amount']);
    // Date-only value: read as sent, so it can't slide a day across zones.
    final due = _asWallClockDate(json['due_date']);
    final rawStatus = _asString(json['status']);

    return InvoiceModel(
      serverId: _asInt(json['id']),
      id: _asString(json['invoice_number']) ?? '#${json['id'] ?? '—'}',
      customer: customer?.name.isNotEmpty == true ? customer!.name : '—',
      customerDetail: customer,
      dueDate: due ?? _asDate(json['created_at']) ?? DateTime.now(),
      createdDate: _asDate(json['created_at']) ?? DateTime.now(),
      status: InvoiceStatus.fromApi(rawStatus),
      statusLabel: rawStatus,
      amount: total,
      paidAmount: paid,
      subTotal: _asDouble(json['sub_total']),
      taxTotal: _asDouble(json['tax_total']),
      discountAmount: _asDouble(json['discount_amount']),
      notes: _asString(json['notes']),
      createdBy: _asString(creator?['name']) ?? '—',
      items: (json['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => InvoiceItem.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false),
      payments: (json['payments'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => InvoicePayment.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  /// Text shown in the status badge: the API's `status` field exactly as sent
  /// ("Saved", "Paid", …). Nothing is derived from dates or payments here — the
  /// badge always mirrors the backend.
  String get displayStatus {
    final raw = statusLabel?.trim();
    return (raw == null || raw.isEmpty) ? status.label : raw;
  }

  /// Outstanding balance still to be collected.
  double get outstanding => (amount - paidAmount).clamp(0, double.infinity);

  /// True when the invoice is past its due date and not fully paid. Used only
  /// to tint the due-date line and the balance figure — it does **not** change
  /// the status badge.
  bool get isOverdue =>
      status == InvoiceStatus.overdue ||
      (outstanding > 0 && dueDate.isBefore(DateTime.now()));

  String get amountLabel => formatCurrency(amount);
  String get paidLabel => formatCurrency(paidAmount);

  String get displayInitials {
    final parts =
        customer.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '#';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  String formatCurrency(double value) => '$currency${_thousands(value)}';

  InvoiceModel copyWith({
    int? serverId,
    String? id,
    String? customer,
    DateTime? dueDate,
    DateTime? createdDate,
    InvoiceStatus? status,
    String? statusLabel,
    double? amount,
    double? paidAmount,
    double? subTotal,
    double? taxTotal,
    double? discountAmount,
    String? createdBy,
    String? notes,
    InvoiceCustomer? customerDetail,
    List<InvoiceItem>? items,
    List<InvoicePayment>? payments,
  }) {
    return InvoiceModel(
      serverId: serverId ?? this.serverId,
      id: id ?? this.id,
      customer: customer ?? this.customer,
      dueDate: dueDate ?? this.dueDate,
      createdDate: createdDate ?? this.createdDate,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      subTotal: subTotal ?? this.subTotal,
      taxTotal: taxTotal ?? this.taxTotal,
      discountAmount: discountAmount ?? this.discountAmount,
      createdBy: createdBy ?? this.createdBy,
      notes: notes ?? this.notes,
      customerDetail: customerDetail ?? this.customerDetail,
      items: items ?? this.items,
      payments: payments ?? this.payments,
      currency: currency,
    );
  }
}

/// Aggregate figures shown in the summary row above the invoice list.
class InvoiceSummary {
  final int totalInvoices;
  final double totalAmount;
  final double collection; // amount collected so far
  final double pending; // outstanding on non-overdue invoices
  final double overdue; // outstanding on overdue invoices

  const InvoiceSummary({
    required this.totalInvoices,
    required this.totalAmount,
    required this.collection,
    required this.pending,
    required this.overdue,
  });

  static const empty = InvoiceSummary(
    totalInvoices: 0,
    totalAmount: 0,
    collection: 0,
    pending: 0,
    overdue: 0,
  );

  /// Reads the `summary` block that `GET /invoices` returns alongside the
  /// paginator, so the tiles show server-wide totals rather than page totals.
  factory InvoiceSummary.fromJson(Map<String, dynamic> json) {
    return InvoiceSummary(
      totalInvoices: _asInt(json['total_invoices']) ?? 0,
      totalAmount: _asDouble(json['total_amount']),
      collection: _asDouble(json['collected_amount']),
      pending: _asDouble(json['pending_amount']),
      overdue: _asDouble(json['overdue_amount']),
    );
  }

  /// Local fallback used when the API sends no `summary` block.
  factory InvoiceSummary.from(List<InvoiceModel> invoices) {
    double total = 0, collected = 0, pending = 0, overdue = 0;
    for (final inv in invoices) {
      total += inv.amount;
      collected += inv.paidAmount;
      if (inv.isOverdue) {
        overdue += inv.outstanding;
      } else {
        pending += inv.outstanding;
      }
    }
    return InvoiceSummary(
      totalInvoices: invoices.length,
      totalAmount: total,
      collection: collected,
      pending: pending,
      overdue: overdue,
    );
  }
}

// ─────────────────────────────────────────────
//  JSON helpers — the API mixes numbers and numeric strings ("0.00").
// ─────────────────────────────────────────────

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}

int? _asInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

/// Reads a timestamp as the wall-clock time it literally spells, ignoring any
/// zone marker.
///
/// `payment_date` and `due_date` are values the client chose (`2026-08-21
/// 13:04:43`) and the backend stores verbatim, but serializes with a `Z`
/// suffix. Converting those to local time would shift them by the device's
/// offset — a payment entered at 1:04 PM would read 6:34 PM in IST. Laravel's
/// own `created_at` / `updated_at` are genuinely UTC and still go through
/// [_asDate].
DateTime? _asWallClockDate(dynamic value) {
  if (value is! String) return null;
  final p = DateTime.tryParse(value);
  if (p == null) return null;
  // p.year/.hour report the components exactly as sent (UTC-flavoured or not);
  // rebuilding from them drops the zone instead of applying it.
  return DateTime(p.year, p.month, p.day, p.hour, p.minute, p.second);
}

DateTime? _asDate(dynamic value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

/// Formats a number with Indian-style thousands grouping (no decimals unless
/// there's a fractional part). Kept top-level so both the model and the UI can
/// reuse it.
String _thousands(double value) {
  final isNegative = value < 0;
  final abs = value.abs();
  final whole = abs.truncate();
  final digits = whole.toString();

  // Indian grouping: last 3 digits, then groups of 2.
  final buffer = StringBuffer();
  final n = digits.length;
  for (int i = 0; i < n; i++) {
    buffer.write(digits[i]);
    final remaining = n - i - 1;
    if (remaining == 0) continue;
    if (remaining == 3 || (remaining > 3 && (remaining - 3) % 2 == 0)) {
      buffer.write(',');
    }
  }
  final frac = abs - whole;
  final fracStr =
      frac > 0 ? '.${(frac * 100).round().toString().padLeft(2, '0')}' : '';
  return '${isNegative ? '-' : ''}$buffer$fracStr';
}

/// Public formatter for summary tiles that don't hold an [InvoiceModel].
String formatMoney(double value, {String currency = '₹'}) =>
    '$currency${_thousands(value)}';
