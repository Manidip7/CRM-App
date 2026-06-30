import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A call the user started *from inside the CRM* (the in-app Call button). We
/// remember the number + which lead/opportunity it was for + when it was
/// launched, so when that call later shows up in the device call log we can
/// attribute it precisely instead of relying on number-matching alone.
///
/// Persisted across restarts because the app is usually backgrounded (or even
/// killed) while the call is in progress.
class PendingCallIntent {
  final String number;
  final String? leadId;
  final String? opportunityId;
  final DateTime launchedAt;

  const PendingCallIntent({
    required this.number,
    this.leadId,
    this.opportunityId,
    required this.launchedAt,
  });

  Map<String, dynamic> toJson() => {
        'number': number,
        if (leadId != null) 'lead_id': leadId,
        if (opportunityId != null) 'opportunity_id': opportunityId,
        'launched_at': launchedAt.millisecondsSinceEpoch,
      };

  factory PendingCallIntent.fromJson(Map<String, dynamic> json) =>
      PendingCallIntent(
        number: json['number'] as String? ?? '',
        leadId: json['lead_id'] as String?,
        opportunityId: json['opportunity_id'] as String?,
        launchedAt: DateTime.fromMillisecondsSinceEpoch(
            (json['launched_at'] as num?)?.toInt() ?? 0),
      );
}

/// SharedPreferences-backed bookkeeping for call syncing: the last sync time,
/// the set of already-uploaded call keys (de-dup), and the pending in-app call
/// intents.
class CallSyncStore {
  static const _lastSyncKey = 'calls.last_sync_ms';
  static const _uploadedKey = 'calls.uploaded_keys';
  static const _pendingKey = 'calls.pending_intents';

  /// Cap on how far back the very first sync looks (no point uploading ancient
  /// history) and how stale a pending intent can get before we drop it.
  static const Duration firstSyncLookback = Duration(days: 14);
  static const Duration pendingIntentTtl = Duration(hours: 6);

  /// Keep the de-dup set bounded so it can't grow without limit.
  static const int _maxUploadedKeys = 1000;

  final SharedPreferences _prefs;

  CallSyncStore(this._prefs);

  // --- Last sync timestamp --------------------------------------------------

  DateTime get lastSync {
    final ms = _prefs.getInt(_lastSyncKey);
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime.now().subtract(firstSyncLookback);
  }

  Future<void> setLastSync(DateTime when) =>
      _prefs.setInt(_lastSyncKey, when.millisecondsSinceEpoch);

  // --- Upload de-dup --------------------------------------------------------

  Set<String> get uploadedKeys =>
      (_prefs.getStringList(_uploadedKey) ?? const []).toSet();

  bool isUploaded(String key) =>
      (_prefs.getStringList(_uploadedKey) ?? const []).contains(key);

  /// Adds [keys] to the uploaded set, trimming the oldest entries if the set
  /// grows past [_maxUploadedKeys].
  Future<void> addUploaded(Iterable<String> keys) async {
    final current = _prefs.getStringList(_uploadedKey) ?? <String>[];
    current.addAll(keys);
    final trimmed = current.length > _maxUploadedKeys
        ? current.sublist(current.length - _maxUploadedKeys)
        : current;
    await _prefs.setStringList(_uploadedKey, trimmed);
  }

  // --- Pending in-app call intents -----------------------------------------

  /// Live (non-expired) pending intents.
  List<PendingCallIntent> get pendingIntents {
    final raw = _prefs.getStringList(_pendingKey) ?? const [];
    final cutoff = DateTime.now().subtract(pendingIntentTtl);
    return raw
        .map((s) {
          try {
            return PendingCallIntent.fromJson(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<PendingCallIntent>()
        .where((i) => i.launchedAt.isAfter(cutoff))
        .toList();
  }

  Future<void> addPendingIntent(PendingCallIntent intent) async {
    final live = pendingIntents..add(intent);
    await _writePending(live);
  }

  Future<void> setPendingIntents(List<PendingCallIntent> intents) =>
      _writePending(intents);

  Future<void> _writePending(List<PendingCallIntent> intents) =>
      _prefs.setStringList(
        _pendingKey,
        intents.map((i) => jsonEncode(i.toJson())).toList(),
      );
}

/// Async provider for the store; depends on [SharedPreferences].
final callSyncStoreProvider = FutureProvider<CallSyncStore>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return CallSyncStore(prefs);
});
