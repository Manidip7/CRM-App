import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/followups_repository.dart';
import '../model/next_followup_model.dart';

/// State for the API-backed Next Follow-ups list: the loaded pages plus the
/// paginator info.
class FollowUpsApiState {
  final List<NextFollowUp> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  const FollowUpsApiState({
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
  });

  bool get hasMore => currentPage < lastPage;

  FollowUpsApiState copyWith({
    List<NextFollowUp>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) {
    return FollowUpsApiState(
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

/// Loads `GET /next-followups` page by page: replaces on page 1, appends on
/// later pages. The from/to date range is applied server-side via
/// `date_from` / `date_to`; changing it reloads from page 1.
class FollowUpsApi extends Notifier<FollowUpsApiState> {
  DateTime? _from;
  DateTime? _to;

  DateTime? get dateFrom => _from;
  DateTime? get dateTo => _to;

  @override
  FollowUpsApiState build() {
    Future.microtask(() => _load(1));
    return const FollowUpsApiState(isLoading: true);
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _load(int page) async {
    final result = await ref.read(followUpsRepositoryProvider).getNextFollowups(
          page: page,
          dateFrom: _from == null ? null : _fmt(_from!),
          dateTo: _to == null ? null : _fmt(_to!),
        );
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

  /// Reloads from page 1 keeping the current date range.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _load(1);
  }

  /// Replaces the server-side date range and reloads from page 1. Pass null for
  /// a bound to leave it open.
  void setDateRange({DateTime? from, DateTime? to}) {
    _from = from;
    _to = to;
    state = state.copyWith(isLoading: true, clearError: true);
    _load(1);
  }

  /// Clears both date bounds and reloads from page 1.
  void clearDates() => setDateRange(from: null, to: null);
}

final followUpsApiProvider =
    NotifierProvider<FollowUpsApi, FollowUpsApiState>(FollowUpsApi.new);
