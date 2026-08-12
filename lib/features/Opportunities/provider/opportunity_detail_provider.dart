import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_result.dart';
import '../../Leads/model/lead_model.dart' show StatusOption;
import '../data/opportunities_repository.dart';
import '../model/opportunity_detail_model.dart';
import '../model/opportunity_model.dart';

part 'opportunity_detail_provider.freezed.dart';
part 'opportunity_detail_provider.g.dart';

/// Loads an opportunity's full detail bundle from `GET /opportunities/{id}`,
/// keyed by opportunity id. Watched by the header, Information, Products,
/// Quotes, Timeline, Notes and Tasks sections of the detail screen.
final opportunityDetailBundleProvider = FutureProvider.autoDispose
    .family<OpportunityDetailBundle, String>((ref, id) async {
  final result =
      await ref.watch(opportunitiesRepositoryProvider).getOpportunityDetail(id);
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});

/// GET /opportunity-stages — the selectable stages for the header dropdown.
/// Session-cached (not autoDispose) so it is fetched once and shared.
final opportunityStagesProvider =
    FutureProvider<List<StageOption>>((ref) async {
  final result = await ref.watch(opportunitiesRepositoryProvider).getStages();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});

/// GET /statuses, narrowed to opportunity statuses — the options behind the
/// advanced filter's `status_id` dropdown. Session-cached.
final opportunityStatusesProvider =
    FutureProvider<List<StatusOption>>((ref) async {
  final result =
      await ref.watch(opportunitiesRepositoryProvider).getOpportunityStatuses();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});

/// GET /products — the product catalog for the Add Product picker.
/// Session-cached (not autoDispose) so it is fetched once and shared.
final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final result =
      await ref.watch(opportunitiesRepositoryProvider).getProducts();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});

@freezed
abstract class OpportunityDetailState with _$OpportunityDetailState {
  const factory OpportunityDetailState({
    @Default(OpportunityStage.proposal) OpportunityStage stage,

    /// The raw stage id currently selected in the header dropdown (e.g.
    /// `"Prospecting"`). Null until seeded from the opportunity's `stageRaw`.
    String? stageId,
    @Default(50) int probability,
    @Default(false) bool closedWon,
    @Default(<OpportunityProduct>[]) List<OpportunityProduct> products,
  }) = _OpportunityDetailState;
}

/// Editable stage / probability / won flag for a single opportunity, keyed by
/// the opportunity id so each one keeps its own state.
@riverpod
class OpportunityDetailController extends _$OpportunityDetailController {
  @override
  OpportunityDetailState build(
    String opportunityId, {
    OpportunityStage initialStage = OpportunityStage.proposal,
    String? initialStageId,
    int initialProbability = 50,
  }) =>
      OpportunityDetailState(
        stage: initialStage,
        stageId: initialStageId,
        probability: initialProbability,
        closedWon: initialStage == OpportunityStage.won,
      );

  void setStage(OpportunityStage s) => state = state.copyWith(
        stage: s,
        closedWon: s == OpportunityStage.won,
      );

  /// Selects a status by its `status_id` from `GET /opportunity-statuses`.
  /// Keeps the [OpportunityStage] enum (used for colors / badges elsewhere) in
  /// sync — mapped from [name] when the caller knows it, because the ids are
  /// numeric and would all collapse to the enum's fallback value.
  void setStageId(String id, {String? name}) {
    final mapped = opportunityStageFromId(name ?? id);
    state = state.copyWith(
      stageId: id,
      stage: mapped,
      closedWon: mapped == OpportunityStage.won,
    );
  }

  void setProbability(int p) => state = state.copyWith(probability: p);

  void markWon() => state = state.copyWith(
        stage: OpportunityStage.won,
        stageId: 'Won',
        probability: 100,
        closedWon: true,
      );

  void addProduct(OpportunityProduct product) =>
      state = state.copyWith(products: [...state.products, product]);

  void removeProduct(int index) => state = state.copyWith(
        products: [
          for (var i = 0; i < state.products.length; i++)
            if (i != index) state.products[i],
        ],
      );
}

/// Handles adding a note to an opportunity (`POST /opportunities/{id}/notes`),
/// keyed by opportunity id. The state is the in-flight `saving` flag. On success
/// it refreshes the opportunity's detail bundle so the new note appears.
@riverpod
class AddOpportunityNote extends _$AddOpportunityNote {
  late String _opportunityId;

  @override
  bool build(String opportunityId) {
    _opportunityId = opportunityId;
    return false;
  }

  /// Submits [content]. Returns `null` on success, or an error message to show.
  Future<String?> submit(String content) async {
    final text = content.trim();
    if (text.isEmpty) return 'Write a note first';
    if (state) return null; // already saving

    state = true;
    final result = await ref
        .read(opportunitiesRepositoryProvider)
        .addOpportunityNote(_opportunityId, text);
    state = false;

    return result.when(
      success: (_) {
        ref.invalidate(opportunityDetailBundleProvider(_opportunityId));
        return null;
      },
      failure: (error) => error.message,
    );
  }
}

