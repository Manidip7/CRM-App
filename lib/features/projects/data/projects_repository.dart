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
  /// `status` is not part of the documented body — it is sent so the sheet's
  /// Status choice sticks, on the assumption the backend accepts or ignores it.
  Future<ApiResult<void>> addProjectTask(
    String id, {
    required String title,
    String? description,
    String? dueAt,
    int? assignedTo,
    required String priority,
    required String status,
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
        'status': status,
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
  /// meta: { total_projects, ... } }`.
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

    final meta = (map['meta'] as Map?)?.cast<String, dynamic>();

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
