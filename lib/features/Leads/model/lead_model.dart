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

/// Maps the app's [LeadStatus] / [LeadSource] enums to the values the backend
/// expects on `GET /leads` (`status_id`, `source`).
extension LeadStatusApi on LeadStatus {
  /// Backend `status_id`: New=1, In Progress=2, Interested=3, Lost=4, Won=5.
  int get statusId => switch (this) {
        LeadStatus.newLead => 1,
        LeadStatus.contacted => 2, // "In Progress"
        LeadStatus.qualified => 3, // "Interested"
        LeadStatus.lost => 4,
        LeadStatus.won => 5,
      };
}

extension LeadSourceApi on LeadSource {
  /// Backend `source` query value (lowercase enum name).
  String get apiValue => name;
}

/// One option for the Add-Lead `lead_source_id` dropdown, from
/// `GET /lead-sources`.
class LeadSourceOption {
  final int id;
  final String label;
  final bool isActive;
  final bool isDefault;
  final int sortOrder;

  const LeadSourceOption({
    required this.id,
    required this.label,
    this.isActive = true,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  factory LeadSourceOption.fromJson(Map<String, dynamic> json) {
    return LeadSourceOption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      label: json['name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      isDefault: json['is_default'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A generic `{ id, name, is_active, sort_order }` lookup option used by the
/// follow-up dropdowns, e.g. `GET /current-updates`.
class NamedLookup {
  final int id;
  final String name;
  final bool isActive;
  final int sortOrder;

  const NamedLookup({
    required this.id,
    required this.name,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory NamedLookup.fromJson(Map<String, dynamic> json) {
    return NamedLookup(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A user that a lead can be assigned to (`GET /users`), used by the
/// Assign-Lead popup's multi-select. [designation] backs the sub-label.
class AssignableUser {
  final int id;
  final String name;
  final String? email;
  final String? designation;

  const AssignableUser({
    required this.id,
    required this.name,
    this.email,
    this.designation,
  });

  factory AssignableUser.fromJson(Map<String, dynamic> json) {
    return AssignableUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      designation: json['designation'] as String?,
    );
  }
}

/// A lead status option from `GET /statuses` (`type == "lead"`), used for the
/// status chip/menu on the lead detail header. [colorHex] is the raw
/// `#rrggbb` string; the UI converts it to a Color.
class StatusOption {
  final int id;
  final String name;
  final String type;
  final String? colorHex;
  final int sortOrder;

  const StatusOption({
    required this.id,
    required this.name,
    this.type = 'lead',
    this.colorHex,
    this.sortOrder = 0,
  });

  factory StatusOption.fromJson(Map<String, dynamic> json) {
    return StatusOption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'lead',
      colorHex: json['color_hex'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

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

  /// Whether the backend actually sent a recognized source. When false the UI
  /// hides the source badge rather than showing the `manual` fallback.
  final bool sourceKnown;
  final DateTime nextFollowUp;
  final DateTime createdAt;
  final double? dealValue;
  final String? avatarInitials;
  final int avatarColorIndex;

  /// First assignee (the person the lead is assigned to), if any.
  final String? assigneeName;
  final String? assigneeEmail;
  final String? assigneeDesignation;

  /// Names of all assignees on this lead (a lead can have several). Used to
  /// render the stacked initials avatars on the leads list card.
  final List<String> assigneeNames;

  /// The raw name parts, kept alongside the composed [contactName] so the
  /// Edit-Lead form can round-trip `first_name` / `last_name` separately.
  final String? firstName;
  final String? lastName;

  // Extra contact / professional fields.
  final String? alternatePhone;
  final String? designation;
  final String? website;
  final String? interestedIn;
  final String? priority;
  final String? description;

  // Location details.
  final String? address;
  final String? city;

  /// The lead's state/region (`state` on the API). Named `stateName` to avoid
  /// reading as a sibling of [status].
  final String? stateName;
  final String? pincode;
  final String? country;

  // Marketing & tracking.
  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;
  final String? integrationRef;

  /// Classification ids (and their resolved labels, when the API sends them).
  /// The Edit-Lead form binds its dropdowns to the ids; the labels let the UI
  /// render a value before the option lists have loaded.
  final int? leadSourceId;
  final int? leadTypeId;
  final String? leadTypeName;
  final int? territoryId;
  final String? territoryName;
  final int? branchId;
  final String? branchName;

  /// Backend status id (from `GET /statuses`), used to show/select the status
  /// chip on the detail header.
  final int? statusId;

  // Follow-up fields.
  final String? currentUpdate;
  final String? nextAction;
  final String? followupRemarks;

  /// Ids backing [currentUpdate] / [nextAction]. The detail API may return only
  /// these ids (no name), in which case the UI resolves the label from the
  /// `/current-updates` and `/next-actions` option lists.
  final int? currentUpdateId;
  final int? nextActionId;

  /// Interest/engagement score (0–100), set when scheduling a follow-up.
  final int? interestScore;

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
    this.sourceKnown = true,
    required this.nextFollowUp,
    required this.createdAt,
    this.dealValue,
    this.avatarInitials,
    required this.avatarColorIndex,
    this.assigneeName,
    this.assigneeEmail,
    this.assigneeDesignation,
    this.assigneeNames = const [],
    this.firstName,
    this.lastName,
    this.alternatePhone,
    this.designation,
    this.website,
    this.interestedIn,
    this.priority,
    this.description,
    this.address,
    this.city,
    this.stateName,
    this.pincode,
    this.country,
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.integrationRef,
    this.leadSourceId,
    this.leadTypeId,
    this.leadTypeName,
    this.territoryId,
    this.territoryName,
    this.branchId,
    this.branchName,
    this.statusId,
    this.currentUpdate,
    this.nextAction,
    this.followupRemarks,
    this.currentUpdateId,
    this.nextActionId,
    this.interestScore,
  });

  /// Returns a copy with updated follow-up fields (after the detail screen
  /// schedules a new follow-up), leaving every other field unchanged. Omitted
  /// arguments keep their current value.
  LeadModel copyWithFollowUp({
    DateTime? nextFollowUp,
    String? currentUpdate,
    String? nextAction,
    String? followupRemarks,
    int? currentUpdateId,
    int? nextActionId,
    int? interestScore,
  }) =>
      LeadModel(
        id: id,
        leadNo: leadNo,
        title: title,
        contactName: contactName,
        companyName: companyName,
        phone: phone,
        email: email,
        status: status,
        source: source,
        sourceKnown: sourceKnown,
        nextFollowUp: nextFollowUp ?? this.nextFollowUp,
        createdAt: createdAt,
        dealValue: dealValue,
        avatarInitials: avatarInitials,
        avatarColorIndex: avatarColorIndex,
        assigneeName: assigneeName,
        assigneeEmail: assigneeEmail,
        assigneeDesignation: assigneeDesignation,
        assigneeNames: assigneeNames,
        firstName: firstName,
        lastName: lastName,
        alternatePhone: alternatePhone,
        designation: designation,
        website: website,
        interestedIn: interestedIn,
        priority: priority,
        description: description,
        address: address,
        city: city,
        stateName: stateName,
        pincode: pincode,
        country: country,
        utmSource: utmSource,
        utmMedium: utmMedium,
        utmCampaign: utmCampaign,
        integrationRef: integrationRef,
        leadSourceId: leadSourceId,
        leadTypeId: leadTypeId,
        leadTypeName: leadTypeName,
        territoryId: territoryId,
        territoryName: territoryName,
        branchId: branchId,
        branchName: branchName,
        statusId: statusId,
        currentUpdate: currentUpdate ?? this.currentUpdate,
        nextAction: nextAction ?? this.nextAction,
        followupRemarks: followupRemarks ?? this.followupRemarks,
        currentUpdateId: currentUpdateId ?? this.currentUpdateId,
        nextActionId: nextActionId ?? this.nextActionId,
        interestScore: interestScore ?? this.interestScore,
      );

  /// Returns a copy with a new [priority] (e.g. after the detail screen updates
  /// the lead's temperature), leaving every other field unchanged.
  LeadModel copyWithPriority(String? priority) => LeadModel(
        id: id,
        leadNo: leadNo,
        title: title,
        contactName: contactName,
        companyName: companyName,
        phone: phone,
        email: email,
        status: status,
        source: source,
        sourceKnown: sourceKnown,
        nextFollowUp: nextFollowUp,
        createdAt: createdAt,
        dealValue: dealValue,
        avatarInitials: avatarInitials,
        avatarColorIndex: avatarColorIndex,
        assigneeName: assigneeName,
        assigneeEmail: assigneeEmail,
        assigneeDesignation: assigneeDesignation,
        assigneeNames: assigneeNames,
        firstName: firstName,
        lastName: lastName,
        alternatePhone: alternatePhone,
        designation: designation,
        website: website,
        interestedIn: interestedIn,
        priority: priority,
        description: description,
        address: address,
        city: city,
        stateName: stateName,
        pincode: pincode,
        country: country,
        utmSource: utmSource,
        utmMedium: utmMedium,
        utmCampaign: utmCampaign,
        integrationRef: integrationRef,
        leadSourceId: leadSourceId,
        leadTypeId: leadTypeId,
        leadTypeName: leadTypeName,
        territoryId: territoryId,
        territoryName: territoryName,
        branchId: branchId,
        branchName: branchName,
        statusId: statusId,
        currentUpdate: currentUpdate,
        nextAction: nextAction,
        followupRemarks: followupRemarks,
        currentUpdateId: currentUpdateId,
        nextActionId: nextActionId,
        interestScore: interestScore,
      );

  /// Returns a copy with the fields edited on the Edit-Lead form applied.
  ///
  /// Unlike [copyWithFollowUp], every argument is applied exactly as given —
  /// passing `null` *clears* the field, which is what an emptied form input
  /// means. [contactName] is recomposed from [firstName] / [lastName] so the
  /// header reflects a renamed contact, falling back to the current name when
  /// both parts are blank. Fields the form does not expose (assignees,
  /// follow-up, timestamps) are carried over untouched.
  ///
  /// [statusName] and [leadSourceName] are the *labels* of the picked options;
  /// they are mapped back onto the [status] / [source] enums here so the badge
  /// mapping stays in one place. Pass null to leave the enum as it is.
  LeadModel copyWithEdit({
    required String title,
    required String? firstName,
    required String? lastName,
    required String? interestedIn,
    required String? description,
    required String? phone,
    required String? alternatePhone,
    required String? email,
    required String? companyName,
    required String? designation,
    required String? website,
    required String? address,
    required String? city,
    required String? stateName,
    required String? pincode,
    required String? country,
    required String? priority,
    required String? statusName,
    required int? statusId,
    required String? leadSourceName,
    required int? leadSourceId,
    required int? leadTypeId,
    required String? leadTypeName,
    required int? territoryId,
    required String? territoryName,
    required int? branchId,
    required String? branchName,
    required String? utmSource,
    required String? utmMedium,
    required String? utmCampaign,
    required String? integrationRef,
  }) {
    final contact = [firstName ?? '', lastName ?? '']
        .where((s) => s.trim().isNotEmpty)
        .join(' ')
        .trim();
    return LeadModel(
      id: id,
      leadNo: leadNo,
      title: title,
      contactName: contact.isNotEmpty ? contact : contactName,
      companyName: companyName,
      phone: phone,
      email: email,
      status: statusName == null ? status : _statusFromString(statusName),
      source: leadSourceName == null ? source : _sourceFromString(leadSourceName),
      sourceKnown:
          leadSourceName == null ? sourceKnown : _isKnownSource(leadSourceName),
      nextFollowUp: nextFollowUp,
      createdAt: createdAt,
      dealValue: dealValue,
      avatarInitials: avatarInitials,
      avatarColorIndex: avatarColorIndex,
      assigneeName: assigneeName,
      assigneeEmail: assigneeEmail,
      assigneeDesignation: assigneeDesignation,
      assigneeNames: assigneeNames,
      firstName: firstName,
      lastName: lastName,
      alternatePhone: alternatePhone,
      designation: designation,
      website: website,
      interestedIn: interestedIn,
      priority: priority,
      description: description,
      address: address,
      city: city,
      stateName: stateName,
      pincode: pincode,
      country: country,
      utmSource: utmSource,
      utmMedium: utmMedium,
      utmCampaign: utmCampaign,
      integrationRef: integrationRef,
      leadSourceId: leadSourceId,
      leadTypeId: leadTypeId,
      leadTypeName: leadTypeName,
      territoryId: territoryId,
      territoryName: territoryName,
      branchId: branchId,
      branchName: branchName,
      statusId: statusId,
      currentUpdate: currentUpdate,
      nextAction: nextAction,
      followupRemarks: followupRemarks,
      currentUpdateId: currentUpdateId,
      nextActionId: nextActionId,
      interestScore: interestScore,
    );
  }

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
    // All assignee names (a lead can have multiple assignees).
    final assigneeNames = (assignees is List)
        ? assignees
            .whereType<Map>()
            .map((a) => a['name'] as String?)
            .where((n) => n != null && n.trim().isNotEmpty)
            .cast<String>()
            .toList()
        : <String>[];

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
      sourceKnown: _isKnownSource(_nameOf(json['source'])),
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
      assigneeNames: assigneeNames,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      alternatePhone: json['alternate_phone'] as String?,
      designation: json['designation'] as String?,
      website: json['website'] as String?,
      interestedIn: json['interested_in'] as String?,
      priority: json['priority'] as String?,
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      stateName: json['state'] as String?,
      // Sent as a number by some backends, so normalise to a string.
      pincode: (json['pincode'] ?? json['pin_code'])?.toString(),
      country: json['country'] as String?,
      utmSource: json['utm_source'] as String?,
      utmMedium: json['utm_medium'] as String?,
      utmCampaign: json['utm_campaign'] as String?,
      integrationRef:
          json['integration_ref'] as String? ?? json['integration_reference'] as String?,
      leadSourceId: _lookupId(json, const ['lead_source_id', 'source']),
      leadTypeId: _lookupId(json, const ['lead_type_id', 'lead_type', 'leadType']),
      leadTypeName:
          _lookupName(json, const ['lead_type', 'leadType', 'lead_type_name']),
      territoryId: _lookupId(json, const ['territory_id', 'territory']),
      territoryName: _lookupName(json, const ['territory', 'territory_name']),
      branchId: _lookupId(json, const ['branch_id', 'branch']),
      branchName: _lookupName(json, const ['branch', 'branch_name']),
      statusId: _lookupId(json, const ['status_id', 'status']),
      currentUpdate: _lookupName(
          json, const ['current_update', 'currentUpdate', 'current_update_name']),
      nextAction: _lookupName(
          json, const ['next_action', 'nextAction', 'next_action_name']),
      followupRemarks:
          json['followup_remarks'] as String? ?? json['next_remark'] as String?,
      currentUpdateId: _lookupId(
          json, const ['current_update_id', 'current_update', 'currentUpdate']),
      nextActionId: _lookupId(
          json, const ['next_action_id', 'next_action', 'nextAction']),
      interestScore: (json['interest_score'] as num?)?.toInt(),
    );
  }

  /// Returns the first non-empty name found across the given [keys] (handles
  /// snake_case / camelCase / `*_name` variants the backend might use).
  static String? _lookupName(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = _nameOf(json[k]);
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  /// Returns the first id found across the given [keys]: a plain numeric id
  /// (`next_action_id`) or the `id` of a nested object (`next_action: {id}`).
  static int? _lookupId(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v is num) return v.toInt();
      if (v is Map && v['id'] is num) return (v['id'] as num).toInt();
    }
    return null;
  }

  /// Reads the display name from a nested object (trying `name` / `title` /
  /// `label`), or treats the value itself as the name when the API sends a
  /// plain string.
  static String? _nameOf(dynamic value) {
    if (value is Map) {
      return (value['name'] ?? value['title'] ?? value['label']) as String?;
    }
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

  /// Whether [value] names a source the app recognizes. Used to decide if the
  /// source badge should be shown at all — an unknown/missing source is hidden
  /// rather than displayed as the `manual` fallback.
  static bool _isKnownSource(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'facebook':
      case 'manual':
      case 'referral':
      case 'email':
      case 'website':
      case 'cold':
      case 'cold call':
        return true;
      default:
        return false;
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
