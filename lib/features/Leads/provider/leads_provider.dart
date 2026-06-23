import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_result.dart';
import '../data/leads_repository.dart';
import '../model/lead_model.dart';

part 'leads_provider.freezed.dart';
part 'leads_provider.g.dart';

@freezed
abstract class LeadsFilterState with _$LeadsFilterState {
  const factory LeadsFilterState({
    @Default('') String searchQuery,
    LeadStatus? filterStatus,
    LeadSource? filterSource,
    @Default(false) bool showBacklog,

    /// Server-side date range filter (`from_date` / `to_date`).
    DateTime? fromDate,
    DateTime? toDate,
  }) = _LeadsFilterState;

  const LeadsFilterState._();

  /// `true` when any server-side date filter is active.
  bool get hasDateFilter => fromDate != null || toDate != null;
}

@riverpod
class LeadsFilter extends _$LeadsFilter {
  @override
  LeadsFilterState build() => const LeadsFilterState();

  void setSearch(String q) => state = state.copyWith(searchQuery: q);

  void clearSearch() => state = state.copyWith(searchQuery: '');

  void clearFilters() =>
      state = state.copyWith(filterStatus: null, filterSource: null);

  void toggleStatus(LeadStatus s) => state = state.copyWith(
        filterStatus: state.filterStatus == s ? null : s,
      );

  void toggleSource(LeadSource s) => state = state.copyWith(
        filterSource: state.filterSource == s ? null : s,
      );

  /// Sets the server-side date range. Pass null to clear a bound.
  void setDateRange({DateTime? from, DateTime? to}) =>
      state = state.copyWith(fromDate: from, toDate: to);

  void clearDateRange() =>
      state = state.copyWith(fromDate: null, toDate: null);


  void toggleBacklog() =>
      state = LeadsFilterState(showBacklog: !state.showBacklog);
}

@freezed
abstract class LeadsPagination with _$LeadsPagination {
  const factory LeadsPagination({
    @Default(1) int currentPage,
    @Default(1) int lastPage,
    @Default(0) int total,
    @Default(false) bool isLoadingMore,
  }) = _LeadsPagination;

  const LeadsPagination._();

  bool get hasMore => currentPage < lastPage;
}

@riverpod
class LeadsPaginationState extends _$LeadsPaginationState {
  @override
  LeadsPagination build() => const LeadsPagination();

  void setFromPage(LeadsPage page) => state = state.copyWith(
        currentPage: page.currentPage,
        lastPage: page.lastPage,
        total: page.total,
      );

  void setLoadingMore(bool value) =>
      state = state.copyWith(isLoadingMore: value);
}

/// The server-side query bits (search + date range) as a record. Record
/// equality means [LeadsList] only refetches when one of these changes — not
/// when the client-side status/source chips toggle.
@riverpod
(String, DateTime?, DateTime?) leadsServerQuery(Ref ref) {
  final f = ref.watch(leadsFilterProvider);
  return (f.searchQuery, f.fromDate, f.toDate);
}


@riverpod
class LeadsList extends _$LeadsList {
  LeadsPaginationState get _pagination =>
      ref.read(leadsPaginationStateProvider.notifier);

  // Active query, captured from the filter on each build so loadMore reuses it.
  String? _search;
  String? _fromDate;
  String? _toDate;

  @override
  Future<List<LeadModel>> build() async {
    // Re-fetch from page 1 whenever the search text or date range changes
    // (record equality means status/source chip toggles don't refetch).
    final query = ref.watch(leadsServerQueryProvider);
    _search = query.$1.trim().isEmpty ? null : query.$1.trim();
    _fromDate = _fmtDate(query.$2);
    _toDate = _fmtDate(query.$3);

    final page = await _fetch(1);
    _pagination.setFromPage(page);
    return page.leads;
  }

  Future<LeadsPage> _fetch(int page) async {
    final result = await ref.read(leadsRepositoryProvider).getLeads(
          page: page,
          search: _search,
          fromDate: _fromDate,
          toDate: _toDate,
        );
    return switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw error,
    };
  }

  /// Formats a date as `yyyy-MM-dd` for the API, or null.
  static String? _fmtDate(DateTime? d) {
    if (d == null) return null;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// Fetches the next page and appends it to the current list. No-op while a
  /// load is already running or when the last page has been reached.
  Future<void> loadMore() async {
    final meta = ref.read(leadsPaginationStateProvider);
    if (meta.isLoadingMore || !meta.hasMore) return;

    final current = state.value ?? const <LeadModel>[];
    _pagination.setLoadingMore(true);
    try {
      final next = await _fetch(meta.currentPage + 1);
      _pagination.setFromPage(next);
      state = AsyncData([...current, ...next.leads]);
    } catch (_) {
      // Keep the already-loaded leads; the next scroll will retry.
    } finally {
      _pagination.setLoadingMore(false);
    }
  }

  /// Reloads from page 1.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final page = await _fetch(1);
      _pagination.setFromPage(page);
      return page.leads;
    });
  }
}

/// Base data set — swaps between normal (API) leads and backlog (sample) leads.
@riverpod
List<LeadModel> leadsSource(Ref ref) {
  final showBacklog = ref.watch(leadsFilterProvider).showBacklog;
  if (showBacklog) return LeadModel.backlogLeads();
  return ref.watch(leadsListProvider).value ?? const [];
}

/// The source list with the active search query + status/source filters applied.
@riverpod
List<LeadModel> filteredLeads(Ref ref) {
  final all = ref.watch(leadsSourceProvider);
  final f = ref.watch(leadsFilterProvider);
  final q = f.searchQuery.toLowerCase();
  return all.where((lead) {
    final matchSearch = !f.showBacklog ||
        q.isEmpty ||
        lead.title.toLowerCase().contains(q) ||
        lead.contactName.toLowerCase().contains(q) ||
        (lead.companyName?.toLowerCase().contains(q) ?? false) ||
        (lead.phone?.contains(q) ?? false) ||
        (lead.email?.toLowerCase().contains(q) ?? false);
    final matchStatus = f.filterStatus == null || lead.status == f.filterStatus;
    final matchSource = f.filterSource == null || lead.source == f.filterSource;
    return matchSearch && matchStatus && matchSource;
  }).toList();
}
