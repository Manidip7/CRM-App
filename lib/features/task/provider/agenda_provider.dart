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
