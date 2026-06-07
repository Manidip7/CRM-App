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

/// Base data set — swaps between normal leads and backlog leads.

@ProviderFor(leadsSource)
final leadsSourceProvider = LeadsSourceProvider._();

/// Base data set — swaps between normal leads and backlog leads.

final class LeadsSourceProvider
    extends
        $FunctionalProvider<List<LeadModel>, List<LeadModel>, List<LeadModel>>
    with $Provider<List<LeadModel>> {
  /// Base data set — swaps between normal leads and backlog leads.
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

String _$leadsSourceHash() => r'688a7399b92180d38a794f393f052af23dd98ea2';

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
