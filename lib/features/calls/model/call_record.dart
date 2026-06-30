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
