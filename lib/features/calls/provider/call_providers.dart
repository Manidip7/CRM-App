import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../data/call_log_service.dart';
import '../data/call_sync_store.dart';
import '../data/calls_repository.dart';
import '../model/call_record.dart';
import '../util/phone_utils.dart';

/// Status of the background call-sync.
class CallSyncState {
  final bool syncing;

  /// How many calls were uploaded in the last successful sync (for a snackbar /
  /// debugging), or null if it never ran.
  final int? lastUploaded;

  const CallSyncState({this.syncing = false, this.lastUploaded});

  CallSyncState copyWith({bool? syncing, int? lastUploaded}) => CallSyncState(
        syncing: syncing ?? this.syncing,
        lastUploaded: lastUploaded ?? this.lastUploaded,
      );
}

/// Orchestrates capturing call details and pushing them to the backend.
///
/// Two entry points, covering both ways a user can call a contact:
///  * [recordDirectCall] — call this right before launching the dialer from an
///    in-app Call button, so the captured call is tagged with the exact
///    lead/opportunity.
///  * [syncNow] — scans the device call log for anything new since the last
///    sync (catching copy-paste / native-dialer calls too), matches it to a
///    pending in-app intent when possible, and uploads. Wired to run whenever
///    the app resumes.
class CallSyncController extends Notifier<CallSyncState> {
  @override
  CallSyncState build() => const CallSyncState();

  CallLogService get _service => ref.read(callLogServiceProvider);
  CallsRepository get _repo => ref.read(callsRepositoryProvider);

  /// Records that the user is about to call [number] for the given lead /
  /// opportunity, and (best-effort) makes sure the call-log permission is
  /// granted so the resume-sync can read the result. Safe to await or not.
  Future<void> recordDirectCall({
    required String number,
    String? leadId,
    String? opportunityId,
  }) async {
    if (!_service.isSupported) return;
    final store = await ref.read(callSyncStoreProvider.future);
    await store.addPendingIntent(
      PendingCallIntent(
        number: number,
        leadId: leadId,
        opportunityId: opportunityId,
        launchedAt: DateTime.now(),
      ),
    );
    // Ask for permission now (the natural moment) so the result is readable
    // when the user comes back from the call.
    await _service.ensurePermission(request: true);
  }

  /// For every number the user called from the app, finds the **single latest**
  /// matching call-log entry and uploads just that one object (tagged with its
  /// lead/opportunity). Returns how many calls were uploaded. No-ops (returns
  /// 0) when unsupported or the permission isn't granted. When
  /// [requestPermission] is true it prompts for the permission if needed.
  Future<int> syncNow({bool requestPermission = false}) async {
    if (!_service.isSupported || state.syncing) return 0;
    if (!await _service.ensurePermission(request: requestPermission)) return 0;

    state = state.copyWith(syncing: true);
    try {
      final store = await ref.read(callSyncStoreProvider.future);
      final pending = store.pendingIntents;
      if (pending.isEmpty) return 0;

      final uploads = <CallUpload>[];
      final keys = <String>[];
      final doneIntents = <PendingCallIntent>{};

      for (final intent in pending) {
        // The latest call for this number since it was dialed (2-minute grace
        // for dial + connect lag).
        final latest = await _service.latestForNumber(
          intent.number,
          since: intent.launchedAt.subtract(const Duration(minutes: 2)),
        );
        if (latest == null) continue; // call not in the log yet — keep waiting

        final key = '${PhoneUtils.normalize(latest.number)}|'
            '${latest.timestamp.millisecondsSinceEpoch}|'
            '${latest.durationSeconds}';
        // Already uploaded this exact call — just clear the intent.
        if (store.isUploaded(key)) {
          doneIntents.add(intent);
          continue;
        }

        uploads.add(
          CallUpload(
            phone: latest.number,
            type: latest.type,
            durationSeconds: latest.durationSeconds,
            calledAt: latest.timestamp,
            contactName: latest.name,
            leadId: intent.leadId,
            opportunityId: intent.opportunityId,
          ),
        );
        keys.add(key);
        doneIntents.add(intent);
      }

      // Drop intents we've handled (uploaded or already-uploaded) regardless.
      if (doneIntents.isNotEmpty) {
        await store.setPendingIntents(
          pending.where((p) => !doneIntents.contains(p)).toList(),
        );
      }

      if (uploads.isEmpty) return 0;

      // Lead-tagged calls go to POST /leads/{id}/call-logs (url-encoded), one
      // per call. Anything else (e.g. opportunity calls) still batches to
      // POST /calls, since there's no per-opportunity call-logs endpoint.
      final leadRecords = <({CallUpload up, String key})>[];
      final otherRecords = <({CallUpload up, String key})>[];
      for (var i = 0; i < uploads.length; i++) {
        final rec = (up: uploads[i], key: keys[i]);
        (uploads[i].leadId != null ? leadRecords : otherRecords).add(rec);
      }

      final uploadedKeys = <String>[];
      var uploadedCount = 0;
      var anyFailure = false;

      for (final rec in leadRecords) {
        final res = await _repo.logLeadCall(
          rec.up.leadId!,
          callType: rec.up.type.directionApiValue,
          duration: rec.up.durationSeconds,
          // A connected call has a non-zero duration; missed/rejected are 0.
          outcome: rec.up.durationSeconds > 0 ? 'answered' : 'no_answer',
        );
        if (res.errorOrNull == null) {
          uploadedKeys.add(rec.key);
          uploadedCount++;
        } else {
          anyFailure = true;
        }
      }

      if (otherRecords.isNotEmpty) {
        final res =
            await _repo.uploadCalls(otherRecords.map((r) => r.up).toList());
        if (res.errorOrNull == null) {
          uploadedKeys.addAll(otherRecords.map((r) => r.key));
          uploadedCount += otherRecords.length;
        } else {
          anyFailure = true;
        }
      }

      if (uploadedKeys.isNotEmpty) {
        await store.addUploaded(uploadedKeys);
        // Refresh any open history lists so the new calls appear.
        ref.invalidate(leadCallHistoryProvider);
        ref.invalidate(opportunityCallHistoryProvider);
        state = state.copyWith(lastUploaded: uploadedCount);
      }
      // Re-queue every intent when anything failed; the isUploaded() check
      // skips the ones that already succeeded on the next run.
      if (anyFailure) {
        await store.setPendingIntents(pending);
      }
      return uploadedCount;
    } finally {
      state = state.copyWith(syncing: false);
    }
  }
}

