import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/AppColors.dart';
import '../../Leads/model/lead_model.dart';
import '../model/TaskStatus.dart';

/// Status options offered by the Create-Task form. Distinct from the list's
/// [TaskStatus] (which is a *derived* due-date bucket) — these are the raw
/// workflow states the backend stores against a task.
enum NewTaskStatus { open, inProgress, backlog, done }

extension NewTaskStatusX on NewTaskStatus {
  String get label {
    switch (this) {
      case NewTaskStatus.open:
        return 'Open';
      case NewTaskStatus.inProgress:
        return 'In Progress';
      case NewTaskStatus.backlog:
        return 'Backlog';
      case NewTaskStatus.done:
        return 'Done';
    }
  }

  /// Value sent to the API (`status` field).
  String get apiValue {
    switch (this) {
      case NewTaskStatus.open:
        return 'open';
      case NewTaskStatus.inProgress:
        return 'in_progress';
      case NewTaskStatus.backlog:
        return 'backlog';
      case NewTaskStatus.done:
        return 'done';
    }
  }

  Color get color {
    switch (this) {
      case NewTaskStatus.open:
        return AppColors.primary;
      case NewTaskStatus.inProgress:
        return AppColors.accent;
      case NewTaskStatus.backlog:
        return AppColors.textSecondary;
      case NewTaskStatus.done:
        return AppColors.green;
    }
  }
}

/// Priority order shown in the Create-Task dropdown (Low → High), reusing the
/// shared [TaskPriority] enum.
const kCreateTaskPriorities = [
  TaskPriority.low,
  TaskPriority.medium,
  TaskPriority.high,
];

/// The non-text state of the Create-Task form. Title/description live in local
/// controllers; everything the UI drives reactively lives here.
class CreateTaskDraft {
  final NewTaskStatus status;
  final TaskPriority priority;
  final AssignableUser? assignee;
  final DateTime? startDate;
  final DateTime? dueDate;

  const CreateTaskDraft({
    this.status = NewTaskStatus.open,
    this.priority = TaskPriority.medium,
    this.assignee,
    this.startDate,
    this.dueDate,
  });

  CreateTaskDraft copyWith({
    NewTaskStatus? status,
    TaskPriority? priority,
    AssignableUser? assignee,
    DateTime? startDate,
    DateTime? dueDate,
    bool clearAssignee = false,
  }) {
    return CreateTaskDraft(
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignee: clearAssignee ? null : (assignee ?? this.assignee),
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

class CreateTaskDraftNotifier extends Notifier<CreateTaskDraft> {
  @override
  CreateTaskDraft build() => const CreateTaskDraft();

  /// Clears the form back to defaults; call when the screen opens.
  void reset() => state = const CreateTaskDraft();

  void setStatus(NewTaskStatus s) => state = state.copyWith(status: s);
  void setPriority(TaskPriority p) => state = state.copyWith(priority: p);
  void setAssignee(AssignableUser? a) =>
      state = a == null ? state.copyWith(clearAssignee: true) : state.copyWith(assignee: a);
  void setStartDate(DateTime d) => state = state.copyWith(startDate: d);
  void setDueDate(DateTime d) => state = state.copyWith(dueDate: d);
}

final createTaskDraftProvider =
    NotifierProvider<CreateTaskDraftNotifier, CreateTaskDraft>(
        CreateTaskDraftNotifier.new);

/// Whether the Create-Task form is currently submitting to the API.
class CreateTaskSubmittingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final createTaskSubmittingProvider =
    NotifierProvider<CreateTaskSubmittingNotifier, bool>(
        CreateTaskSubmittingNotifier.new);
