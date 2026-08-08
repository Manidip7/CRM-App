import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/leads_repository.dart';
import '../model/lead_model.dart';
import 'leads_provider.dart';

/// The field a bulk update writes to every selected lead — plus [delete],
/// which removes them instead.
///
/// [apiField] is what goes in the `update_field` key of the
/// `POST /leads/bulk-action` body; [label] is what the dropdown shows.
enum BulkUpdateField {
  status('Status', 'status_id'),
  priority('Priority', 'priority'),
  leadSource('Lead Source', 'lead_source_id'),
  leadType('Lead Type', 'lead_type_id'),
  territory('Territory', 'territory_id'),
  branch('Branch', 'branch_id'),
  assignee('Assignee', 'assigned_to'),
  delete('Delete Leads', 'delete');

  final String label;
  final String apiField;

  const BulkUpdateField(this.label, this.apiField);

  /// Whether picking this option destroys data rather than editing it — the
  /// popup turns red and asks for a confirmation before running it.
  bool get isDestructive => this == BulkUpdateField.delete;
}

/// Priority (temperature) values the backend accepts on `POST /leads/{id}/priority`.
const kBulkPriorities = <String>['hot', 'warm', 'cold'];

/// 'hot' → 'Hot'.
String bulkPriorityLabel(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

// ─────────────────────────────────────────────────────────────────────────────
//  List + filters
// ─────────────────────────────────────────────────────────────────────────────

/// Stands in for "argument not given" in [BulkLeadsFilters.copyWith], so that a
/// real `null` can mean "clear this filter back to All …" — something a plain
/// optional parameter can't express, since it uses null for both.
const Object _unset = Object();

/// Everything the Bulk Action screen's filter panel can narrow by. Each field
/// maps to one key in the `POST /leads/filter` body.
class BulkLeadsFilters {
  final String search;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int? leadSourceId;
  final int? statusId;
  final String? priority;
  final int? assigneeId;
  final int? leadTypeId;
  final int? territoryId;
  final int? branchId;

  const BulkLeadsFilters({
    this.search = '',
    this.fromDate,
    this.toDate,
    this.leadSourceId,
    this.statusId,
    this.priority,
    this.assigneeId,
    this.leadTypeId,
    this.territoryId,
    this.branchId,
  });

  /// How many filters are narrowing the list — drives the badge on the filter
  /// toggle. Search has its own visible field, so it isn't counted.
  int get activeCount => [
    fromDate,
    toDate,
    leadSourceId,
    statusId,
    priority,
    assigneeId,
    leadTypeId,
    territoryId,
    branchId,
  ].where((v) => v != null).length;

  /// The dates as the API wants them (`yyyy-MM-dd`), or null when unset.
  String? get fromDateApi => _formatDate(fromDate);
  String? get toDateApi => _formatDate(toDate);

  static String? _formatDate(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';

  /// Passing a value sets it, passing `null` clears it, omitting it keeps it.
  BulkLeadsFilters copyWith({
    String? search,
    Object? fromDate = _unset,
    Object? toDate = _unset,
    Object? leadSourceId = _unset,
    Object? statusId = _unset,
    Object? priority = _unset,
    Object? assigneeId = _unset,
    Object? leadTypeId = _unset,
    Object? territoryId = _unset,
    Object? branchId = _unset,
  }) {
    return BulkLeadsFilters(
      search: search ?? this.search,
      fromDate: identical(fromDate, _unset)
          ? this.fromDate
          : fromDate as DateTime?,
      toDate: identical(toDate, _unset) ? this.toDate : toDate as DateTime?,
      leadSourceId: identical(leadSourceId, _unset)
          ? this.leadSourceId
          : leadSourceId as int?,
      statusId: identical(statusId, _unset) ? this.statusId : statusId as int?,
      priority: identical(priority, _unset)
          ? this.priority
          : priority as String?,
      assigneeId: identical(assigneeId, _unset)
          ? this.assigneeId
          : assigneeId as int?,
      leadTypeId: identical(leadTypeId, _unset)
          ? this.leadTypeId
          : leadTypeId as int?,
      territoryId: identical(territoryId, _unset)
          ? this.territoryId
          : territoryId as int?,
      branchId: identical(branchId, _unset) ? this.branchId : branchId as int?,
    );
  }

  /// Clears every dropdown/date back to "All …", leaving the search box alone.
  BulkLeadsFilters cleared() => BulkLeadsFilters(search: search);
}

/// The Bulk Action screen's own slice of the leads list — deliberately separate
/// from [leadsListProvider] so filtering here never disturbs the Leads screen.
class BulkLeadsState {
  final List<LeadModel> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;
  final BulkLeadsFilters filters;

  const BulkLeadsState({
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
    this.filters = const BulkLeadsFilters(),
  });

  bool get hasMore => currentPage < lastPage;

  int get activeFilterCount => filters.activeCount;

  BulkLeadsState copyWith({
    List<LeadModel>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
    BulkLeadsFilters? filters,
  }) {
    return BulkLeadsState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
    );
  }
}

/// Loads `POST /leads/filter` page by page for the Bulk Action screen: replaces
/// on page 1, appends on later pages. Any filter change clears the current
/// selection — keeping rows selected that the user can no longer see would make
/// the "N selected" count lie about what Apply is going to touch.
class BulkLeads extends Notifier<BulkLeadsState> {
  Timer? _debounce;

  @override
  BulkLeadsState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(() => _load(1));
    return const BulkLeadsState();
  }

  Future<void> _load(int page) async {
    final f = state.filters;
    final result = await ref
        .read(leadsRepositoryProvider)
        .filterLeads(
          page: page,
          search: f.search.trim().isEmpty ? null : f.search.trim(),
          fromDate: f.fromDateApi,
          toDate: f.toDateApi,
          leadSourceId: f.leadSourceId,
          statusId: f.statusId,
          priority: f.priority,
          assigneeId: f.assigneeId,
          leadTypeId: f.leadTypeId,
          territoryId: f.territoryId,
          branchId: f.branchId,
        );
    result.when(
      success: (data) {
        state = state.copyWith(
          items: page == 1 ? data.leads : [...state.items, ...data.leads],
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
          isLoading: false,
          isLoadingMore: false,
          error: e,
        );
      },
    );
  }

  /// Fetches and appends the next page. No-op while loading or on the last page.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    await _load(state.currentPage + 1);
  }

  /// Reloads from page 1, keeping the current filters and selection.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _load(1);
  }

  /// Debounced server-side search.
  void setSearch(String query) {
    if (query == state.filters.search) return;
    state = state.copyWith(filters: state.filters.copyWith(search: query));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(bulkSelectionProvider.notifier).clear();
      state = state.copyWith(isLoading: true, clearError: true);
      _load(1);
    });
  }

  /// Swaps in a new filter set and refetches from page 1. Build it off
  /// `state.filters` with `copyWith`, where `null` means "All …".
  void applyFilters(BulkLeadsFilters filters) {
    state = state.copyWith(
      filters: filters,
      isLoading: true,
      clearError: true,
    );
    ref.read(bulkSelectionProvider.notifier).clear();
    _load(1);
  }

  /// Resets every dropdown and date back to "All …"; leaves the search box alone.
  void clearFilters() => applyFilters(state.filters.cleared());
}

