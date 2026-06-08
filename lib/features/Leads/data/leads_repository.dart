import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/network_providers.dart';
import '../model/lead_model.dart';

/// Example repository for the Leads feature. Demonstrates decoding a JSON
/// list and a single object through the shared [ApiClient].
class LeadsRepository {
  final ApiClient _api;

  LeadsRepository(this._api);

  /// GET /leads — supports optional search/status query params.
  Future<ApiResult<List<LeadModel>>> getLeads({
    String? search,
    String? status,
  }) {
    return _api.get<List<LeadModel>>(
      ApiConstants.leads,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'status': ?status,
      },
      // Handles both `[ ... ]` and `{ "data": [ ... ] }` response shapes.
      decoder: (json) {
        final list = json is Map ? json['data'] as List : json as List;
        return list
            .map((e) => LeadModel.fromJson(e as Map<String, dynamic>))
            .toList();
      },
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
