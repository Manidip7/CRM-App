import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/network_providers.dart';
import '../model/dashboard_overview_model.dart';

/// Talks to the dashboard endpoint through [ApiClient]. The bearer token is
/// attached automatically by the auth interceptor, so callers only need to be
/// logged in.
class DashboardRepository {
  final ApiClient _api;

  DashboardRepository(this._api);

  /// GET /dashboard/overview → everything the Overview tab renders, in one
  /// call.
  Future<ApiResult<DashboardOverview>> getOverview() {
    return _api.get<DashboardOverview>(
      ApiConstants.dashboardOverview,
      decoder: _decodeOverview,
    );
  }

  /// Unwraps the envelope and builds a [DashboardOverview].
  ///
  /// Careful: this endpoint reports failure as `{"status": "error"}` — a
  /// *string* — where the rest of the API uses a `success` boolean. Both are
  /// checked so the decoder keeps working if the backend ever aligns them.
  static DashboardOverview _decodeOverview(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();

    final status = map['status'];
    final failed = map['success'] == false ||
        (status is String && status.toLowerCase() != 'success');
    if (failed) {
      throw ApiException(
        type: ApiErrorType.validation,
        message: map['message'] as String? ?? 'Could not load the dashboard.',
        raw: json,
      );
    }

    final data = (map['data'] as Map?)?.cast<String, dynamic>();
    if (data == null) {
      throw ApiException.unexpected('Dashboard response had no "data" object.');
    }
    return DashboardOverview.fromJson(data);
  }
}

/// DI for the repository.
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});
