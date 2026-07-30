// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leads_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LeadsFilter)
final leadsFilterProvider = LeadsFilterProvider._();

final class LeadsFilterProvider
    extends $NotifierProvider<LeadsFilter, LeadsFilterState> {
  LeadsFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadsFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadsFilterHash();

  @$internal
  @override
  LeadsFilter create() => LeadsFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeadsFilterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeadsFilterState>(value),
    );
  }
}

String _$leadsFilterHash() => r'206d0edfc04711ec5f7cd06040f1b227fbc7c35a';

abstract class _$LeadsFilter extends $Notifier<LeadsFilterState> {
  LeadsFilterState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LeadsFilterState, LeadsFilterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LeadsFilterState, LeadsFilterState>,
              LeadsFilterState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Pagination metadata for the live list. Kept alive (like
/// [LeadsBacklogPagination]) because the backlog toggle drops every listener on
/// this provider while the backlog view is active — an auto-disposed instance
/// would reset `total` to 0 and, since [LeadsList] itself stays alive and does
/// not refetch, nothing would ever set it again on the way back.

@ProviderFor(LeadsPaginationState)
final leadsPaginationStateProvider = LeadsPaginationStateProvider._();

/// Pagination metadata for the live list. Kept alive (like
/// [LeadsBacklogPagination]) because the backlog toggle drops every listener on
/// this provider while the backlog view is active — an auto-disposed instance
/// would reset `total` to 0 and, since [LeadsList] itself stays alive and does
/// not refetch, nothing would ever set it again on the way back.
final class LeadsPaginationStateProvider
    extends $NotifierProvider<LeadsPaginationState, LeadsPagination> {
  /// Pagination metadata for the live list. Kept alive (like
  /// [LeadsBacklogPagination]) because the backlog toggle drops every listener on
  /// this provider while the backlog view is active — an auto-disposed instance
  /// would reset `total` to 0 and, since [LeadsList] itself stays alive and does
  /// not refetch, nothing would ever set it again on the way back.
  LeadsPaginationStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadsPaginationStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadsPaginationStateHash();

  @$internal
  @override
  LeadsPaginationState create() => LeadsPaginationState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeadsPagination value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeadsPagination>(value),
    );
  }
}

String _$leadsPaginationStateHash() =>
    r'86341d73c229d09274f1212fc1e98837bfe51701';

/// Pagination metadata for the live list. Kept alive (like
/// [LeadsBacklogPagination]) because the backlog toggle drops every listener on
/// this provider while the backlog view is active — an auto-disposed instance
/// would reset `total` to 0 and, since [LeadsList] itself stays alive and does
/// not refetch, nothing would ever set it again on the way back.

