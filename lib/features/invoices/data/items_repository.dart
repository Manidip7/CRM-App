import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/network_providers.dart';
import '../model/catalog_item.dart';

/// One page of catalogue items. `GET /items` currently answers with a flat
/// `{ success, data: [...] }` list — reported here as a single page — but the
/// decoder also accepts a Laravel paginator, so the dropdown keeps working if
/// the endpoint starts paging.
class ItemsPage {
  final List<CatalogItem> items;
  final int currentPage;
  final int lastPage;

  const ItemsPage({
    required this.items,
    this.currentPage = 1,
    this.lastPage = 1,
  });

  bool get hasMore => currentPage < lastPage;
}

/// Repository for the item catalogue (`GET /items`).
class ItemsRepository {
  final ApiClient _api;

  ItemsRepository(this._api);

  /// Pages beyond this are not fetched, so a huge catalogue can't stall the
  /// New Invoice form. At [_perPage] each that is 1,000 items.
  static const int _maxPages = 10;
  static const int _perPage = 100;

  /// GET /items?page=N — one page of the catalogue.
  Future<ApiResult<ItemsPage>> getItems({int page = 1, String? search}) {
    return _api.get<ItemsPage>(
      ApiConstants.items,
      queryParameters: {
        'page': page,
        'per_page': _perPage,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
      decoder: _decodePage,
    );
  }

  /// Loads the whole catalogue by walking the paginator (capped at [_maxPages]),
  /// which is what the line-item dropdown needs — it shows every item at once.
  /// A failure on a later page keeps the items already gathered.
  Future<ApiResult<List<CatalogItem>>> getAllItems() async {
    final first = await getItems(page: 1);
    if (first is Failure<ItemsPage>) {
      return ApiResult.failure(first.error);
    }

    final page = (first as Success<ItemsPage>).data;
    final all = [...page.items];
    var current = page.currentPage;
    final last = page.lastPage < _maxPages ? page.lastPage : _maxPages;

    while (current < last) {
      current++;
      final next = await getItems(page: current);
      final data = next.dataOrNull;
      if (data == null) break; // keep what we have rather than failing outright
      all.addAll(data.items);
    }
    return ApiResult.success(all);
  }

  /// Accepts `{ success, data: [...] }`, `{ success, data: { data: [...] } }`
  /// and a bare `[...]`, so the dropdown survives either response shape.
  static ItemsPage _decodePage(dynamic json) {
    if (json is List) {
      return ItemsPage(items: _parseList(json));
    }

    final map = (json as Map).cast<String, dynamic>();
    if (map['success'] == false) {
      throw ApiException(
        type: ApiErrorType.validation,
        message: map['message'] as String? ?? 'Could not load items.',
        raw: json,
      );
    }

    final data = map['data'];
    if (data is List) return ItemsPage(items: _parseList(data));

    final paginator = (data as Map?)?.cast<String, dynamic>();
    if (paginator == null) {
      throw ApiException.unexpected('Items response had no "data" object.');
    }
    return ItemsPage(
      items: _parseList(paginator['data'] as List? ?? const []),
      currentPage: (paginator['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (paginator['last_page'] as num?)?.toInt() ?? 1,
    );
  }

  static List<CatalogItem> _parseList(List raw) => raw
      .whereType<Map>()
      .map((e) => CatalogItem.fromJson(e.cast<String, dynamic>()))
      .toList(growable: false);
}

final itemsRepositoryProvider = Provider<ItemsRepository>((ref) {
  return ItemsRepository(ref.watch(apiClientProvider));
});
