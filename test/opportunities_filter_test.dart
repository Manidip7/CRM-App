import 'package:crm_app/features/Opportunities/model/opportunity_model.dart';
import 'package:crm_app/features/Opportunities/provider/opportunities_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the query-string assembly in
/// `OpportunitiesRepository.getOpportunities`, so the param names and the
/// omit-when-null rule are covered without a live Dio.
Map<String, dynamic> buildQuery({
  int page = 1,
  int perPage = 15,
  String? search,
  String? category,
  List<String>? quickFilters,
  int? statusId,
  String? stage,
  int? assignedTo,
  String? dateRange,
  String? fromDate,
  String? toDate,
}) {
  return {
    'page': page,
    'per_page': perPage,
    if (search != null && search.isNotEmpty) 'search': search,
    if (category != null && category.isNotEmpty) 'category': category,
    if (quickFilters != null && quickFilters.isNotEmpty)
      'quick_filter': quickFilters,
    if (statusId != null) 'status_id': statusId,
    if (stage != null && stage.isNotEmpty) 'stage': stage,
    if (assignedTo != null) 'assigned_to': assignedTo,
    if (dateRange != null && dateRange.isNotEmpty) 'date_range': dateRange,
    if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
    if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
  };
}

/// Mirrors how `Opportunities._load` turns the state's date selection into
/// query params: a preset sends its keyword, a custom range sends dates.
({String? dateRange, String? fromDate, String? toDate}) dateParams(
  OpportunityDateRange range, {
  String? from,
  String? to,
}) {
  final isCustom = range == OpportunityDateRange.custom;
  return (
    dateRange: isCustom ? null : range.apiValue,
    fromDate: isCustom ? from : null,
    toDate: isCustom ? to : null,
  );
}

void main() {
  group('OpportunityDateRange', () {
    test('presets carry the keyword the API documents', () {
      expect(OpportunityDateRange.lastMonth.apiValue, 'last_month');
      expect(OpportunityDateRange.today.apiValue, 'today');
      expect(OpportunityDateRange.yesterday.apiValue, 'yesterday');
      expect(OpportunityDateRange.thisWeek.apiValue, 'this_week');
      expect(OpportunityDateRange.lastWeek.apiValue, 'last_week');
      expect(OpportunityDateRange.thisMonth.apiValue, 'this_month');
      expect(OpportunityDateRange.thisYear.apiValue, 'this_year');
    });

    test('All Time and Custom send no keyword', () {
      expect(OpportunityDateRange.allTime.apiValue, isNull);
      expect(OpportunityDateRange.custom.apiValue, isNull);
    });

    test('every entry has a user-facing label', () {
      for (final range in OpportunityDateRange.values) {
        expect(range.label, isNotEmpty);
      }
      expect(OpportunityDateRange.allTime.label, 'All Time');
      expect(OpportunityDateRange.values.first, OpportunityDateRange.allTime);
    });

    test('a preset sends only date_range, never explicit dates', () {
      final p = dateParams(OpportunityDateRange.lastMonth,
          from: '2024-01-01', to: '2024-01-31');
      expect(p.dateRange, 'last_month');
      // Sending both would risk the server's "last month" fighting ours.
      expect(p.fromDate, isNull);
      expect(p.toDate, isNull);
    });

    test('a custom range sends only the dates, never a keyword', () {
      final p = dateParams(OpportunityDateRange.custom,
          from: '2024-01-01', to: '2024-01-31');
      expect(p.dateRange, isNull);
      expect(p.fromDate, '2024-01-01');
      expect(p.toDate, '2024-01-31');
    });

    test('All Time sends nothing at all', () {
      final p = dateParams(OpportunityDateRange.allTime);
      expect(p.dateRange, isNull);
      expect(p.fromDate, isNull);
      expect(p.toDate, isNull);
    });
  });

  group('OpportunitiesState.advancedFilterCount', () {
    test('a clean state has no active filters', () {
      const state = OpportunitiesState();
      expect(state.advancedFilterCount, 0);
      expect(state.hasAdvancedFilters, isFalse);
    });

    test('counts each control once', () {
      const state = OpportunitiesState(
        statusId: 2,
        stageFilter: 'Proposal',
        assignedTo: 5,
        dateRange: OpportunityDateRange.lastMonth,
        activeOnly: true,
        myOpportunitiesOnly: true,
      );
      expect(state.advancedFilterCount, 6);
      expect(state.hasAdvancedFilters, isTrue);
    });

    test('All Time and the off switches do not count', () {
      const state = OpportunitiesState(
        dateRange: OpportunityDateRange.allTime,
        activeOnly: false,
        myOpportunitiesOnly: false,
      );
      expect(state.advancedFilterCount, 0);
    });

    test('search and the stage chips are not counted', () {
      const state = OpportunitiesState(
        searchQuery: 'John',
        selectedStage: OpportunityStage.won,
      );
      expect(state.advancedFilterCount, 0);
    });

    test('a switch on its own registers', () {
      expect(
        const OpportunitiesState(myOpportunitiesOnly: true).advancedFilterCount,
        1,
      );
      expect(
        const OpportunitiesState(activeOnly: true).advancedFilterCount,
        1,
      );
    });
  });

  group('getOpportunities query assembly', () {
    test('a bare call sends only paging', () {
      expect(buildQuery(), {'page': 1, 'per_page': 15});
    });

    test('the documented example round-trips', () {
      final q = buildQuery(
        search: 'John',
        category: 'active',
        quickFilters: const ['my_opportunities'],
        statusId: 2,
        stage: 'Proposal',
        assignedTo: 5,
        dateRange: 'last_month',
      );

      expect(q['search'], 'John');
      expect(q['category'], 'active');
      expect(q['quick_filter'], ['my_opportunities']);
      expect(q['status_id'], 2);
      expect(q['stage'], 'Proposal');
      expect(q['assigned_to'], 5);
      expect(q['date_range'], 'last_month');
      expect(q['page'], 1);
    });

    test('null filters are omitted, not sent empty', () {
      final q = buildQuery(statusId: 2);
      expect(q.containsKey('status_id'), isTrue);
      expect(q.containsKey('stage'), isFalse);
      expect(q.containsKey('assigned_to'), isFalse);
      expect(q.containsKey('date_range'), isFalse);
      expect(q.containsKey('category'), isFalse);
      expect(q.containsKey('quick_filter'), isFalse);
    });

    test('empty strings are treated as absent', () {
      final q = buildQuery(search: '', category: '', stage: '', dateRange: '');
      expect(q.keys, ['page', 'per_page']);
    });

    test('an empty quick-filter list is omitted', () {
      expect(buildQuery(quickFilters: const []).containsKey('quick_filter'),
          isFalse);
    });

    test('quick filters stay a list so Dio repeats the param', () {
      final q = buildQuery(quickFilters: const ['my_opportunities']);
      expect(q['quick_filter'], ['my_opportunities']);
    });

    test('the backlog view still sends its own category', () {
      final q = buildQuery(category: 'backlog');
      expect(q['category'], 'backlog');
    });

    test('a custom range sends both bounds and no keyword', () {
      final q = buildQuery(fromDate: '2024-01-01', toDate: '2024-01-31');
      expect(q['from_date'], '2024-01-01');
      expect(q['to_date'], '2024-01-31');
      expect(q.containsKey('date_range'), isFalse);
    });
  });
}
