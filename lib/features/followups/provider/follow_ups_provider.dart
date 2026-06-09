import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Leads/model/lead_model.dart';
import '../../Opportunities/model/opportunity_model.dart';
import '../../Opportunities/provider/opportunities_provider.dart';
import '../model/follow_up_item.dart';

/// All the active filters applied to the follow-up list.
class FollowUpFilterState {
  final FollowUpType? type; // null = All
  final String search;
  final FollowUpStatus? status; // null = All Status
  final DateTime? fromDate;
  final DateTime? toDate;

  const FollowUpFilterState({
    this.type,
    this.search = '',
    this.status,
    this.fromDate,
    this.toDate,
  });

  FollowUpFilterState copyWith({
    FollowUpType? type,
    bool clearType = false,
    String? search,
    FollowUpStatus? status,
    bool clearStatus = false,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearDates = false,
  }) {
    return FollowUpFilterState(
      type: clearType ? null : (type ?? this.type),
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      fromDate: clearDates ? null : (fromDate ?? this.fromDate),
      toDate: clearDates ? null : (toDate ?? this.toDate),
    );
  }
}

class FollowUpFilterNotifier extends Notifier<FollowUpFilterState> {
  @override
  FollowUpFilterState build() => const FollowUpFilterState();

  void setType(FollowUpType? type) =>
      state = type == null ? state.copyWith(clearType: true) : state.copyWith(type: type);

  void setSearch(String q) => state = state.copyWith(search: q);

  void setStatus(FollowUpStatus? status) => state =
      status == null ? state.copyWith(clearStatus: true) : state.copyWith(status: status);

  void setFromDate(DateTime? d) => state = state.copyWith(fromDate: d);

  void setToDate(DateTime? d) => state = state.copyWith(toDate: d);

