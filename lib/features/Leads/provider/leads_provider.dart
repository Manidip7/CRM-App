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

    /// Server-side `quick_filter` values (today / upcoming / overdue /
    /// my_leads). Multiple can be active at once.
    @Default(<String>{}) Set<String> quickFilters,
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

  void clearFilters() => state = state.copyWith(
        filterStatus: null,
        filterSource: null,
        quickFilters: const <String>{},
      );

  void toggleStatus(LeadStatus s) => state = state.copyWith(
        filterStatus: state.filterStatus == s ? null : s,
      );

  void toggleSource(LeadSource s) => state = state.copyWith(
        filterSource: state.filterSource == s ? null : s,
      );

  /// Adds/removes a `quick_filter` value (today / upcoming / overdue /
  /// my_leads). Multiple may be active simultaneously.
  void toggleQuickFilter(String value) {
    final next = Set<String>.from(state.quickFilters);
    if (!next.remove(value)) next.add(value);
    state = state.copyWith(quickFilters: next);
  }

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

/// Pagination metadata for the live list. Kept alive (like
/// [LeadsBacklogPagination]) because the backlog toggle drops every listener on
/// this provider while the backlog view is active — an auto-disposed instance
/// would reset `total` to 0 and, since [LeadsList] itself stays alive and does
/// not refetch, nothing would ever set it again on the way back.
@Riverpod(keepAlive: true)
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

/// The server-side query bits (search, status_id, source, quick_filter and
/// date range) as a record. Record equality means [LeadsList] only refetches
/// when one of these actually changes. The quick filters are joined into a
/// stable, sorted string because two `Set` instances with the same elements are
/// not `==` to each other (which would otherwise refetch on every rebuild).
@riverpod
({
  String search,
  int? statusId,
  String? source,
  String quickFilters,
  DateTime? fromDate,
  DateTime? toDate,
}) leadsServerQuery(Ref ref) {
  final f = ref.watch(leadsFilterProvider);
  return (
    search: f.searchQuery,
    statusId: f.filterStatus?.statusId,
    source: f.filterSource?.apiValue,
    quickFilters: (f.quickFilters.toList()..sort()).join(','),
    fromDate: f.fromDate,
    toDate: f.toDate,
  );
}


@riverpod
class LeadsList extends _$LeadsList {
  LeadsPaginationState get _pagination =>
      ref.read(leadsPaginationStateProvider.notifier);

  // Active query, captured from the filter on each build so loadMore reuses it.
  String? _search;
  int? _statusId;
  String? _source;
  List<String>? _quickFilters;
  String? _fromDate;
  String? _toDate;

  @override
  Future<List<LeadModel>> build() async {
    // Re-fetch from page 1 whenever any server-side filter changes (search,
    // status_id, source, quick_filter or date range).
    final query = ref.watch(leadsServerQueryProvider);
    _search = query.search.trim().isEmpty ? null : query.search.trim();
    _statusId = query.statusId;
    _source = query.source;
    _quickFilters =
        query.quickFilters.isEmpty ? null : query.quickFilters.split(',');
    _fromDate = _fmtDate(query.fromDate);
    _toDate = _fmtDate(query.toDate);

    final page = await _fetch(1);
    _pagination.setFromPage(page);
    return page.leads;
  }

