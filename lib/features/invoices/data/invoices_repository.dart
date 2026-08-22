import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/network_providers.dart';
import '../model/invoice_model.dart';

/// One page of invoices: the Laravel paginator plus the `summary` block that
/// `GET /invoices` returns next to it.
class InvoicesPage {
  final List<InvoiceModel> items;
  final int currentPage;
  final int lastPage;
  final int total;

  /// Server-wide totals. Null when the response carried no `summary` object —
  /// the provider then falls back to totals computed from the loaded rows.
  final InvoiceSummary? summary;

  const InvoicesPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    this.summary,
  });

  bool get hasMore => currentPage < lastPage;
}

/// The raw bytes of a downloaded invoice PDF plus a suggested file name.
class InvoiceDownload {
  final List<int> bytes;
  final String filename;

  const InvoiceDownload({required this.bytes, required this.filename});
}

/// One line of a [InvoiceRequest] body.
class InvoiceRequestItem {
  final String name;
  final String? sku;
  final String? unit;
  final double qty;
  final double unitPrice;
  final double taxPercent;
  final double discountPercent;

  const InvoiceRequestItem({
    required this.name,
    required this.qty,
    required this.unitPrice,
    this.sku,
    this.unit,
    this.taxPercent = 0,
    this.discountPercent = 0,
  });

  /// `sku` / `unit` are omitted when unknown — `GET /items` doesn't send them,
  /// so most picks have neither.
  Map<String, dynamic> toJson() => {
        'item_name': name,
        if (sku != null && sku!.isNotEmpty) 'sku': sku,
        if (unit != null && unit!.isNotEmpty) 'unit': unit,
        'qty': qty,
        'unit_price': unitPrice,
        'tax_percent': taxPercent,
        'discount_percent': discountPercent,
      };
}

/// Body of `POST /invoices` and `PUT /invoices/{id}` — both take the same
/// shape, so one class serves create and update. The invoice number is **not**
/// sent; the backend owns it (e.g. `P/26-27/0001`).
class InvoiceRequest {
  final int customerId;
  final String status;
  final DateTime dueDate;
  final String notes;
  final double overallDiscount;
  final List<InvoiceRequestItem> items;

  const InvoiceRequest({
    required this.customerId,
    required this.status,
    required this.dueDate,
    required this.items,
    this.notes = '',
    this.overallDiscount = 0,
  });

  Map<String, dynamic> toJson() => {
        'customer_id': customerId,
        'status': status,
        'due_date': _apiDate(dueDate),
        'notes': notes,
        'overall_discount': overallDiscount,
        'items': items.map((i) => i.toJson()).toList(),
      };

  /// The `yyyy-MM-dd` the API expects — the time part is dropped.
  static String _apiDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Repository for the Invoices feature (`GET /invoices`).
class InvoicesRepository {
  final ApiClient _api;

  InvoicesRepository(this._api);

