import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/leads_repository.dart';
import '../model/lead_model.dart';
import 'leads_provider.dart';

/// The field a bulk update writes to every selected lead.
///
/// The API has no batch route, so each option maps to the existing single-lead
/// endpoint and [BulkUpdateRunner] applies it one lead at a time.
enum BulkUpdateField {
  status('Status'),
  priority('Priority'),
  assignee('Assigned To');

  final String label;

  const BulkUpdateField(this.label);
}

/// Priority (temperature) values the backend accepts on `POST /leads/{id}/priority`.
const kBulkPriorities = <String>['hot', 'warm', 'cold'];

/// 'hot' → 'Hot'.
String bulkPriorityLabel(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

// ─────────────────────────────────────────────────────────────────────────────
//  List + filters
// ─────────────────────────────────────────────────────────────────────────────

/// The Bulk Action screen's own slice of `GET /leads` — deliberately separate
/// from [leadsListProvider] so filtering here never disturbs the Leads screen.
class BulkLeadsState {
  final List<LeadModel> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  // Active filters (each maps to one query param on `GET /leads`).
  final String search;
  final int? statusId;
  final int? leadSourceId;
  final String? priority;
  final int? assignedTo;

  const BulkLeadsState({
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
    this.search = '',
    this.statusId,
    this.leadSourceId,
    this.priority,
    this.assignedTo,
  });

  bool get hasMore => currentPage < lastPage;

  /// How many dropdown filters are narrowing the list — drives the badge on the
  /// filter toggle. Search is shown by its own field, so it isn't counted.
  int get activeFilterCount => [
    statusId,
    leadSourceId,
    priority,
    assignedTo,
  ].where((v) => v != null).length;

  BulkLeadsState copyWith({
    List<LeadModel>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) {
    return BulkLeadsState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      search: search,
      statusId: statusId,
      leadSourceId: leadSourceId,
      priority: priority,
      assignedTo: assignedTo,
    );
  }

  /// Replaces the whole filter set. Separate from [copyWith] because `null`
  /// here means "All …" — it has to be able to clear a filter, not skip it.
  BulkLeadsState withFilters({
    required String search,
    required int? statusId,
    required int? leadSourceId,
    required String? priority,
    required int? assignedTo,
    bool? isLoading,
  }) {
    return BulkLeadsState(
      items: items,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore,
      error: error,
      search: search,
      statusId: statusId,
      leadSourceId: leadSourceId,
      priority: priority,
      assignedTo: assignedTo,
    );
  }
}

/// Loads `GET /leads` page by page for the Bulk Action screen: replaces on page
/// 1, appends on later pages. Any filter change clears the current selection —
/// keeping rows selected that the user can no longer see would make the
/// "N selected" count lie about what Apply is going to touch.
class BulkLeads extends Notifier<BulkLeadsState> {
  Timer? _debounce;

  @override
  BulkLeadsState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(() => _load(1));
    return const BulkLeadsState();
  }

  Future<void> _load(int page) async {
    final s = state;
    final result = await ref
        .read(leadsRepositoryProvider)
        .getLeads(
          page: page,
          search: s.search.trim().isEmpty ? null : s.search.trim(),
          statusId: s.statusId,
          leadSourceId: s.leadSourceId,
          priority: s.priority,
          assignedTo: s.assignedTo,
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

  /// Debounced server-side search (`?search=`).
  void setSearch(String query) {
    if (query == state.search) return;
    state = state.withFilters(
      search: query,
      statusId: state.statusId,
      leadSourceId: state.leadSourceId,
      priority: state.priority,
      assignedTo: state.assignedTo,
    );
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(bulkSelectionProvider.notifier).clear();
      state = state.copyWith(isLoading: true, clearError: true);
      _load(1);
    });
  }

  /// Applies every filter dropdown at once. A `null` argument means "All …".
  void applyFilters({
    int? statusId,
    int? leadSourceId,
    String? priority,
    int? assignedTo,
  }) {
    state = state.withFilters(
      search: state.search,
      statusId: statusId,
      leadSourceId: leadSourceId,
      priority: priority,
      assignedTo: assignedTo,
      isLoading: true,
    );
    ref.read(bulkSelectionProvider.notifier).clear();
    _load(1);
  }

  /// Resets every dropdown back to "All …"; leaves the search box alone.
  void clearFilters() => applyFilters();
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
  final int? assigneeId;

  const BulkUpdateDraft({
    this.field,
    this.statusId,
    this.priority,
    this.assigneeId,
  });

  /// Whether both dropdowns are filled in, i.e. Apply Update can run.
  bool get isReady => switch (field) {
    null => false,
    BulkUpdateField.status => statusId != null,
    BulkUpdateField.priority => priority != null,
    BulkUpdateField.assignee => assigneeId != null,
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

  void setAssignee(int id) =>
      state = BulkUpdateDraft(field: state.field, assigneeId: id);
}

final bulkUpdateDraftProvider =
    NotifierProvider<BulkUpdateDraftNotifier, BulkUpdateDraft>(
      BulkUpdateDraftNotifier.new,
    );

/// How far through the selected leads the update has got, so the dialog's
/// button can read "3 / 5" instead of an anonymous spinner.
class BulkUpdateProgress {
  final bool running;
  final int done;
  final int total;

  const BulkUpdateProgress({
    this.running = false,
    this.done = 0,
    this.total = 0,
  });
}

/// Result of a bulk update: how many leads went through, and a
/// `<lead>: <message>` line for each that did not.
class BulkUpdateOutcome {
  final int succeeded;
  final List<String> failures;

  const BulkUpdateOutcome(this.succeeded, this.failures);

  bool get allSucceeded => failures.isEmpty;
}

/// Applies one field change across the selected leads, one request at a time
/// (sequential rather than parallel — a bulk action shouldn't fire 50
/// simultaneous writes at the API). A failure on one lead is recorded and the
/// run continues, so a single bad row can't abandon the rest.
class BulkUpdateRunner extends Notifier<BulkUpdateProgress> {
  @override
  BulkUpdateProgress build() => const BulkUpdateProgress();

  Future<BulkUpdateOutcome> apply({
    required List<LeadModel> leads,
    required BulkUpdateField field,
    int? statusId,
    String? priority,
    int? assigneeId,
  }) async {
    final repo = ref.read(leadsRepositoryProvider);
    state = BulkUpdateProgress(running: true, done: 0, total: leads.length);

    var succeeded = 0;
    final failures = <String>[];

    for (final lead in leads) {
      final result = await switch (field) {
        BulkUpdateField.status => repo.updateLeadStatus(lead.id, statusId!),
        BulkUpdateField.priority => repo.updateLeadPriority(lead.id, priority!),
        BulkUpdateField.assignee => repo.assignLead(
          lead.id,
          assigneeIds: [assigneeId!],
          isPrivate: false,
        ),
      };
      final error = result.errorOrNull;
      if (error != null) {
        failures.add('${_leadLabel(lead)}: ${error.message}');
      } else {
        succeeded++;
      }
      state = BulkUpdateProgress(
        running: true,
        done: succeeded + failures.length,
        total: leads.length,
      );
    }

    state = const BulkUpdateProgress();

    if (succeeded > 0) {
      // The edited rows are stale everywhere they're shown.
      await ref.read(bulkLeadsProvider.notifier).refresh();
      ref.invalidate(leadsListProvider);
      ref.invalidate(leadsBacklogProvider);
    }
    return BulkUpdateOutcome(succeeded, failures);
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
