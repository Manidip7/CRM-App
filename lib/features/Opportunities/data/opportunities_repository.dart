import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/network_providers.dart';
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

  /// GET /opportunities?page=N&per_page=15&search=... — one paginated page,
  /// optionally filtered by a server-side [search] query.
  Future<ApiResult<OpportunitiesPage>> getOpportunities({
    int page = 1,
    String? search,
  }) {
    return _api.get<OpportunitiesPage>(
      ApiConstants.opportunities,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
      },
      decoder: _decodePage,
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