  Future<LeadsPage> _fetch(int page) async {
    final result = await ref.read(leadsRepositoryProvider).getLeads(
          page: page,
          search: _search,
          statusId: _statusId,
          source: _source,
          quickFilters: _quickFilters,
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

  /// Patches a single loaded lead's priority in place (no refetch), so a
  /// temperature change on the detail screen is reflected when returning to the
  /// list — and re-seeds the detail screen correctly on re-entry.
  void updatePriority(String id, String? priority) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final lead in current)
        lead.id == id ? lead.copyWithPriority(priority) : lead,
    ]);
  }

  /// Replaces a single loaded lead in place (no refetch), so an edit made on the
  /// detail screen shows on the list when navigating back.
  void replaceLead(LeadModel updated) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final lead in current) lead.id == updated.id ? updated : lead,
    ]);
  }

  /// Patches a single loaded lead's follow-up fields in place (no refetch), so a
  /// newly scheduled follow-up shows on the list (and re-seeds the detail
  /// screen) immediately, without waiting for a reload.
  void updateFollowUp(
    String id, {
    DateTime? nextFollowUp,
    String? currentUpdate,
    String? nextAction,
    String? followupRemarks,
    int? currentUpdateId,
    int? nextActionId,
    int? interestScore,
  }) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final lead in current)
        lead.id == id
            ? lead.copyWithFollowUp(
                nextFollowUp: nextFollowUp,
                currentUpdate: currentUpdate,
                nextAction: nextAction,
                followupRemarks: followupRemarks,
                currentUpdateId: currentUpdateId,
                nextActionId: nextActionId,
                interestScore: interestScore,
              )
            : lead,
    ]);
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

/// Pagination metadata for the backlog list — a separate instance from the live
/// list's [LeadsPaginationState] so the two views keep independent page cursors.
@Riverpod(keepAlive: true)
class LeadsBacklogPagination extends _$LeadsBacklogPagination {
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

/// The backlog leads — overdue leads needing follow-up (GET
/// /leads?quick_filter=backlog), paginated by scroll exactly like the live list.
/// Cached for the session; pull-to-refresh (or a Retry) reloads from page 1.
@Riverpod(keepAlive: true)
class LeadsBacklog extends _$LeadsBacklog {
  LeadsBacklogPagination get _pagination =>
      ref.read(leadsBacklogPaginationProvider.notifier);

  @override
  Future<List<LeadModel>> build() async {
    final page = await _fetch(1);
    _pagination.setFromPage(page);
    return page.leads;
  }

  Future<LeadsPage> _fetch(int page) async {
    final result = await ref.read(leadsRepositoryProvider).getLeads(
          page: page,
          quickFilters: const ['backlog'],
        );
    return switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw error,
    };
  }

  /// Fetches the next page and appends it. No-op while a load is running or the
  /// last page has been reached.
  Future<void> loadMore() async {
    final meta = ref.read(leadsBacklogPaginationProvider);
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

/// Base data set — swaps between the live (API) leads and the backlog leads.
/// Both are API-backed; the backlog is its own cached list so switching views
/// never disturbs the live pipeline (mirrors the Opportunities screen).
@riverpod
List<LeadModel> leadsSource(Ref ref) {
  final showBacklog = ref.watch(leadsFilterProvider).showBacklog;
  if (showBacklog) {
    return ref.watch(leadsBacklogProvider).value ?? const [];
  }
  return ref.watch(leadsListProvider).value ?? const [];
}

/// The source list with the active search + status/source filters applied.
/// For the live list, search runs server-side; the backlog list is searched
/// client-side here (mirrors the Opportunities screen).
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

/// The lead-source options for the Add-Lead dropdown (`GET /lead-sources`).
/// Cached for the session; the form watches this to populate the dropdown.
@riverpod
Future<List<LeadSourceOption>> leadSources(Ref ref) async {
  final result = await ref.watch(leadsRepositoryProvider).getLeadSources();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
}

/// The "Current Update" options for the Schedule Follow-up popup
/// (`GET /current-updates`). Cached for the session.
@riverpod
Future<List<NamedLookup>> currentUpdates(Ref ref) async {
  final result = await ref.watch(leadsRepositoryProvider).getCurrentUpdates();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
}

/// The "Next Action" options for the Schedule Follow-up popup
/// (`GET /next-actions`). Cached for the session.
@riverpod
Future<List<NamedLookup>> nextActions(Ref ref) async {
  final result = await ref.watch(leadsRepositoryProvider).getNextActions();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
}

/// The lead status options (`GET /statuses`) for the detail header chip/menu.
/// Cached for the session.
@riverpod
Future<List<StatusOption>> leadStatuses(Ref ref) async {
  final result = await ref.watch(leadsRepositoryProvider).getStatuses();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
}
