import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../data/projects_repository.dart';
import '../model/project_detail_models.dart';

/// A project's detail bundle from `GET /projects/{id}`, keyed by project id.
/// Backs the whole detail screen — Overview reads the project and progress,
/// the other tabs read their arrays.
final projectBundleProvider =
    FutureProvider.family<ProjectDetailBundle, String>((ref, projectId) async {
  final result = await ref.watch(projectsRepositoryProvider).getProject(projectId);
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});

/// Handles `POST /projects/{id}/notes`. The state is the in-flight `saving`
/// flag, which the Add Note sheet watches to block a double submit.
class AddProjectNote extends Notifier<bool> {
  @override
  bool build() => false;

  /// Submits [content]. Returns null on success, or the message to show on
  /// failure. On success the project is refetched so the new note — and the
  /// "Note Added" activity the backend logs — come back from the server.
  Future<String?> submit(String projectId, String content) async {
    final text = content.trim();
    if (text.isEmpty) return 'Write something first.';
    if (state) return null; // already in flight

    state = true;
    final result =
        await ref.read(projectsRepositoryProvider).addProjectNote(projectId, text);
    state = false;

    return result.when(
      success: (_) {
        ref.invalidate(projectBundleProvider(projectId));
        return null;
      },
      failure: (error) => error.message,
    );
  }
}

final addProjectNoteProvider =
    NotifierProvider<AddProjectNote, bool>(AddProjectNote.new);

/// Handles `POST /projects/{id}/files`. The state is the in-flight `uploading`
/// flag, which the Files tab watches to show progress and block a second pick.
class UploadProjectFile extends Notifier<bool> {
  @override
  bool build() => false;

  /// Uploads the file at [path] as [filename]. Returns null on success, or the
  /// message to show on failure. On success the project is refetched so the
  /// stored file — and the "File Uploaded" activity — come back from the server.
  Future<String?> submit(
    String projectId, {
    required String path,
    required String filename,
  }) async {
    if (state) return null; // already in flight

    state = true;
    final result = await ref
        .read(projectsRepositoryProvider)
        .uploadProjectFile(projectId, path: path, filename: filename);
    state = false;

    return result.when(
      success: (_) {
        ref.invalidate(projectBundleProvider(projectId));
        return null;
      },
      failure: (error) => error.message,
    );
  }
}

final uploadProjectFileProvider =
    NotifierProvider<UploadProjectFile, bool>(UploadProjectFile.new);

/// The reactive parts of the "Add Task" sheet — everything except the title and
/// description, which stay in text controllers because they drive nothing else.
///
/// The assignee is held as a user id (not a name) because that is what the
/// backend's `assigned_to` takes; the sheet resolves the name for display.
class ProjectTaskDraft {
  final int? assignedToId;
  final DateTime? dueDate;
  final TaskPriority priority;

  /// True while `POST /projects/{id}/tasks` is in flight.
  final bool saving;

  const ProjectTaskDraft({
    this.assignedToId,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.saving = false,
  });

  ProjectTaskDraft copyWith({
    int? assignedToId,
    DateTime? dueDate,
    TaskPriority? priority,
    bool? saving,
  }) {
    return ProjectTaskDraft(
      assignedToId: assignedToId ?? this.assignedToId,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      saving: saving ?? this.saving,
    );
  }
}

/// Holds the Add Task form and submits it via `POST /projects/{id}/tasks`.
class ProjectTaskDraftNotifier extends Notifier<ProjectTaskDraft> {
  @override
  ProjectTaskDraft build() => const ProjectTaskDraft();

  /// Clears the form. Call each time the sheet opens.
  void reset() => state = const ProjectTaskDraft();

  /// Rebuilt rather than copied so that picking "Unassigned" (null) sticks.
  void setAssignedToId(int? v) => state = ProjectTaskDraft(
        assignedToId: v,
        dueDate: state.dueDate,
        priority: state.priority,
        saving: state.saving,
      );

  void setDueDate(DateTime v) => state = state.copyWith(dueDate: v);
  void setPriority(TaskPriority v) => state = state.copyWith(priority: v);

  /// `due_at` in this endpoint's plain `yyyy-MM-dd` form.
  static String fmtDue(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  /// Submits the task. Returns null on success, or the message to show on
  /// failure. On success the project is refetched so the task — and the
  /// "Task Added" activity — come back from the server.
  Future<String?> submit(
    String projectId, {
    required String title,
    required String description,
  }) async {
    final text = title.trim();
    if (text.isEmpty) return 'Give the task a title.';
    if (state.saving) return null; // already in flight

    state = state.copyWith(saving: true);
    final due = state.dueDate;
    final result = await ref.read(projectsRepositoryProvider).addProjectTask(
          projectId,
          title: text,
          description: description.trim(),
          dueAt: due == null ? null : fmtDue(due),
          assignedTo: state.assignedToId,
          priority: state.priority.apiValue,
        );
    state = state.copyWith(saving: false);

    return result.when(
      success: (_) {
        ref.invalidate(projectBundleProvider(projectId));
        return null;
      },
      failure: (error) => error.message,
    );
  }
}

final projectTaskDraftProvider =
    NotifierProvider<ProjectTaskDraftNotifier, ProjectTaskDraft>(
        ProjectTaskDraftNotifier.new);