abstract class _$LeadsPaginationState extends $Notifier<LeadsPagination> {
  LeadsPagination build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LeadsPagination, LeadsPagination>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LeadsPagination, LeadsPagination>,
              LeadsPagination,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The server-side query bits (search, status_id, source, quick_filter and
/// date range) as a record. Record equality means [LeadsList] only refetches
/// when one of these actually changes. The quick filters are joined into a
/// stable, sorted string because two `Set` instances with the same elements are
/// not `==` to each other (which would otherwise refetch on every rebuild).

@ProviderFor(leadsServerQuery)
final leadsServerQueryProvider = LeadsServerQueryProvider._();

/// The server-side query bits (search, status_id, source, quick_filter and
/// date range) as a record. Record equality means [LeadsList] only refetches
/// when one of these actually changes. The quick filters are joined into a
/// stable, sorted string because two `Set` instances with the same elements are
/// not `==` to each other (which would otherwise refetch on every rebuild).

final class LeadsServerQueryProvider
    extends
        $FunctionalProvider<
          ({
            DateTime? fromDate,
            String quickFilters,
            String search,
            String? source,
            int? statusId,
            DateTime? toDate,
          }),
          ({
            DateTime? fromDate,
            String quickFilters,
            String search,
            String? source,
            int? statusId,
            DateTime? toDate,
          }),
          ({
            DateTime? fromDate,
            String quickFilters,
            String search,
            String? source,
            int? statusId,
            DateTime? toDate,
          })
        >
    with
        $Provider<
          ({
            DateTime? fromDate,
            String quickFilters,
            String search,
            String? source,
            int? statusId,
            DateTime? toDate,
          })
        > {
  /// The server-side query bits (search, status_id, source, quick_filter and
  /// date range) as a record. Record equality means [LeadsList] only refetches
  /// when one of these actually changes. The quick filters are joined into a
  /// stable, sorted string because two `Set` instances with the same elements are
  /// not `==` to each other (which would otherwise refetch on every rebuild).
  LeadsServerQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadsServerQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadsServerQueryHash();

  @$internal
  @override
  $ProviderElement<
    ({
      DateTime? fromDate,
      String quickFilters,
      String search,
      String? source,
      int? statusId,
      DateTime? toDate,
    })
  >
  $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ({
    DateTime? fromDate,
    String quickFilters,
    String search,
    String? source,
    int? statusId,
    DateTime? toDate,
  })
  create(Ref ref) {
    return leadsServerQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    ({
      DateTime? fromDate,
      String quickFilters,
      String search,
      String? source,
      int? statusId,
      DateTime? toDate,
    })
    value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<
            ({
              DateTime? fromDate,
              String quickFilters,
              String search,
              String? source,
              int? statusId,
              DateTime? toDate,
            })
          >(value),
    );
  }
}

String _$leadsServerQueryHash() => r'636bc74068a29e8a7efc6439e9f65d4426b26d8e';

@ProviderFor(LeadsList)
final leadsListProvider = LeadsListProvider._();

final class LeadsListProvider
    extends $AsyncNotifierProvider<LeadsList, List<LeadModel>> {
  LeadsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadsListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadsListHash();

  @$internal
  @override
  LeadsList create() => LeadsList();
}

String _$leadsListHash() => r'4d7da3df7886e157a500d65509e524841b6c74d3';

abstract class _$LeadsList extends $AsyncNotifier<List<LeadModel>> {
  FutureOr<List<LeadModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<LeadModel>>, List<LeadModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<LeadModel>>, List<LeadModel>>,
              AsyncValue<List<LeadModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Pagination metadata for the backlog list — a separate instance from the live
/// list's [LeadsPaginationState] so the two views keep independent page cursors.

@ProviderFor(LeadsBacklogPagination)
final leadsBacklogPaginationProvider = LeadsBacklogPaginationProvider._();

/// Pagination metadata for the backlog list — a separate instance from the live
/// list's [LeadsPaginationState] so the two views keep independent page cursors.
final class LeadsBacklogPaginationProvider
    extends $NotifierProvider<LeadsBacklogPagination, LeadsPagination> {
  /// Pagination metadata for the backlog list — a separate instance from the live
  /// list's [LeadsPaginationState] so the two views keep independent page cursors.
  LeadsBacklogPaginationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadsBacklogPaginationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadsBacklogPaginationHash();

  @$internal
  @override
  LeadsBacklogPagination create() => LeadsBacklogPagination();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeadsPagination value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeadsPagination>(value),
    );
  }
}

String _$leadsBacklogPaginationHash() =>
    r'2edd9ca5ab2f04707987360395122c75bcd5cc0b';

/// Pagination metadata for the backlog list — a separate instance from the live
/// list's [LeadsPaginationState] so the two views keep independent page cursors.