/// Deletes a note from an opportunity (`DELETE /opportunities/{id}/notes/{noteId}`),
/// keyed by opportunity id. The state is the id of the note currently being
/// deleted (`null` when idle), so the notes tab can show a spinner on just that
/// card. On success it refreshes the detail bundle so the note disappears.
@riverpod
class DeleteOpportunityNote extends _$DeleteOpportunityNote {
  late String _opportunityId;

  @override
  int? build(String opportunityId) {
    _opportunityId = opportunityId;
    return null;
  }

  /// Deletes [noteId]. Returns `null` on success, or an error message to show.
  Future<String?> delete(int noteId) async {
    if (state != null) return null; // a delete is already in flight

    state = noteId;
    final result = await ref
        .read(opportunitiesRepositoryProvider)
        .deleteOpportunityNote(_opportunityId, noteId);
    state = null;

    return result.when(
      success: (_) {
        ref.invalidate(opportunityDetailBundleProvider(_opportunityId));
        return null;
      },
      failure: (error) => error.message,
    );
  }
}

/// Form state for the opportunity's Add / Edit Task bottom sheet.
@freezed
abstract class OpportunityTaskFormState with _$OpportunityTaskFormState {
  const factory OpportunityTaskFormState({
    DateTime? dueAt,
    @Default('medium') String priority,

    /// Backend status (`open` / `in_progress` / `backlog` / `done`). Only sent
    /// when editing — the create endpoint doesn't take it.
    @Default('open') String status,
    @Default(false) bool saving,
  }) = _OpportunityTaskFormState;
}

/// Backs the opportunity's Add / Edit Task sheet, keyed by opportunity id and —
/// when editing — the task id, so each sheet keeps its own form. Auto-disposed,
/// so the form resets every time the sheet opens. [taskId] `null` means
/// "create": submitting posts to `/opportunities/{id}/tasks`; otherwise it puts
/// to `/opportunities/{id}/tasks/{taskId}`. The initial values seed the form
/// from the task being edited. On success it refreshes the detail bundle so the
/// Tasks tab reflects the change.
@riverpod
class OpportunityTaskForm extends _$OpportunityTaskForm {
  late String _opportunityId;
  int? _taskId;

  @override
  OpportunityTaskFormState build(
    String opportunityId, {
    int? taskId,
    DateTime? initialDueAt,
    String initialPriority = 'medium',
    String initialStatus = 'open',
  }) {
    _opportunityId = opportunityId;
    _taskId = taskId;
    return OpportunityTaskFormState(
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
  /// a `taskId`. Returns `null` on success, or an error message to show.
  Future<String?> submit(String title) async {
    final text = title.trim();
    final due = state.dueAt;
    if (text.isEmpty) return 'Enter a task title';
    if (due == null) return 'Pick a due date & time';
    if (state.saving) return null;

    final id = _taskId;
    state = state.copyWith(saving: true);
    final repo = ref.read(opportunitiesRepositoryProvider);
    final result = id == null
        ? await repo.addOpportunityTask(
            _opportunityId,
            title: text,
            dueAt: _fmtDue(due),
            priority: state.priority,
          )
        : await repo.updateOpportunityTask(
            _opportunityId,
            id,
            title: text,
            dueAt: _fmtDue(due),
            priority: state.priority,
            status: state.status,
          );
    state = state.copyWith(saving: false);

    return result.when(
      success: (_) {
        ref.invalidate(opportunityDetailBundleProvider(_opportunityId));
        return null;
      },
      failure: (error) => error.message,
    );
  }
}

/// Deletes a task from an opportunity (`DELETE /opportunities/{id}/tasks/{taskId}`),
/// keyed by opportunity id. The state is the id of the task currently being
/// deleted (`null` when idle), so the Tasks tab can show a spinner on just that
/// card. On success it refreshes the detail bundle so the task disappears.
@riverpod
class DeleteOpportunityTask extends _$DeleteOpportunityTask {
  late String _opportunityId;

  @override
  int? build(String opportunityId) {
    _opportunityId = opportunityId;
    return null;
  }

  /// Deletes [taskId]. Returns `null` on success, or an error message to show.
  Future<String?> delete(int taskId) async {
    if (state != null) return null; // a delete is already in flight

    state = taskId;
    final result = await ref
        .read(opportunitiesRepositoryProvider)
        .deleteOpportunityTask(_opportunityId, taskId);
    state = null;

    return result.when(
      success: (_) {
        ref.invalidate(opportunityDetailBundleProvider(_opportunityId));
        return null;
      },
      failure: (error) => error.message,
    );
  }
}
