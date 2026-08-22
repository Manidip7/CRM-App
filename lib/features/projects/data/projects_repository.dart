import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/network_providers.dart';
import '../model/project_detail_models.dart';
import '../model/project_model.dart';

/// One page of projects, the Laravel paginator metadata, and the `meta`
/// totals that back the summary row.
class ProjectsPage {
  final List<ProjectModel> projects;
  final int currentPage;
  final int lastPage;
  final int total;

  /// Server-side totals across every project (not just this page).
  final ProjectSummary summary;

  const ProjectsPage({
    required this.projects,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.summary,
  });

  bool get hasMore => currentPage < lastPage;
}

/// Repository for the Projects feature, decoding through the shared [ApiClient].
class ProjectsRepository {
  final ApiClient _api;

  ProjectsRepository(this._api);

  /// GET /projects?page=N&search=&status= — one paginated page of projects.
  ///
  /// [status] is the backend's display name for the status (e.g. "In Progress").
  /// Both filters are omitted when blank so the server returns everything.
  Future<ApiResult<ProjectsPage>> getProjects({
    int page = 1,
    String? search,
    String? status,
  }) {
    return _api.get<ProjectsPage>(
      ApiConstants.projects,
      queryParameters: {
        'page': page,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      decoder: _decodePage,
    );
  }

  /// POST /projects — creates a project. Sent as a raw JSON body matching the
  /// backend contract: `customer_id` and `members` are ids, `billing_type` /
  /// `status` are the display labels, `total_rate` / `estimated_hours` are
  /// integers, dates are `yyyy-MM-dd`, and `tags` is a comma-separated string.
  /// Returns the created project when the reply carries one.
  Future<ApiResult<ProjectModel?>> createProject({
    required String name,
    required int customerId,
    required String billingType,
    required String status,
    required int totalRate,
    required int estimatedHours,
    String? startDate,
    String? deadline,
    String? tags,
    String? description,
    required List<int> memberIds,
  }) {
    return _api.post<ProjectModel?>(
      ApiConstants.projects,
      options: Options(contentType: Headers.jsonContentType),
      data: {
        'name': name,
        'customer_id': customerId,
        'billing_type': billingType,
        'status': status,
        'total_rate': totalRate,
        'estimated_hours': estimatedHours,
        if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
        if (deadline != null && deadline.isNotEmpty) 'deadline': deadline,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        if (description != null && description.isNotEmpty)
          'description': description,
        'members': memberIds,
      },
      decoder: (json) {
        final map = json is Map ? json.cast<String, dynamic>() : null;
        if (map != null && map['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message: map['message'] as String? ?? 'Could not create project.',
            raw: json,
          );
        }
        final data = (map?['data'] as Map?)?.cast<String, dynamic>();
        return data == null ? null : ProjectModel.fromJson(data);
      },
    );
  }

  /// PUT /projects/{id} — updates a project's core fields. Same JSON contract
  /// as [createProject]; `tags` / `description` / `members` are only sent when
  /// provided so an edit that leaves them out doesn't clear them server-side.
  Future<ApiResult<ProjectModel?>> updateProject(
    String id, {
    required String name,
    required int customerId,
    required String billingType,
    required String status,
    required int totalRate,
    required int estimatedHours,
    String? startDate,
    String? deadline,
    String? tags,
    String? description,
    List<int>? memberIds,
  }) {
    return _api.put<ProjectModel?>(
      ApiConstants.projectDetail(id),
      options: Options(contentType: Headers.jsonContentType),
      data: {
        'name': name,
        'customer_id': customerId,
        'billing_type': billingType,
        'status': status,
        'total_rate': totalRate,
        'estimated_hours': estimatedHours,
        if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
        if (deadline != null && deadline.isNotEmpty) 'deadline': deadline,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (memberIds != null && memberIds.isNotEmpty) 'members': memberIds,
      },
      decoder: (json) {
        final map = json is Map ? json.cast<String, dynamic>() : null;
        if (map != null && map['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message: map['message'] as String? ?? 'Could not update project.',
            raw: json,
          );
        }
        final data = (map?['data'] as Map?)?.cast<String, dynamic>();
        return data == null ? null : ProjectModel.fromJson(data);
      },
    );
  }

  /// GET /projects/{id} — the project plus its tasks, files, notes and
  /// activities, and the `meta` progress counters.
  Future<ApiResult<ProjectDetailBundle>> getProject(String id) {
    return _api.get<ProjectDetailBundle>(
      ApiConstants.projectDetail(id),
      decoder: (json) {
        final map = (json as Map).cast<String, dynamic>();
        if (map['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message: map['message'] as String? ?? 'Could not load project.',
            raw: json,
          );
        }
        final data = (map['data'] as Map?)?.cast<String, dynamic>();
        if (data == null) {
          throw ApiException.unexpected('Project response had no "data".');
        }
        return ProjectDetailBundle.fromJson(
          data,
          meta: (map['meta'] as Map?)?.cast<String, dynamic>(),
        );
      },
    );
  }

  /// DELETE /projects/{id} — deletes a project.
  Future<ApiResult<void>> deleteProject(String id) {
    return _api.delete<void>(
      ApiConstants.projectDetail(id),
      decoder: (json) {
        if (json is Map && json['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message: json['message'] as String? ?? 'Could not delete project.',
            raw: json,
          );
        }
        return null;
      },
    );
  }

  /// POST /projects/{id}/notes — adds a note. Sent as a raw JSON body
  /// (`{ "content": ... }`).
  Future<ApiResult<void>> addProjectNote(String id, String content) {
    return _api.post<void>(
      ApiConstants.projectNotes(id),
      options: Options(contentType: Headers.jsonContentType),
      data: {'content': content},
      decoder: (json) {
        if (json is Map && json['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message: json['message'] as String? ?? 'Could not add note.',
            raw: json,
          );
        }
        return null;
      },
    );
  }

  /// POST /projects/{id}/tasks — adds a task. Sent as a raw JSON body.
  ///
  /// [dueAt] must already be formatted `yyyy-MM-dd` (this endpoint takes a
  /// plain date, unlike the lead task route's `yyyy-MM-dd HH:mm:ss`).
  /// [assignedTo] is a user id from the project's `members`. Optional fields
  /// are omitted rather than sent null.
  ///
  /// The body is exactly `{ title, description, due_at, assigned_to, priority }`
  /// — `status` is deliberately not sent, as this endpoint doesn't take one; a
  /// new task lands on the backend's default state.
  Future<ApiResult<void>> addProjectTask(
    String id, {
    required String title,
    String? description,
    String? dueAt,
    int? assignedTo,
    required String priority,
  }) {
    return _api.post<void>(
      ApiConstants.projectTasks(id),
      options: Options(contentType: Headers.jsonContentType),
      data: {
        'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (dueAt != null && dueAt.isNotEmpty) 'due_at': dueAt,
        if (assignedTo != null) 'assigned_to': assignedTo,
        'priority': priority,
      },
      decoder: (json) {
        if (json is Map && json['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message: json['message'] as String? ?? 'Could not add task.',
            raw: json,
          );
        }
        return null;
      },
    );
  }

  /// POST /projects/{id}/files — uploads one file as `multipart/form-data`
  /// under the `file` field.
  ///
  /// [path] is the picked file on disk; [filename] is the name the server
  /// should store (the picker's original name, not the temp path's).
  Future<ApiResult<void>> uploadProjectFile(
    String id, {
    required String path,
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(path, filename: filename),
    });
    return _api.post<void>(
      ApiConstants.projectFiles(id),
      // Dio sets the multipart content type (and boundary) from the FormData.
      data: formData,
      decoder: (json) {
        if (json is Map && json['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message: json['message'] as String? ?? 'Could not upload file.',
            raw: json,
          );
        }
        return null;
      },
    );
  }

