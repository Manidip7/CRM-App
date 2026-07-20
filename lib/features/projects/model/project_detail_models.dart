import 'package:flutter/material.dart';

import '../../../core/network/api_constants.dart';
import '../../../core/utils/AppColors.dart';
import 'project_model.dart';

/// How urgent a project task is (`priority` on the API: high / medium / low).
enum TaskPriority {
  high,
  medium,
  low;

  String get label => switch (this) {
        TaskPriority.high => 'High',
        TaskPriority.medium => 'Medium',
        TaskPriority.low => 'Low',
      };

  Color get color => switch (this) {
        TaskPriority.high => AppColors.red,
        TaskPriority.medium => const Color(0xFFF5A623),
        TaskPriority.low => AppColors.green,
      };

  /// The value the backend stores.
  String get apiValue => name;

  static TaskPriority fromName(String? value) =>
      switch (value?.toLowerCase().trim()) {
        'high' => TaskPriority.high,
        'low' => TaskPriority.low,
        _ => TaskPriority.medium,
      };
}

/// A project task's workflow status, mirroring the backend's raw `status`
/// strings.
///
/// The backend takes `open` / `in_progress` / `done`. [backlog] is kept because
/// existing rows still carry it — it renders correctly but is not offered as a
/// choice (see [selectable]), so the app can never send a value the API rejects.
enum TaskState {
  backlog,
  open,
  inProgress,
  done;

  /// The statuses a user may pick. Excludes [backlog], which is display-only.
  static const List<TaskState> selectable = [open, inProgress, done];

  String get label => switch (this) {
        TaskState.backlog => 'Backlog',
        TaskState.open => 'Open',
        TaskState.inProgress => 'In Progress',
        TaskState.done => 'Done',
      };

  Color get color => switch (this) {
        TaskState.backlog => AppColors.textSecondary,
        TaskState.open => AppColors.primary,
        TaskState.inProgress => const Color(0xFFF5A623),
        TaskState.done => AppColors.green,
      };

  /// The value the backend stores. `inProgress` is sent snake_cased.
  String get apiValue => switch (this) {
        TaskState.inProgress => 'in_progress',
        _ => name,
      };

  bool get isDone => this == TaskState.done;

  /// Unknown statuses read as [open] rather than being dropped.
  static TaskState fromName(String? value) {
    switch (value?.toLowerCase().trim().replaceAll(RegExp(r'[\s-]'), '_')) {
      case 'done':
      case 'completed':
        return TaskState.done;
      case 'backlog':
        return TaskState.backlog;
      case 'in_progress':
      case 'inprogress':
        return TaskState.inProgress;
      default:
        return TaskState.open;
    }
  }
}

/// A user on the project team (`members[]` of `GET /projects/{id}`).
///
/// Unlike [ProjectModel.members] — which is just names, for the list card's
/// avatar stack — this keeps the user [id], since assigning a task needs it.
class ProjectMember {
  final int id;
  final String name;
  final String? designation;

  const ProjectMember({
    required this.id,
    required this.name,
    this.designation,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      designation: json['designation'] as String?,
    );
  }

  /// Initial for the avatar bubble.
  String get initial =>
      name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase();
}

/// A task on the project's Tasks tab (`tasks[]` of `GET /projects/{id}`).
class ProjectTask {
  final String id;
  final String title;
  final String? description;
  final String? assignedTo;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskState state;

  const ProjectTask({
    required this.id,
    required this.title,
    this.description,
    this.assignedTo,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.state = TaskState.open,
  });

  factory ProjectTask.fromJson(Map<String, dynamic> json) {
    final assignee = json['assignee'];
    return ProjectTask(
      id: '${json['id']}',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      assignedTo: assignee is Map ? assignee['name'] as String? : null,
      dueDate: _parseDate(json['due_at']),
      priority: TaskPriority.fromName(json['priority'] as String?),
      state: TaskState.fromName(json['status'] as String?),
    );
  }

