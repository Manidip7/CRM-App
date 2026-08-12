// Models for the full opportunity detail response (`GET /opportunities/{id}`).
//
// The endpoint returns one rich object: the opportunity's own fields plus its
// nested `lead`, `assignees`, `items`, `activities`, `tasks`, `quotations` and
// `notes`. OpportunityDetailBundle carries all of it so the detail screen can
// fetch the record once and feed every tab from a single source.

/// One entry from an opportunity's `activities` timeline.
class OpportunityActivity {
  final int id;
  final String action;
  final String description;
  final String? userName;
  final DateTime? createdAt;

  const OpportunityActivity({
    required this.id,
    required this.action,
    required this.description,
    this.userName,
    this.createdAt,
  });

  factory OpportunityActivity.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return OpportunityActivity(
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

/// A note attached to an opportunity (`notes` array).
class OpportunityNote {
  final int id;
  final String content;
  final String? userName;
  final DateTime? createdAt;

  const OpportunityNote({
    required this.id,
    required this.content,
    this.userName,
    this.createdAt,
  });

  factory OpportunityNote.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return OpportunityNote(
      id: (json['id'] as num?)?.toInt() ?? 0,
      content: json['content'] as String? ?? '',
      userName: user is Map ? user['name'] as String? : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

/// A task linked to an opportunity (`tasks` array).
class OpportunityTask {
  final int id;
  final String title;
  final String? description;
  final String? priority;
  final String? status;
  final DateTime? dueAt;
  final String? assigneeName;

  const OpportunityTask({
    required this.id,
    required this.title,
    this.description,
    this.priority,
    this.status,
    this.dueAt,
    this.assigneeName,
  });

  factory OpportunityTask.fromJson(Map<String, dynamic> json) {
    final assignee = json['assignee'];
    return OpportunityTask(
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

/// A user assigned to the opportunity (`assignees` array).
class OpportunityAssignee {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? designation;
  final String? avatar;

  const OpportunityAssignee({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.designation,
    this.avatar,
  });

  factory OpportunityAssignee.fromJson(Map<String, dynamic> json) {
    return OpportunityAssignee(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      designation: json['designation'] as String?,
      avatar: json['avatar'] as String?,
    );
  }
}

/// A line-item product on the opportunity (`items` array). The API carries only
/// `item_id` (no product name), so the screen labels it by id.
class OpportunityItem {
  final int id;
  final int itemId;
  final double quantity;
  final double price;
  final double total;

  const OpportunityItem({
    required this.id,
    required this.itemId,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory OpportunityItem.fromJson(Map<String, dynamic> json) {
    final qty = double.tryParse('${json['quantity']}') ?? 0;
    final price = double.tryParse('${json['price']}') ?? 0;
    final total = double.tryParse('${json['total']}') ?? qty * price;
    return OpportunityItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      itemId: (json['item_id'] as num?)?.toInt() ?? 0,
      quantity: qty,
      price: price,
      total: total,
    );
  }
}

/// A quotation generated for the opportunity (`quotations` array).
class OpportunityQuotation {
  final int id;
  final String quotationNumber;
  final DateTime? date;
  final DateTime? validUntil;
  final String? customerName;
  final double subtotal;
  final double taxTotal;
  final double grandTotal;
  final bool isSelectedFinal;

  const OpportunityQuotation({
    required this.id,
    required this.quotationNumber,
    this.date,
    this.validUntil,
    this.customerName,
    required this.subtotal,
    required this.taxTotal,
    required this.grandTotal,
    this.isSelectedFinal = false,
  });

  factory OpportunityQuotation.fromJson(Map<String, dynamic> json) {
    return OpportunityQuotation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      quotationNumber: json['quotation_number'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      validUntil: DateTime.tryParse(json['valid_until'] as String? ?? ''),
      customerName: json['customer_name'] as String?,
      subtotal: double.tryParse('${json['subtotal']}') ?? 0,
      taxTotal: double.tryParse('${json['tax_total']}') ?? 0,
      grandTotal: double.tryParse('${json['grand_total']}') ?? 0,
      isSelectedFinal: json['is_selected_final'] == true,
    );
  }
}

/// The full opportunity detail bundle: the record's own fields plus every nested
/// collection from `GET /opportunities/{id}`.
class OpportunityDetailBundle {
  // Core opportunity fields
  final int id;
  final int? leadId;
  final String title;
  final double expectedValue;
  final int probability;
  final String? stage;

  /// The record's status (`status_id` + the nested `status` object). This is
  /// what the header dropdown selects and what `POST /opportunities/{id}/stage`
  /// writes back, so it — not the free-text [stage] — is the source of truth.
  final int? statusId;
  final String? statusName;
  final String? statusColorHex;

  final bool isWon;
  final bool isLost;
  final DateTime? nextFollowupAt;
  final String? followupRemarks;
  final int? interestScore;

  // Contact info (sourced from the nested `lead`)
  final String? contactName;
  final String? phone;
  final String? email;
  final String? interestedIn;
  final String? leadNo;
  final String? sourceName;

  // Follow-up lookups (from the nested `lead`) used to pre-select the
  // Schedule Follow-up sheet's dropdowns.
  final int? currentUpdateId;
  final int? nextActionId;

  // Nested collections
  final List<OpportunityAssignee> assignees;
  final List<OpportunityItem> items;
  final List<OpportunityActivity> activities;
  final List<OpportunityTask> tasks;
  final List<OpportunityQuotation> quotations;
  final List<OpportunityNote> notes;

  const OpportunityDetailBundle({
    required this.id,
    this.leadId,
    required this.title,
    required this.expectedValue,
    required this.probability,
    this.stage,
    this.statusId,
    this.statusName,
    this.statusColorHex,
    this.isWon = false,
    this.isLost = false,
    this.nextFollowupAt,
    this.followupRemarks,
    this.interestScore,
    this.contactName,
    this.phone,
    this.email,
    this.interestedIn,
    this.leadNo,
    this.sourceName,
    this.currentUpdateId,
    this.nextActionId,
    this.assignees = const [],
    this.items = const [],
    this.activities = const [],
    this.tasks = const [],
    this.quotations = const [],
    this.notes = const [],
  });

  factory OpportunityDetailBundle.fromJson(Map<String, dynamic> json) {
    List<T> parse<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final list = json[key] as List? ?? const [];
      return list
          .map((e) => fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
    }

    final lead = (json['lead'] as Map?)?.cast<String, dynamic>();
    final contact = [
      lead?['first_name'] as String? ?? '',
      lead?['last_name'] as String? ?? '',
    ].where((s) => s.trim().isNotEmpty).join(' ').trim();

    return OpportunityDetailBundle(
      id: (json['id'] as num?)?.toInt() ?? 0,
      leadId: (json['lead_id'] as num?)?.toInt(),
      title: json['title'] as String? ?? '',
      expectedValue: double.tryParse('${json['expected_value']}') ?? 0,
      probability: (json['probability'] as num?)?.toInt() ?? 0,
      stage: json['stage'] as String?,
      statusId: (json['status_id'] as num?)?.toInt() ??
          ((json['status'] as Map?)?['id'] as num?)?.toInt(),
      statusName: (json['status'] as Map?)?['name'] as String?,
      statusColorHex: (json['status'] as Map?)?['color_hex'] as String?,
      isWon: json['is_won'] == true,
      isLost: json['is_lost'] == true,
      nextFollowupAt:
          DateTime.tryParse(json['next_followup_at'] as String? ?? ''),
      followupRemarks: json['followup_remarks'] as String?,
      interestScore: (json['interest_score'] as num?)?.toInt(),
      contactName: contact.isNotEmpty ? contact : null,
      phone: lead?['phone'] as String?,
      email: lead?['email'] as String?,
      interestedIn: lead?['interested_in'] as String?,
      leadNo: lead?['lead_no'] as String?,
      sourceName: (lead?['source'] as Map?)?['name'] as String?,
      currentUpdateId: (lead?['current_update_id'] as num?)?.toInt(),
      nextActionId: (lead?['next_action_id'] as num?)?.toInt(),
      assignees: parse('assignees', OpportunityAssignee.fromJson),
      items: parse('items', OpportunityItem.fromJson),
      activities: parse('activities', OpportunityActivity.fromJson),
      tasks: parse('tasks', OpportunityTask.fromJson),
      quotations: parse('quotations', OpportunityQuotation.fromJson),
      notes: parse('notes', OpportunityNote.fromJson),
    );
  }
}
