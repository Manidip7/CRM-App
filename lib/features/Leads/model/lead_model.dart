enum LeadStatus { newLead, contacted, qualified, won, lost }
enum LeadSource { facebook, manual, referral, email, website, cold }

class LeadModel {
  final String id;
  final String title;
  final String? companyName;
  final String contactName;
  final String? phone;
  final String? email;
  final LeadStatus status;
  final LeadSource source;
  final DateTime nextFollowUp;
  final DateTime createdAt;
  final double? dealValue;
  final String? avatarInitials;
  final int avatarColorIndex;

  LeadModel({
    required this.id,
    required this.title,
    required this.contactName,
    this.companyName,
    this.phone,
    this.email,
    required this.status,
    required this.source,
    required this.nextFollowUp,
    required this.createdAt,
    this.dealValue,
    this.avatarInitials,
    required this.avatarColorIndex,
  });

  String get displayInitials {
    if (avatarInitials != null) return avatarInitials!;
    final parts = contactName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return contactName.isNotEmpty ? contactName[0].toUpperCase() : '?';
  }

  static List<LeadModel> sampleLeads() {
    final now = DateTime.now();
    return [
      LeadModel(
        id: '1',
        title: 'Mindverge Software - Facebook Lead',
        companyName: 'Mindverge Software',
        contactName: 'Rahul Sharma',
        phone: '+91 98765 43210',
        email: 'rahul@mindverge.com',
        status: LeadStatus.newLead,
        source: LeadSource.facebook,
        nextFollowUp: DateTime(2025, 5, 20, 21, 4),
        createdAt: now.subtract(const Duration(days: 7)),
        dealValue: 45000,
        avatarColorIndex: 0,
      ),
      LeadModel(
        id: '2',
        title: 'PeploHr - Facebook Lead',
        companyName: 'PeploHr',
        contactName: 'Priya Menon',
        phone: '+91 87654 32109',
        email: 'priya@peplo.hr',
        status: LeadStatus.newLead,
        source: LeadSource.facebook,
        nextFollowUp: DateTime(2025, 5, 20, 21, 2),
        createdAt: now.subtract(const Duration(days: 7)),
        dealValue: 28000,
        avatarColorIndex: 1,
      ),
      LeadModel(
        id: '3',
        title: 'Facebook Lead',
        companyName: null,
        contactName: 'Arjun Patel',
        phone: '+91 76543 21098',
        email: 'arjun.patel@gmail.com',
        status: LeadStatus.contacted,
        source: LeadSource.facebook,
        nextFollowUp: DateTime(2025, 5, 20, 20, 58),
        createdAt: now.subtract(const Duration(days: 7)),
        dealValue: 15000,
        avatarColorIndex: 2,
      ),
      LeadModel(
        id: '4',
        title: 'Facebook Lead',
        companyName: null,
        contactName: 'Sneha Verma',
        phone: '+91 65432 10987',
        email: 'sneha.v@outlook.com',
        status: LeadStatus.qualified,
        source: LeadSource.facebook,
        nextFollowUp: DateTime(2025, 5, 20, 20, 54),
        createdAt: now.subtract(const Duration(days: 7)),
        dealValue: 62000,
        avatarColorIndex: 3,
      ),
      LeadModel(
        id: '5',
        title: 'Manual Entry Lead',
        companyName: 'GlobalTech Solutions',
        contactName: 'Vikram Singh',
        phone: '+91 54321 09876',
        email: 'vikram@globaltech.in',
        status: LeadStatus.won,
        source: LeadSource.manual,
        nextFollowUp: now.add(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 14)),
        dealValue: 120000,
        avatarColorIndex: 4,
      ),
      LeadModel(
        id: '6',
        title: 'Referral Lead',
        companyName: 'BrightPath Analytics',
        contactName: 'Neha Kapoor',
        phone: '+91 43210 98765',
        email: 'neha@brightpath.io',
        status: LeadStatus.contacted,
        source: LeadSource.referral,
        nextFollowUp: now.add(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 3)),
        dealValue: 38000,
        avatarColorIndex: 5,
      ),
    ];
  }
}

// Extended lead model for detail screen
class LeadDetailModel {
  final LeadModel lead;
  final String leadId;
  final String? assignedToName;
  final String? assignedToRole;
  final String? designation;
  final String? website;
  final String? altPhone;
  final String? leadType;
  final String? territory;
  final String? branch;
  final String? description;
  final bool locationAvailable;
  final double? latitude;
  final double? longitude;

  LeadDetailModel({
    required this.lead,
    required this.leadId,
    this.assignedToName,
    this.assignedToRole,
    this.designation,
    this.website,
    this.altPhone,
    this.leadType,
    this.territory,
    this.branch,
    this.description,
    this.locationAvailable = false,
    this.latitude,
    this.longitude,
  });

  static LeadDetailModel fromLead(LeadModel lead) {
    return LeadDetailModel(
      lead: lead,
      leadId: 'LD-2026-000${lead.id}',
      assignedToName: 'Admin Owner',
      assignedToRole: 'Sales Manager',
      designation: null,
      website: null,
      altPhone: null,
      leadType: null,
      territory: null,
      branch: null,
      description: null,
      locationAvailable: false,
    );
  }
}
