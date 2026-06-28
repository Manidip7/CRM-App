import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/next_followup_model.dart';
import 'next_followups_api_provider.dart';

/// Client-side filters applied over the API-loaded follow-up pages. The date
/// range is NOT here — it is sent to the server via [followUpsApiProvider]
/// (`date_from` / `date_to`). Search, type and status filter the loaded items.
class FollowUpFilterState {
  /// null = All, otherwise the `item_type` to keep (`Lead` / `Opportunity`).
  final String? type;
  final String search;

  /// null = All Status, otherwise the exact status label to keep.
  final String? status;

  const FollowUpFilterState({
    this.type,
    this.search = '',
    this.status,
  });

  FollowUpFilterState copyWith({
    String? type,
    bool clearType = false,
    String? search,
    String? status,
    bool clearStatus = false,
  }) {
    return FollowUpFilterState(
      type: clearType ? null : (type ?? this.type),
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

class FollowUpFilterNotifier extends Notifier<FollowUpFilterState> {
  @override
  FollowUpFilterState build() => const FollowUpFilterState();

  void setType(String? type) => state =
      type == null ? state.copyWith(clearType: true) : state.copyWith(type: type);

  void setSearch(String q) => state = state.copyWith(search: q);

  void setStatus(String? status) => state = status == null
      ? state.copyWith(clearStatus: true)
      : state.copyWith(status: status);
}

final followUpFilterProvider =
    NotifierProvider<FollowUpFilterNotifier, FollowUpFilterState>(
        FollowUpFilterNotifier.new);

/// Whether the collapsible date + status filter row is currently expanded.
class FollowUpFiltersExpanded extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final followUpFiltersExpandedProvider =
    NotifierProvider<FollowUpFiltersExpanded, bool>(
        FollowUpFiltersExpanded.new);

/// The API follow-ups after applying the client-side type / search / status
/// filters. Date filtering happens server-side, so the items here are already
/// within the requested range.
final filteredFollowUpsProvider = Provider<List<NextFollowUp>>((ref) {
  final f = ref.watch(followUpFilterProvider);
  final items = ref.watch(followUpsApiProvider).items;
  final q = f.search.trim().toLowerCase();

  return items.where((i) {
    if (f.type != null &&
        i.itemType.toLowerCase() != f.type!.toLowerCase()) {
      return false;
    }
    if (f.status != null && i.statusLabel != f.status) return false;
    if (q.isNotEmpty) {
      final matches = i.title.toLowerCase().contains(q) ||
          i.contactName.toLowerCase().contains(q) ||
          (i.company?.toLowerCase().contains(q) ?? false) ||
          (i.phone?.toLowerCase().contains(q) ?? false);
      if (!matches) return false;
    }
    return true;
  }).toList();
});

/// The distinct status labels present in the loaded items, for the status
/// dropdown (sorted alphabetically).
final followUpStatusOptionsProvider = Provider<List<String>>((ref) {
  final items = ref.watch(followUpsApiProvider).items;
  final set = items.map((i) => i.statusLabel).where((s) => s != '—').toSet();
  final list = set.toList()..sort();
  return list;
});
