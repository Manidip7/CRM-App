import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/network_providers.dart';
import '../model/lead_model.dart';

/// One page of leads plus the Laravel paginator metadata, so the UI knows
/// whether more pages exist.
class LeadsPage {
  final List<LeadModel> leads;
  final int currentPage;
  final int lastPage;
  final int total;

  const LeadsPage({
    required this.leads,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}

/// Repository for the Leads feature, decoding through the shared [ApiClient].
class LeadsRepository {
  final ApiClient _api;

  LeadsRepository(this._api);

  /// How many leads to fetch per page.
  static const int perPage = 10;

  /// GET /leads?page=N&per_page=10 — supports optional search, `status_id`,
  /// `source`, repeated `quick_filter` and date-range query params, and returns
  /// one paginated [LeadsPage].
  ///
  /// [quickFilters] is sent as repeated `quick_filter=today&quick_filter=...`
  /// params (Dio is configured with `ListFormat.multi`, so no `[]` brackets).
  Future<ApiResult<LeadsPage>> getLeads({
    int page = 1,
    String? search,
    int? statusId,
    String? source,
    List<String>? quickFilters,
    String? fromDate,
    String? toDate,
  }) {
    return _api.get<LeadsPage>(
      ApiConstants.leads,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
        if (statusId != null) 'status_id': statusId,
        if (source != null && source.isNotEmpty) 'source': source,
        if (quickFilters != null && quickFilters.isNotEmpty)
          'quick_filter': quickFilters,
        if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
      },
      decoder: _decodePage,
    );
  }

  /// Unwraps `{ success, data: { current_page, data: [...], last_page, total } }`.
  static LeadsPage _decodePage(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();

    if (map['success'] == false) {
      throw ApiException(
        type: ApiErrorType.validation,
        message: map['message'] as String? ?? 'Could not load leads.',
        raw: json,
      );
    }

    final paginator = (map['data'] as Map?)?.cast<String, dynamic>();
    if (paginator == null) {
      throw ApiException.unexpected('Leads response had no "data" object.');
    }

    final items = (paginator['data'] as List? ?? const [])
        .map((e) => LeadModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);

    return LeadsPage(
      leads: items,
      currentPage: (paginator['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (paginator['last_page'] as num?)?.toInt() ?? 1,
      total: (paginator['total'] as num?)?.toInt() ?? items.length,
    );
  }

  /// GET /leads/{id}
  Future<ApiResult<LeadModel>> getLead(String id) {
    return _api.get<LeadModel>(
      ApiConstants.leadDetail(id),
      decoder: (json) {
        final map = json is Map && json['data'] is Map ? json['data'] : json;
        return LeadModel.fromJson(map as Map<String, dynamic>);
      },
    );
  }

  /// GET /leads/{id} → the lead's timeline, notes and tasks.
  Future<ApiResult<LeadDetailBundle>> getLeadDetail(String id) {
    return _api.get<LeadDetailBundle>(
      ApiConstants.leadDetail(id),
      decoder: (json) {
        final map = json is Map && json['data'] is Map ? json['data'] : json;
        return LeadDetailBundle.fromJson((map as Map).cast<String, dynamic>());
      },
    );
  }

  /// GET /lead-sources — the options for the Add-Lead source dropdown.
  /// Returns only active sources, ordered by `sort_order`.
  Future<ApiResult<List<LeadSourceOption>>> getLeadSources() {
    return _api.get<List<LeadSourceOption>>(
      ApiConstants.leadSources,
      decoder: (json) {
        final list = (json is Map ? json['data'] : json) as List? ?? const [];
        final sources = list
            .map((e) =>
                LeadSourceOption.fromJson((e as Map).cast<String, dynamic>()))
            .where((s) => s.isActive)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return sources;
      },
    );
  }

  /// GET /current-updates — the options for the "Current Update" dropdown in
  /// the Schedule Follow-up popup. Returns only active options, ordered by
  /// `sort_order`.
  Future<ApiResult<List<NamedLookup>>> getCurrentUpdates() {
    return _api.get<List<NamedLookup>>(
      ApiConstants.currentUpdates,
      decoder: (json) {
        final list = (json is Map ? json['data'] : json) as List? ?? const [];
        final updates = list
            .map((e) => NamedLookup.fromJson((e as Map).cast<String, dynamic>()))
            .where((o) => o.isActive)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return updates;
      },
    );
  }

  /// GET /next-actions — the options for the "Next Action" dropdown in the
  /// Schedule Follow-up popup. Returns only active options, ordered by
  /// `sort_order`.
  Future<ApiResult<List<NamedLookup>>> getNextActions() {
    return _api.get<List<NamedLookup>>(
      ApiConstants.nextActions,
      decoder: (json) {
        final list = (json is Map ? json['data'] : json) as List? ?? const [];
        final actions = list
            .map((e) => NamedLookup.fromJson((e as Map).cast<String, dynamic>()))
            .where((o) => o.isActive)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return actions;
      },
    );
  }

  /// GET /statuses — lead status options for the detail header chip/menu.
  /// Returns only `type == "lead"` statuses, ordered by `sort_order`.
  Future<ApiResult<List<StatusOption>>> getStatuses() {
    return _api.get<List<StatusOption>>(
      ApiConstants.statuses,
      decoder: (json) {
        final list = (json is Map ? json['data'] : json) as List? ?? const [];
        final statuses = list
            .map((e) => StatusOption.fromJson((e as Map).cast<String, dynamic>()))
            .where((s) => s.type == 'lead')
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return statuses;
      },
    );
  }

  /// POST /leads — creates a lead from the Add-Lead form fields. Only [email]
  /// is optional; everything else is required by the backend.
  Future<ApiResult<LeadModel>> createLead({
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
    required String interestedIn,
    required String priority,
    required int leadSourceId,
  }) {
    return _api.post<LeadModel>(
      ApiConstants.leads,
      // Backend expects an `application/x-www-form-urlencoded` body.
      options: Options(contentType: Headers.formUrlEncodedContentType),
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        'interested_in': interestedIn,
        'priority': priority,
        'lead_source_id': leadSourceId,
      },
      decoder: (json) {
        final map = json is Map && json['data'] is Map ? json['data'] : json;
        return LeadModel.fromJson(map as Map<String, dynamic>);
      },
    );
  }

  /// POST /leads/{id}/followup — schedules the next follow-up for a lead.
  /// Sent as an `x-www-form-urlencoded` body. [nextFollowUpAt] must already be
  /// formatted as `yyyy-MM-dd HH:mm:ss`.
  Future<ApiResult<void>> scheduleFollowUp(
    String id, {
    int? currentUpdateId,
    int? nextActionId,
    String? followupRemarks,
    required String nextFollowUpAt,
    required int interestScore,
  }) {
    return _api.post<void>(
      ApiConstants.leadFollowup(id),
      options: Options(contentType: Headers.formUrlEncodedContentType),
      data: {
        if (currentUpdateId != null) 'current_update_id': currentUpdateId,
        if (nextActionId != null) 'next_action_id': nextActionId,
        if (followupRemarks != null && followupRemarks.isNotEmpty)
          'followup_remarks': followupRemarks,
        'next_followup_at': nextFollowUpAt,
        'interest_score': interestScore,
      },
      decoder: (json) {
        if (json is Map && json['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message:
                json['message'] as String? ?? 'Could not schedule follow-up.',
            raw: json,
          );
        }
        return null;
      },
    );
  }

  /// POST /leads/{id}/notes — adds a note to a lead. Sent as an
  /// `x-www-form-urlencoded` body (`content`).
  Future<ApiResult<void>> addLeadNote(String id, String content) {
    return _api.post<void>(
      ApiConstants.leadNotes(id),
      options: Options(contentType: Headers.formUrlEncodedContentType),
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

  /// POST /leads/{id}/convert — converts a lead to an opportunity. Sent as an
  /// `x-www-form-urlencoded` body (`expected_value`, `probability`).
  Future<ApiResult<void>> convertLead(
    String id, {
    required double expectedValue,
    required int probability,
  }) {
    return _api.post<void>(
      ApiConstants.leadConvert(id),
      options: Options(contentType: Headers.formUrlEncodedContentType),
      data: {
        'expected_value': expectedValue,
        'probability': probability,
      },
      decoder: (json) {
        if (json is Map && json['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message:
                json['message'] as String? ?? 'Could not convert lead.',
            raw: json,
          );
        }
        return null;
      },
    );
  }

  /// POST /leads/{id}/tasks — adds a task to a lead. Sent as an
  /// `x-www-form-urlencoded` body. [dueAt] must already be formatted as
  /// `yyyy-MM-dd HH:mm:ss`; [priority] is `high` / `medium` / `low`.
  Future<ApiResult<void>> addLeadTask(
    String id, {
    required String title,
    String? dueAt,
    required String priority,
  }) {
    return _api.post<void>(
      ApiConstants.leadTasks(id),
      options: Options(contentType: Headers.formUrlEncodedContentType),
      data: {
        'title': title,
        if (dueAt != null && dueAt.isNotEmpty) 'due_at': dueAt,
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

  /// POST /leads/{id}/status — updates a lead's status. Sent as an
  /// `x-www-form-urlencoded` body (`status_id`).
  Future<ApiResult<void>> updateLeadStatus(String id, int statusId) {
    return _api.post<void>(
      ApiConstants.leadStatus(id),
      options: Options(contentType: Headers.formUrlEncodedContentType),
      data: {'status_id': statusId},
      decoder: (json) {
        if (json is Map && json['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message: json['message'] as String? ?? 'Could not update status.',
            raw: json,
          );
        }
        return null;
      },
    );
  }

  /// POST /leads/{id}/priority — updates a lead's priority/temperature
  /// (`hot` / `warm` / `cold`). Sent as an `x-www-form-urlencoded` body.
  Future<ApiResult<void>> updateLeadPriority(String id, String priority) {
    return _api.post<void>(
      ApiConstants.leadPriority(id),
      options: Options(contentType: Headers.formUrlEncodedContentType),
      data: {'priority': priority},
      decoder: (json) {
        if (json is Map && json['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message: json['message'] as String? ?? 'Could not update priority.',
            raw: json,
          );
        }
        return null;
      },
    );
  }
}

final leadsRepositoryProvider = Provider<LeadsRepository>((ref) {
  return LeadsRepository(ref.watch(apiClientProvider));
});
