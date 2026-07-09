import 'package:flutter/material.dart';

import '../../../core/utils/AppColors.dart';

/// Lifecycle state of an invoice. Colours map onto the shared [AppColors]
/// palette so cards/badges stay visually consistent with the rest of the app.
enum InvoiceStatus {
  paid,
  partial,
  pending,
  overdue,
  draft;

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
      case InvoiceStatus.draft:
        return AppColors.textSecondary;
    }
  }
}

/// A single invoice. Amounts are stored as plain numbers; use [amountLabel] /
/// [paidLabel] for the `₹`-formatted display strings.
class InvoiceModel {
  final String id; // invoice number, e.g. INV-2026-0007
  final String customer;
  final DateTime dueDate;
  final DateTime createdDate;
  final InvoiceStatus status;
  final double amount; // total invoice amount
  final double paidAmount;
  final String createdBy;
  final String currency;

  const InvoiceModel({
    required this.id,
    required this.customer,
    required this.dueDate,
    required this.createdDate,
    required this.status,
    required this.amount,
    required this.paidAmount,
    required this.createdBy,
    this.currency = '₹',
  });

  /// Outstanding balance still to be collected.
  double get outstanding => (amount - paidAmount).clamp(0, double.infinity);

  /// True when the invoice is past its due date and not fully paid.
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

  String formatCurrency(double value) =>
      '$currency${_thousands(value)}';

  InvoiceModel copyWith({
    String? id,
    String? customer,
    DateTime? dueDate,
    DateTime? createdDate,
    InvoiceStatus? status,
    double? amount,
    double? paidAmount,
    String? createdBy,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      dueDate: dueDate ?? this.dueDate,
      createdDate: createdDate ?? this.createdDate,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      createdBy: createdBy ?? this.createdBy,
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
