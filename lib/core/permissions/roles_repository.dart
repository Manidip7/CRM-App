import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/api_constants.dart';
import '../network/api_exception.dart';
import '../network/api_result.dart';
import '../network/network_providers.dart';
import 'role_model.dart';

/// Talks to the roles/permissions endpoint through [ApiClient].
///
/// The bearer token is attached automatically by the auth interceptor, so
/// callers only need to be logged in.
class RolesRepository {
  final ApiClient _api;

  RolesRepository(this._api);

  /// GET /api/roles → every role defined on the backend, each with its
  /// `permissions_map`.
  ///
  /// The endpoint sits outside the `/api/v1` prefix the rest of the app uses,
  /// so [ApiConstants.rolesUrl] is an absolute URL — Dio uses it as-is instead
  /// of appending it to `baseUrl`.
  Future<ApiResult<List<RoleModel>>> getRoles() {
    return _api.get<List<RoleModel>>(
      ApiConstants.rolesUrl,
      decoder: _decodeRoles,
    );
  }

  /// Unwraps the standard `{ success, message, data: [...] }` envelope.
  static List<RoleModel> _decodeRoles(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();

    if (map['success'] == false) {
      throw ApiException(
        type: ApiErrorType.validation,
        message: map['message'] as String? ?? 'Could not load roles.',
        raw: json,
      );
    }

    final data = map['data'];
    if (data is! List) {
      throw ApiException.unexpected('Roles response had no "data" array.');
    }

    return data
        .whereType<Map>()
        .map((e) => RoleModel.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }
}

/// DI for the repository.
final rolesRepositoryProvider = Provider<RolesRepository>((ref) {
  return RolesRepository(ref.watch(apiClientProvider));
});
