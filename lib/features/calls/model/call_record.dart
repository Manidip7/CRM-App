/// The kind of a logged call. Mirrors the call types Android exposes; the app
/// keeps its own enum so the rest of the code doesn't depend on the `call_log`
/// plugin's enum directly.
enum AppCallType {
  incoming,
  outgoing,
  missed,
  rejected,
  blocked,
  unknown;

  /// Value sent to / received from the backend (stable, lowercase).
  String get apiValue => name;

  /// Direction label for the call-logs endpoint, which expects `inbound` /
  /// `outbound` rather than the granular call type. Outgoing is the only
  /// outbound case; everything else (incoming/missed/rejected/blocked) is
  /// inbound.
  String get directionApiValue =>
      this == AppCallType.outgoing ? 'outbound' : 'inbound';

  /// Human label for the UI.
  String get label => switch (this) {
        AppCallType.incoming => 'Incoming',
        AppCallType.outgoing => 'Outgoing',
        AppCallType.missed => 'Missed',
        AppCallType.rejected => 'Rejected',
        AppCallType.blocked => 'Blocked',
        AppCallType.unknown => 'Call',
      };

  /// Parses the backend string back into an [AppCallType].
  static AppCallType fromApi(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'incoming':
        return AppCallType.incoming;
      case 'outgoing':
        return AppCallType.outgoing;
      case 'missed':
        return AppCallType.missed;
      case 'rejected':
        return AppCallType.rejected;
      case 'blocked':
        return AppCallType.blocked;
      default:
        return AppCallType.unknown;
    }
  }
}

/// A single call as stored on the backend and shown in the CRM's call history
/// (`GET /leads/{id}/calls` and `GET /opportunities/{id}/calls`).
class CallRecord {
  final int id;
  final String phone;

  /// Contact name cached on the device / resolved by the backend, if any.
  final String? contactName;
  final AppCallType type;

  /// Call duration in seconds (0 for missed / not-connected calls).
  final int durationSeconds;
  final DateTime calledAt;

  /// Name of the CRM user who made/received the call, if the backend attributes
  /// it to a user.
  final String? userName;

  const CallRecord({
    required this.id,
    required this.phone,
    this.contactName,
    required this.type,
    required this.durationSeconds,
    required this.calledAt,
    this.userName,
  });

  factory CallRecord.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return CallRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String? ?? '',
      contactName: json['contact_name'] as String? ?? json['name'] as String?,
      type: AppCallType.fromApi(json['call_type'] as String?),
      durationSeconds: (json['duration'] as num?)?.toInt() ??
          (json['duration_seconds'] as num?)?.toInt() ??
          0,
      calledAt: DateTime.tryParse(json['called_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(
            (json['called_at_ms'] as num?)?.toInt() ?? 0,
          ),
      userName: user is Map ? user['name'] as String? : json['user_name'] as String?,
    );
  }

  /// Pretty `m:ss` / `h:mm:ss` duration, or `—` when there was no connection.
  String get durationLabel {
    if (durationSeconds <= 0) return '—';
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }
}

/// A call recorded against a lead, from the `call_logs` array of
/// `GET /leads/{id}`. Unlike [CallRecord] (device-captured history from
/// `/leads/{id}/calls`), these are the CRM's own logged calls — created by the
/// manual Log-Call form or the resume-sync (`POST /leads/{id}/call-logs`) — so
/// they carry an outcome / description and show regardless of device
/// call-log permission.
class LeadCallLog {
  final int id;
  final String? phone;
  final String? contactName;

  /// Direction as the backend stores it: `inbound` / `outbound` maps to
  /// incoming / outgoing (falls back to the granular type when that's sent).
  final AppCallType type;

  /// Duration in seconds (0 when not connected).
  final int durationSeconds;

  /// Raw outcome string (`answered` / `no_answer`), if present.
  final String? outcome;
  final String? description;
  final DateTime? calledAt;

  /// Name of the CRM user who logged the call, if attributed.
  final String? userName;

  const LeadCallLog({
    required this.id,
    this.phone,
    this.contactName,
    required this.type,
    required this.durationSeconds,
    this.outcome,
    this.description,
    this.calledAt,
    this.userName,
  });

  factory LeadCallLog.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return LeadCallLog(
      id: (json['id'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String? ?? json['number'] as String?,
      contactName: json['contact_name'] as String? ?? json['name'] as String?,
      type: _parseType(json['call_type'] as String? ??
          json['direction'] as String? ??
          json['type'] as String?),
      durationSeconds: (json['duration'] as num?)?.toInt() ??
          (json['duration_seconds'] as num?)?.toInt() ??
          0,
      outcome: json['outcome'] as String?,
      description: json['description'] as String? ?? json['notes'] as String?,
      calledAt: DateTime.tryParse(
          (json['called_at'] ?? json['created_at']) as String? ?? ''),
      userName:
          user is Map ? user['name'] as String? : json['user_name'] as String?,
    );
  }

  /// Maps the backend direction/type onto [AppCallType]. Accepts the
  /// `inbound` / `outbound` the call-logs endpoint uses as well as the granular
  /// incoming / outgoing / missed names.
  static AppCallType _parseType(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'outbound':
        return AppCallType.outgoing;
      case 'inbound':
        return AppCallType.incoming;
      default:
        return AppCallType.fromApi(value);
    }
  }

  bool get isOutbound => type == AppCallType.outgoing;

  /// Direction label for the row title (`Outbound` / `Inbound`).
  String get directionLabel => isOutbound ? 'Outbound' : 'Inbound';

  /// Pretty `m:ss` / `h:mm:ss` duration, or `—` when there was no connection.
  String get durationLabel {
    if (durationSeconds <= 0) return '—';
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }

  /// Human label for [outcome] (`answered` → "Answered"), or null when absent.
  String? get outcomeLabel {
    final o = outcome?.toLowerCase().trim();
    if (o == null || o.isEmpty) return null;
    switch (o) {
      case 'answered':
        return 'Answered';
      case 'no_answer':
      case 'no answer':
        return 'No Answer';
      default:
        return o
            .split(RegExp(r'[_\s]+'))
            .where((w) => w.isNotEmpty)
            .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
    }
  }
}
