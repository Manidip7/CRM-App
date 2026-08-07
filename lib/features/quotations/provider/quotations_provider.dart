import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quotations_repository.dart';
import '../model/quotation_model.dart';

/// Special selection used by the status dropdown. It carries either a concrete
/// [QuotationStatus], the "Final Only" pseudo-filter, or null (= All Status).
class QuotationStatusFilter {
  final QuotationStatus? status;
  final bool finalOnly;

  const QuotationStatusFilter({this.status, this.finalOnly = false});

  static const all = QuotationStatusFilter();
  static const onlyFinal = QuotationStatusFilter(finalOnly: true);

  bool matches(QuotationModel q) {
    if (finalOnly) return q.status.isFinal;
    if (status == null) return true;
    return q.status == status;
  }

  @override
  bool operator ==(Object other) =>
      other is QuotationStatusFilter &&
      other.status == status &&
      other.finalOnly == finalOnly;

  @override
  int get hashCode => Object.hash(status, finalOnly);
}

/// All the active filters applied to the quotation list.
class QuotationFilterState {
  final String search;
  final QuotationStatusFilter statusFilter;
  final DateTime? fromDate;
  final DateTime? toDate;

  const QuotationFilterState({
    this.search = '',
    this.statusFilter = QuotationStatusFilter.all,
    this.fromDate,
    this.toDate,
  });

  QuotationFilterState copyWith({
    String? search,
    QuotationStatusFilter? statusFilter,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearDates = false,
  }) {
    return QuotationFilterState(
      search: search ?? this.search,
      statusFilter: statusFilter ?? this.statusFilter,
      fromDate: clearDates ? null : (fromDate ?? this.fromDate),
      toDate: clearDates ? null : (toDate ?? this.toDate),
    );
  }
}

class QuotationFilterNotifier extends Notifier<QuotationFilterState> {
  @override
  QuotationFilterState build() => const QuotationFilterState();

  void setSearch(String q) => state = state.copyWith(search: q);

  void setStatusFilter(QuotationStatusFilter filter) =>
      state = state.copyWith(statusFilter: filter);

  void setFromDate(DateTime? d) => state = state.copyWith(fromDate: d);

  void setToDate(DateTime? d) => state = state.copyWith(toDate: d);

  void clearDates() => state = state.copyWith(clearDates: true);
}

final quotationFilterProvider =
    NotifierProvider<QuotationFilterNotifier, QuotationFilterState>(
        QuotationFilterNotifier.new);

/// Whether the collapsible date + status filter row is currently expanded.
class QuotationFiltersExpanded extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final quotationFiltersExpandedProvider =
    NotifierProvider<QuotationFiltersExpanded, bool>(
        QuotationFiltersExpanded.new);

/// State for the API-backed Quotations list: the loaded pages plus paginator
/// info and loading / error flags.
class QuotationsState {
  final List<QuotationModel> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;

  /// Id of the quotation currently being deleted, so its card can show a
  /// spinner. Null when no delete is in flight.
  final String? deletingId;

  const QuotationsState({
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
    this.deletingId,
  });

  bool get hasMore => currentPage < lastPage;

  QuotationsState copyWith({
    List<QuotationModel>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
    String? deletingId,
    bool clearDeleting = false,
  }) {
    return QuotationsState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      deletingId: clearDeleting ? null : (deletingId ?? this.deletingId),
    );
  }
}

/// Loads `GET /quotations` page by page (replace on page 1, append after) and
/// holds the list so cards can be deleted / updated locally.
class QuotationsNotifier extends Notifier<QuotationsState> {
  @override
  QuotationsState build() {
    Future.microtask(() => _load(1));
    return const QuotationsState(isLoading: true);
  }

  Future<void> _load(int page) async {
    final result =
        await ref.read(quotationsRepositoryProvider).getQuotations(page: page);
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

  /// Deletes [item] via `DELETE /opportunities/{opportunityId}/quotations/{id}`,
  /// then drops it from the loaded list. Returns `null` on success, or an error
  /// message to show. The endpoint is opportunity-scoped, so a quotation with no
  /// `opportunity_id` cannot be deleted from here.
  Future<String?> delete(QuotationModel item) async {
    final opportunityId = item.opportunityId;
    if (opportunityId == null || opportunityId.isEmpty) {
      return 'This quotation has no linked opportunity to delete it from.';
    }
    if (state.deletingId != null) return null; // one delete at a time

    state = state.copyWith(deletingId: item.id);
    final result = await ref
        .read(quotationsRepositoryProvider)
        .deleteQuotation(opportunityId, item.id);
    state = state.copyWith(clearDeleting: true);

    return result.when(
      success: (_) {
        state = state.copyWith(
          items: state.items.where((q) => q.id != item.id).toList(),
          total: state.total > 0 ? state.total - 1 : 0,
        );
        return null;
      },
      failure: (error) => error.message,
    );
  }

  /// Upserts [updated]: replaces the quotation sharing its id, or prepends it to
  /// the list when no match exists (a newly created quote). Note: this is a
  /// local change only — there is no create/update API call yet, so it is lost
  /// on the next refresh.
  void update(QuotationModel updated) {
    final exists = state.items.any((q) => q.id == updated.id);
    if (exists) {
      state = state.copyWith(items: [
        for (final q in state.items) if (q.id == updated.id) updated else q,
      ]);
    } else {
      state = state.copyWith(
        items: [updated, ...state.items],
        total: state.total + 1,
      );
    }
  }
}

final quotationsProvider =
    NotifierProvider<QuotationsNotifier, QuotationsState>(
        QuotationsNotifier.new);

/// Quotations after applying every active filter, newest first.
final filteredQuotationsProvider = Provider<List<QuotationModel>>((ref) {
  final f = ref.watch(quotationFilterProvider);
  final items = ref.watch(quotationsProvider).items;
  final q = f.search.trim().toLowerCase();

  final result = items.where((item) {
    if (!f.statusFilter.matches(item)) return false;

    if (q.isNotEmpty) {
      final matches = item.clientName.toLowerCase().contains(q) ||
          item.title.toLowerCase().contains(q) ||
          item.number.toLowerCase().contains(q) ||
          (item.companyName?.toLowerCase().contains(q) ?? false);
      if (!matches) return false;
    }

    if (f.fromDate != null && item.createdDate.isBefore(_dayStart(f.fromDate!))) {
      return false;
    }
    if (f.toDate != null && item.createdDate.isAfter(_dayEnd(f.toDate!))) {
      return false;
    }
    return true;
  }).toList();

  result.sort((a, b) => b.createdDate.compareTo(a.createdDate));
  return result;
});

DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _dayEnd(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);
