import 'package:flutter/material.dart';

import '../../../core/utils/AppColors.dart';

// ─────────────────────────────────────────────
//  DATA MODELS
// ─────────────────────────────────────────────

enum OpportunityStage { proposal, negotiation, qualified, won, lost }

extension OpportunityStageName on OpportunityStage {
  String get label {
    switch (this) {
      case OpportunityStage.proposal:
        return 'PROPOSAL';
      case OpportunityStage.negotiation:
        return 'NEGOTIATION';
      case OpportunityStage.qualified:
        return 'QUALIFIED';
      case OpportunityStage.won:
        return 'WON';
      case OpportunityStage.lost:
        return 'LOST';
    }
  }

  Color get color {
    switch (this) {
      case OpportunityStage.proposal:
        return AppColors.green;
      case OpportunityStage.negotiation:
        return AppColors.greenLight;
      case OpportunityStage.qualified:
        return const Color(0xFF4CAF9A);
      case OpportunityStage.won:
        return AppColors.leadFunnelWon;
      case OpportunityStage.lost:
        return AppColors.lossRed;
    }
  }

  Color get bgColor {
    switch (this) {
      case OpportunityStage.proposal:
        return AppColors.green.withOpacity(0.12);
      case OpportunityStage.negotiation:
        return AppColors.greenLight.withOpacity(0.12);
      case OpportunityStage.qualified:
        return const Color(0xFF4CAF9A).withOpacity(0.12);
      case OpportunityStage.won:
        return AppColors.leadFunnelWon.withOpacity(0.12);
      case OpportunityStage.lost:
        return AppColors.redLight;
    }
  }
}

/// Maps a raw stage id (as returned by `GET /opportunity-stages`, e.g.
/// `"Prospecting"`) to the app's [OpportunityStage] enum. Case-insensitive.
/// Prospecting / Qualification / Qualified all collapse to [OpportunityStage.qualified].
OpportunityStage opportunityStageFromId(String id) {
  switch (id.toLowerCase().trim()) {
    case 'won':
      return OpportunityStage.won;
    case 'lost':
      return OpportunityStage.lost;
    case 'negotiation':
      return OpportunityStage.negotiation;
    case 'proposal':
      return OpportunityStage.proposal;
    case 'prospecting':
    case 'qualification':
    case 'qualified':
    default:
      return OpportunityStage.qualified;
  }
}

/// The accent color for a raw stage id. Derived from the [OpportunityStage]
/// palette so the dropdown matches the rest of the screen.
Color opportunityStageColor(String id) => opportunityStageFromId(id).color;

/// A selectable pipeline stage from `GET /opportunity-stages`
/// (`{ id, name }`, e.g. `{ "id": "Prospecting", "name": "Prospecting" }`).
/// Drives the stage dropdown on the opportunity detail header.
class StageOption {
  final String id;
  final String name;

  const StageOption({required this.id, required this.name});

  factory StageOption.fromJson(Map<String, dynamic> json) => StageOption(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? json['id']?.toString() ?? '',
      );

  Color get color => opportunityStageColor(id);
}

enum SourceType { manual, facebook, website, referral, email }

extension SourceTypeName on SourceType {
  String get label {
    switch (this) {
      case SourceType.manual:
        return 'MANUAL';
      case SourceType.facebook:
        return 'FACEBOOK';
      case SourceType.website:
        return 'WEBSITE';
      case SourceType.referral:
        return 'REFERRAL';
      case SourceType.email:
        return 'EMAIL';
    }
  }

  Color get color {
    switch (this) {
      case SourceType.manual:
        return const Color(0xFFB39DDB);
      case SourceType.facebook:
        return const Color(0xFF1877F2);
      case SourceType.website:
        return AppColors.primary;
      case SourceType.referral:
        return AppColors.donutTeal;
      case SourceType.email:
        return AppColors.accent;
    }
  }