  /// Unwraps `{ success, data: { current_page, data: [...], last_page, total },
  /// summary: { total_projects, ... } }`.
  static ProjectsPage _decodePage(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();

    if (map['success'] == false) {
      throw ApiException(
        type: ApiErrorType.validation,
        message: map['message'] as String? ?? 'Could not load projects.',
        raw: json,
      );
    }

    final paginator = (map['data'] as Map?)?.cast<String, dynamic>();
    if (paginator == null) {
      throw ApiException.unexpected('Projects response had no "data" object.');
    }

    final items = (paginator['data'] as List? ?? const [])
        .map((e) => ProjectModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);

    // The totals arrive in a top-level `summary` block; `meta` is kept as a
    // fallback in case an older build of the endpoint is in front of the app.
    final meta =
        ((map['summary'] ?? map['meta']) as Map?)?.cast<String, dynamic>();

    return ProjectsPage(
      projects: items,
      currentPage: (paginator['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (paginator['last_page'] as num?)?.toInt() ?? 1,
      total: (paginator['total'] as num?)?.toInt() ?? items.length,
      summary: meta == null
          ? ProjectSummary.empty
          : ProjectSummary.fromJson(meta),
    );
  }
}

final projectsRepositoryProvider = Provider<ProjectsRepository>((ref) {
  return ProjectsRepository(ref.watch(apiClientProvider));
});
