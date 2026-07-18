// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'opportunity_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Editable stage / probability / won flag for a single opportunity, keyed by
/// the opportunity id so each one keeps its own state.

@ProviderFor(OpportunityDetailController)
final opportunityDetailControllerProvider =
    OpportunityDetailControllerFamily._();

/// Editable stage / probability / won flag for a single opportunity, keyed by
/// the opportunity id so each one keeps its own state.
final class OpportunityDetailControllerProvider
    extends
        $NotifierProvider<OpportunityDetailController, OpportunityDetailState> {
  /// Editable stage / probability / won flag for a single opportunity, keyed by
  /// the opportunity id so each one keeps its own state.
  OpportunityDetailControllerProvider._({
    required OpportunityDetailControllerFamily super.from,
    required (
      String, {
      OpportunityStage initialStage,
      String? initialStageId,
      int initialProbability,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'opportunityDetailControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$opportunityDetailControllerHash();

  @override
  String toString() {
    return r'opportunityDetailControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  OpportunityDetailController create() => OpportunityDetailController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OpportunityDetailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OpportunityDetailState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OpportunityDetailControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$opportunityDetailControllerHash() =>
    r'c00cf672c35a1784ee8c8ef83058994b586d7159';

/// Editable stage / probability / won flag for a single opportunity, keyed by
/// the opportunity id so each one keeps its own state.

final class OpportunityDetailControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          OpportunityDetailController,
          OpportunityDetailState,
          OpportunityDetailState,
          OpportunityDetailState,
          (
            String, {
            OpportunityStage initialStage,
            String? initialStageId,
            int initialProbability,
          })
        > {
  OpportunityDetailControllerFamily._()
    : super(
        retry: null,
        name: r'opportunityDetailControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Editable stage / probability / won flag for a single opportunity, keyed by
  /// the opportunity id so each one keeps its own state.

  OpportunityDetailControllerProvider call(
    String opportunityId, {
    OpportunityStage initialStage = OpportunityStage.proposal,
    String? initialStageId,
    int initialProbability = 50,
  }) => OpportunityDetailControllerProvider._(
    argument: (
      opportunityId,
      initialStage: initialStage,
      initialStageId: initialStageId,
      initialProbability: initialProbability,
    ),
    from: this,
  );

  @override
  String toString() => r'opportunityDetailControllerProvider';
}

/// Editable stage / probability / won flag for a single opportunity, keyed by
/// the opportunity id so each one keeps its own state.

abstract class _$OpportunityDetailController
    extends $Notifier<OpportunityDetailState> {
  late final _$args =
      ref.$arg
          as (
            String, {
            OpportunityStage initialStage,
            String? initialStageId,
            int initialProbability,
          });
  String get opportunityId => _$args.$1;
  OpportunityStage get initialStage => _$args.initialStage;
  String? get initialStageId => _$args.initialStageId;
  int get initialProbability => _$args.initialProbability;

  OpportunityDetailState build(
    String opportunityId, {
    OpportunityStage initialStage = OpportunityStage.proposal,
    String? initialStageId,
    int initialProbability = 50,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<OpportunityDetailState, OpportunityDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OpportunityDetailState, OpportunityDetailState>,
              OpportunityDetailState,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(
        _$args.$1,
        initialStage: _$args.initialStage,
        initialStageId: _$args.initialStageId,
        initialProbability: _$args.initialProbability,
      ),
    );
  }
}
