import 'package:crm_app/features/Leads/provider/leads_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the query-string assembly in `LeadsRepository.getLeads`, so the
/// param names and the omit-when-null rule are covered without a live Dio.
Map<String, dynamic> buildQuery({
  int page = 1,
  int perPage = 10,
  String? search,
  int? statusId,
  String? source,
  List<String>? quickFilters,
  String? fromDate,
  String? toDate,
  int? leadSourceId,
  int? leadTypeId,
  int? territoryId,
  int? assignedTo,
  int? branchId,
  String? category,
  String? priority,
}) {
  final hasFrom = fromDate != null && fromDate.isNotEmpty;
  final hasTo = toDate != null && toDate.isNotEmpty;
  return {
    'page': page,
    'per_page': perPage,
    if (search != null && search.isNotEmpty) 'search': search,
    if (statusId != null) 'status_id': statusId,
    if (source != null && source.isNotEmpty) 'source': source,
    if (quickFilters != null && quickFilters.isNotEmpty)
      'quick_filter': quickFilters,
    if (hasFrom) 'from_date': fromDate,
    if (hasTo) 'to_date': toDate,
    if (hasFrom && hasTo) 'date_range': '$fromDate to $toDate',
    if (leadSourceId != null) 'lead_source_id': leadSourceId,
    if (leadTypeId != null) 'lead_type_id': leadTypeId,
    if (territoryId != null) 'territory_id': territoryId,
    if (assignedTo != null) 'assigned_to': assignedTo,
    if (branchId != null) 'branch_id': branchId,
    if (category != null && category.isNotEmpty) 'category': category,
    if (priority != null && priority.isNotEmpty) 'priority': priority,
  };
}

