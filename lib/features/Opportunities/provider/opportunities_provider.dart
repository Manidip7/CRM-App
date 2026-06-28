import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/opportunities_repository.dart';
import '../model/opportunity_model.dart';

part 'opportunities_provider.freezed.dart';
part 'opportunities_provider.g.dart';

@freezed
abstract class OpportunitiesState with _$OpportunitiesState {
  const factory OpportunitiesState({
    @Default(<OpportunityModel>[]) List<OpportunityModel> items,
    @Default(<OpportunityModel>[]) List<OpportunityModel> backlogItems,
    OpportunityStage? selectedStage,
    @Default('') String searchQuery,
    @Default('Newest first') String sortLabel,
    @Default(false) bool showBacklog,

    // Pagination / loading (API-backed pipeline list).
    @Default(1) int currentPage,
    @Default(1) int lastPage,
    @Default(0) int total,
    @Default(true) bool isLoading,
    @Default(false) bool isLoadingMore,
    Object? error,

    // Backlog list (API-backed, `category=backlog`).
    @Default(false) bool backlogLoading,
    @Default(false) bool backlogLoaded,
    Object? backlogError,
  }) = _OpportunitiesState;

  const OpportunitiesState._();

  bool get hasMore => currentPage < lastPage;
}

/// Kept alive so opportunities converted from leads survive navigation.
@Riverpod(keepAlive: true)
class Opportunities extends _$Opportunities {
  Timer? _searchDebounce;

  @override
  OpportunitiesState build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    // Kick off the first page after build returns, so `state` is initialized
    // before `_load` reads `searchQuery`.
    Future.microtask(() => _load(1));
    return const OpportunitiesState(isLoading: true);
  }

  /// Loads [page]: replaces the list on page 1, appends on later pages. The
  /// active search query is sent server-side.
  Future<void> _load(int page) async {
    final search = state.searchQuery.trim();
    final result =
        await ref.read(opportunitiesRepositoryProvider).getOpportunities(
              page: page,
              search: search.isEmpty ? null : search,
            );
    result.when(
      success: (data) {
        state = state.copyWith(
          items:
              page == 1 ? data.items : [...state.items, ...data.items],
          currentPage: data.currentPage,
          lastPage: data.lastPage,
          total: data.total,
          isLoading: false,
          isLoadingMore: false,
          error: null,
        );
      },
      failure: (e) {
        state = state.copyWith(
            isLoading: false, isLoadingMore: false, error: e);
      },
    );
  }

  /// Fetches and appends the next page. No-op while loading, on the last page,
  /// or while viewing the backlog.
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.showBacklog) return;
    state = state.copyWith(isLoadingMore: true);
    await _load(state.currentPage + 1);
  }

  /// Reloads from page 1 — or reloads the backlog when it is the active view.
  Future<void> refresh() async {
    if (state.showBacklog) {
      await _loadBacklog();
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    await _load(1);
  }

  /// GET /opportunities?category=backlog — overdue deals needing attention.
  Future<void> _loadBacklog() async {
    state = state.copyWith(backlogLoading: true, backlogError: null);
    final result =
        await ref.read(opportunitiesRepositoryProvider).getOpportunities(
              category: 'backlog',
            );
    result.when(
      success: (data) {
        state = state.copyWith(
          backlogItems: data.items,
          backlogLoading: false,
          backlogLoaded: true,
          backlogError: null,
        );
      },
      failure: (e) {
        state = state.copyWith(backlogLoading: false, backlogError: e);
      },
    );
  }

  void setStage(OpportunityStage? stage) =>
      state = state.copyWith(selectedStage: stage);

  /// Updates the search query and, for the API-backed pipeline, debounces a
  /// reload from page 1 with the server-side `search` param.
  void setSearch(String q) {
    state = state.copyWith(searchQuery: q);
    if (state.showBacklog) return; // backlog is sample data, filtered locally
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      state = state.copyWith(isLoading: true, items: const [], error: null);
      _load(1);
    });
  }

  /// Adds a freshly converted opportunity to the top of the active list.
  void addOpportunity(OpportunityModel opp) => state = state.copyWith(
        items: [opp, ...state.items],
        total: state.total + 1,
      );

  /// Switches between the live pipeline and the backlog, resetting filters.
  /// Lazily loads the backlog from the API the first time it is opened.
  void toggleBacklog() {
    final showBacklog = !state.showBacklog;
    state = state.copyWith(
      showBacklog: showBacklog,
      selectedStage: null,
      searchQuery: '',
    );
    if (showBacklog && !state.backlogLoaded && !state.backlogLoading) {
      _loadBacklog();
    }
  }

  /// Applies stage / probability edits made on the detail screen back onto the
  /// matching opportunity (in whichever list it lives).
  void updateOpportunity(
    String id, {
    OpportunityStage? stage,
    int? probability,
  }) {
    OpportunityModel patch(OpportunityModel o) => o.id == id
        ? o.copyWith(stage: stage, probability: probability)
        : o;
    state = state.copyWith(
      items: [for (final o in state.items) patch(o)],
      backlogItems: [for (final o in state.backlogItems) patch(o)],
    );
  }

  int countByStage(OpportunityStage s) {
    final list = state.showBacklog ? state.backlogItems : state.items;
    return list.where((o) => o.stage == s).length;
  }
}

/// Opportunities filtered by the selected stage. Text search is server-side for
/// the live pipeline; only the local backlog is searched client-side here.
@riverpod
List<OpportunityModel> filteredOpportunities(Ref ref) {
  final s = ref.watch(opportunitiesProvider);
  final source = s.showBacklog ? s.backlogItems : s.items;
  final query = s.searchQuery.toLowerCase();
  return source.where((o) {
    final matchesSearch = !s.showBacklog ||
        query.isEmpty ||
        o.title.toLowerCase().contains(query) ||
        o.contactName.toLowerCase().contains(query) ||
        o.phone.contains(query);
    final matchesStage =
        s.selectedStage == null || o.stage == s.selectedStage;
    return matchesSearch && matchesStage;
  }).toList();
}
