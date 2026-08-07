import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_result.dart';
import '../data/leads_repository.dart';
import '../model/lead_model.dart';
import 'leads_provider.dart';

part 'lead_detail_provider.freezed.dart';
part 'lead_detail_provider.g.dart';

/// Loads a lead's detail bundle (timeline, notes, tasks) from `GET /leads/{id}`,
/// keyed by lead id. Watched by the Timeline / Notes / Tasks tabs.
@riverpod
Future<LeadDetailBundle> leadDetail(Ref ref, String leadId) async {
  final result = await ref.watch(leadsRepositoryProvider).getLeadDetail(leadId);
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
}

/// Loads the full lead record from `GET /leads/{id}` (its own fields, including
/// the follow-up data: current_update, next_action, interest_score, etc.),
/// keyed by lead id. The detail screen uses this to populate the header with
/// server-authoritative values the list endpoint may omit.
@riverpod
Future<LeadModel> leadFull(Ref ref, String leadId) async {
  final result = await ref.watch(leadsRepositoryProvider).getLead(leadId);
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
}

/// Holds the detail screen's display copy of a lead, keyed by lead id, so
/// follow-up edits (scheduling) and server-loaded values update through Riverpod
/// instead of `setState`. Seeded once from the lead passed via navigation;
/// `null` until seeded (the screen falls back to the navigation lead).
@riverpod
class LeadView extends _$LeadView {
  @override
  LeadModel? build(String leadId) => null;

  /// Seeds the initial lead (from the list/navigation) once.
  void seed(LeadModel lead) => state ??= lead;

  /// Applies an optimistically-scheduled follow-up to the held lead.
  void applyFollowUp({
    required DateTime nextFollowUp,
    String? currentUpdate,
    String? nextAction,
    String? followupRemarks,
    int? currentUpdateId,
    int? nextActionId,
    int? interestScore,
  }) {
    final lead = state;
    if (lead == null) return;
    state = lead.copyWithFollowUp(
      nextFollowUp: nextFollowUp,
      currentUpdate: currentUpdate,
      nextAction: nextAction,
      followupRemarks: followupRemarks,
      currentUpdateId: currentUpdateId,
      nextActionId: nextActionId,
      interestScore: interestScore,
    );
  }

  /// Replaces the held lead wholesale after the Edit-Lead form saves.
  void applyEdit(LeadModel lead) => state = lead;

  /// Merges the server-authoritative follow-up fields from the full lead.
  void applyServerFollowUp(LeadModel full) {
    final lead = state ?? full;
    state = lead.copyWithFollowUp(
      nextFollowUp: full.nextFollowUp,
      currentUpdate: full.currentUpdate,
      nextAction: full.nextAction,
      followupRemarks: full.followupRemarks,
      currentUpdateId: full.currentUpdateId,
      nextActionId: full.nextActionId,
      interestScore: full.interestScore,
    );
  }
}

@freezed
abstract class LeadDetailState with _$LeadDetailState {
  const factory LeadDetailState({
    @Default(LeadPipelineStatus.newLead) LeadPipelineStatus pipelineStatus,
    @Default(LeadTemperature.warm) LeadTemperature temperature,
    @Default(false) bool converted,

    /// Selected backend status id (from `GET /statuses`), shown on the header.
    int? statusId,
  }) = _LeadDetailState;
}

/// Editable pipeline status / temperature / conversion flag for a single lead,
/// keyed by the lead id so each lead keeps its own state. The initial
/// temperature is seeded from the lead's `priority` via [initialTemperature].
@riverpod
class LeadDetailController extends _$LeadDetailController {
  late String _leadId;

  @override
  LeadDetailState build(
    String leadId, {
    LeadTemperature initialTemperature = LeadTemperature.warm,
    int? initialStatusId,
  }) {
    _leadId = leadId;
    return LeadDetailState(
      temperature: initialTemperature,
      statusId: initialStatusId,
    );
  }

  void setStatus(LeadPipelineStatus s) =>
      state = state.copyWith(pipelineStatus: s);

  /// Seeds the status id from the server (no API call) — used when the full
  /// lead loads. Leaves state unchanged if it already matches.
  void seedStatusId(int id) {
    if (state.statusId != id) state = state.copyWith(statusId: id);
  }

  /// Changes the status optimistically and persists it via
  /// `POST /leads/{id}/status`. Reverts and returns `false` if the call fails.
  Future<bool> setStatusId(int id) async {
    final previous = state.statusId;
    if (previous == id) return true;

    state = state.copyWith(statusId: id); // optimistic
    final result =
        await ref.read(leadsRepositoryProvider).updateLeadStatus(_leadId, id);

    return result.when(
      success: (_) => true,
      failure: (_) {
        state = state.copyWith(statusId: previous); // revert
        return false;
      },
    );
  }

