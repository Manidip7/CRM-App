import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/network_providers.dart';
import '../model/quotation_model.dart';

/// The raw bytes of a downloaded quotation PDF plus a suggested file name.
class QuotationDownload {
  final List<int> bytes;
  final String filename;

  const QuotationDownload({required this.bytes, required this.filename});
}

/// One page of quotations plus the Laravel paginator metadata.
class QuotationsPage {
  final List<QuotationModel> items;
  final int currentPage;
  final int lastPage;
  final int total;

  const QuotationsPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}

/// One line item in a [QuotationRequest].
class QuotationRequestItem {
  final String name;
  final String hsn;
  final int quantity;
  final double unitPrice;

  const QuotationRequestItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.hsn = '',
  });

  Map<String, dynamic> toJson() => {
        'item_name': name,
        if (hsn.isNotEmpty) 'hsn_no': hsn,
        'quantity': quantity,
        'unit_price': unitPrice,
      };
}

/// Body of `POST /quotations` and `PUT /quotations/{id}` — both take the same
/// shape, so one class serves create and update.
class QuotationRequest {
  final int customerId;
  final DateTime date;
  final DateTime validUntil;
  final String companyName;
  final String? companyAddress;
  final String notes;
  final double taxRate;
  final List<QuotationRequestItem> items;

  const QuotationRequest({
    required this.customerId,
    required this.date,
    required this.validUntil,
    required this.companyName,
    required this.taxRate,
    required this.items,
    this.companyAddress,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'customer_id': customerId,
        'date': _apiDate(date),
        'valid_until': _apiDate(validUntil),
        'company_name': companyName,
        if (companyAddress != null && companyAddress!.isNotEmpty)
          'company_address': companyAddress,
        'notes': notes,
        'tax_rate': taxRate,
        'items': items.map((i) => i.toJson()).toList(),
      };

  /// The `yyyy-MM-dd` the API expects — the time part is dropped.
  static String _apiDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Repository for the Quotations feature (`GET /quotations`).
class QuotationsRepository {
  final ApiClient _api;

  QuotationsRepository(this._api);

  /// GET /quotations?page=N — one paginated page of quotations.
  Future<ApiResult<QuotationsPage>> getQuotations({int page = 1}) {
    return _api.get<QuotationsPage>(
      ApiConstants.quotations,
      queryParameters: {'page': page},
      decoder: _decodePage,
    );
  }

  /// POST /quotations — creates a quotation. Returns the created row when the
  /// response carries one, else null (the list is refreshed either way).
  Future<ApiResult<QuotationModel?>> createQuotation(QuotationRequest request) {
    return _api.post<QuotationModel?>(
      ApiConstants.quotations,
      data: request.toJson(),
      decoder: (json) => _decodeSaved(json, 'Could not create quotation.'),
    );
  }

  /// PUT /quotations/{id} — updates a quotation with the same body as create.
  Future<ApiResult<QuotationModel?>> updateQuotation(
      String id, QuotationRequest request) {
    return _api.put<QuotationModel?>(
      ApiConstants.quotation(id),
      data: request.toJson(),
      decoder: (json) => _decodeSaved(json, 'Could not update quotation.'),
    );
  }

  /// Unwraps the `{ success, data: { ...quotation } }` reply shared by create
  /// and update. Returns null when the reply carries no quotation object.
  static QuotationModel? _decodeSaved(dynamic json, String fallbackMessage) {
    final map = json is Map ? json.cast<String, dynamic>() : null;
    if (map != null && map['success'] == false) {
      throw ApiException(
        type: ApiErrorType.validation,
        message: map['message'] as String? ?? fallbackMessage,
        raw: json,
      );
    }
    final data = (map?['data'] as Map?)?.cast<String, dynamic>();
    return data == null ? null : QuotationModel.fromJson(data);
  }

  /// GET /quotations/{id}/download — fetches the quotation PDF as bytes (the
  /// auth token is attached by the Dio interceptor). The file name is taken from
  /// the `Content-Disposition` header when present, else `quotation-{id}.pdf`.
  Future<ApiResult<QuotationDownload>> downloadQuotation(String id) async {
    try {
      final response = await _api.dio.get<List<int>>(
        ApiConstants.quotationDownload(id),
        options: Options(responseType: ResponseType.bytes),
      );
      return ApiResult.success(QuotationDownload(
        bytes: response.data ?? const [],
        filename: _filenameFrom(response.headers, id),
      ));
    } on DioException catch (e) {
      return ApiResult.failure(ApiException.fromDio(e));
    } catch (e) {
      return ApiResult.failure(ApiException.unexpected(e));
    }
  }

  /// Pulls `filename="..."` out of the `Content-Disposition` header, falling
  /// back to `quotation-{id}.pdf`.
  static String _filenameFrom(Headers headers, String id) {
    final disposition = headers.value('content-disposition');
    if (disposition != null) {
      final match =
          RegExp(r'filename\*?=(?:UTF-8'')?"?([^";]+)"?', caseSensitive: false)
              .firstMatch(disposition);
      final name = match?.group(1)?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return 'quotation-$id.pdf';
  }

  /// Unwraps `{ success, data: { current_page, data: [...], last_page, total } }`.
  static QuotationsPage _decodePage(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();
    if (map['success'] == false) {
      throw ApiException(
        type: ApiErrorType.validation,
        message: map['message'] as String? ?? 'Could not load quotations.',
        raw: json,
      );
    }
    final paginator = (map['data'] as Map?)?.cast<String, dynamic>();
    if (paginator == null) {
      throw ApiException.unexpected('Quotations response had no "data" object.');
    }
    final items = (paginator['data'] as List? ?? const [])
        .map((e) => QuotationModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
    return QuotationsPage(
      items: items,
      currentPage: (paginator['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (paginator['last_page'] as num?)?.toInt() ?? 1,
      total: (paginator['total'] as num?)?.toInt() ?? items.length,
    );
  }
}

final quotationsRepositoryProvider = Provider<QuotationsRepository>((ref) {
  return QuotationsRepository(ref.watch(apiClientProvider));
});
