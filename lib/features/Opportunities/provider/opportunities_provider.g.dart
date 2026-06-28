// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'opportunities_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Kept alive so opportunities converted from leads survive navigation.

@ProviderFor(Opportunities)
final opportunitiesProvider = OpportunitiesProvider._();

/// Kept alive so opportunities converted from leads survive navigation.
final class OpportunitiesProvider
    extends $NotifierProvider<Opportunities, OpportunitiesState> {
  /// Kept alive so opportunities converted from leads survive navigation.
  OpportunitiesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'opportunitiesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$opportunitiesHash();

  @$internal
  @override
  Opportunities create() => Opportunities();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OpportunitiesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OpportunitiesState>(value),
    );
  }
}

String _$opportunitiesHash() => r'de343d25d29538491debe659c73e4e64b3766fca';

/// Kept alive so opportunities converted from leads survive navigation.

abstract class _$Opportunities extends $Notifier<OpportunitiesState> {
  OpportunitiesState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<OpportunitiesState, OpportunitiesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OpportunitiesState, OpportunitiesState>,
              OpportunitiesState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Opportunities filtered by the selected stage. Text search is server-side for
/// the live pipeline; only the local backlog is searched client-side here.

@ProviderFor(filteredOpportunities)
final filteredOpportunitiesProvider = FilteredOpportunitiesProvider._();

/// Opportunities filtered by the selected stage. Text search is server-side for
/// the live pipeline; only the local backlog is searched client-side here.

final class FilteredOpportunitiesProvider
    extends
        $FunctionalProvider<
          List<OpportunityModel>,
          List<OpportunityModel>,
          List<OpportunityModel>
        >
    with $Provider<List<OpportunityModel>> {
  /// Opportunities filtered by the selected stage. Text search is server-side for
  /// the live pipeline; only the local backlog is searched client-side here.
  FilteredOpportunitiesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredOpportunitiesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredOpportunitiesHash();

  @$internal
  @override
  $ProviderElement<List<OpportunityModel>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<OpportunityModel> create(Ref ref) {
    return filteredOpportunities(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<OpportunityModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<OpportunityModel>>(value),
    );
  }
}

String _$filteredOpportunitiesHash() =>
    r'c8804be5e6266beb10701e0a278ce1f1b1f5db29';