void main() {
  group('LeadDateRange presets', () {
    // A fixed Wednesday, so "this week" and month arithmetic are deterministic.
    final now = DateTime(2026, 8, 5, 14, 30);

    test('All Time and Custom resolve to no bounds', () {
      expect(LeadDateRange.allTime.resolve(now), (null, null));
      expect(LeadDateRange.custom.resolve(now), (null, null));
    });

    test('Today is a single day, with the time-of-day stripped', () {
      final (from, to) = LeadDateRange.today.resolve(now);
      expect(from, DateTime(2026, 8, 5));
      expect(to, DateTime(2026, 8, 5));
    });

    test('Yesterday steps back one day', () {
      final (from, to) = LeadDateRange.yesterday.resolve(now);
      expect(from, DateTime(2026, 8, 4));
      expect(to, DateTime(2026, 8, 4));
    });

    test('This Week starts on Monday', () {
      final (from, to) = LeadDateRange.thisWeek.resolve(now);
      expect(from, DateTime(2026, 8, 3)); // the Monday
      expect(from!.weekday, DateTime.monday);
      expect(to, DateTime(2026, 8, 5));
    });

    test('This Week on a Monday does not step back into last week', () {
      final monday = DateTime(2026, 8, 3, 9);
      final (from, _) = LeadDateRange.thisWeek.resolve(monday);
      expect(from, DateTime(2026, 8, 3));
    });

    test('This Month runs from the 1st to today', () {
      final (from, to) = LeadDateRange.thisMonth.resolve(now);
      expect(from, DateTime(2026, 8, 1));
      expect(to, DateTime(2026, 8, 5));
    });

    test('Last Month covers the whole previous month', () {
      final (from, to) = LeadDateRange.lastMonth.resolve(now);
      expect(from, DateTime(2026, 7, 1));
      expect(to, DateTime(2026, 7, 31));
    });

    test('Last Month rolls back across a year boundary', () {
      final january = DateTime(2026, 1, 15);
      final (from, to) = LeadDateRange.lastMonth.resolve(january);
      expect(from, DateTime(2025, 12, 1));
      expect(to, DateTime(2025, 12, 31));
    });

    test('Last Month gets February right in a leap year', () {
      final march = DateTime(2024, 3, 10);
      final (from, to) = LeadDateRange.lastMonth.resolve(march);
      expect(from, DateTime(2024, 2, 1));
      expect(to, DateTime(2024, 2, 29));
    });

    test('This Year starts on 1 January', () {
      final (from, to) = LeadDateRange.thisYear.resolve(now);
      expect(from, DateTime(2026, 1, 1));
      expect(to, DateTime(2026, 8, 5));
    });

    test('every preset has a user-facing label', () {
      for (final range in LeadDateRange.values) {
        expect(range.label, isNotEmpty);
      }
      expect(LeadDateRange.allTime.label, 'All Time');
      expect(LeadDateRange.values.first, LeadDateRange.allTime);
    });
  });

  group('LeadsFilterState.advancedFilterCount', () {
    test('a clean state has no active filters', () {
      const state = LeadsFilterState();
      expect(state.advancedFilterCount, 0);
      expect(state.hasAdvancedFilters, isFalse);
    });

    test('counts each dropdown once', () {
      const state = LeadsFilterState(
        statusId: 1,
        leadSourceId: 2,
        leadTypeId: 3,
        territoryId: 4,
        assignedTo: 5,
        dateRange: LeadDateRange.thisMonth,
      );
      expect(state.advancedFilterCount, 6);
      expect(state.hasAdvancedFilters, isTrue);
    });

    test('All Time does not count as a filter', () {
      const state = LeadsFilterState(dateRange: LeadDateRange.allTime);
      expect(state.advancedFilterCount, 0);
    });

    test('search and quick-filter chips are not counted', () {
      const state = LeadsFilterState(
        searchQuery: 'John',
        quickFilters: {'today', 'overdue'},
      );
      expect(state.advancedFilterCount, 0);
    });

    test('hasDateFilter tracks the resolved bounds', () {
      expect(const LeadsFilterState().hasDateFilter, isFalse);
      expect(
        LeadsFilterState(fromDate: DateTime(2026, 1, 1)).hasDateFilter,
        isTrue,
      );
    });
  });

  group('getLeads query assembly', () {
    test('a bare call sends only paging', () {
      expect(buildQuery(), {'page': 1, 'per_page': 10});
    });

    test('every advanced filter maps to its documented param', () {
      final q = buildQuery(
        statusId: 1,
        leadSourceId: 2,
        leadTypeId: 3,
        territoryId: 4,
        assignedTo: 5,
        branchId: 1,
        category: 'active',
        priority: 'hot',
        search: 'John',
      );

      expect(q['status_id'], 1);
      expect(q['lead_source_id'], 2);
      expect(q['lead_type_id'], 3);
      expect(q['territory_id'], 4);
      expect(q['assigned_to'], 5);
      expect(q['branch_id'], 1);
      expect(q['category'], 'active');
      expect(q['priority'], 'hot');
      expect(q['search'], 'John');
    });

    test('null filters are omitted, not sent empty', () {
      final q = buildQuery(statusId: 1);
      expect(q.containsKey('status_id'), isTrue);
      expect(q.containsKey('lead_source_id'), isFalse);
      expect(q.containsKey('territory_id'), isFalse);
      expect(q.containsKey('assigned_to'), isFalse);
      expect(q.containsKey('date_range'), isFalse);
    });

    test('empty strings are treated as absent', () {
      final q = buildQuery(search: '', source: '', category: '', priority: '');
      expect(q.keys, ['page', 'per_page']);
    });

    test('both date bounds also produce the combined date_range param', () {
      final q = buildQuery(fromDate: '2024-01-01', toDate: '2024-01-31');
      expect(q['from_date'], '2024-01-01');
      expect(q['to_date'], '2024-01-31');
      expect(q['date_range'], '2024-01-01 to 2024-01-31');
    });

    test('a single date bound sends no date_range', () {
      final q = buildQuery(fromDate: '2024-01-01');
      expect(q['from_date'], '2024-01-01');
      expect(q.containsKey('to_date'), isFalse);
      expect(q.containsKey('date_range'), isFalse);
    });

    test('quick filters stay a list so Dio repeats the param', () {
      final q = buildQuery(quickFilters: const ['today', 'overdue']);
      expect(q['quick_filter'], ['today', 'overdue']);
    });

    test('an empty quick-filter list is omitted', () {
      expect(buildQuery(quickFilters: const []).containsKey('quick_filter'),
          isFalse);
    });
  });
}
