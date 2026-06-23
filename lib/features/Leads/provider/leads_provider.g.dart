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

String _$leadsFilterHash() => r'f5c139bb68c45669a33d7b4f7bedb99095dc1b30';

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

/// The server-side query bits (search + date range) as a record. Record
/// equality means [LeadsList] only refetches when one of these changes — not
/// when the client-side status/source chips toggle.

@ProviderFor(leadsServerQuery)
final leadsServerQueryProvider = LeadsServerQueryProvider._();

/// The server-side query bits (search + date range) as a record. Record
/// equality means [LeadsList] only refetches when one of these changes — not
/// when the client-side status/source chips toggle.

final class LeadsServerQueryProvider
    extends
        $FunctionalProvider<
          (String, DateTime?, DateTime?),
          (String, DateTime?, DateTime?),
          (String, DateTime?, DateTime?)
        >
    with $Provider<(String, DateTime?, DateTime?)> {
  /// The server-side query bits (search + date range) as a record. Record
  /// equality means [LeadsList] only refetches when one of these changes — not
  /// when the client-side status/source chips toggle.
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
  $ProviderElement<(String, DateTime?, DateTime?)> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  (String, DateTime?, DateTime?) create(Ref ref) {
    return leadsServerQuery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue((String, DateTime?, DateTime?) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<(String, DateTime?, DateTime?)>(
        value,
      ),
    );
  }
}

String _$leadsServerQueryHash() => r'38b468d056e670e65ca2009732114c69c55baec8';

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

String _$leadsListHash() => r'f2d7be9f5162f2fc68780ca043a813240aec38c6';

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

String _$filteredLeadsHash() => r'66e7199beb031238f5583d51ea4a037e725da678';
