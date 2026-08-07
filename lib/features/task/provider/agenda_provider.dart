import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../data/task_repository.dart';
import '../model/agenda_model.dart';

/// Which agenda view is selected: `my` (My Tasks) or `team` (Team View).
class AgendaView extends Notifier<String> {
  @override
  String build() => 'my';

  void set(String view) => state = view;
}

final agendaViewProvider =
    NotifierProvider<AgendaView, String>(AgendaView.new);

/// Loads the agenda bundle from `GET /agenda?view=...`, keyed by the view.
final agendaProvider =
    FutureProvider.autoDispose.family<AgendaBundle, String>((ref, view) async {
  final result = await ref.watch(taskRepositoryProvider).getAgenda(view);
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});

/// Deletes an agenda task (`DELETE /tasks/{id}`). The state is the id of the
/// task currently being deleted (`null` when idle), so the agenda can show a
/// spinner on just that card. On success it invalidates every agenda view (My
/// Tasks / Team View) so the task disappears wherever it was listed.
class DeleteTask extends Notifier<int?> {
  @override
  int? build() => null;

  /// Deletes [taskId]. Returns `null` on success, or an error message to show.
  Future<String?> delete(int taskId) async {
    if (state != null) return null; // a delete is already in flight

    state = taskId;
    final result = await ref.read(taskRepositoryProvider).deleteTask(taskId);
    state = null;

    return result.when(
      success: (_) {
        ref.invalidate(agendaProvider);
        return null;
      },
      failure: (error) => error.message,
    );
  }
}

final deleteTaskProvider =
    NotifierProvider<DeleteTask, int?>(DeleteTask.new);

/// Marks an agenda task complete (`PUT /tasks/{id}/mark-done`). The state is
/// the id of the task currently being marked (`null` when idle), so the agenda
/// can show a spinner on just that card. On success it invalidates every agenda
/// view so the task moves into the Completed bucket.
class MarkTaskDone extends Notifier<int?> {
  @override
  int? build() => null;

  /// Marks [taskId] done. Returns `null` on success, or an error message.
  Future<String?> markDone(int taskId) async {
    if (state != null) return null; // already marking one

    state = taskId;
    final result = await ref.read(taskRepositoryProvider).markTaskDone(taskId);
    state = null;

    return result.when(
      success: (_) {
        ref.invalidate(agendaProvider);
        return null;
      },
      failure: (error) => error.message,
    );
  }
}

final markTaskDoneProvider =
    NotifierProvider<MarkTaskDone, int?>(MarkTaskDone.new);
