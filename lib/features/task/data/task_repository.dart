import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/network_providers.dart';
import '../model/agenda_model.dart';
import '../model/task_item_model.dart';

/// Repository for the Task / Agenda feature, decoding through [ApiClient].
class TaskRepository {
  final ApiClient _api;

  TaskRepository(this._api);

  static const int perPage = 15;

  /// GET /tasks?page=N&per_page=15[&search=...] — one paginated page of tasks.
  /// When [search] is non-empty the server filters by it (e.g. `?search=Abhijit`).
  Future<ApiResult<TasksPage>> getTasks({int page = 1, String? search}) {
    final q = search?.trim() ?? '';
    return _api.get<TasksPage>(
      ApiConstants.tasks,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (q.isNotEmpty) 'search': q,
      },
      decoder: _decodeTasksPage,
    );
  }

  /// Unwraps `{ success, data: { current_page, data: [...], last_page, total } }`.
  static TasksPage _decodeTasksPage(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();
    if (map['success'] == false) {
      throw ApiException(
        type: ApiErrorType.validation,
        message: map['message'] as String? ?? 'Could not load tasks.',
        raw: json,
      );
    }
    final paginator = (map['data'] as Map?)?.cast<String, dynamic>();
    if (paginator == null) {
      throw ApiException.unexpected('Tasks response had no "data" object.');
    }
    final items = (paginator['data'] as List? ?? const [])
        .map((e) => TaskItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
    return TasksPage(
      items: items,
      currentPage: (paginator['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (paginator['last_page'] as num?)?.toInt() ?? 1,
      total: (paginator['total'] as num?)?.toInt() ?? items.length,
    );
  }

  /// GET /agenda?view=my|team — the agenda buckets (overdue / today / upcoming /
  /// completed) with their counts, for either the current user ([view] = `my`)
  /// or the whole team ([view] = `team`).
  Future<ApiResult<AgendaBundle>> getAgenda(String view) {
    return _api.get<AgendaBundle>(
      ApiConstants.agenda,
      queryParameters: {'view': view},
      decoder: (json) {
        final map = (json as Map).cast<String, dynamic>();
        if (map['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message: map['message'] as String? ?? 'Could not load agenda.',
            raw: json,
          );
        }
        final data = (map['data'] as Map?)?.cast<String, dynamic>();
        if (data == null) {
          throw ApiException.unexpected('Agenda response had no "data" object.');
        }
        return AgendaBundle.fromJson(data);
      },
    );
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(apiClientProvider));
});