  void clearDates() => state = state.copyWith(clearDates: true);
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

/// All next follow-ups, merged from leads + opportunities (including their
/// backlogs) and sorted so the soonest (and overdue) items surface first.
/// Plain providers are used here so no build_runner codegen step is required.
final followUpItemsProvider = Provider<List<FollowUpItem>>((ref) {
  final now = DateTime.now();

  // ── Leads → follow-ups (active + backlog) ──
  FollowUpItem fromLead(LeadModel lead, {required bool backlog}) {
    return FollowUpItem(
      id: 'lead-${lead.id}',
      type: FollowUpType.lead,
      title: lead.title,
      contactName: lead.contactName,
      companyName: lead.companyName,
      phone: lead.phone,
      dueLabel: _formatDate(lead.nextFollowUp),
      dueDate: lead.nextFollowUp,
      isOverdue: lead.nextFollowUp.isBefore(now),
      status: backlog ? FollowUpStatus.backlog : _leadStatus(lead.status),
      avatarInitials: lead.displayInitials,
      avatarColor: _avatarPalette[lead.avatarColorIndex % _avatarPalette.length],
      lead: lead,
    );
  }

  final leadItems = [
    ...LeadModel.sampleLeads().map((l) => fromLead(l, backlog: false)),
    ...LeadModel.backlogLeads().map((l) => fromLead(l, backlog: true)),
  ];

  // ── Opportunities → follow-ups (active + backlog) ──
  final oppState = ref.watch(opportunitiesProvider);
  FollowUpItem fromOpp(OpportunityModel opp, {required bool backlog}) {
    final date = _parseOppDate(opp.nextFollowUp, now);
    return FollowUpItem(
      id: 'opp-${opp.id}',
      type: FollowUpType.opportunity,
      title: opp.title,
      contactName: opp.contactName,
      phone: opp.phone,
      dueLabel: opp.nextFollowUp,
      dueDate: date,
      isOverdue: opp.nextFollowUp.toLowerCase().contains('overdue') ||
          (date != null && date.isBefore(now)),
      status: backlog ? FollowUpStatus.backlog : _oppStatus(opp.stage),
      avatarInitials: opp.avatarInitials,
      avatarColor: opp.avatarColor,
      opportunity: opp,
    );
  }

  final oppItems = [
    ...oppState.items.map((o) => fromOpp(o, backlog: false)),
    ...oppState.backlogItems.map((o) => fromOpp(o, backlog: true)),
  ];

  final all = [...leadItems, ...oppItems];

  // Sort: overdue first, then by due date (items without a date go last).
  all.sort((a, b) {
    if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
    if (a.dueDate != null && b.dueDate != null) {
      return a.dueDate!.compareTo(b.dueDate!);
    }
    if (a.dueDate == null && b.dueDate != null) return 1;
    if (a.dueDate != null && b.dueDate == null) return -1;
    return 0;
  });

  return all;
});

/// Follow-ups after applying every active filter in [followUpFilterProvider].
final filteredFollowUpsProvider = Provider<List<FollowUpItem>>((ref) {
  final f = ref.watch(followUpFilterProvider);
  final items = ref.watch(followUpItemsProvider);
  final q = f.search.trim().toLowerCase();

  return items.where((i) {
    if (f.type != null && i.type != f.type) return false;
    if (f.status != null && i.status != f.status) return false;

    if (q.isNotEmpty) {
      final matches = i.contactName.toLowerCase().contains(q) ||
          i.title.toLowerCase().contains(q) ||
          (i.companyName?.toLowerCase().contains(q) ?? false);
      if (!matches) return false;
    }

    // Date range — items without a parsable date are excluded once a bound is set.
    if (f.fromDate != null || f.toDate != null) {
      final d = i.dueDate;
      if (d == null) return false;
      if (f.fromDate != null && d.isBefore(_dayStart(f.fromDate!))) return false;
      if (f.toDate != null && d.isAfter(_dayEnd(f.toDate!))) return false;
    }
    return true;
  }).toList();
});

// ─────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────

DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _dayEnd(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

const List<Color> _avatarPalette = [
  Color(0xFFE53935),
  Color(0xFF7B72E9),
  Color(0xFF2DD4A0),
  Color(0xFFFF7043),
  Color(0xFF26C6DA),
  Color(0xFFAB47BC),
];

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime d) {
  final month = _months[d.month - 1];
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final period = d.hour < 12 ? 'AM' : 'PM';
  return '$month ${d.day}, $hour12:$minute $period';
}

/// Parses an opportunity follow-up label into a [DateTime] for sorting/filtering.
/// Handles "Jun 2, 10:00 AM" and "Overdue by 5d". Returns null if unparsable.
DateTime? _parseOppDate(String s, DateTime now) {
  final lower = s.toLowerCase();
  if (lower.contains('overdue')) {
    final m = RegExp(r'(\d+)').firstMatch(s);
    final days = m != null ? int.parse(m.group(1)!) : 1;
    return now.subtract(Duration(days: days));
  }
  try {
    final parts = s.split(',');
    final dm = parts[0].trim().split(' '); // ['Jun', '2']
    final month = _months.indexOf(dm[0]) + 1;
    if (month < 1) return null;
    final day = int.parse(dm[1]);
    int hour = 0, minute = 0;
    if (parts.length > 1) {
      final tm = parts[1].trim().split(' '); // ['10:00', 'AM']
      final hm = tm[0].split(':');
      hour = int.parse(hm[0]) % 12;
      minute = int.parse(hm[1]);
      if (tm.length > 1 && tm[1].toUpperCase() == 'PM') hour += 12;
    }
    return DateTime(now.year, month, day, hour, minute);
  } catch (_) {
    return null;
  }
}

FollowUpStatus _leadStatus(LeadStatus s) {
  switch (s) {
    case LeadStatus.newLead:
      return FollowUpStatus.newStatus;
    case LeadStatus.contacted:
      return FollowUpStatus.inProgress;
    case LeadStatus.qualified:
      return FollowUpStatus.discovery;
    case LeadStatus.won:
      return FollowUpStatus.won;
    case LeadStatus.lost:
      return FollowUpStatus.lost;
  }
}

FollowUpStatus _oppStatus(OpportunityStage s) {
  switch (s) {
    case OpportunityStage.proposal:
      return FollowUpStatus.proposal;
    case OpportunityStage.negotiation:
      return FollowUpStatus.negotiation;
    case OpportunityStage.qualified:
      return FollowUpStatus.discovery;
    case OpportunityStage.won:
      return FollowUpStatus.won;
    case OpportunityStage.lost:
      return FollowUpStatus.lost;
  }
}
