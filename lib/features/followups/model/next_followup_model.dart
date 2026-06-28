import 'package:flutter/material.dart';

import '../../Leads/model/lead_model.dart';

/// A single row from `GET /next-followups`. The endpoint returns lead-shaped
/// objects (plus an `item_type` discriminator), so the raw lead is parsed into a
/// [LeadModel] for navigation while the display fields are pulled out here.
class NextFollowUp {
  final int id;

  /// `"Lead"` / `"Opportunity"` — drives the All / Lead / Opportunity filter.
  final String itemType;

  /// `item_title` from the API (falls back to the contact name).
  final String title;
  final String contactName;
  final String? company;
  final String? phone;

  final DateTime? nextFollowUpAt;

  /// Display status (`status.name` / `item_status`), e.g. "Interested".
  final String statusLabel;

  /// Raw `#rrggbb` colour for the status tag, if the API sent one.
  final String? statusColorHex;

  /// `hot` / `warm` / `cold`.
  final String? priority;

  /// The full lead, used to open the detail screen for `Lead` items.
  final LeadModel lead;

  const NextFollowUp({
    required this.id,
    required this.itemType,
    required this.title,
    required this.contactName,
    required this.statusLabel,
    required this.lead,
    this.company,
    this.phone,
    this.nextFollowUpAt,
    this.statusColorHex,
    this.priority,
  });

  bool get isLead => itemType.toLowerCase() == 'lead';

  bool get isOverdue {
    final d = nextFollowUpAt?.toLocal();
    return d != null && d.isBefore(DateTime.now());
  }

  /// Two-letter avatar initials from the contact / title.
  String get initials {
    final source = contactName.trim().isNotEmpty ? contactName : title;
    final parts = source.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return source.isNotEmpty ? source[0].toUpperCase() : '?';
  }

  /// Parses [statusColorHex] (`#10b981`) into a [Color], or null if absent.
  Color? get statusColor {
    final hex = statusColorHex?.replaceAll('#', '').trim();
    if (hex == null || hex.length != 6) return null;
    final value = int.tryParse(hex, radix: 16);
    return value == null ? null : Color(0xFF000000 | value);
  }

  factory NextFollowUp.fromJson(Map<String, dynamic> json) {
    final contact = [
      json['first_name'] as String? ?? '',
      json['last_name'] as String? ?? '',
    ].where((s) => s.trim().isNotEmpty && s.trim() != '.').join(' ').trim();

    final status = (json['status'] as Map?)?.cast<String, dynamic>();

    return NextFollowUp(
      id: (json['id'] as num?)?.toInt() ?? 0,
      itemType: json['item_type'] as String? ?? 'Lead',
      title: (json['item_title'] as String?)?.trim().isNotEmpty == true
          ? (json['item_title'] as String).trim()
          : (contact.isNotEmpty ? contact : (json['title'] as String? ?? '')),
      contactName: contact,
      company: (json['company'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['company'] as String?,
      phone: (json['phone'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['phone'] as String?,
      nextFollowUpAt: DateTime.tryParse(json['next_followup_at'] as String? ?? ''),
      statusLabel: status?['name'] as String? ??
          json['item_status'] as String? ??
          '—',
      statusColorHex: status?['color_hex'] as String?,
      priority: json['priority'] as String?,
      lead: LeadModel.fromJson(json),
    );
  }
}

/// One page of follow-ups plus the Laravel paginator metadata.
class NextFollowUpsPage {
  final List<NextFollowUp> items;
  final int currentPage;
  final int lastPage;
  final int total;

  const NextFollowUpsPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}