final callSyncControllerProvider =
    NotifierProvider<CallSyncController, CallSyncState>(CallSyncController.new);

/// Whether call logging is available on this device and the permission state.
class CallPermissionState {
  /// Call logging is only available on Android.
  final bool supported;

  /// The call-log/phone permission is granted.
  final bool granted;

  const CallPermissionState({this.supported = false, this.granted = false});
}

/// Holds the call-log permission state for the [CallHistoryCard], replacing the
/// old `setState`-driven local flags. Checking the permission on [build] and
/// after [enable] flows through Riverpod so the card just watches this provider.
class CallPermissionController extends AsyncNotifier<CallPermissionState> {
  CallLogService get _service => ref.read(callLogServiceProvider);

  Future<CallPermissionState> _check() async {
    final supported = _service.isSupported;
    final granted = supported && await _service.isGranted;
    // If we already have access, pull the latest calls in case the user dialed
    // before this card was shown.
    if (granted) {
      await ref.read(callSyncControllerProvider.notifier).syncNow();
    }
    return CallPermissionState(supported: supported, granted: granted);
  }

  @override
  Future<CallPermissionState> build() => _check();

  /// Requests the permission (if needed), syncs, and refreshes the state.
  /// Returns how many calls were uploaded by the sync.
  Future<int> enable() async {
    final uploaded = await ref
        .read(callSyncControllerProvider.notifier)
        .syncNow(requestPermission: true);
    state = await AsyncValue.guard(_check);
    return uploaded;
  }
}

final callPermissionProvider =
    AsyncNotifierProvider<CallPermissionController, CallPermissionState>(
        CallPermissionController.new);

// ─────────────────────────────────────────────
//  Manual "Log Call" form (POST /leads/{id}/call-logs)
// ─────────────────────────────────────────────

/// The outcome of a manually-logged call, sent as the `outcome` field.
enum CallOutcome { answered, noAnswer }

extension CallOutcomeX on CallOutcome {
  String get label {
    switch (this) {
      case CallOutcome.answered:
        return 'Answered';
      case CallOutcome.noAnswer:
        return 'No Answer';
    }
  }

  /// Value sent to the API (`outcome` field).
  String get apiValue {
    switch (this) {
      case CallOutcome.answered:
        return 'answered';
      case CallOutcome.noAnswer:
        return 'no_answer';
    }
  }
}

/// The call directions offered in the Log-Call form — the endpoint expects
/// `Outbound` / `Inbound` (see [AppCallType.directionApiValue]).
const kLogCallTypes = [
  AppCallType.outgoing,
  AppCallType.incoming,
];

/// Dropdown + submit state for the Log-Call sheet. Text fields (duration,
/// description, contact name) stay in local controllers; the reactive bits live
/// here so the sheet needs no [setState].
class LogCallFormState {
  final AppCallType callType;
  final CallOutcome outcome;
  final bool submitting;

  const LogCallFormState({
    this.callType = AppCallType.outgoing,
    this.outcome = CallOutcome.answered,
    this.submitting = false,
  });

  LogCallFormState copyWith({
    AppCallType? callType,
    CallOutcome? outcome,
    bool? submitting,
  }) {
    return LogCallFormState(
      callType: callType ?? this.callType,
      outcome: outcome ?? this.outcome,
      submitting: submitting ?? this.submitting,
    );
  }
}

class LogCallFormNotifier extends Notifier<LogCallFormState> {
  @override
  LogCallFormState build() => const LogCallFormState();

  void reset() => state = const LogCallFormState();
  void setCallType(AppCallType t) => state = state.copyWith(callType: t);
  void setOutcome(CallOutcome o) => state = state.copyWith(outcome: o);
  void setSubmitting(bool v) => state = state.copyWith(submitting: v);
}

final logCallFormProvider =
    NotifierProvider<LogCallFormNotifier, LogCallFormState>(
        LogCallFormNotifier.new);

/// Call history for a lead (`GET /leads/{id}/calls`), keyed by lead id.
final leadCallHistoryProvider =
    FutureProvider.family<List<CallRecord>, String>((ref, leadId) async {
  final result = await ref.watch(callsRepositoryProvider).getLeadCalls(leadId);
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});

/// Call history for an opportunity (`GET /opportunities/{id}/calls`), keyed by
/// opportunity id.
final opportunityCallHistoryProvider =
    FutureProvider.family<List<CallRecord>, String>((ref, oppId) async {
  final result =
      await ref.watch(callsRepositoryProvider).getOpportunityCalls(oppId);
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});