  /// True when the due date has passed and the task is not finished.
  bool get isOverdue =>
      !state.isDone && dueDate != null && dueDate!.isBefore(DateTime.now());

  ProjectTask copyWith({TaskState? state}) => ProjectTask(
        id: id,
        title: title,
        description: description,
        assignedTo: assignedTo,
        dueDate: dueDate,
        priority: priority,
        state: state ?? this.state,
      );
}

/// A file attached to the project (`files[]` of `GET /projects/{id}`).
class ProjectFile {
  final String id;
  final String name;

  /// Size in bytes; 0 when unknown.
  final int sizeBytes;

  /// Server-side storage path, e.g. `project_files/abc.pdf`.
  final String? storagePath;

  /// MIME type from the API (`file_type`), e.g. `application/pdf`.
  final String? mimeType;

  final String? uploadedBy;
  final DateTime uploadedAt;

  const ProjectFile({
    required this.id,
    required this.name,
    required this.uploadedAt,
    this.sizeBytes = 0,
    this.storagePath,
    this.mimeType,
    this.uploadedBy,
  });

  factory ProjectFile.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return ProjectFile(
      id: '${json['id']}',
      name: json['file_name'] as String? ?? '',
      sizeBytes: (json['file_size'] as num?)?.toInt() ?? 0,
      storagePath: json['file_path'] as String?,
      mimeType: json['file_type'] as String?,
      uploadedBy: user is Map ? user['name'] as String? : null,
      uploadedAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  /// The file's extension, lowercase and without the dot ('' when it has none).
  String get extension {
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
  }

  bool get isImage =>
      (mimeType?.startsWith('image/') ?? false) ||
      const {'png', 'jpg', 'jpeg', 'gif', 'webp', 'heic'}.contains(extension);

  /// Public URL of a server-stored file.
  ///
  /// The API returns a storage-relative `file_path`, so this assumes Laravel's
  /// conventional `public/storage` symlink. If the deployment serves uploads
  /// from somewhere else, this is the one place to change.
  String? get downloadUrl => storagePath == null
      ? null
      : '${ApiConstants.baseUrl}/storage/$storagePath';

  /// Human-readable size, e.g. `1.4 MB`.
  String get readableSize {
    if (sizeBytes <= 0) return '—';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = sizeBytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    // Whole bytes/KB read better without a decimal.
    final text = unit == 0 || size >= 100
        ? size.toStringAsFixed(0)
        : size.toStringAsFixed(1);
    return '$text ${units[unit]}';
  }
}

/// A note on the project's Notes tab (`notes[]` of `GET /projects/{id}`).
class ProjectNote {
  final String id;
  final String content;
  final String? author;
  final DateTime createdAt;

  const ProjectNote({
    required this.id,
    required this.content,
    required this.createdAt,
    this.author,
  });

  factory ProjectNote.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return ProjectNote(
      id: '${json['id']}',
      content: json['content'] as String? ?? '',
      author: user is Map ? user['name'] as String? : null,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }
}

/// One entry on the project's Activity timeline (`activities[]` of
/// `GET /projects/{id}`).
///
/// [action] is kept raw because the backend mixes human labels ("Note Added",
/// "File Uploaded") with machine codes ("created", "updated"); the icon and
/// colour are derived from it by keyword rather than a closed enum, so an
/// action this app has never seen still renders sensibly.
class ProjectActivity {
  final String id;
  final String action;
  final String description;
  final String? user;
  final DateTime at;

  const ProjectActivity({
    required this.id,
    required this.action,
    required this.description,
    required this.at,
    this.user,
  });

