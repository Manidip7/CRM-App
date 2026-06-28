import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/task_repository.dart';
import '../model/task_item_model.dart';

/// State for the API-backed Task List: the loaded pages plus paginator info.
class TaskListApiState {
  final List<TaskItem> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  const TaskListApiState({
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
  });

  bool get hasMore => currentPage < lastPage;

  TaskListApiState copyWith({
    List<TaskItem>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) {
    return TaskListApiState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Loads `GET /tasks` page by page: replaces on page 1, appends on later pages.
/// A non-empty [_search] is sent to the server as `?search=` (e.g. `Abhijit`).
class TaskListApi extends Notifier<TaskListApiState> {
  String _search = '';
  Timer? _debounce;

  @override
  TaskListApiState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(() => _load(1));
    return const TaskListApiState(isLoading: true);
  }

  Future<void> _load(int page) async {
    final result = await ref
        .read(taskRepositoryProvider)
        .getTasks(page: page, search: _search);
    result.when(
      success: (data) {
        state = state.copyWith(
          items: page == 1 ? data.items : [...state.items, ...data.items],
          currentPage: data.currentPage,
          lastPage: data.lastPage,
          total: data.total,
          isLoading: false,
          isLoadingMore: false,
          clearError: true,
        );
      },
      failure: (e) {
        state = state.copyWith(
            isLoading: false, isLoadingMore: false, error: e);
      },
    );
  }

  /// Fetches and appends the next page. No-op while loading or on the last page.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    await _load(state.currentPage + 1);
  }

  /// Reloads from page 1.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _load(1);
  }

  /// Debounced server-side search. Updates `?search=` and reloads from page 1.
  void setSearch(String query) {
    final next = query.trim();
    if (next == _search) return;
    _search = next;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      state = state.copyWith(isLoading: true, clearError: true);
      _load(1);
    });
  }
}

final taskListApiProvider =
    NotifierProvider<TaskListApi, TaskListApiState>(TaskListApi.new);
