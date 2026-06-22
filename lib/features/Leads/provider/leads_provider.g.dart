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

String _$leadsFilterHash() => r'c0aefe65f91c7be51037a4dfaf3d61bb868b17e5';

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

@ProviderFor(LeadsPaginationState)
final leadsPaginationStateProvider = LeadsPaginationStateProvider._();

final class LeadsPaginationStateProvider
    extends $NotifierProvider<LeadsPaginationState, LeadsPagination> {
  LeadsPaginationStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadsPaginationStateProvider',
        isAutoDispose: true,
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
    r'7d266a10bb510fde92b170299df682570cd63644';

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

/// Loads leads from `GET /leads` with page-based pagination, accumulating each
/// fetched page into one growing list. Call [LeadsList.loadMore] when the user
/// scrolls near the bottom, and [LeadsList.refresh] for pull-to-refresh.

@ProviderFor(LeadsList)
final leadsListProvider = LeadsListProvider._();

/// Loads leads from `GET /leads` with page-based pagination, accumulating each
/// fetched page into one growing list. Call [LeadsList.loadMore] when the user
/// scrolls near the bottom, and [LeadsList.refresh] for pull-to-refresh.
final class LeadsListProvider
    extends $AsyncNotifierProvider<LeadsList, List<LeadModel>> {
  /// Loads leads from `GET /leads` with page-based pagination, accumulating each
  /// fetched page into one growing list. Call [LeadsList.loadMore] when the user
  /// scrolls near the bottom, and [LeadsList.refresh] for pull-to-refresh.
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

String _$leadsListHash() => r'107d8439960533ec1abafbf1f553eabb7a023a16';

/// Loads leads from `GET /leads` with page-based pagination, accumulating each
/// fetched page into one growing list. Call [LeadsList.loadMore] when the user
/// scrolls near the bottom, and [LeadsList.refresh] for pull-to-refresh.

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

/// Base data set — swaps between normal (API) leads and backlog (sample) leads.

@ProviderFor(leadsSource)
final leadsSourceProvider = LeadsSourceProvider._();

/// Base data set — swaps between normal (API) leads and backlog (sample) leads.

final class LeadsSourceProvider
    extends
        $FunctionalProvider<List<LeadModel>, List<LeadModel>, List<LeadModel>>
    with $Provider<List<LeadModel>> {
  /// Base data set — swaps between normal (API) leads and backlog (sample) leads.
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

String _$leadsSourceHash() => r'701d8a37267a6ddc934b0f78d87bcd6cc2a7d697';

/// The source list with the active search query + status/source filters applied.

@ProviderFor(filteredLeads)
final filteredLeadsProvider = FilteredLeadsProvider._();

/// The source list with the active search query + status/source filters applied.

final class FilteredLeadsProvider
    extends
        $FunctionalProvider<List<LeadModel>, List<LeadModel>, List<LeadModel>>
    with $Provider<List<LeadModel>> {
  /// The source list with the active search query + status/source filters applied.
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

String _$filteredLeadsHash() => r'febc76fdb7027f56876752c382a46b23416c65a5';
