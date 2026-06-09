import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Holds the (mutable) master list of quotations so cards can be deleted.
class QuotationsNotifier extends Notifier<List<QuotationModel>> {
  @override
  List<QuotationModel> build() => QuotationModel.sampleQuotations();

  void delete(String id) =>
      state = state.where((q) => q.id != id).toList();

  /// Replaces the quotation sharing [updated]'s id with the new version.
  void update(QuotationModel updated) => state = [
        for (final q in state) if (q.id == updated.id) updated else q,
      ];
}

final quotationsProvider =
    NotifierProvider<QuotationsNotifier, List<QuotationModel>>(
        QuotationsNotifier.new);

/// Quotations after applying every active filter, newest first.
final filteredQuotationsProvider = Provider<List<QuotationModel>>((ref) {
  final f = ref.watch(quotationFilterProvider);
  final items = ref.watch(quotationsProvider);
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