final bulkLeadsProvider = NotifierProvider<BulkLeads, BulkLeadsState>(
  BulkLeads.new,
);

/// Whether the filter dropdowns are expanded on the Bulk Action screen.
class BulkFiltersExpanded extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final bulkFiltersExpandedProvider = NotifierProvider<BulkFiltersExpanded, bool>(
  BulkFiltersExpanded.new,
);

// ─────────────────────────────────────────────────────────────────────────────
//  Selection
// ─────────────────────────────────────────────────────────────────────────────

/// Ids of the leads ticked on the Bulk Action screen.
class BulkSelection extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  void toggle(String id) {
    final next = Set<String>.from(state);
    if (!next.remove(id)) next.add(id);
    state = next;
  }

  /// Ticks every [ids] — or unticks them all when they are already selected.
  void toggleAll(List<String> ids) {
    final allSelected = ids.isNotEmpty && ids.every(state.contains);
    if (allSelected) {
      final next = Set<String>.from(state)..removeAll(ids);
      state = next;
    } else {
      state = {...state, ...ids};
    }
  }

  void clear() => state = const <String>{};
}

final bulkSelectionProvider = NotifierProvider<BulkSelection, Set<String>>(
  BulkSelection.new,
);

// ─────────────────────────────────────────────────────────────────────────────
//  Applying the update
// ─────────────────────────────────────────────────────────────────────────────

/// What the Bulk Update popup's two dropdowns currently hold. Only the value
/// belonging to the chosen [field] is meaningful; picking a different field
/// clears it, since a status id is not a valid priority.
class BulkUpdateDraft {
  final BulkUpdateField? field;
  final int? statusId;
  final String? priority;
  final int? leadSourceId;
  final int? leadTypeId;
  final int? territoryId;
  final int? branchId;
  final int? assigneeId;

  const BulkUpdateDraft({
    this.field,
    this.statusId,
    this.priority,
    this.leadSourceId,
    this.leadTypeId,
    this.territoryId,
    this.branchId,
    this.assigneeId,
  });

  /// Whether both dropdowns are filled in, i.e. Apply Update can run. Delete
  /// takes no value, so choosing it is enough on its own.
  bool get isReady => switch (field) {
    null => false,
    BulkUpdateField.status => statusId != null,
    BulkUpdateField.priority => priority != null,
    BulkUpdateField.leadSource => leadSourceId != null,
    BulkUpdateField.leadType => leadTypeId != null,
    BulkUpdateField.territory => territoryId != null,
    BulkUpdateField.branch => branchId != null,
    BulkUpdateField.assignee => assigneeId != null,
    BulkUpdateField.delete => true,
  };
}

