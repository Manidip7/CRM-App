import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/network_providers.dart';
import '../../Leads/model/lead_model.dart' show StatusOption;
import '../model/opportunity_detail_model.dart';
import '../model/opportunity_model.dart';

/// One page of opportunities plus the Laravel paginator metadata.
class OpportunitiesPage {
  final List<OpportunityModel> items;
  final int currentPage;
  final int lastPage;
  final int total;

  const OpportunitiesPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}

/// Repository for the Opportunities feature, decoding through [ApiClient].
class OpportunitiesRepository {
  final ApiClient _api;

  OpportunitiesRepository(this._api);

  static const int perPage = 15;

  /// GET /opportunities?page=N&per_page=15&... — one paginated page. Every
  /// filter is optional; anything left `null` is omitted from the query string
  /// entirely rather than sent empty, which the backend would read as a real
  /// filter.
  ///
  /// [category] is e.g. `active`, or `backlog` for overdue deals needing
  /// attention. [stage] is a raw stage id from `GET /opportunity-statuses`
  /// (e.g. `Proposal`).
  ///
  /// Dates work differently here than on the leads endpoint: [dateRange] is a
  /// *preset keyword* the server resolves itself (`last_month`), so it is sent
  /// on its own. Only a hand-picked range uses [fromDate] / [toDate]. Sending
  /// both would risk the server's idea of "last month" fighting ours.
  Future<ApiResult<OpportunitiesPage>> getOpportunities({
    int page = 1,
    String? search,
    String? category,
    List<String>? quickFilters,
    int? statusId,
    String? stage,
    int? assignedTo,
    String? dateRange,
    String? fromDate,
    String? toDate,
  }) {
    return _api.get<OpportunitiesPage>(
      ApiConstants.opportunities,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
        if (quickFilters != null && quickFilters.isNotEmpty)
          'quick_filter': quickFilters,
        if (statusId != null) 'status_id': statusId,
        if (stage != null && stage.isNotEmpty) 'stage': stage,
        if (assignedTo != null) 'assigned_to': assignedTo,
        if (dateRange != null && dateRange.isNotEmpty) 'date_range': dateRange,
        if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
      },
      decoder: _decodePage,
    );
  }

  /// GET /statuses, narrowed to the ones that apply to opportunities — the
  /// options behind the advanced filter's `status_id` dropdown.
  ///
  /// The endpoint returns lead *and* opportunity statuses in one list, tagged
  /// by `type`. If nothing carries the opportunity tag (a backend that labels
  /// them differently, or doesn't split them at all) the full list is returned
  /// rather than an inexplicably empty dropdown.
  Future<ApiResult<List<StatusOption>>> getOpportunityStatuses() {
    return _api.get<List<StatusOption>>(
      ApiConstants.statuses,
      decoder: (json) {
        final list = (json is Map ? json['data'] : json) as List? ?? const [];
        final all = list
            .whereType<Map>()
            .map((e) => StatusOption.fromJson(e.cast<String, dynamic>()))
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final scoped =
            all.where((s) => s.type.toLowerCase() == 'opportunity').toList();
        return scoped.isEmpty ? all : scoped;
      },
    );
  }

  /// GET /opportunities/{id} → the full detail bundle (record fields plus its
  /// nested assignees, items, activities, tasks, quotations and notes).
  Future<ApiResult<OpportunityDetailBundle>> getOpportunityDetail(String id) {
    return _api.get<OpportunityDetailBundle>(
      ApiConstants.opportunityDetail(id),
      decoder: (json) {
        final map = json is Map && json['data'] is Map ? json['data'] : json;
        if (map is! Map) {
          throw ApiException.unexpected(
              'Opportunity detail response had no "data" object.');
        }
        return OpportunityDetailBundle.fromJson(map.cast<String, dynamic>());
      },
    );
  }

  /// GET /opportunity-stages — the selectable pipeline stages for the detail
  /// header dropdown. Response shape: `{ success, data: [ { id, name } ] }`.
  Future<ApiResult<List<StageOption>>> getStages() {
    return _api.get<List<StageOption>>(
      ApiConstants.opportunityStages,
      decoder: (json) {
        final list = (json is Map ? json['data'] : json) as List? ?? const [];
        return list
            .map((e) => StageOption.fromJson((e as Map).cast<String, dynamic>()))
            .toList(growable: false);
      },
    );
  }

  /// GET /products — the product catalog for the Add Product picker.
  /// Response shape: `{ success, data: [ { id, name, selling_price, ... } ] }`.
  Future<ApiResult<List<ProductModel>>> getProducts() {
    return _api.get<List<ProductModel>>(
      ApiConstants.products,
      decoder: (json) {
        final list = (json is Map ? json['data'] : json) as List? ?? const [];
        return list
            .map((e) =>
                ProductModel.fromJson((e as Map).cast<String, dynamic>()))
            .toList(growable: false);
      },
    );
  }

  /// POST /opportunities/{id}/stage — updates an opportunity's pipeline stage.
  /// Sent as an `x-www-form-urlencoded` body (`stage`), where [stage] is the raw
  /// stage id from `GET /opportunity-statuses` (e.g. `"Prospecting"`).
  Future<ApiResult<void>> updateStage(String id, String stage) {
    return _api.post<void>(
      ApiConstants.opportunityStage(id),
      options: Options(contentType: Headers.formUrlEncodedContentType),
      data: {'stage': stage},
      decoder: (json) {
        if (json is Map && json['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message: json['message'] as String? ?? 'Could not update stage.',
            raw: json,
          );
        }
        return null;
      },
    );
  }

  /// POST /opportunities/{id}/followup — schedules the next follow-up for an
  /// opportunity. Sent as an `x-www-form-urlencoded` body. [nextFollowUpAt] must
  /// already be formatted as `yyyy-MM-dd HH:mm:ss`.
  Future<ApiResult<void>> scheduleFollowUp(
    String id, {
    int? currentUpdateId,
    int? nextActionId,
    String? followupRemarks,
    required String nextFollowUpAt,
    required int interestScore,
  }) {
    return _api.post<void>(
      ApiConstants.opportunityFollowup(id),
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

  /// Unwraps `{ success, data: { current_page, data: [...], last_page, total } }`.
  static OpportunitiesPage _decodePage(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();

    if (map['success'] == false) {
      throw ApiException(
        type: ApiErrorType.validation,
        message:
            map['message'] as String? ?? 'Could not load opportunities.',
        raw: json,
      );
    }

    final paginator = (map['data'] as Map?)?.cast<String, dynamic>();
    if (paginator == null) {
      throw ApiException.unexpected(
          'Opportunities response had no "data" object.');
    }

    final items = (paginator['data'] as List? ?? const [])
        .map((e) =>
            OpportunityModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);

    return OpportunitiesPage(
      items: items,
      currentPage: (paginator['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (paginator['last_page'] as num?)?.toInt() ?? 1,
      total: (paginator['total'] as num?)?.toInt() ?? items.length,
    );
  }
}

final opportunitiesRepositoryProvider = Provider<OpportunitiesRepository>((ref) {
  return OpportunitiesRepository(ref.watch(apiClientProvider));
});
