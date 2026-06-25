import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_result.dart';
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
    return const OpportunitiesState(
        backlogItems: _backlogSeed, isLoading: true);
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

  /// Reloads from page 1.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    await _load(1);
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
  void toggleBacklog() => state = state.copyWith(
        showBacklog: !state.showBacklog,
        selectedStage: null,
        searchQuery: '',
      );

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

  // Backlog — stalled / overdue deals that have slipped and need attention.
  static const List<OpportunityModel> _backlogSeed = [
    OpportunityModel(
      id: 'B1',
      title: 'Acme Corp - Stalled Deal',
      contactName: 'Rohan Gupta',
      value: 52000,
      probability: 30,
      stage: OpportunityStage.negotiation,
      source: SourceType.facebook,
      timeAgo: '5w',
      nextFollowUp: 'Overdue by 5d',
      phone: '+91 99887 76655',
      avatarInitials: 'RG',
      avatarColor: Color(0xFFE53935),
    ),
    OpportunityModel(
      id: 'B2',
      title: 'NovaTech - No Response',
      contactName: 'Kavya Nair',
      value: 30000,
      probability: 20,
      stage: OpportunityStage.proposal,
      source: SourceType.website,
      timeAgo: '6w',
      nextFollowUp: 'Overdue by 8d',
      phone: '+91 88776 65544',
      avatarInitials: 'KN',
      avatarColor: Color(0xFF7B72E9),
    ),
    OpportunityModel(
      id: 'B3',
      title: 'Skyline Ventures - Cold',
      contactName: 'Aditya Rao',
      value: 88000,
      probability: 25,
      stage: OpportunityStage.qualified,
      source: SourceType.referral,
      timeAgo: '8w',
      nextFollowUp: 'Overdue by 12d',
      phone: '+91 77665 54433',
      avatarInitials: 'AR',
      avatarColor: Color(0xFF2DD4A0),
    ),
    OpportunityModel(
      id: 'B4',
      title: 'Pixel Labs - Reactivate',
      contactName: 'Meera Joshi',
      value: 21000,
      probability: 15,
      stage: OpportunityStage.proposal,
      source: SourceType.manual,
      timeAgo: '4w',
      nextFollowUp: 'Overdue by 3d',
      phone: '+91 66554 43322',
      avatarInitials: 'MJ',
      avatarColor: Color(0xFF26C6DA),
    ),
    OpportunityModel(
      id: 'B5',
      title: 'Quantum Soft - Dropped',
      contactName: 'Sahil Khan',
      value: 47000,
      probability: 10,
      stage: OpportunityStage.lost,
      source: SourceType.email,
      timeAgo: '9w',
      nextFollowUp: 'Overdue by 20d',
      phone: '+91 55443 32211',
      avatarInitials: 'SK',
      avatarColor: Color(0xFFAB47BC),
    ),
  ];
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
