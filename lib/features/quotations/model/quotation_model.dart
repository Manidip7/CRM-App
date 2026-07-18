import 'package:flutter/material.dart';

import '../../../core/utils/AppColors.dart';

/// Lifecycle status of a quotation. The enum order matches the status dropdown
/// order: Draft, Sent, Viewed, Accepted, Rejected, Expired, Final.
enum QuotationStatus {
  draft,
  sent,
  viewed,
  accepted,
  rejected,
  expired,
  finalized,
}

extension QuotationStatusName on QuotationStatus {
  /// Label shown in the status dropdown menu.
  String get label {
    switch (this) {
      case QuotationStatus.draft:
        return 'Draft';
      case QuotationStatus.sent:
        return 'Sent';
      case QuotationStatus.viewed:
        return 'Viewed';
      case QuotationStatus.accepted:
        return 'Accepted';
      case QuotationStatus.rejected:
        return 'Rejected';
      case QuotationStatus.expired:
        return 'Expired';
      case QuotationStatus.finalized:
        return 'Final';
    }
  }

  /// Short label shown on the card tag (uppercased).
  String get tagLabel => label.toUpperCase();

  /// A "final" quotation is one that has reached a closing state — accepted or
  /// explicitly finalized. Drives the "Final Only" dropdown filter.
  bool get isFinal =>
      this == QuotationStatus.accepted || this == QuotationStatus.finalized;

  Color get color {
    switch (this) {
      case QuotationStatus.draft:
        return AppColors.textSecondary;
      case QuotationStatus.sent:
        return AppColors.leadFunnelContacted;
      case QuotationStatus.viewed:
        return AppColors.primaryLight;
      case QuotationStatus.accepted:
        return AppColors.green;
      case QuotationStatus.rejected:
        return AppColors.red;
      case QuotationStatus.expired:
        return AppColors.lossPink;
      case QuotationStatus.finalized:
        return AppColors.leadFunnelWon;
    }
  }
}

/// A single line item attached to a quotation.
class QuotationItem {
  final String name;

  /// HSN / SAC code for the item, blank when not supplied.
  final String hsn;

  final int quantity;
  final double price;

  const QuotationItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.hsn = '',
  });

  double get total => quantity * price;
}

/// A single quotation row shown in the Quotations list.
class QuotationModel {
  /// GST a new quotation starts at; the user can still change it on the form.
  static const double defaultGstPercent = 18;

  final String id;

  /// Human-readable reference, e.g. "QT-2026-014".
  final String number;

  /// Short subject / title of the quotation.
  final String title;

  final String clientName;
  final String? companyName;

  /// Postal address of the company the quotation is raised for.
  final String? companyAddress;

  /// Total quoted amount (in [currency]).
  final double amount;
  final String currency;

  /// Number of line items in the quotation. When [items] is populated this is
  /// kept in sync, but it is also stored for sample rows without explicit items.
  final int itemCount;

  final QuotationStatus status;

  /// Date the quotation was created — used for sorting and the from/to filter.
  final DateTime createdDate;

  /// Date the quotation is valid until.
  final DateTime validUntil;

  /// Tax / GST applied to the subtotal, as a percentage (e.g. 18 = 18%).
  final double taxPercent;

  /// Free-form notes shown on the quotation.
  final String notes;

  /// Line items making up the quotation.
  final List<QuotationItem> items;

  /// Opportunity this quotation was generated from, if any.
  final String? opportunityId;

  /// Customer (`GET /customers`) this quotation is raised for, if any.
  final String? customerId;

  const QuotationModel({
    required this.id,
    required this.number,
    required this.title,
    required this.clientName,
    required this.amount,
    required this.itemCount,
    required this.status,
    required this.createdDate,
    required this.validUntil,
    this.companyName,
    this.companyAddress,
    this.currency = '\$',
    this.taxPercent = 0,
    this.notes = '',
    this.items = const [],
    this.opportunityId,
    this.customerId,
  });

  /// Item count to show in summaries — prefers the explicit [items] list.
  int get effectiveItemCount => items.isNotEmpty ? items.length : itemCount;

  /// Builds a [QuotationModel] from a `GET /quotations` list row. The title /
  /// client come from the linked opportunity → lead when present, otherwise the
  /// quotation's own customer fields. Amounts are INR strings (e.g. "8496.00").
  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    final opp = (json['opportunity'] as Map?)?.cast<String, dynamic>();
    final validUntil = _parseDate(json['valid_until']);
    final isFinal = json['is_selected_final'] == true;

    // Status: explicit "final" wins, otherwise expired-by-date, else "sent".
    QuotationStatus status;
    if (isFinal) {
      status = QuotationStatus.finalized;
    } else if (validUntil != null && validUntil.isBefore(DateTime.now())) {
      status = QuotationStatus.expired;
    } else {
      status = QuotationStatus.sent;
    }

    final customerCompany = (json['customer_company'] as String?)?.trim();

