// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Editable pipeline status / temperature / conversion flag for a single lead,
/// keyed by the lead id so each lead keeps its own state.

@ProviderFor(LeadDetailController)
final leadDetailControllerProvider = LeadDetailControllerFamily._();

/// Editable pipeline status / temperature / conversion flag for a single lead,
/// keyed by the lead id so each lead keeps its own state.
final class LeadDetailControllerProvider
    extends $NotifierProvider<LeadDetailController, LeadDetailState> {
  /// Editable pipeline status / temperature / conversion flag for a single lead,
  /// keyed by the lead id so each lead keeps its own state.
  LeadDetailControllerProvider._({
    required LeadDetailControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'leadDetailControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$leadDetailControllerHash();

  @override
  String toString() {
    return r'leadDetailControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LeadDetailController create() => LeadDetailController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeadDetailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeadDetailState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LeadDetailControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$leadDetailControllerHash() =>
    r'367da4addfe2b34693bb849e722d5421bf1cf8a8';

/// Editable pipeline status / temperature / conversion flag for a single lead,
/// keyed by the lead id so each lead keeps its own state.

final class LeadDetailControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LeadDetailController,
          LeadDetailState,
          LeadDetailState,
          LeadDetailState,
          String
        > {
  LeadDetailControllerFamily._()
    : super(
        retry: null,
        name: r'leadDetailControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Editable pipeline status / temperature / conversion flag for a single lead,
  /// keyed by the lead id so each lead keeps its own state.

  LeadDetailControllerProvider call(String leadId) =>
      LeadDetailControllerProvider._(argument: leadId, from: this);

  @override
  String toString() => r'leadDetailControllerProvider';
}

/// Editable pipeline status / temperature / conversion flag for a single lead,
/// keyed by the lead id so each lead keeps its own state.

abstract class _$LeadDetailController extends $Notifier<LeadDetailState> {
  late final _$args = ref.$arg as String;
  String get leadId => _$args;

  LeadDetailState build(String leadId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LeadDetailState, LeadDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LeadDetailState, LeadDetailState>,
              LeadDetailState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
