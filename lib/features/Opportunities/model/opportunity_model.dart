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

class OpportunityModel {
  final String id;
  final String title;
  final String contactName;
  final double value;
  final int probability;
  final OpportunityStage stage;
  final SourceType source;
  final String timeAgo;
  final String nextFollowUp;
  final String phone;
  final String avatarInitials;
  final Color avatarColor;

  const OpportunityModel({
    required this.id,
    required this.title,
    required this.contactName,
    required this.value,
    required this.probability,
    required this.stage,
    required this.source,
    required this.timeAgo,
    required this.nextFollowUp,
    required this.phone,
    required this.avatarInitials,
    required this.avatarColor,
  });
}