abstract class _$LeadsBacklogPagination extends $Notifier<LeadsPagination> {
  LeadsPagination build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LeadsPagination, LeadsPagination>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LeadsPagination, LeadsPagination>,
              LeadsPagination,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The backlog leads — overdue leads needing follow-up (GET
/// /leads?quick_filter=backlog), paginated by scroll exactly like the live list.
/// Cached for the session; pull-to-refresh (or a Retry) reloads from page 1.

@ProviderFor(LeadsBacklog)
final leadsBacklogProvider = LeadsBacklogProvider._();

/// The backlog leads — overdue leads needing follow-up (GET
/// /leads?quick_filter=backlog), paginated by scroll exactly like the live list.
/// Cached for the session; pull-to-refresh (or a Retry) reloads from page 1.
final class LeadsBacklogProvider
    extends $AsyncNotifierProvider<LeadsBacklog, List<LeadModel>> {
  /// The backlog leads — overdue leads needing follow-up (GET
  /// /leads?quick_filter=backlog), paginated by scroll exactly like the live list.
  /// Cached for the session; pull-to-refresh (or a Retry) reloads from page 1.
  LeadsBacklogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadsBacklogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadsBacklogHash();

  @$internal
  @override
  LeadsBacklog create() => LeadsBacklog();
}

String _$leadsBacklogHash() => r'74774b67419863eecd0c54b10cca897cb078cbd8';

/// The backlog leads — overdue leads needing follow-up (GET
/// /leads?quick_filter=backlog), paginated by scroll exactly like the live list.
/// Cached for the session; pull-to-refresh (or a Retry) reloads from page 1.

abstract class _$LeadsBacklog extends $AsyncNotifier<List<LeadModel>> {
  FutureOr<List<LeadModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<LeadModel>>, List<LeadModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<LeadModel>>, List<LeadModel>>,
              AsyncValue<List<LeadModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Base data set — swaps between the live (API) leads and the backlog leads.
/// Both are API-backed; the backlog is its own cached list so switching views
/// never disturbs the live pipeline (mirrors the Opportunities screen).

@ProviderFor(leadsSource)
final leadsSourceProvider = LeadsSourceProvider._();

/// Base data set — swaps between the live (API) leads and the backlog leads.
/// Both are API-backed; the backlog is its own cached list so switching views
/// never disturbs the live pipeline (mirrors the Opportunities screen).

final class LeadsSourceProvider
    extends
        $FunctionalProvider<List<LeadModel>, List<LeadModel>, List<LeadModel>>
    with $Provider<List<LeadModel>> {
  /// Base data set — swaps between the live (API) leads and the backlog leads.
  /// Both are API-backed; the backlog is its own cached list so switching views
  /// never disturbs the live pipeline (mirrors the Opportunities screen).
  LeadsSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadsSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadsSourceHash();

  @$internal
  @override
  $ProviderElement<List<LeadModel>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<LeadModel> create(Ref ref) {
    return leadsSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<LeadModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<LeadModel>>(value),
    );
  }
}

String _$leadsSourceHash() => r'a308ca4a19c1cf39af4583d3141e0b4d6f68ae74';

/// The source list with the active search + status/source filters applied.
/// For the live list, search runs server-side; the backlog list is searched
/// client-side here (mirrors the Opportunities screen).

@ProviderFor(filteredLeads)
final filteredLeadsProvider = FilteredLeadsProvider._();

/// The source list with the active search + status/source filters applied.
/// For the live list, search runs server-side; the backlog list is searched
/// client-side here (mirrors the Opportunities screen).

final class FilteredLeadsProvider
    extends
        $FunctionalProvider<List<LeadModel>, List<LeadModel>, List<LeadModel>>
    with $Provider<List<LeadModel>> {
  /// The source list with the active search + status/source filters applied.
  /// For the live list, search runs server-side; the backlog list is searched
  /// client-side here (mirrors the Opportunities screen).
  FilteredLeadsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredLeadsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredLeadsHash();

  @$internal
  @override
  $ProviderElement<List<LeadModel>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<LeadModel> create(Ref ref) {
    return filteredLeads(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<LeadModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<LeadModel>>(value),
    );
  }
}

String _$filteredLeadsHash() => r'66e7199beb031238f5583d51ea4a037e725da678';

/// The lead-source options for the Add-Lead dropdown (`GET /lead-sources`).
/// Cached for the session; the form watches this to populate the dropdown.

@ProviderFor(leadSources)
final leadSourcesProvider = LeadSourcesProvider._();

/// The lead-source options for the Add-Lead dropdown (`GET /lead-sources`).
/// Cached for the session; the form watches this to populate the dropdown.

final class LeadSourcesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LeadSourceOption>>,
          List<LeadSourceOption>,
          FutureOr<List<LeadSourceOption>>
        >
    with
        $FutureModifier<List<LeadSourceOption>>,
        $FutureProvider<List<LeadSourceOption>> {
  /// The lead-source options for the Add-Lead dropdown (`GET /lead-sources`).
  /// Cached for the session; the form watches this to populate the dropdown.
  LeadSourcesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadSourcesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadSourcesHash();

  @$internal
  @override
  $FutureProviderElement<List<LeadSourceOption>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LeadSourceOption>> create(Ref ref) {
    return leadSources(ref);
  }
}

String _$leadSourcesHash() => r'9472c89da361c70d0b0594ea0a84056457d4c58a';

/// The "Current Update" options for the Schedule Follow-up popup
/// (`GET /current-updates`). Cached for the session.

@ProviderFor(currentUpdates)
final currentUpdatesProvider = CurrentUpdatesProvider._();

/// The "Current Update" options for the Schedule Follow-up popup
/// (`GET /current-updates`). Cached for the session.

final class CurrentUpdatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NamedLookup>>,
          List<NamedLookup>,
          FutureOr<List<NamedLookup>>
        >
    with
        $FutureModifier<List<NamedLookup>>,
        $FutureProvider<List<NamedLookup>> {
  /// The "Current Update" options for the Schedule Follow-up popup
  /// (`GET /current-updates`). Cached for the session.
  CurrentUpdatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUpdatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUpdatesHash();

  @$internal
  @override
  $FutureProviderElement<List<NamedLookup>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<NamedLookup>> create(Ref ref) {
    return currentUpdates(ref);
  }
}

String _$currentUpdatesHash() => r'805e2b6b3a5997809e845a2ee23fb1e07db70394';

/// The "Next Action" options for the Schedule Follow-up popup
/// (`GET /next-actions`). Cached for the session.

@ProviderFor(nextActions)
final nextActionsProvider = NextActionsProvider._();

/// The "Next Action" options for the Schedule Follow-up popup
/// (`GET /next-actions`). Cached for the session.

final class NextActionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NamedLookup>>,
          List<NamedLookup>,
          FutureOr<List<NamedLookup>>
        >
    with
        $FutureModifier<List<NamedLookup>>,
        $FutureProvider<List<NamedLookup>> {
  /// The "Next Action" options for the Schedule Follow-up popup
  /// (`GET /next-actions`). Cached for the session.
  NextActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nextActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nextActionsHash();

  @$internal
  @override
  $FutureProviderElement<List<NamedLookup>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<NamedLookup>> create(Ref ref) {
    return nextActions(ref);
  }
}

String _$nextActionsHash() => r'21ee22a21084127bd238a77f7b44028f61c50d77';

/// The lead status options (`GET /statuses`) for the detail header chip/menu.
/// Cached for the session.

@ProviderFor(leadStatuses)
final leadStatusesProvider = LeadStatusesProvider._();

/// The lead status options (`GET /statuses`) for the detail header chip/menu.
/// Cached for the session.

final class LeadStatusesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<StatusOption>>,
          List<StatusOption>,
          FutureOr<List<StatusOption>>
        >
    with
        $FutureModifier<List<StatusOption>>,
        $FutureProvider<List<StatusOption>> {
  /// The lead status options (`GET /statuses`) for the detail header chip/menu.
  /// Cached for the session.
  LeadStatusesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadStatusesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadStatusesHash();

  @$internal
  @override
  $FutureProviderElement<List<StatusOption>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<StatusOption>> create(Ref ref) {
    return leadStatuses(ref);
  }
}

String _$leadStatusesHash() => r'3ec70e1bcdfe6afdc4ab0e795d55bdc2b87be76a';