  /// Updates the temperature optimistically and persists it via
  /// `POST /leads/{id}/priority`. Reverts and returns `false` if the call fails.
  Future<bool> setTemperature(LeadTemperature t) async {
    final previous = state.temperature;
    if (previous == t) return true;

    state = state.copyWith(temperature: t); // optimistic
    final result = await ref
        .read(leadsRepositoryProvider)
        .updateLeadPriority(_leadId, t.name);

    return result.when(
      success: (_) {
        // Patch the lead in the list so the change survives navigating back
        // and re-seeds the detail screen on re-entry.
        ref.read(leadsListProvider.notifier).updatePriority(_leadId, t.name);
        return true;
      },
      failure: (_) {
        state = state.copyWith(temperature: previous); // revert
        return false;
      },
    );
  }

  void markConverted() => state = state.copyWith(converted: true);
}

/// Handles adding a note to a lead (`POST /leads/{id}/notes`), keyed by lead id.
/// The state is the in-flight `saving` flag. On success it refreshes the lead's
/// detail bundle so the new note appears.
@riverpod
class AddNote extends _$AddNote {
  late String _leadId;

  @override
  bool build(String leadId) {
    _leadId = leadId;
    return false;
  }

  /// Submits [content]. Returns `true` on success, `false` on empty input or
  /// API failure.
  Future<bool> submit(String content) async {
    final text = content.trim();
    if (text.isEmpty || state) return false;

    state = true;
    final result =
        await ref.read(leadsRepositoryProvider).addLeadNote(_leadId, text);
    state = false;

    return result.when(
      success: (_) {
        ref.invalidate(leadDetailProvider(_leadId));
        return true;
      },
      failure: (_) => false,
    );
  }
}

/// Deletes a note from a lead (`DELETE /leads/{id}/notes/{noteId}`), keyed by
/// lead id. The state is the id of the note currently being deleted (`null`
/// when idle), so the notes tab can show a spinner on just that card. On
/// success it refreshes the lead's detail bundle so the note disappears.
@riverpod
class DeleteLeadNote extends _$DeleteLeadNote {
  late String _leadId;

  @override
  int? build(String leadId) {
    _leadId = leadId;
    return null;
  }

  /// Deletes [noteId]. Returns `null` on success, or an error message to show.
  Future<String?> delete(int noteId) async {
    if (state != null) return null; // a delete is already in flight

    state = noteId;
    final result =
        await ref.read(leadsRepositoryProvider).deleteLeadNote(_leadId, noteId);
    state = null;

    return result.when(
      success: (_) {
        ref.invalidate(leadDetailProvider(_leadId));
        return null;
      },
      failure: (error) => error.message,
    );
  }
}

/// Form state for the "Convert to Opportunity" bottom sheet.
@freezed
abstract class ConvertLeadState with _$ConvertLeadState {
  const factory ConvertLeadState({
    @Default(50) double probability,
    @Default(false) bool saving,
  }) = _ConvertLeadState;
}

/// Converts a lead to an opportunity (`POST /leads/{id}/convert`), keyed by lead
/// id and auto-disposed so the form resets each time the sheet opens.
@riverpod
class ConvertLead extends _$ConvertLead {
  late String _leadId;

  @override
  ConvertLeadState build(String leadId) {
    _leadId = leadId;
    return const ConvertLeadState();
  }

  void setProbability(double p) => state = state.copyWith(probability: p);

  /// Submits the conversion with [expectedValue] and the chosen probability.
  /// Returns `true` on success.
  Future<bool> submit(double expectedValue) async {
    if (state.saving) return false;
    state = state.copyWith(saving: true);
    final result = await ref.read(leadsRepositoryProvider).convertLead(
          _leadId,
          expectedValue: expectedValue,
          probability: state.probability.round(),
        );
    state = state.copyWith(saving: false);
    return result.when(success: (_) => true, failure: (_) => false);
  }
}

/// Form state for the Add / Edit Task bottom sheet.
@freezed
abstract class LeadTaskFormState with _$LeadTaskFormState {
  const factory LeadTaskFormState({
    DateTime? dueAt,
    @Default('medium') String priority,

    /// Backend status (`open` / `in_progress` / `backlog` / `done`). Only sent
    /// when editing — the create endpoint doesn't take it.
    @Default('open') String status,
    @Default(false) bool saving,
  }) = _LeadTaskFormState;
}

/// Backs the lead's Add / Edit Task sheet, keyed by lead id and — when editing —
/// the task id, so each sheet keeps its own form. Auto-disposed, so the form
/// resets every time the sheet opens. [taskId] `null` means "create": submitting
/// posts to `/leads/{id}/tasks`; otherwise it puts to `/leads/{id}/tasks/{taskId}`.
/// The initial values seed the form from the task being edited. On success it
/// refreshes the lead's detail bundle so the tasks tab reflects the change.
@riverpod
class LeadTaskForm extends _$LeadTaskForm {
  late String _leadId;
  int? _taskId;

  @override
  LeadTaskFormState build(
    String leadId, {
    int? taskId,
    DateTime? initialDueAt,
    String initialPriority = 'medium',
    String initialStatus = 'open',
  }) {
    _leadId = leadId;
    _taskId = taskId;
    return LeadTaskFormState(
      dueAt: initialDueAt,
      priority: initialPriority,
      status: initialStatus,
    );
  }