  /// GET /invoices?page=N — one paginated page of invoices with its summary.
  Future<ApiResult<InvoicesPage>> getInvoices({int page = 1, String? search}) {
    return _api.get<InvoicesPage>(
      ApiConstants.invoices,
      queryParameters: {
        'page': page,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
      decoder: _decodePage,
    );
  }

  /// POST /invoices — creates an invoice. Returns the created row when the
  /// reply carries one, else null (the list is refreshed either way).
  Future<ApiResult<InvoiceModel?>> createInvoice(InvoiceRequest request) {
    return _api.post<InvoiceModel?>(
      ApiConstants.invoices,
      data: request.toJson(),
      decoder: (json) => _decodeSaved(json, 'Could not create invoice.'),
    );
  }

  /// PUT /invoices/{id} — updates an invoice with the same body as create.
  Future<ApiResult<InvoiceModel?>> updateInvoice(
      String id, InvoiceRequest request) {
    return _api.put<InvoiceModel?>(
      ApiConstants.invoice(id),
      data: request.toJson(),
      decoder: (json) => _decodeSaved(json, 'Could not update invoice.'),
    );
  }

  /// Unwraps the `{ success, data: { ...invoice } }` reply shared by create and
  /// update. Returns null when the reply carries no invoice object.
  static InvoiceModel? _decodeSaved(dynamic json, String fallbackMessage) {
    final map = json is Map ? json.cast<String, dynamic>() : null;
    if (map != null && map['success'] == false) {
      throw ApiException(
        type: ApiErrorType.validation,
        message: map['message'] as String? ?? fallbackMessage,
        raw: json,
      );
    }
    final data = (map?['data'] as Map?)?.cast<String, dynamic>();
    return data == null ? null : InvoiceModel.fromJson(data);
  }

  /// GET /invoices/{id}/download — fetches the invoice PDF as bytes (the auth
  /// token is attached by the Dio interceptor). The file name comes from the
  /// `Content-Disposition` header when present, else `invoice-{id}.pdf`.
  Future<ApiResult<InvoiceDownload>> downloadInvoice(String id) async {
    try {
      final response = await _api.dio.get<List<int>>(
        ApiConstants.invoiceDownload(id),
        options: Options(responseType: ResponseType.bytes),
      );
      return ApiResult.success(InvoiceDownload(
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
  /// back to `invoice-{id}.pdf`.
  static String _filenameFrom(Headers headers, String id) {
    final disposition = headers.value('content-disposition');
    if (disposition != null) {
      final match =
          RegExp(r'filename\*?=(?:UTF-8'')?"?([^";]+)"?', caseSensitive: false)
              .firstMatch(disposition);
      final name = match?.group(1)?.trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return 'invoice-$id.pdf';
  }

  /// GET /invoices/{id}/payments — the payment ledger plus the server's own
  /// total / paid / due figures and current status.
  Future<ApiResult<InvoicePaymentHistory>> getPayments(String invoiceId) {
    return _api.get<InvoicePaymentHistory>(
      ApiConstants.invoicePayments(invoiceId),
      decoder: (json) {
        final map = (json as Map).cast<String, dynamic>();
        if (map['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message: map['message'] as String? ?? 'Could not load payments.',
            raw: json,
          );
        }
        final data = (map['data'] as Map?)?.cast<String, dynamic>();
        if (data == null) {
          throw ApiException.unexpected('Payments response had no "data".');
        }
        return InvoicePaymentHistory.fromJson(data);
      },
    );
  }

  /// POST /invoices/{id}/payments — records a payment against an invoice.
  ///
  /// `payment_date` carries the time as well (`yyyy-MM-dd HH:mm:ss`), so the
  /// history can show when each payment landed.
  Future<ApiResult<void>> addPayment(
    String invoiceId,
    double amount, {
    DateTime? paidAt,
    String notes = '',
  }) {
    return _api.post<void>(
      ApiConstants.invoicePayments(invoiceId),
      data: {
        'amount': amount,
        'payment_date': _apiDateTime(paidAt ?? DateTime.now()),
        'notes': notes,
      },
      decoder: (json) {
        if (json is Map && json['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message: json['message'] as String? ?? 'Could not record payment.',
            raw: json,
          );
        }
      },
    );
  }

  /// DELETE /invoices/{id} — removes an invoice (soft-deleted server side).
  Future<ApiResult<void>> deleteInvoice(String id) {
    return _api.delete<void>(
      ApiConstants.invoice(id),
      decoder: (json) {
        if (json is Map && json['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message: json['message'] as String? ?? 'Could not delete invoice.',
            raw: json,
          );
        }
      },
    );
  }

  /// Unwraps `{ success, data: { current_page, data: [...] }, summary: {...} }`.
  static InvoicesPage _decodePage(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();
    if (map['success'] == false) {
      throw ApiException(
        type: ApiErrorType.validation,
        message: map['message'] as String? ?? 'Could not load invoices.',
        raw: json,
      );
    }
    final paginator = (map['data'] as Map?)?.cast<String, dynamic>();
    if (paginator == null) {
      throw ApiException.unexpected('Invoices response had no "data" object.');
    }
    final items = (paginator['data'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => InvoiceModel.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
    final summary = (map['summary'] as Map?)?.cast<String, dynamic>();

    return InvoicesPage(
      items: items,
      currentPage: (paginator['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (paginator['last_page'] as num?)?.toInt() ?? 1,
      total: (paginator['total'] as num?)?.toInt() ?? items.length,
      summary: summary == null ? null : InvoiceSummary.fromJson(summary),
    );
  }
}

/// `yyyy-MM-dd HH:mm:ss` — the timestamp format `payment_date` expects.
String _apiDateTime(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)} '
      '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
}

final invoicesRepositoryProvider = Provider<InvoicesRepository>((ref) {
  return InvoicesRepository(ref.watch(apiClientProvider));
});
