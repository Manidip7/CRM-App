/// One entry from a lead's `activities` timeline (`GET /leads/{id}`).
class LeadActivity {
  final int id;
  final String action;
  final String description;
  final String? userName;
  final DateTime? createdAt;

  const LeadActivity({
    required this.id,
    required this.action,
    required this.description,
    this.userName,
    this.createdAt,
  });

  factory LeadActivity.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return LeadActivity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      action: json['action'] as String? ?? '',
      description: json['description'] as String? ?? '',
      userName: user is Map ? user['name'] as String? : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  /// Human label for the [action] code, e.g. `followup_scheduled` → "Follow-up
  /// Scheduled".
  String get actionLabel => action
      .split(RegExp(r'[_\s]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// A note attached to a lead (`notes` array of `GET /leads/{id}`).
class LeadNote {
  final int id;
  final String content;
  final String? userName;
  final DateTime? createdAt;

  const LeadNote({
    required this.id,
    required this.content,
    this.userName,
    this.createdAt,
  });

  factory LeadNote.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return LeadNote(
      id: (json['id'] as num?)?.toInt() ?? 0,
      content: json['content'] as String? ?? '',
      userName: user is Map ? user['name'] as String? : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

/// A task linked to a lead (`tasks` array of `GET /leads/{id}`).
class LeadTask {
  final int id;
  final String title;
  final String? description;
  final String? priority;
  final String? status;
  final DateTime? dueAt;
  final String? assigneeName;

  const LeadTask({
    required this.id,
    required this.title,
    this.description,
    this.priority,
    this.status,
    this.dueAt,
    this.assigneeName,
  });

  factory LeadTask.fromJson(Map<String, dynamic> json) {
    final assignee = json['assignee'];
    return LeadTask(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      priority: json['priority'] as String?,
      status: json['status'] as String?,
      dueAt: DateTime.tryParse(json['due_at'] as String? ?? ''),
      assigneeName: assignee is Map ? assignee['name'] as String? : null,
    );
  }
}

/// The expandable parts of a lead's detail response: its activity timeline,
/// notes and tasks. Bundled so the screen fetches `GET /leads/{id}` once.
class LeadDetailBundle {
  final List<LeadActivity> activities;
  final List<LeadNote> notes;
  final List<LeadTask> tasks;

  const LeadDetailBundle({
    required this.activities,
    required this.notes,
    required this.tasks,
  });

  factory LeadDetailBundle.fromJson(Map<String, dynamic> json) {
    List<T> parse<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final list = json[key] as List? ?? const [];
      return list
          .map((e) => fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
    }

    return LeadDetailBundle(
      activities: parse('activities', LeadActivity.fromJson),
      notes: parse('notes', LeadNote.fromJson),
      tasks: parse('tasks', LeadTask.fromJson),
    );
  }
}

enum LeadStatus { newLead, contacted, qualified, won, lost }
enum LeadSource { facebook, manual, referral, email, website, cold }

// Pipeline status shown/edited on the detail screen
enum LeadPipelineStatus { newLead, inProgress, interested, lost }

// Temperature classification (engagement level)
enum LeadTemperature { hot, warm, cold }

class LeadModel {
  final String id;
  final String? leadNo;
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

  /// First assignee (the person the lead is assigned to), if any.
  final String? assigneeName;
  final String? assigneeEmail;
  final String? assigneeDesignation;

  // Extra contact / professional fields.
  final String? alternatePhone;
  final String? designation;
  final String? website;
  final String? interestedIn;
  final String? priority;

  // Follow-up fields.
  final String? currentUpdate;
  final String? nextAction;
  final String? followupRemarks;

  LeadModel({
    required this.id,
    this.leadNo,
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
    this.assigneeName,
    this.assigneeEmail,
    this.assigneeDesignation,
    this.alternatePhone,
    this.designation,
    this.website,
    this.interestedIn,
    this.priority,
    this.currentUpdate,
    this.nextAction,
    this.followupRemarks,
  });

  /// Builds a [LeadModel] from the backend JSON shape (the `/leads` list item).
  /// `status` and `source` arrive as nested objects (`{ "name": ... }`); the
  /// contact name is composed from `first_name` + `last_name`. Unknown/missing
  /// values fall back to sensible defaults so a single bad row can't crash the
  /// whole list.
  factory LeadModel.fromJson(Map<String, dynamic> json) {
    final id = '${json['id']}';
    final contact = [
      json['first_name'] as String? ?? '',
      json['last_name'] as String? ?? '',
    ].where((s) => s.trim().isNotEmpty).join(' ').trim();

    // First assignee from the `assignees` array, if present.
    final assignees = json['assignees'];
    final firstAssignee = (assignees is List && assignees.isNotEmpty)
        ? (assignees.first as Map).cast<String, dynamic>()
        : null;

    return LeadModel(
      id: id,
      leadNo: json['lead_no'] as String?,
      title: json['title'] as String? ?? '',
      companyName: json['company'] as String? ?? json['company_name'] as String?,
      contactName: contact.isNotEmpty
          ? contact
          : (json['contact_name'] as String? ?? ''),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      status: _statusFromString(_nameOf(json['status'])),
      source: _sourceFromString(_nameOf(json['source'])),
      nextFollowUp: _parseDate(json['next_followup_at'] ?? json['next_follow_up']) ??
          DateTime.now(),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      dealValue: (json['deal_value'] as num?)?.toDouble(),
      avatarInitials: json['avatar_initials'] as String?,
      avatarColorIndex: (json['avatar_color_index'] as num?)?.toInt() ??
          (int.tryParse(id) ?? 0),
      assigneeName: firstAssignee?['name'] as String?,
      assigneeEmail: firstAssignee?['email'] as String?,
      assigneeDesignation: firstAssignee?['designation'] as String?,
      alternatePhone: json['alternate_phone'] as String?,
      designation: json['designation'] as String?,
      website: json['website'] as String?,
      interestedIn: json['interested_in'] as String?,
      priority: json['priority'] as String?,
      currentUpdate: _nameOf(json['current_update']),
      nextAction: _nameOf(json['next_action']),
      followupRemarks: json['followup_remarks'] as String?,
    );
  }

  /// Reads `.name` from a nested object, or treats the value itself as the name
  /// when the API sends a plain string.
  static String? _nameOf(dynamic value) {
    if (value is Map) return value['name'] as String?;
    if (value is String) return value;
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'company_name': companyName,
        'contact_name': contactName,
        'phone': phone,
        'email': email,
        'status': status.name,
        'source': source.name,
        'next_follow_up': nextFollowUp.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'deal_value': dealValue,
        'avatar_initials': avatarInitials,
        'avatar_color_index': avatarColorIndex,
      };

  static DateTime? _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Maps the backend status name (e.g. "In Progress", "Interested") to the
  /// app's [LeadStatus] enum. Also accepts the enum's own `name` for safety.
  static LeadStatus _statusFromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'new':
      case 'newlead':
        return LeadStatus.newLead;
      case 'in progress':
      case 'contacted':
        return LeadStatus.contacted;
      case 'interested':
      case 'qualified':
        return LeadStatus.qualified;
      case 'won':
      case 'converted':
        return LeadStatus.won;
      case 'lost':
      case 'not interested':
        return LeadStatus.lost;
      default:
        return LeadStatus.newLead;
    }
  }

  static LeadSource _sourceFromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'facebook':
        return LeadSource.facebook;
      case 'manual':
        return LeadSource.manual;
      case 'referral':
        return LeadSource.referral;
      case 'email':
        return LeadSource.email;
      case 'website':
        return LeadSource.website;
      case 'cold':
      case 'cold call':
        return LeadSource.cold;
      default:
        return LeadSource.manual;
    }
  }

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

  // Backlog leads — overdue / stale leads that need urgent follow-up
  static List<LeadModel> backlogLeads() {
    final now = DateTime.now();
    return [
      LeadModel(
        id: 'B1',
        title: 'Acme Corp - Stale Lead',
        companyName: 'Acme Corp',
        contactName: 'Rohan Gupta',
        phone: '+91 99887 76655',
        email: 'rohan@acmecorp.com',
        status: LeadStatus.contacted,
        source: LeadSource.facebook,
        nextFollowUp: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 32)),
        dealValue: 52000,
        avatarColorIndex: 2,
      ),
      LeadModel(
        id: 'B2',
        title: 'NovaTech - No Response',
        companyName: 'NovaTech',
        contactName: 'Kavya Nair',
        phone: '+91 88776 65544',
        email: 'kavya@novatech.io',
        status: LeadStatus.newLead,
        source: LeadSource.website,
        nextFollowUp: now.subtract(const Duration(days: 8)),
        createdAt: now.subtract(const Duration(days: 40)),
        dealValue: 30000,
        avatarColorIndex: 0,
      ),
      LeadModel(
        id: 'B3',
        title: 'Overdue Follow-up',
        companyName: 'Skyline Ventures',
        contactName: 'Aditya Rao',
        phone: '+91 77665 54433',
        email: 'aditya@skyline.vc',
        status: LeadStatus.qualified,
        source: LeadSource.referral,
        nextFollowUp: now.subtract(const Duration(days: 12)),
        createdAt: now.subtract(const Duration(days: 55)),
        dealValue: 88000,
        avatarColorIndex: 3,
      ),
      LeadModel(
        id: 'B4',
        title: 'Cold Lead - Reactivate',
        companyName: 'Pixel Labs',
        contactName: 'Meera Joshi',
        phone: '+91 66554 43322',
        email: 'meera@pixellabs.in',
        status: LeadStatus.contacted,
        source: LeadSource.cold,
        nextFollowUp: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 28)),
        dealValue: 21000,
        avatarColorIndex: 1,
      ),
      LeadModel(
        id: 'B5',
        title: 'Dropped Lead',
        companyName: 'Quantum Soft',
        contactName: 'Sahil Khan',
        phone: '+91 55443 32211',
        email: 'sahil@quantumsoft.com',
        status: LeadStatus.lost,
        source: LeadSource.email,
        nextFollowUp: now.subtract(const Duration(days: 20)),
        createdAt: now.subtract(const Duration(days: 60)),
        dealValue: 47000,
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