  void setDueAt(DateTime d) => state = state.copyWith(dueAt: d);
  void setPriority(String p) => state = state.copyWith(priority: p);
  void setStatus(String s) => state = state.copyWith(status: s);

  /// `due_at` in the API's `yyyy-MM-dd HH:mm:ss` format.
  static String _fmtDue(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  /// Creates or updates the task, depending on whether this form was built with
  /// a `taskId`. Requires a non-empty [title] and a chosen due date. Returns
  /// `null` on success, or an error message to show.
  Future<String?> submit(String title) async {
    final text = title.trim();
    final due = state.dueAt;
    if (text.isEmpty) return 'Enter a task title';
    if (due == null) return 'Pick a due date & time';
    if (state.saving) return null;

    final id = _taskId;
    state = state.copyWith(saving: true);
    final repo = ref.read(leadsRepositoryProvider);
    final result = id == null
        ? await repo.addLeadTask(
            _leadId,
            title: text,
            dueAt: _fmtDue(due),
            priority: state.priority,
          )
        : await repo.updateLeadTask(
            _leadId,
            id,
            title: text,
            dueAt: _fmtDue(due),
            priority: state.priority,
            status: state.status,
          );
    state = state.copyWith(saving: false);

    return result.when(
      success: (_) {
        ref.invalidate(leadDetailProvider(_leadId));
        return null;
      },
      failure: (error) => error.message,
    );
  }
}

/// Deletes a task from a lead (`DELETE /leads/{id}/tasks/{taskId}`), keyed by
/// lead id. The state is the id of the task currently being deleted (`null`
/// when idle), so the tasks tab can show a spinner on just that card. On
/// success it refreshes the lead's detail bundle so the task disappears.
@riverpod
class DeleteLeadTask extends _$DeleteLeadTask {
  late String _leadId;

  @override
  int? build(String leadId) {
    _leadId = leadId;
    return null;
  }

  /// Deletes [taskId]. Returns `null` on success, or an error message to show.
  Future<String?> delete(int taskId) async {
    if (state != null) return null; // a delete is already in flight

    state = taskId;
    final result =
        await ref.read(leadsRepositoryProvider).deleteLeadTask(_leadId, taskId);
    state = null;

    return result.when(
      success: (_) {
        ref.invalidate(leadDetailProvider(_leadId));
        return null;
      },
      failure: (error) => error.message,
    );
  }
}

/// Transient form state for the "Schedule Follow-up" bottom sheet.
@freezed
abstract class FollowUpFormState with _$FollowUpFormState {
  const factory FollowUpFormState({
    NamedLookup? currentUpdate,
    NamedLookup? nextAction,
    DateTime? scheduleDate,
    @Default(50) double score,
    @Default(false) bool saving,
  }) = _FollowUpFormState;
}

/// Holds the "Schedule Follow-up" form state, keyed by lead id and auto-disposed
/// so each time the sheet opens it starts fresh. Replaces the sheet's local
/// `setState` so the form is Riverpod-managed too.
@riverpod
class FollowUpForm extends _$FollowUpForm {
  @override
  FollowUpFormState build(String leadId) => const FollowUpFormState();

  void setCurrentUpdate(NamedLookup? v) =>
      state = state.copyWith(currentUpdate: v);
  void setNextAction(NamedLookup? v) => state = state.copyWith(nextAction: v);
  void setScheduleDate(DateTime d) => state = state.copyWith(scheduleDate: d);
  void setScore(double s) => state = state.copyWith(score: s);
  void setSaving(bool b) => state = state.copyWith(saving: b);
}

/// Transient form state for the "Assign Lead" bottom sheet.
@freezed
abstract class AssignLeadFormState with _$AssignLeadFormState {
  const factory AssignLeadFormState({
    NamedLookup? territory,
    NamedLookup? branch,
    @Default(<int>{}) Set<int> selectedUserIds,
    @Default(false) bool isPrivate,
    @Default(false) bool saving,

    /// Turns the assignee picker red once a submit is attempted with none
    /// selected.
    @Default(false) bool assigneeError,
  }) = _AssignLeadFormState;
}

/// Holds the "Assign Lead" form state, keyed by lead id and auto-disposed so
/// each time the sheet opens it starts fresh. Replaces the sheet's local
/// `setState` so the form is Riverpod-managed too.
@riverpod
class AssignLeadForm extends _$AssignLeadForm {
  @override
  AssignLeadFormState build(String leadId) => const AssignLeadFormState();

  /// Territory scopes the branch list, so changing it drops the stale branch.
  void setTerritory(NamedLookup? v) =>
      state = state.copyWith(territory: v, branch: null);
  void setBranch(NamedLookup? v) => state = state.copyWith(branch: v);
  void setPrivate(bool v) => state = state.copyWith(isPrivate: v);
  void setSaving(bool v) => state = state.copyWith(saving: v);
  void flagAssigneeError() => state = state.copyWith(assigneeError: true);

  /// Adds the user if not already picked, removes them if they were.
  void toggleUser(int id) {
    final next = Set<int>.of(state.selectedUserIds);
    if (!next.remove(id)) next.add(id);
    state = state.copyWith(selectedUserIds: next, assigneeError: false);
  }
}
