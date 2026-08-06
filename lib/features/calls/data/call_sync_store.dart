import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/phone_utils.dart';

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

/// A CRM number the user has recently had on screen (the phone on a lead /
/// opportunity detail screen). Unlike a [PendingCallIntent] this records no
/// intent to call — it just says "this number belongs to that entity".
///
/// It exists because a [PendingCallIntent] is only created by the in-app Call
/// button. When the user copies the number and dials from the native dialer,
/// redials from Recents, or *receives* a call from the lead, there is no
/// intent — so the resume-sync falls back to matching the device call log
/// against these watched numbers instead.
class WatchedNumber {
  final String number;
  final String? leadId;
  final String? opportunityId;
  final DateTime seenAt;

  const WatchedNumber({
    required this.number,
    this.leadId,
    this.opportunityId,
    required this.seenAt,
  });

  /// Identity for de-dup: the same line for the same CRM record.
  String get dedupKey =>
      '${PhoneUtils.normalize(number)}|${leadId ?? ''}|${opportunityId ?? ''}';

  Map<String, dynamic> toJson() => {
        'number': number,
        if (leadId != null) 'lead_id': leadId,
        if (opportunityId != null) 'opportunity_id': opportunityId,
        'seen_at': seenAt.millisecondsSinceEpoch,
      };

  factory WatchedNumber.fromJson(Map<String, dynamic> json) => WatchedNumber(
        number: json['number'] as String? ?? '',
        leadId: json['lead_id'] as String?,
        opportunityId: json['opportunity_id'] as String?,
        seenAt: DateTime.fromMillisecondsSinceEpoch(
            (json['seen_at'] as num?)?.toInt() ?? 0),
      );
}

/// SharedPreferences-backed bookkeeping for call syncing: the last sync time,
/// the set of already-uploaded call keys (de-dup), the pending in-app call
/// intents, and the watched CRM numbers.
class CallSyncStore {
  static const _lastSyncKey = 'calls.last_sync_ms';
  static const _uploadedKey = 'calls.uploaded_keys';
  static const _pendingKey = 'calls.pending_intents';
  static const _watchedKey = 'calls.watched_numbers';

  /// Cap on how far back the very first sync looks (no point uploading ancient
  /// history) and how stale a pending intent can get before we drop it.
  static const Duration firstSyncLookback = Duration(days: 14);
  static const Duration pendingIntentTtl = Duration(hours: 6);

  /// How long a number stays watched after the user last opened its record.
  static const Duration watchedNumberTtl = Duration(days: 7);

  /// Hard floor on the number-matching sweep window. [lastSync] normally keeps
  /// it to minutes, but it stays at its 14-day default until the first sync
  /// that can actually read the log — so without this cap, granting the
  /// permission after browsing leads would back-fill a fortnight of history in
  /// one go. Half a day is enough to catch "called earlier, opened the app
  /// later" without dumping old calls into the CRM.
  static const Duration sweepLookback = Duration(hours: 12);

  /// Keep the de-dup set bounded so it can't grow without limit.
  static const int _maxUploadedKeys = 1000;

  /// Cap on the watch list (newest kept) so it can't grow without limit.
  static const int _maxWatchedNumbers = 300;

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

  // --- Watched CRM numbers --------------------------------------------------

  /// Live (non-expired) watched numbers, oldest first.
  List<WatchedNumber> get watchedNumbers {
    final raw = _prefs.getStringList(_watchedKey) ?? const [];
    final cutoff = DateTime.now().subtract(watchedNumberTtl);
    return raw
        .map((s) {
          try {
            return WatchedNumber.fromJson(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<WatchedNumber>()
        .where((w) =>
            w.seenAt.isAfter(cutoff) && PhoneUtils.normalize(w.number).isNotEmpty)
        .toList();
  }

  /// Adds [items] to the watch list. An entry for the same number + record is
  /// replaced (so `seenAt` refreshes), and the list is trimmed to the newest
  /// [_maxWatchedNumbers].
  Future<void> addWatchedNumbers(Iterable<WatchedNumber> items) async {
    final incoming =
        items.where((w) => PhoneUtils.normalize(w.number).isNotEmpty).toList();
    if (incoming.isEmpty) return;

    final replaced = incoming.map((w) => w.dedupKey).toSet();
    final merged = [
      ...watchedNumbers.where((w) => !replaced.contains(w.dedupKey)),
      ...incoming,
    ];
    final trimmed = merged.length > _maxWatchedNumbers
        ? merged.sublist(merged.length - _maxWatchedNumbers)
        : merged;
    await _prefs.setStringList(
      _watchedKey,
      trimmed.map((w) => jsonEncode(w.toJson())).toList(),
    );
  }

  // --- Wipe -----------------------------------------------------------------

  /// Drops every key this store owns. Called on logout: the de-dup set, the
  /// pending intents and the watched numbers all describe the signed-out
  /// user's activity, and leaving them behind would make the next account's
  /// first sync skip calls it has never uploaded.
  Future<void> clear() async {
    await _prefs.remove(_lastSyncKey);
    await _prefs.remove(_uploadedKey);
    await _prefs.remove(_pendingKey);
    await _prefs.remove(_watchedKey);
  }
}

/// Async provider for the store; depends on [SharedPreferences].
final callSyncStoreProvider = FutureProvider<CallSyncStore>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return CallSyncStore(prefs);
});
