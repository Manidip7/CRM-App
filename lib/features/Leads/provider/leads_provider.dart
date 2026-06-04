import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
  }) = _LeadsFilterState;
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

  /// Switches between normal leads and backlog leads, resetting search/filters.
  void toggleBacklog() =>
      state = LeadsFilterState(showBacklog: !state.showBacklog);
}

/// Base data set — swaps between normal leads and backlog leads.
@riverpod
List<LeadModel> leadsSource(Ref ref) {
  final showBacklog = ref.watch(leadsFilterProvider).showBacklog;
  return showBacklog ? LeadModel.backlogLeads() : LeadModel.sampleLeads();
}

/// The source list with the active search query + status/source filters applied.
@riverpod
List<LeadModel> filteredLeads(Ref ref) {
  final all = ref.watch(leadsSourceProvider);
  final f = ref.watch(leadsFilterProvider);
  final q = f.searchQuery.toLowerCase();
  return all.where((lead) {
    final matchSearch = q.isEmpty ||
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
