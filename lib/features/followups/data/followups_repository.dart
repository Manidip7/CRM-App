import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/network_providers.dart';
import '../model/next_followup_model.dart';

/// Repository for the Next Follow-ups feature (`GET /next-followups`).
class FollowUpsRepository {
  final ApiClient _api;

  FollowUpsRepository(this._api);

  static const int perPage = 15;

  /// GET /next-followups?page=N[&date_from=YYYY-MM-DD&date_to=YYYY-MM-DD].
  /// One paginated page of upcoming follow-ups, optionally bounded by a date
  /// range (both bounds are sent as `YYYY-MM-DD`).
  Future<ApiResult<NextFollowUpsPage>> getNextFollowups({
    int page = 1,
    String? dateFrom,
    String? dateTo,
  }) {
    return _api.get<NextFollowUpsPage>(
      ApiConstants.nextFollowups,
      queryParameters: {
        'page': page,
        if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
      },
      decoder: _decodePage,
    );
  }

  /// Unwraps `{ success, data: { current_page, data: [...], last_page, total } }`.
  static NextFollowUpsPage _decodePage(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();
    if (map['success'] == false) {
      throw ApiException(
        type: ApiErrorType.validation,
        message: map['message'] as String? ?? 'Could not load follow-ups.',
        raw: json,
      );
    }
    final paginator = (map['data'] as Map?)?.cast<String, dynamic>();
    if (paginator == null) {
      throw ApiException.unexpected('Follow-ups response had no "data" object.');
    }
    final items = (paginator['data'] as List? ?? const [])
        .map((e) => NextFollowUp.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
    return NextFollowUpsPage(
      items: items,
      currentPage: (paginator['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (paginator['last_page'] as num?)?.toInt() ?? 1,
      total: (paginator['total'] as num?)?.toInt() ?? items.length,
    );
  }
}

final followUpsRepositoryProvider = Provider<FollowUpsRepository>((ref) {
  return FollowUpsRepository(ref.watch(apiClientProvider));
});