  IconData get icon {
    switch (this) {
      case SourceType.manual:
        return Icons.edit_outlined;
      case SourceType.facebook:
        return Icons.facebook_rounded;
      case SourceType.website:
        return Icons.language_rounded;
      case SourceType.referral:
        return Icons.people_outline_rounded;
      case SourceType.email:
        return Icons.email_outlined;
    }
  }
}

/// A line-item product attached to an opportunity.
class OpportunityProduct {
  final String name;
  final int quantity;
  final double price;

  const OpportunityProduct({
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;
}

/// A catalog product from `GET /products`, shown in the Add Product picker on
/// the opportunity detail screen. Prices arrive from the API as strings.
class ProductModel {
  final int id;
  final String name;
  final String? sku;

  /// HSN / SAC code (`hsn_no`), often null in the catalog.
  final String? hsnNo;

  final String? unit;
  final double sellingPrice;
  final double taxPercent;
  final double priceAfterTax;

  const ProductModel({
    required this.id,
    required this.name,
    this.sku,
    this.hsnNo,
    this.unit,
    required this.sellingPrice,
    this.taxPercent = 0,
    required this.priceAfterTax,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final selling = double.tryParse('${json['selling_price']}') ?? 0;
    return ProductModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      hsnNo: json['hsn_no'] == null ? null : '${json['hsn_no']}',
      unit: json['unit'] as String?,
      sellingPrice: selling,
      taxPercent: double.tryParse('${json['tax_percent']}') ?? 0,
      priceAfterTax:
          double.tryParse('${json['price_after_tax']}') ?? selling,
    );
  }
}

class OpportunityModel {
  final String id;

  /// The originating lead's id (`lead_id`). Used for lead-scoped actions on the
  /// detail screen (notes / tasks / follow-up), which the backend keys by lead.
  final String? leadId;
  final String title;
  final String contactName;
  final double value;
  final int probability;
  final OpportunityStage stage;

  /// The raw stage id as sent by the backend (e.g. `"Prospecting"`,
  /// `"Qualification"`). Preserved unmodified so the header dropdown can
  /// highlight the exact stage, which the lossy [stage] enum cannot always
  /// distinguish (prospecting vs qualification both map to `qualified`).
  final String? stageRaw;

  final SourceType source;
  final String timeAgo;
  final String nextFollowUp;
  final String phone;
  final String avatarInitials;
  final Color avatarColor;

  /// Names of every user assigned to this opportunity (an opportunity can have
  /// several). Used to render the overlapping assignee avatars on the card,
  /// matching the Leads screen.
  final List<String> assigneeNames;

  const OpportunityModel({
    required this.id,
    this.leadId,
    required this.title,
    required this.contactName,
    required this.value,
    required this.probability,
    required this.stage,
    this.stageRaw,
    required this.source,
    required this.timeAgo,
    required this.nextFollowUp,
    required this.phone,
    required this.avatarInitials,
    required this.avatarColor,
    this.assigneeNames = const [],
  });

  // Red (0xFFFF4D6A) is intentionally excluded so it stays reserved for the
  // backlog ("overdue") accent — pipeline avatars never read as red.
  static const List<Color> _avatarColors = [
    Color(0xFF4B3FC7),
    Color(0xFF2DD4A0),
    Color(0xFFFFB547),
    Color(0xFF7B72E9),
    Color(0xFF4CAF9A),
  ];

  /// Builds an [OpportunityModel] from the `GET /opportunities` list item.
  /// Contact/phone/source come from the nested `lead`; `expected_value` arrives
  /// as a string; the stage is derived from `stage` + `is_won` / `is_lost`.
  factory OpportunityModel.fromJson(Map<String, dynamic> json) {
    final lead = (json['lead'] as Map?)?.cast<String, dynamic>();
    final contact = [
      lead?['first_name'] as String? ?? '',
      lead?['last_name'] as String? ?? '',
    ].where((s) => s.trim().isNotEmpty).join(' ').trim();
    final contactName =
        contact.isNotEmpty ? contact : (json['title'] as String? ?? '—');
    final sourceName = (lead?['source'] as Map?)?['name'] as String?;
    final createdAt =
        DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal();
    final nextRaw = json['next_followup_at'] ?? lead?['next_followup_at'];
    final nextDate =
        nextRaw is String ? DateTime.tryParse(nextRaw)?.toLocal() : null;
    final idStr = '${json['id']}';

    // Every assignee's name (an opportunity can have multiple assignees).
    final assignees = json['assignees'];
    final assigneeNames = (assignees is List)
        ? assignees
            .whereType<Map>()
            .map((a) => a['name'] as String?)
            .where((n) => n != null && n.trim().isNotEmpty)
            .cast<String>()
            .toList()
        : <String>[];

    return OpportunityModel(
      id: idStr,
      leadId: json['lead_id'] != null ? '${json['lead_id']}' : null,
      title: json['title'] as String? ?? '',
      contactName: contactName,
      value: double.tryParse('${json['expected_value']}') ?? 0,
      probability: (json['probability'] as num?)?.toInt() ?? 0,
      stage: _stageFrom(
        json['stage'] as String?,
        json['is_won'] == true,
        json['is_lost'] == true,
      ),
      stageRaw: json['is_won'] == true
          ? 'Won'
          : json['is_lost'] == true
              ? 'Lost'
              : json['stage'] as String?,
      source: _sourceFrom(sourceName),
      timeAgo: createdAt != null ? _timeAgo(createdAt) : '',
      nextFollowUp: nextDate != null ? _fmtDate(nextDate) : '—',
      phone: lead?['phone'] as String? ?? '—',
      avatarInitials: _initials(contactName),
      avatarColor:
          _avatarColors[(int.tryParse(idStr) ?? 0) % _avatarColors.length],
      assigneeNames: assigneeNames,
    );
  }

  static OpportunityStage _stageFrom(String? s, bool isWon, bool isLost) {
    if (isWon) return OpportunityStage.won;
    if (isLost) return OpportunityStage.lost;
    switch (s?.toLowerCase().trim()) {
      case 'won':
        return OpportunityStage.won;
      case 'lost':
        return OpportunityStage.lost;
      case 'negotiation':
        return OpportunityStage.negotiation;
      case 'proposal':
        return OpportunityStage.proposal;
      case 'prospecting':
      case 'qualified':
      case 'qualification':
        return OpportunityStage.qualified;
      default:
        return OpportunityStage.qualified;
    }
  }

  static SourceType _sourceFrom(String? name) {
    switch (name?.toLowerCase().trim()) {
      case 'facebook':
        return SourceType.facebook;
      case 'website':
        return SourceType.website;
      case 'referral':
        return SourceType.referral;
      case 'email':
        return SourceType.email;
      case 'manual':
      default:
        return SourceType.manual;
    }
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7) return '${diff.inDays ~/ 7}w';
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  }

  static String _fmtDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $h:$min $ampm';
  }

  OpportunityModel copyWith({
    String? id,
    String? leadId,
    String? title,
    String? contactName,
    double? value,
    int? probability,
    OpportunityStage? stage,
    String? stageRaw,
    SourceType? source,
    String? timeAgo,
    String? nextFollowUp,
    String? phone,
    String? avatarInitials,
    Color? avatarColor,
    List<String>? assigneeNames,
  }) {
    return OpportunityModel(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      title: title ?? this.title,
      contactName: contactName ?? this.contactName,
      value: value ?? this.value,
      probability: probability ?? this.probability,
      stage: stage ?? this.stage,
      stageRaw: stageRaw ?? this.stageRaw,
      source: source ?? this.source,
      timeAgo: timeAgo ?? this.timeAgo,
      nextFollowUp: nextFollowUp ?? this.nextFollowUp,
      phone: phone ?? this.phone,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      avatarColor: avatarColor ?? this.avatarColor,
      assigneeNames: assigneeNames ?? this.assigneeNames,
    );
  }
}
