import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/TaskStatus.dart';

part 'task_provider.freezed.dart';
part 'task_provider.g.dart';

@freezed
abstract class TaskListState with _$TaskListState {
  const factory TaskListState({
    @Default(0) int selectedTab, // 0 = My Tasks, 1 = Team View
    @Default(<TaskModel>[]) List<TaskModel> tasks,
  }) = _TaskListState;
}

@riverpod
class TaskList extends _$TaskList {
  @override
  TaskListState build() => TaskListState(tasks: TaskModel.sampleTasks());

  void selectTab(int index) => state = state.copyWith(selectedTab: index);

  void markComplete(TaskModel task) => state = state.copyWith(
        tasks: [
          for (final t in state.tasks)
            if (t.id == task.id)
              t.copyWith(status: TaskStatus.completed)
            else
              t,
        ],
      );

  void deleteTask(TaskModel task) => state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != task.id).toList(),
      );
}
