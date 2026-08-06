import 'TaskStatus.dart';

/// A single task from `GET /tasks` (paginated). Shares the task shape used by
/// the agenda, plus the raw `status` string (open / backlog / done) which is
/// mapped to a [TaskStatus] for the UI via [derivedStatus].
class TaskItem {
  final int id;
  final String title;
  final String? description;
  final DateTime? startDate;
  final DateTime? dueAt;
  final String? priority;

  /// Raw backend status: `open`, `backlog`, `done`, …
  final String? rawStatus;

  final String? taskableType;
  final int? taskableId;
  final String? taskableTitle;
  final String? assigneeName;

  /// Id of the assigned user (`assigned_to`), needed to prefill the Edit form.
  final int? assignedTo;

  const TaskItem({
    required this.id,
    required this.title,
    this.description,
    this.startDate,
    this.dueAt,
    this.priority,
    this.rawStatus,
    this.taskableType,
    this.taskableId,
    this.taskableTitle,
    this.assigneeName,
    this.assignedTo,
  });

  bool get isOpportunity =>
      (taskableType ?? '').toLowerCase().contains('opportunity');

  String get linkedLabel => isOpportunity ? 'Opportunity' : 'Lead';

  /// Maps the backend status + due date to a [TaskStatus] bucket so the list's
  /// status tag / filter line up with the agenda: `done` → completed; otherwise
  /// overdue / due-today / upcoming based on [dueAt].
  TaskStatus get derivedStatus {
    if ((rawStatus ?? '').toLowerCase() == 'done') return TaskStatus.completed;
    final due = dueAt?.toLocal();
    if (due == null) return TaskStatus.upcoming;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    if (dueDay.isBefore(today)) return TaskStatus.overdue;
    if (dueDay.isAtSameMomentAs(today)) return TaskStatus.dueToday;
    return TaskStatus.upcoming;
  }

  TaskPriority get priorityEnum {
    switch ((priority ?? '').toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      case 'medium':
      default:
        return TaskPriority.medium;
    }
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final taskable = (json['taskable'] as Map?)?.cast<String, dynamic>();
    final assignee = (json['assignee'] as Map?)?.cast<String, dynamic>();

    String? taskableTitle = taskable?['title'] as String?;
    if ((taskableTitle == null || taskableTitle.isEmpty) && taskable != null) {
      final name = [
        taskable['first_name'] as String? ?? '',
        taskable['last_name'] as String? ?? '',
      ].where((s) => s.trim().isNotEmpty).join(' ').trim();
      if (name.isNotEmpty) taskableTitle = name;
    }

    return TaskItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      startDate: DateTime.tryParse(json['start_date'] as String? ?? ''),
      dueAt: DateTime.tryParse(json['due_at'] as String? ?? ''),
      priority: json['priority'] as String?,
      rawStatus: json['status'] as String?,
      taskableType: json['taskable_type'] as String?,
      taskableId: (json['taskable_id'] as num?)?.toInt(),
      taskableTitle: taskableTitle,
      assigneeName: assignee?['name'] as String?,
      // Prefer the flat `assigned_to`; fall back to the nested assignee object.
      assignedTo: (json['assigned_to'] as num?)?.toInt() ??
          (assignee?['id'] as num?)?.toInt(),
    );
  }
}

/// One page of tasks plus the Laravel paginator metadata.
class TasksPage {
  final List<TaskItem> items;
  final int currentPage;
  final int lastPage;
  final int total;

  const TasksPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}
