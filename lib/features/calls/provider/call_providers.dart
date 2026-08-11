import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../Leads/provider/lead_detail_provider.dart';
import '../../Opportunities/provider/opportunity_detail_provider.dart';
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
/// Three entry points, covering every way a user can end up on a call with a
/// contact:
///  * [recordDirectCall] — call this right before launching the dialer from an
///    in-app Call button, so the captured call is tagged with the exact
///    lead/opportunity.
///  * [watchNumbers] — call this when a lead/opportunity's phone number is
///    shown, so a call placed *outside* the app (number copied into the
///    dialer, redial from Recents) or an incoming call from that contact can
///    still be attributed by number.
///  * [syncNow] — scans the device call log, matches entries against pending
///    in-app intents first and watched numbers second, and uploads. Wired to
///    run whenever the app resumes.
class CallSyncController extends Notifier<CallSyncState> {
  @override
  CallSyncState build() => const CallSyncState();

  CallLogService get _service => ref.read(callLogServiceProvider);
  CallsRepository get _repo => ref.read(callsRepositoryProvider);

  /// Records that the user is about to call [number] for the given lead /
  /// opportunity, so the resume-sync can attribute the resulting call-log entry.
  ///
  /// Deliberately does **not** touch the call-log permission: the only place
  /// allowed to trigger the system dialog is `ensureCallLogAccess`, which shows
  /// the prominent disclosure first. Recording the intent is free either way —
  /// if the user grants access later, the call is still waiting to be matched.
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
    // Also watch the number, so a redial from Recents (or the contact calling
    // back) after this one is still attributed to the same record.
    await store.addWatchedNumbers([
      WatchedNumber(
        number: number,
        leadId: leadId,
        opportunityId: opportunityId,
        seenAt: DateTime.now(),
      ),
    ]);
  }

  /// Registers [numbers] as belonging to a lead / opportunity, so [syncNow] can
  /// attribute calls that never went through the in-app Call button. Call it
  /// when a detail screen shows the contact's phone. Blank / duplicate numbers
  /// are ignored; nothing is uploaded here.
  Future<void> watchNumbers(
    Iterable<String?> numbers, {
    String? leadId,
    String? opportunityId,
  }) async {
    if (!_service.isSupported) return;
    final now = DateTime.now();
    final entries = numbers
        .whereType<String>()
        .where((n) => n.trim().isNotEmpty)
        .map((n) => WatchedNumber(
              number: n,
              leadId: leadId,
              opportunityId: opportunityId,
              seenAt: now,
            ));
    if (entries.isEmpty) return;
    final store = await ref.read(callSyncStoreProvider.future);
    await store.addWatchedNumbers(entries);
  }

  /// For every number the user called from the app, finds the **single latest**
  /// matching call-log entry and uploads just that one object (tagged with its
  /// lead/opportunity). Returns how many calls were uploaded.
  ///
  /// Never prompts: it silently returns 0 when unsupported or when the
  /// permission isn't granted. Granting is `ensureCallLogAccess`'s job, and
  /// keeping the prompt out of here is what guarantees no code path can reach
  /// the system dialog without the prominent disclosure being shown first.
  Future<int> syncNow() async {
    if (!_service.isSupported || state.syncing) return 0;
    if (!await _service.ensurePermission()) return 0;

    state = state.copyWith(syncing: true);
    try {
      final store = await ref.read(callSyncStoreProvider.future);
      final pending = store.pendingIntents;
      final syncStartedAt = DateTime.now();

      final uploads = <CallUpload>[];
      final keys = <String>[];
      final doneIntents = <PendingCallIntent>{};

      // ── 1. Calls launched from the in-app Call button ───────────────────
      for (final intent in pending) {
        // The latest call for this number since it was dialed (2-minute grace
        // for dial + connect lag).
        final latest = await _service.latestForNumber(
          intent.number,
          since: intent.launchedAt.subtract(const Duration(minutes: 2)),
        );
        if (latest == null) continue; // call not in the log yet — keep waiting

        final key = _keyFor(latest);
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

      // ── 2. Calls that never went through the in-app Call button ─────────
      // The number copied into the native dialer, a redial from Recents, or an
      // incoming call from the contact: no pending intent exists, so match the
      // device log against the numbers of the records the user has opened.
      final watched = store.watchedNumbers;
      if (watched.isNotEmpty) {
        final floor = syncStartedAt.subtract(CallSyncStore.sweepLookback);
        final since =
            store.lastSync.isBefore(floor) ? floor : store.lastSync;
        for (final entry in await _service.query(since: since)) {
          final key = _keyFor(entry);
          // Skip calls already uploaded, or captured by an intent just above.
          if (keys.contains(key) || store.isUploaded(key)) continue;

          WatchedNumber? match;
          for (final w in watched) {
            if (!PhoneUtils.sameNumber(w.number, entry.number)) continue;
            // Newest registration wins when the same line is on two records.
            if (match == null || w.seenAt.isAfter(match.seenAt)) match = w;
          }
          if (match == null) continue; // not a CRM number — leave it alone

          uploads.add(
            CallUpload(
              phone: entry.number,
              type: entry.type,
              durationSeconds: entry.durationSeconds,
              calledAt: entry.timestamp,
              contactName: entry.name,
              leadId: match.leadId,
              opportunityId: match.opportunityId,
            ),
          );
          keys.add(key);
        }
      }

      if (uploads.isEmpty) {
        await _advanceLastSync(store, syncStartedAt);
        return 0;
      }

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
        // The Lead Details screen renders its "Call Logs" section from the
        // detail response (`GET /leads/{id}`), not from the history provider —
        // refetch it too or a freshly-uploaded call stays invisible there.
        ref.invalidate(leadDetailProvider);
        ref.invalidate(opportunityDetailBundleProvider);
        state = state.copyWith(lastUploaded: uploadedCount);
      }
      // Re-queue every intent when anything failed; the isUploaded() check
      // skips the ones that already succeeded on the next run.
      if (anyFailure) {
        await store.setPendingIntents(pending);
      } else {
        await _advanceLastSync(store, syncStartedAt);
      }
      return uploadedCount;
    } finally {
      state = state.copyWith(syncing: false);
    }
  }

  /// De-dup identity for a device call: line + start time + duration.
  static String _keyFor(DeviceCallEntry e) =>
      '${PhoneUtils.normalize(e.number)}|'
      '${e.timestamp.millisecondsSinceEpoch}|'
      '${e.durationSeconds}';

  /// Moves the sweep window forward, keeping a 5-minute overlap because a call
  /// can land in the device log a moment after it ends. Re-reading those few
  /// minutes is free — [CallSyncStore.isUploaded] filters the duplicates.
  Future<void> _advanceLastSync(CallSyncStore store, DateTime startedAt) =>
      store.setLastSync(startedAt.subtract(const Duration(minutes: 5)));
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
/// old `setState`-driven local flags. Checking the permission on [build] flows
/// through Riverpod so the card just watches this provider; the disclosure gate
/// invalidates it once access is granted.
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
}