class BulkUpdateDraftNotifier extends Notifier<BulkUpdateDraft> {
  @override
  BulkUpdateDraft build() => const BulkUpdateDraft();

  void reset() => state = const BulkUpdateDraft();

  /// Switching the field drops whatever value was picked for the previous one.
  void setField(BulkUpdateField field) => state = BulkUpdateDraft(field: field);

  void setStatus(int id) =>
      state = BulkUpdateDraft(field: state.field, statusId: id);

  void setPriority(String value) =>
      state = BulkUpdateDraft(field: state.field, priority: value);

  void setLeadSource(int id) =>
      state = BulkUpdateDraft(field: state.field, leadSourceId: id);

  void setLeadType(int id) =>
      state = BulkUpdateDraft(field: state.field, leadTypeId: id);

  void setTerritory(int id) =>
      state = BulkUpdateDraft(field: state.field, territoryId: id);

  void setBranch(int id) =>
      state = BulkUpdateDraft(field: state.field, branchId: id);

  void setAssignee(int id) =>
      state = BulkUpdateDraft(field: state.field, assigneeId: id);
}

final bulkUpdateDraftProvider =
    NotifierProvider<BulkUpdateDraftNotifier, BulkUpdateDraft>(
      BulkUpdateDraftNotifier.new,
    );

/// Whether a bulk run is in flight, and over how many leads — the popup keeps
/// its button spinning and its inputs locked while this says `running`.
class BulkUpdateProgress {
  final bool running;
  final int total;

  const BulkUpdateProgress({this.running = false, this.total = 0});
}

/// Result of a bulk run: how many leads went through, and a
/// `<lead>: <message>` line for each that did not. [deleted] says which verb
/// the screen should report the count with.
class BulkUpdateOutcome {
  final int succeeded;
  final List<String> failures;
  final bool deleted;

  const BulkUpdateOutcome(this.succeeded, this.failures,
      {this.deleted = false});

  bool get allSucceeded => failures.isEmpty;

  /// 'updated' / 'deleted', for the confirmation snackbar.
  String get verb => deleted ? 'deleted' : 'updated';
}

/// Sends the whole selection to `POST /leads/bulk-action` in one request —
/// `{ lead_ids: [...], update_field: ..., new_value: ... }` — and reports what
/// came back. The endpoint answers for the batch as a whole, so a rejection is
/// one failure line for the run rather than one per lead.
class BulkUpdateRunner extends Notifier<BulkUpdateProgress> {
  @override
  BulkUpdateProgress build() => const BulkUpdateProgress();

  Future<BulkUpdateOutcome> apply({
    required List<LeadModel> leads,
    required BulkUpdateField field,
    int? statusId,
    String? priority,
    int? leadSourceId,
    int? leadTypeId,
    int? territoryId,
    int? branchId,
    int? assigneeId,
  }) async {
    final isDelete = field == BulkUpdateField.delete;
    final failures = <String>[];

    // `lead_ids` is a list of numbers; anything non-numeric can't go in the
    // body, so it's reported instead of silently dropped.
    final leadIds = <int>[];
    for (final lead in leads) {
      final id = int.tryParse(lead.id);
      if (id == null) {
        failures.add('${_leadLabel(lead)}: unrecognised lead id');
      } else {
        leadIds.add(id);
      }
    }
    if (leadIds.isEmpty) {
      return BulkUpdateOutcome(0, failures, deleted: isDelete);
    }

    state = BulkUpdateProgress(running: true, total: leadIds.length);

    final result = await ref
        .read(leadsRepositoryProvider)
        .bulkAction(
          leadIds: leadIds,
          updateField: field.apiField,
          // Delete carries no value; every other field sends the one the popup
          // collected for it.
          newValue: switch (field) {
            BulkUpdateField.status => statusId,
            BulkUpdateField.priority => priority,
            BulkUpdateField.leadSource => leadSourceId,
            BulkUpdateField.leadType => leadTypeId,
            BulkUpdateField.territory => territoryId,
            BulkUpdateField.branch => branchId,
            BulkUpdateField.assignee => assigneeId,
            BulkUpdateField.delete => null,
          },
        );

    state = const BulkUpdateProgress();

    var succeeded = 0;
    result.when(
      success: (data) => succeeded = data.affected,
      failure: (e) => failures.add(e.message),
    );

    if (succeeded > 0) {
      // The edited (or removed) rows are stale everywhere they're shown.
      await ref.read(bulkLeadsProvider.notifier).refresh();
      ref.invalidate(leadsListProvider);
      ref.invalidate(leadsBacklogProvider);
    }
    return BulkUpdateOutcome(succeeded, failures, deleted: isDelete);
  }

  static String _leadLabel(LeadModel lead) {
    final name = lead.contactName.trim();
    return name.isNotEmpty ? name : lead.title;
  }
}

final bulkUpdateRunnerProvider =
    NotifierProvider<BulkUpdateRunner, BulkUpdateProgress>(
      BulkUpdateRunner.new,
    );