  factory ProjectActivity.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return ProjectActivity(
      id: '${json['id']}',
      action: json['action'] as String? ?? '',
      description: json['description'] as String? ?? '',
      user: user is Map ? user['name'] as String? : null,
      at: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  /// "Note Added" stays as-is; "updated" becomes "Updated".
  String get label {
    if (action.isEmpty) return 'Activity';
    return action
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String get _key => action.toLowerCase();

  IconData get icon {
    if (_key.contains('note')) return Icons.sticky_note_2_outlined;
    if (_key.contains('file') || _key.contains('upload')) {
      return Icons.attach_file_rounded;
    }
    if (_key.contains('task')) return Icons.checklist_rounded;
    if (_key.contains('delet')) return Icons.delete_outline_rounded;
    if (_key.contains('creat')) return Icons.add_circle_outline_rounded;
    if (_key.contains('updat') || _key.contains('status')) {
      return Icons.edit_outlined;
    }
    return Icons.circle_notifications_outlined;
  }

  Color get color {
    if (_key.contains('note')) return const Color(0xFFF5A623);
    if (_key.contains('file') || _key.contains('upload')) {
      return AppColors.accent;
    }
    if (_key.contains('delet')) return AppColors.red;
    if (_key.contains('creat')) return AppColors.green;
    if (_key.contains('task') ||
        _key.contains('updat') ||
        _key.contains('status')) {
      return AppColors.primary;
    }
    return AppColors.textSecondary;
  }
}

/// The task counters and progress from the `meta` block of
/// `GET /projects/{id}`. These are server-authoritative — progress is not
/// recomputed from the loaded task list.
class ProjectProgress {
  final int completedTasks;
  final int totalTasks;

  /// 0–100, as sent by the API.
  final int percentage;

  const ProjectProgress({
    this.completedTasks = 0,
    this.totalTasks = 0,
    this.percentage = 0,
  });

  static const empty = ProjectProgress();

  /// 0..1, for the progress bar.
  double get fraction => (percentage.clamp(0, 100)) / 100;

  factory ProjectProgress.fromJson(Map<String, dynamic> json) {
    // Tolerate numbers arriving as strings (Laravel serializes some numeric
    // columns that way), so one string value can't break the whole decode.
    int toInt(dynamic v) {
      if (v is num) return v.round();
      if (v is String) return double.tryParse(v)?.round() ?? 0;
      return 0;
    }

    return ProjectProgress(
      completedTasks: toInt(json['completed_tasks_count']),
      totalTasks: toInt(json['total_tasks_count']),
      percentage: toInt(json['project_progress_percentage']),
    );
  }
}

/// Everything behind `GET /projects/{id}`: the project itself plus its tabs.
class ProjectDetailBundle {
  final ProjectModel project;
  final List<ProjectMember> members;
  final List<ProjectTask> tasks;
  final List<ProjectFile> files;
  final List<ProjectNote> notes;
  final List<ProjectActivity> activities;
  final ProjectProgress progress;

  const ProjectDetailBundle({
    required this.project,
    this.members = const [],
    this.tasks = const [],
    this.files = const [],
    this.notes = const [],
    this.activities = const [],
    this.progress = ProjectProgress.empty,
  });

  /// Decodes the `data` object. The project's own fields sit alongside the
  /// tab arrays, so [ProjectModel.fromJson] reads the same map.
  factory ProjectDetailBundle.fromJson(
    Map<String, dynamic> data, {
    Map<String, dynamic>? meta,
  }) {
    List<T> parse<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final list = data[key] as List? ?? const [];
      return list
          .map((e) => fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
    }

    return ProjectDetailBundle(
      project: ProjectModel.fromJson(data),
      members: parse('members', ProjectMember.fromJson),
      tasks: parse('tasks', ProjectTask.fromJson),
      files: parse('files', ProjectFile.fromJson),
      notes: parse('notes', ProjectNote.fromJson),
      activities: parse('activities', ProjectActivity.fromJson),
      progress:
          meta == null ? ProjectProgress.empty : ProjectProgress.fromJson(meta),
    );
  }
}

DateTime? _parseDate(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;
