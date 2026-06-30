import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/network_providers.dart';
import '../model/call_record.dart';

/// One captured call ready to be uploaded. Built from a device call-log entry,
/// optionally tagged with the lead/opportunity it belongs to when we know it
/// (in-app calls) — otherwise the backend matches it by phone number.
class CallUpload {
  final String phone;
  final AppCallType type;
  final int durationSeconds;
  final DateTime calledAt;
  final String? contactName;
  final String? leadId;
  final String? opportunityId;

  const CallUpload({
    required this.phone,
    required this.type,
    required this.durationSeconds,
    required this.calledAt,
    this.contactName,
    this.leadId,
    this.opportunityId,
  });

  /// `called_at` in the backend's `yyyy-MM-dd HH:mm:ss` format (same as the
  /// follow-up / task endpoints).
  static String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'call_type': type.apiValue,
        'duration': durationSeconds,
        'called_at': _fmt(calledAt),
        if (contactName != null && contactName!.isNotEmpty)
          'contact_name': contactName,
        if (leadId != null) 'lead_id': leadId,
        if (opportunityId != null) 'opportunity_id': opportunityId,
      };
}

/// Repository for the call-history feature, decoding through the shared
/// [ApiClient] like every other feature.
class CallsRepository {
  final ApiClient _api;

  CallsRepository(this._api);

  /// POST /calls — uploads a batch of captured calls. The backend de-dups /
  /// matches each call to a lead or opportunity by phone number (or uses the
  /// `lead_id` / `opportunity_id` we attach for in-app calls).
  ///
  /// Sent as a JSON body `{ "calls": [ ... ] }`.
  Future<ApiResult<void>> uploadCalls(List<CallUpload> calls) {
    return _api.post<void>(
      ApiConstants.calls,
      data: {'calls': calls.map((c) => c.toJson()).toList()},
      decoder: (json) {
        if (json is Map && json['success'] == false) {
          throw ApiException(
            type: ApiErrorType.validation,
            message: json['message'] as String? ?? 'Could not upload calls.',
            raw: json,
          );
        }
        return null;
      },
    );
  }

  /// GET /leads/{id}/calls — call history for a lead.
  Future<ApiResult<List<CallRecord>>> getLeadCalls(String leadId) {
    return _api.get<List<CallRecord>>(
      ApiConstants.leadCalls(leadId),
      decoder: _decodeList,
    );
  }

  /// GET /opportunities/{id}/calls — call history for an opportunity.
  Future<ApiResult<List<CallRecord>>> getOpportunityCalls(String oppId) {
    return _api.get<List<CallRecord>>(
      ApiConstants.opportunityCalls(oppId),
      decoder: _decodeList,
    );
  }

  /// Unwraps `{ success, data: [...] }` (or a bare list) into [CallRecord]s,
  /// newest first.
  static List<CallRecord> _decodeList(dynamic json) {
    final list = (json is Map ? json['data'] : json) as List? ?? const [];
    final calls = list
        .map((e) => CallRecord.fromJson((e as Map).cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => b.calledAt.compareTo(a.calledAt));
    return calls;
  }
}

final callsRepositoryProvider = Provider<CallsRepository>((ref) {
  return CallsRepository(ref.watch(apiClientProvider));
});
