import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_result.dart';
import '../data/leads_repository.dart';
import '../model/lead_model.dart';

part 'leads_provider.freezed.dart';
part 'leads_provider.g.dart';

/// The presets behind the advanced filter's "All Time" dropdown.
///
/// Each one resolves to a concrete `from_date` / `to_date` pair the moment the
/// user applies it — the resolved dates are what gets stored, so the active
/// query can't silently change underneath the list when the clock rolls past
/// midnight. [custom] is the escape hatch: the user picks both bounds by hand.
enum LeadDateRange {
  allTime('All Time'),
  today('Today'),
  yesterday('Yesterday'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  lastMonth('Last Month'),
  thisYear('This Year'),
  custom('Custom Range');

  final String label;

  const LeadDateRange(this.label);

  /// The `(from, to)` bounds for this preset, relative to [now]. Both are
  /// `null` for [allTime] and [custom] — custom carries its own dates.
  (DateTime?, DateTime?) resolve(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      LeadDateRange.allTime || LeadDateRange.custom => (null, null),
      LeadDateRange.today => (today, today),
      LeadDateRange.yesterday => () {
          final d = today.subtract(const Duration(days: 1));
          return (d, d);
        }(),
      // Dart's weekday is 1=Mon…7=Sun, so this starts the week on Monday.
      LeadDateRange.thisWeek => (
          today.subtract(Duration(days: today.weekday - 1)),
          today,
        ),
      LeadDateRange.thisMonth => (DateTime(now.year, now.month, 1), today),
      LeadDateRange.lastMonth => (
          DateTime(now.year, now.month - 1, 1),
          // Day 0 of this month is the last day of the previous one.
          DateTime(now.year, now.month, 0),
        ),
      LeadDateRange.thisYear => (DateTime(now.year, 1, 1), today),
    };
  }
}

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

    // ── Advanced filter (the dropdowns behind the tune button) ──────────────
    // Each maps to one query param on `GET /leads`. `null` means "All …" and
    // the param is left off the request entirely.

    /// `status_id` — takes precedence over the [filterStatus] chip.
    int? statusId,

    /// `lead_source_id`.
    int? leadSourceId,

    /// `lead_type_id`.
    int? leadTypeId,

    /// `territory_id`.
    int? territoryId,

    /// `assigned_to`.
    int? assignedTo,

    /// Which preset the "All Time" dropdown is showing. The dates it resolved
    /// to live in [fromDate] / [toDate].
    @Default(LeadDateRange.allTime) LeadDateRange dateRange,
  }) = _LeadsFilterState;

  const LeadsFilterState._();

  /// `true` when any server-side date filter is active.
  bool get hasDateFilter => fromDate != null || toDate != null;

  /// How many advanced dropdowns are currently narrowing the list. Drives the
  /// badge on the filter button.
  int get advancedFilterCount => [
        statusId,
        leadSourceId,
        leadTypeId,
        territoryId,
        assignedTo,
        dateRange == LeadDateRange.allTime ? null : dateRange,
      ].where((v) => v != null).length;

  bool get hasAdvancedFilters => advancedFilterCount > 0;
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
        // The chips and the advanced dropdown drive the same `status_id`, so
        // tapping a chip takes over from whatever the dropdown had selected.
        statusId: null,
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

  void clearDateRange() => state = state.copyWith(
        fromDate: null,
        toDate: null,
        dateRange: LeadDateRange.allTime,
      );

  /// Applies every advanced dropdown in one go, so the list refetches once
  /// rather than once per dropdown as the user works through the sheet.
  ///
  /// A `null` argument means "All …" and clears that filter — which is why
  /// this takes the whole set rather than patching one field at a time.
  void applyAdvanced({
    int? statusId,
    int? leadSourceId,
    int? leadTypeId,
    int? territoryId,
    int? assignedTo,
    required LeadDateRange dateRange,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    // A preset resolves to concrete bounds now; `custom` keeps what the user
    // picked by hand.
    final (presetFrom, presetTo) = dateRange.resolve(DateTime.now());
    final from = dateRange == LeadDateRange.custom ? fromDate : presetFrom;
    final to = dateRange == LeadDateRange.custom ? toDate : presetTo;

    state = state.copyWith(
      statusId: statusId,
      leadSourceId: leadSourceId,
      leadTypeId: leadTypeId,
      territoryId: territoryId,
      assignedTo: assignedTo,
      dateRange: dateRange,
      fromDate: from,
      toDate: to,
      // The chip and the dropdown share `status_id`; the dropdown wins.
      filterStatus: statusId != null ? null : state.filterStatus,
    );
  }

  /// Resets every advanced dropdown back to "All …" — leaves the search box
  /// and the quick-filter chips alone.
  void clearAdvanced() => state = state.copyWith(
        statusId: null,
        leadSourceId: null,
        leadTypeId: null,
        territoryId: null,
        assignedTo: null,
        dateRange: LeadDateRange.allTime,
        fromDate: null,
        toDate: null,
      );

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
  int? leadSourceId,
  int? leadTypeId,
  int? territoryId,
  int? assignedTo,
}) leadsServerQuery(Ref ref) {
  final f = ref.watch(leadsFilterProvider);
  return (
    search: f.searchQuery,
    // The advanced dropdown and the status chip both feed `status_id`; the
    // dropdown is the explicit choice, so it wins.
    statusId: f.statusId ?? f.filterStatus?.statusId,
    source: f.filterSource?.apiValue,
    quickFilters: (f.quickFilters.toList()..sort()).join(','),
    fromDate: f.fromDate,
    toDate: f.toDate,
    leadSourceId: f.leadSourceId,
    leadTypeId: f.leadTypeId,
    territoryId: f.territoryId,
    assignedTo: f.assignedTo,
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
  int? _leadSourceId;
  int? _leadTypeId;
  int? _territoryId;
  int? _assignedTo;

  @override
  Future<List<LeadModel>> build() async {
    // Re-fetch from page 1 whenever any server-side filter changes (search,
    // status_id, source, quick_filter, date range or an advanced dropdown).
    final query = ref.watch(leadsServerQueryProvider);
    _search = query.search.trim().isEmpty ? null : query.search.trim();
    _statusId = query.statusId;
    _source = query.source;
    _quickFilters =
        query.quickFilters.isEmpty ? null : query.quickFilters.split(',');
    _fromDate = _fmtDate(query.fromDate);
    _toDate = _fmtDate(query.toDate);
    _leadSourceId = query.leadSourceId;
    _leadTypeId = query.leadTypeId;
    _territoryId = query.territoryId;
    _assignedTo = query.assignedTo;

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
          leadSourceId: _leadSourceId,
          leadTypeId: _leadTypeId,
          territoryId: _territoryId,
          assignedTo: _assignedTo,
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