final callPermissionProvider =
    AsyncNotifierProvider<CallPermissionController, CallPermissionState>(
        CallPermissionController.new);

/// The one place in the app allowed to trigger the `READ_CALL_LOG` system
/// dialog, and the bookkeeping behind Google Play's *prominent disclosure*
/// requirement.
///
/// Play policy: before the OS permission prompt appears, the app must show its
/// own in-app screen naming the data, the purpose, and the fact that it leaves
/// the device — and the user must act on it affirmatively. The UI half of that
/// lives in `CallLogDisclosureDialog`; this controller owns the decisions
/// around it so no screen has to keep permission flags in local state.
///
/// Drive it through `ensureCallLogAccess(context, ref)` rather than calling
/// these methods directly.
class CallDisclosureController extends Notifier<void> {
  @override
  void build() {}

  CallLogService get _service => ref.read(callLogServiceProvider);

  /// Whether access is already granted — the disclosure is pointless then.
  Future<bool> get isGranted => _service.isGranted;

  /// Whether the disclosure should be put in front of the user right now.
  ///
  /// `false` on iOS (no call-log API at all), when access is already granted,
  /// and when the user has previously said no — unless [force] is set, which is
  /// how the explicit *Enable call logging* button re-opens the conversation.
  Future<bool> shouldDisclose({bool force = false}) async {
    if (!_service.isSupported) return false;
    if (await _service.isGranted) return false;
    if (force) return true;
    final store = await ref.read(callSyncStoreProvider.future);
    return !store.disclosureDeclined;
  }

  /// Remembers that the user dismissed the disclosure, so the automatic gate
  /// stops asking.
  Future<void> markDeclined() async {
    final store = await ref.read(callSyncStoreProvider.future);
    await store.setDisclosureDeclined(true);
  }

  /// Runs the system permission request. Only legal to call *after* the user
  /// has accepted the disclosure. Denying at the OS level counts as a decline,
  /// so the gate won't ask again on its own.
  Future<bool> grantAfterDisclosure() async {
    final granted = await _service.ensurePermission(request: true);
    final store = await ref.read(callSyncStoreProvider.future);
    await store.setDisclosureDeclined(!granted);
    // Let every CallHistoryCard on screen re-check and back-fill.
    if (granted) ref.invalidate(callPermissionProvider);
    return granted;
  }
}

final callDisclosureProvider =
    NotifierProvider<CallDisclosureController, void>(
        CallDisclosureController.new);

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
