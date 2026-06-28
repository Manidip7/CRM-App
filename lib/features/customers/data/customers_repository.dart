import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/network_providers.dart';
import '../model/customer_list_item.dart';

/// Repository for the Customers feature, decoding through [ApiClient].
class CustomersRepository {
  final ApiClient _api;

  CustomersRepository(this._api);

  static const int perPage = 15;

  /// GET /customers?page=N&per_page=15[&search=...] — one paginated page.
  /// When [search] is non-empty the server filters by it.
  Future<ApiResult<CustomersPage>> getCustomers({int page = 1, String? search}) {
    final q = search?.trim() ?? '';
    return _api.get<CustomersPage>(
      ApiConstants.customers,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (q.isNotEmpty) 'search': q,
      },
      decoder: _decodeCustomersPage,
    );
  }

  /// Unwraps `{ success, data: { current_page, data: [...], last_page, total } }`.
  static CustomersPage _decodeCustomersPage(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();
    if (map['success'] == false) {
      throw ApiException(
        type: ApiErrorType.validation,
        message: map['message'] as String? ?? 'Could not load customers.',
        raw: json,
      );
    }
    final paginator = (map['data'] as Map?)?.cast<String, dynamic>();
    if (paginator == null) {
      throw ApiException.unexpected('Customers response had no "data" object.');
    }
    final items = (paginator['data'] as List? ?? const [])
        .map((e) => CustomerListItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
    return CustomersPage(
      items: items,
      currentPage: (paginator['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (paginator['last_page'] as num?)?.toInt() ?? 1,
      total: (paginator['total'] as num?)?.toInt() ?? items.length,
    );
  }
}

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepository(ref.watch(apiClientProvider));
});