    return QuotationModel(
      id: '${json['id']}',
      number: json['quotation_number'] as String? ?? '—',
      title: (opp?['title'] as String?)?.trim().isNotEmpty == true
          ? (opp!['title'] as String).trim()
          : (json['customer_name'] as String? ?? 'Quotation'),
      clientName: json['customer_name'] as String? ?? '—',
      companyName: (customerCompany?.isEmpty ?? true) ? null : customerCompany,
      companyAddress: (json['customer_address'] as String?)?.trim().isEmpty ??
              true
          ? null
          : (json['customer_address'] as String).trim(),
      amount: _parseAmount(json['grand_total']),
      currency: '₹',
      itemCount: 0,
      status: status,
      createdDate:
          _parseDate(json['date']) ?? _parseDate(json['created_at']) ?? DateTime.now(),
      validUntil: validUntil ?? DateTime.now(),
      notes: json['notes'] as String? ?? '',
      opportunityId:
          json['opportunity_id'] == null ? null : '${json['opportunity_id']}',
      customerId:
          json['customer_id'] == null ? null : '${json['customer_id']}',
    );
  }

  static double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _parseDate(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;

  QuotationModel copyWith({
    String? id,
    String? number,
    String? title,
    String? clientName,
    String? companyName,
    String? companyAddress,
    double? amount,
    String? currency,
    int? itemCount,
    QuotationStatus? status,
    DateTime? createdDate,
    DateTime? validUntil,
    double? taxPercent,
    String? notes,
    List<QuotationItem>? items,
    String? opportunityId,
    String? customerId,
  }) {
    return QuotationModel(
      id: id ?? this.id,
      number: number ?? this.number,
      title: title ?? this.title,
      clientName: clientName ?? this.clientName,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      itemCount: itemCount ?? this.itemCount,
      status: status ?? this.status,
      createdDate: createdDate ?? this.createdDate,
      validUntil: validUntil ?? this.validUntil,
      taxPercent: taxPercent ?? this.taxPercent,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      opportunityId: opportunityId ?? this.opportunityId,
      customerId: customerId ?? this.customerId,
    );
  }

  String get displayInitials {
    final source = (companyName ?? clientName).trim();
    if (source.isEmpty) return '?';
    final parts = source.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  /// Formatted amount, e.g. "$12,500".
  String get amountLabel {
    final whole = amount.round();
    final digits = whole.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '$currency$buffer';
  }

  /// Sample quotations used to populate the list (no backend yet).
  static List<QuotationModel> sampleQuotations() {
    return [
      QuotationModel(
        id: '1',
        number: 'QT-2026-014',
        title: 'Annual SaaS Subscription',
        clientName: 'Priya Sharma',
        companyName: 'Nimbus Retail',
        amount: 48500,
        itemCount: 6,
        status: QuotationStatus.finalized,
        createdDate: DateTime(2026, 6, 2),
        validUntil: DateTime(2026, 7, 2),
        opportunityId: '1',
      ),
      QuotationModel(
        id: '2',
        number: 'QT-2026-013',
        title: 'Onboarding & Implementation',
        clientName: 'Marcus Lee',
        companyName: 'BlueWave Logistics',
        amount: 12750,
        itemCount: 4,
        status: QuotationStatus.accepted,
        createdDate: DateTime(2026, 5, 28),
        validUntil: DateTime(2026, 6, 28),
        opportunityId: '2',
      ),
      QuotationModel(
        id: '3',
        number: 'QT-2026-012',
        title: 'Premium Support Plan',
        clientName: 'Elena Rossi',
        companyName: 'Aurora Health',
        amount: 9200,
        itemCount: 3,
        status: QuotationStatus.sent,
        createdDate: DateTime(2026, 5, 24),
        validUntil: DateTime(2026, 6, 24),
        opportunityId: '3',
      ),
      QuotationModel(
        id: '4',
        number: 'QT-2026-011',
        title: 'Custom Integration Package',
        clientName: 'David Okafor',
        companyName: 'Summit Finance',
        amount: 27600,
        itemCount: 8,
        status: QuotationStatus.viewed,
        createdDate: DateTime(2026, 5, 20),
        validUntil: DateTime(2026, 6, 20),
        opportunityId: '4',
      ),
      QuotationModel(
        id: '5',
        number: 'QT-2026-010',
        title: 'Hardware Bundle Renewal',
        clientName: 'Sophie Turner',
        companyName: 'GreenField Agri',
        amount: 15400,
        itemCount: 5,
        status: QuotationStatus.draft,
        createdDate: DateTime(2026, 5, 16),
        validUntil: DateTime(2026, 6, 16),
        opportunityId: '5',
      ),
      QuotationModel(
        id: '6',
        number: 'QT-2026-009',
        title: 'Data Migration Service',
        clientName: 'Ahmed Hassan',
        companyName: 'Vertex Media',
        amount: 8300,
        itemCount: 2,
        status: QuotationStatus.rejected,
        createdDate: DateTime(2026, 5, 10),
        validUntil: DateTime(2026, 6, 10),
        opportunityId: '6',
      ),
      QuotationModel(
        id: '7',
        number: 'QT-2026-008',
        title: 'Marketing Automation Suite',
        clientName: 'Laura Chen',
        companyName: 'Pulse Digital',
        amount: 33900,
        itemCount: 7,
        status: QuotationStatus.expired,
        createdDate: DateTime(2026, 4, 30),
        validUntil: DateTime(2026, 5, 30),
        opportunityId: '2',
      ),
      QuotationModel(
        id: '8',
        number: 'QT-2026-007',
        title: 'Enterprise License Upgrade',
        clientName: 'Tom Baker',
        companyName: 'IronClad Security',
        amount: 62000,
        itemCount: 9,
        status: QuotationStatus.accepted,
        createdDate: DateTime(2026, 4, 22),
        validUntil: DateTime(2026, 5, 22),
        opportunityId: '4',
      ),
    ];
  }
}
