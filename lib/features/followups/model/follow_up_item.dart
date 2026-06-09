import 'package:flutter/material.dart';

import '../../../core/utils/AppColors.dart';
import '../../Leads/model/lead_model.dart';
import '../../Opportunities/model/opportunity_model.dart';

/// Where a follow-up originates from. Drives the All / Lead / Opportunity filter.
enum FollowUpType { lead, opportunity }

extension FollowUpTypeName on FollowUpType {
  String get label {
    switch (this) {
      case FollowUpType.lead:
        return 'Lead';
      case FollowUpType.opportunity:
        return 'Opportunity';
    }
  }

  Color get color {
    switch (this) {
      case FollowUpType.lead:
        return AppColors.primary;
      case FollowUpType.opportunity:
        return AppColors.green;
    }
  }

  IconData get icon {
    switch (this) {
      case FollowUpType.lead:
        return Icons.filter_list_rounded;
      case FollowUpType.opportunity:
        return Icons.trending_up_rounded;
    }
  }
}

/// Unified status taxonomy used by the status dropdown filter. The enum order
/// matches the dropdown order: Backlog, Discovery, InProgress, Interested,
/// Lost, Negotiation, New, Proposal, Won.
enum FollowUpStatus {
  backlog,
  discovery,
  inProgress,
  interested,
  lost,
  negotiation,
  newStatus,
  proposal,
  won,
}

extension FollowUpStatusName on FollowUpStatus {
  /// Label shown in the status dropdown menu.
  String get label {
    switch (this) {
      case FollowUpStatus.backlog:
        return 'Backlog';
      case FollowUpStatus.discovery:
        return 'Discovery';
      case FollowUpStatus.inProgress:
        return 'InProgress';
      case FollowUpStatus.interested:
        return 'Interested';
      case FollowUpStatus.lost:
        return 'Lost';
      case FollowUpStatus.negotiation:
        return 'Negotiation';
      case FollowUpStatus.newStatus:
        return 'New';
      case FollowUpStatus.proposal:
        return 'Proposal';
      case FollowUpStatus.won:
        return 'Won';
    }
  }

  /// Short label shown on the card tag (uppercased).
  String get tagLabel => label.toUpperCase();

  Color get color {
    switch (this) {
      case FollowUpStatus.backlog:
        return AppColors.red;
      case FollowUpStatus.discovery:
        return AppColors.leadFunnelQualified;
      case FollowUpStatus.inProgress:
        return AppColors.leadFunnelContacted;
      case FollowUpStatus.interested:
        return AppColors.primaryLight;
      case FollowUpStatus.lost:
        return AppColors.lossRed;
      case FollowUpStatus.negotiation:
        return AppColors.greenLight;
      case FollowUpStatus.newStatus:
        return AppColors.leadFunnelNew;
      case FollowUpStatus.proposal:
        return AppColors.green;
      case FollowUpStatus.won:
        return AppColors.leadFunnelWon;
    }
  }
}

/// A single unified "next follow-up" row, built from either a [LeadModel] or an
/// [OpportunityModel] so both can be shown together in one list.
class FollowUpItem {
  final String id;
  final FollowUpType type;
  final String title;
  final String contactName;
  final String? companyName;
  final String? phone;

  /// Human-readable due text shown on the card (e.g. "Jun 8, 9:04 PM").
  final String dueLabel;

  /// Parsed due date used for sorting + the from/to date range filter.
  final DateTime? dueDate;

  final bool isOverdue;

  final FollowUpStatus status;

  final String avatarInitials;
  final Color avatarColor;

  /// Source object — exactly one is non-null. Used to open the detail screen.
  final LeadModel? lead;
  final OpportunityModel? opportunity;

  const FollowUpItem({
    required this.id,
    required this.type,
    required this.title,
    required this.contactName,
    required this.dueLabel,
    required this.status,
    required this.avatarInitials,
    required this.avatarColor,
    this.companyName,
    this.phone,
    this.dueDate,
    this.isOverdue = false,
    this.lead,
    this.opportunity,
  });
}
