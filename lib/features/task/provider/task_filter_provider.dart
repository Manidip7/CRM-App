import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/TaskStatus.dart';
import 'task_provider.dart';

/// All the active filters applied to the Task List screen.
class TaskFilterState {
  final String search;

  /// null = "All Statuses".
  final TaskStatus? status;

  /// null = "All Assignees".
  final String? assignee;

  final DateTime? fromDate;
  final DateTime? toDate;

  const TaskFilterState({
    this.search = '',
    this.status,
    this.assignee,
    this.fromDate,
    this.toDate,
  });

  TaskFilterState copyWith({
    String? search,
    TaskStatus? status,
    String? assignee,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearStatus = false,
    bool clearAssignee = false,
    bool clearDates = false,
  }) {
    return TaskFilterState(
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      assignee: clearAssignee ? null : (assignee ?? this.assignee),
      fromDate: clearDates ? null : (fromDate ?? this.fromDate),
      toDate: clearDates ? null : (toDate ?? this.toDate),
    );
  }
}

class TaskFilterNotifier extends Notifier<TaskFilterState> {
  @override
  TaskFilterState build() => const TaskFilterState();

  void setSearch(String q) => state = state.copyWith(search: q);

  void setStatus(TaskStatus? s) => s == null
      ? state = state.copyWith(clearStatus: true)
      : state = state.copyWith(status: s);

  void setAssignee(String? a) => a == null
      ? state = state.copyWith(clearAssignee: true)
      : state = state.copyWith(assignee: a);

  void setFromDate(DateTime? d) => state = state.copyWith(fromDate: d);

  void setToDate(DateTime? d) => state = state.copyWith(toDate: d);

  void clearDates() => state = state.copyWith(clearDates: true);
}

final taskFilterProvider =
    NotifierProvider<TaskFilterNotifier, TaskFilterState>(
        TaskFilterNotifier.new);

/// Whether the collapsible status / assignee / date filter section is expanded.
class TaskFiltersExpanded extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final taskFiltersExpandedProvider =
    NotifierProvider<TaskFiltersExpanded, bool>(TaskFiltersExpanded.new);

/// Editable draft backing the "Edit Task" sheet. Holds the dropdown / date
/// selections so the sheet needs no local [setState].
class TaskEditDraft {
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime dueDate;

  const TaskEditDraft({
    required this.status,
    required this.priority,
    required this.dueDate,
  });

  TaskEditDraft copyWith({
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
  }) {
    return TaskEditDraft(
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

class TaskEditNotifier extends Notifier<TaskEditDraft?> {
  @override
  TaskEditDraft? build() => null;

  /// Seeds the draft from the task being edited.
  void start(TaskModel task) => state = TaskEditDraft(
        status: task.status,
        priority: task.priority,
        dueDate: task.dueDate,
      );

  void setStatus(TaskStatus s) => state = state?.copyWith(status: s);

  void setPriority(TaskPriority p) => state = state?.copyWith(priority: p);

  void setDueDate(DateTime d) => state = state?.copyWith(dueDate: d);
}

final taskEditProvider =
    NotifierProvider<TaskEditNotifier, TaskEditDraft?>(TaskEditNotifier.new);

/// The distinct list of assignees across every task, sorted alphabetically.
/// Drives the "All Assignees" dropdown.
final taskAssigneesProvider = Provider<List<String>>((ref) {
  final tasks = ref.watch(taskListProvider).tasks;
  final names = tasks.map((t) => t.assignee).toSet().toList()..sort();
  return names;
});

DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _dayEnd(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

/// Tasks after applying every active filter, earliest due-date first.
final filteredTasksProvider = Provider<List<TaskModel>>((ref) {
  final f = ref.watch(taskFilterProvider);
  final tasks = ref.watch(taskListProvider).tasks;
  final q = f.search.trim().toLowerCase();

  final result = tasks.where((t) {
    if (f.status != null && t.status != f.status) return false;
    if (f.assignee != null && t.assignee != f.assignee) return false;

    if (q.isNotEmpty) {
      final matches = t.title.toLowerCase().contains(q) ||
          t.nextAction.toLowerCase().contains(q) ||
          t.remark.toLowerCase().contains(q) ||
          t.assignee.toLowerCase().contains(q) ||
          (t.leadName?.toLowerCase().contains(q) ?? false);
      if (!matches) return false;
    }

    if (f.fromDate != null && t.dueDate.isBefore(_dayStart(f.fromDate!))) {
      return false;
    }
    if (f.toDate != null && t.dueDate.isAfter(_dayEnd(f.toDate!))) {
      return false;
    }
    return true;
  }).toList();

  result.sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return result;
});
