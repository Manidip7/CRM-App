import 'TaskStatus.dart';

/// Models for the agenda response (`GET /agenda?view=my|team`).
///
/// The endpoint groups tasks into four buckets — overdue / today / upcoming /
/// completed — and returns a count for each. Each task carries its linked
/// record (`taskable`: a Lead or an Opportunity) and its assignee.

/// One task from the agenda, tagged with the [group] bucket it came from.
class AgendaTask {
  final int id;
  final String title;
  final String? description;
  final DateTime? dueAt;
  final String? priority;
  final String? status;

  /// `App\Models\Lead` or `App\Models\Opportunity`.
  final String? taskableType;
  final int? taskableId;

  /// Display title of the linked lead / opportunity.
  final String? taskableTitle;
  final String? assigneeName;

  /// Which agenda bucket this task belongs to.
  final TaskStatus group;

  const AgendaTask({
    required this.id,
    required this.title,
    this.description,
    this.dueAt,
    this.priority,
    this.status,
    this.taskableType,
    this.taskableId,
    this.taskableTitle,
    this.assigneeName,
    required this.group,
  });

  /// True when the linked record is an Opportunity (else treated as a Lead).
  bool get isOpportunity =>
      (taskableType ?? '').toLowerCase().contains('opportunity');

  /// "Opportunity" / "Lead" label for the linked-record chip.
  String get linkedLabel => isOpportunity ? 'Opportunity' : 'Lead';

  factory AgendaTask.fromJson(Map<String, dynamic> json, TaskStatus group) {
    final taskable = (json['taskable'] as Map?)?.cast<String, dynamic>();
    final assignee = (json['assignee'] as Map?)?.cast<String, dynamic>();

    // The linked record's display title: opportunities/leads carry `title`;
    // leads also expose first/last name as a fallback.
    String? taskableTitle = taskable?['title'] as String?;
    if ((taskableTitle == null || taskableTitle.isEmpty) && taskable != null) {
      final name = [
        taskable['first_name'] as String? ?? '',
        taskable['last_name'] as String? ?? '',
      ].where((s) => s.trim().isNotEmpty).join(' ').trim();
      if (name.isNotEmpty) taskableTitle = name;
    }

    return AgendaTask(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      dueAt: DateTime.tryParse(json['due_at'] as String? ?? ''),
      priority: json['priority'] as String?,
      status: json['status'] as String?,
      taskableType: json['taskable_type'] as String?,
      taskableId: (json['taskable_id'] as num?)?.toInt(),
      taskableTitle: taskableTitle,
      assigneeName: assignee?['name'] as String?,
      group: group,
    );
  }
}

/// The per-bucket counts returned alongside the task lists.
class AgendaCounts {
  final int overdue;
  final int today;
  final int upcoming;
  final int completed;

  const AgendaCounts({
    this.overdue = 0,
    this.today = 0,
    this.upcoming = 0,
    this.completed = 0,
  });

  factory AgendaCounts.fromJson(Map<String, dynamic> json) => AgendaCounts(
        overdue: (json['overdue'] as num?)?.toInt() ?? 0,
        today: (json['today'] as num?)?.toInt() ?? 0,
        upcoming: (json['upcoming'] as num?)?.toInt() ?? 0,
        completed: (json['completed'] as num?)?.toInt() ?? 0,
      );

  int get total => overdue + today + upcoming + completed;
}

/// The full agenda bundle: counts plus the four task buckets.
class AgendaBundle {
  final AgendaCounts counts;
  final List<AgendaTask> overdue;
  final List<AgendaTask> today;
  final List<AgendaTask> upcoming;
  final List<AgendaTask> completed;

  const AgendaBundle({
    this.counts = const AgendaCounts(),
    this.overdue = const [],
    this.today = const [],
    this.upcoming = const [],
    this.completed = const [],
  });

  int get total =>
      overdue.length + today.length + upcoming.length + completed.length;

  factory AgendaBundle.fromJson(Map<String, dynamic> json) {
    final tasks = (json['tasks'] as Map?)?.cast<String, dynamic>() ?? const {};
    final counts = (json['counts'] as Map?)?.cast<String, dynamic>();

    List<AgendaTask> bucket(String key, TaskStatus group) {
      final list = tasks[key] as List? ?? const [];
      return list
          .map((e) =>
              AgendaTask.fromJson((e as Map).cast<String, dynamic>(), group))
          .toList(growable: false);
    }

    return AgendaBundle(
      counts: counts != null
          ? AgendaCounts.fromJson(counts)
          : const AgendaCounts(),
      overdue: bucket('overdue', TaskStatus.overdue),
      today: bucket('today', TaskStatus.dueToday),
      upcoming: bucket('upcoming', TaskStatus.upcoming),
      completed: bucket('completed', TaskStatus.completed),
    );
  }
}
