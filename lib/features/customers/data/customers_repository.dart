import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/network_providers.dart';
import '../model/customer_list_item.dart';
import '../model/customer_model.dart';

/// Repository for the Customers feature, decoding through [ApiClient].
class CustomersRepository {
  final ApiClient _api;

  CustomersRepository(this._api);

  static const int perPage = 15;

  /// GET /customers?page=N&per_page=15[&search=...] — one paginated page.
  /// When [search] is non-empty the server filters by it. [perPage] overrides
  /// the default page size (used by the picker to pull a large single page).
  Future<ApiResult<CustomersPage>> getCustomers({
    int page = 1,
    String? search,
    int? perPage,
  }) {
    final q = search?.trim() ?? '';
    return _api.get<CustomersPage>(
      ApiConstants.customers,
      queryParameters: {
        'page': page,
        'per_page': perPage ?? CustomersRepository.perPage,
        if (q.isNotEmpty) 'search': q,
      },
      decoder: _decodeCustomersPage,
    );
  }

  /// POST /customers — creates a customer. Sends a raw JSON body; only
  /// non-empty optional fields are included.
  Future<ApiResult<void>> createCustomer({
    required String name,
    String? email,
    String? phone,
    String? address,
  }) {
    return _api.post<void>(
      ApiConstants.customers,
      options: Options(contentType: Headers.jsonContentType),
      data: {
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
      },
      decoder: (json) {
        if (json is Map && json['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message: json['message'] as String? ?? 'Could not create customer.',
            raw: json,
          );
        }
        return null;
      },
    );
  }

  /// PUT /customers/{id} — updates a customer's core fields. Sends a raw JSON
  /// body; only non-empty optional fields are included.
  Future<ApiResult<void>> updateCustomer(
    String id, {
    required String name,
    String? email,
    String? phone,
    String? address,
  }) {
    return _api.put<void>(
      ApiConstants.customerDetail(id),
      options: Options(contentType: Headers.jsonContentType),
      data: {
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
      },
      decoder: (json) {
        if (json is Map && json['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message: json['message'] as String? ?? 'Could not update customer.',
            raw: json,
          );
        }
        return null;
      },
    );
  }

  /// GET /customers/{id} — the full customer profile for the detail screen.
  Future<ApiResult<CustomerModel>> getCustomer(String id) {
    return _api.get<CustomerModel>(
      ApiConstants.customerDetail(id),
      decoder: (json) {
        final map = (json as Map).cast<String, dynamic>();
        if (map['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message: map['message'] as String? ?? 'Could not load customer.',
            raw: json,
          );
        }
        // The customer object lives under `data`; some endpoints return it flat.
        final data = (map['data'] as Map?)?.cast<String, dynamic>() ?? map;
        return CustomerModel.fromDetailJson(data);
      },
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
