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

  /// GET /leads?page=N&per_page=10 — supports optional search/status query
  /// params and returns one paginated [LeadsPage].
  Future<ApiResult<LeadsPage>> getLeads({
    int page = 1,
    String? search,
    String? status,
  }) {
    return _api.get<LeadsPage>(
      ApiConstants.leads,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
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

  /// POST /leads
  Future<ApiResult<LeadModel>> createLead(LeadModel lead) {
    return _api.post<LeadModel>(
      ApiConstants.leads,
      data: lead.toJson(),
      decoder: (json) {
        final map = json is Map && json['data'] is Map ? json['data'] : json;
        return LeadModel.fromJson(map as Map<String, dynamic>);
      },
    );
  }
}

final leadsRepositoryProvider = Provider<LeadsRepository>((ref) {
  return LeadsRepository(ref.watch(apiClientProvider));
});
