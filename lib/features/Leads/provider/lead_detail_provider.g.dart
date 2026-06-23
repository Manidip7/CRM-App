// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads a lead's detail bundle (timeline, notes, tasks) from `GET /leads/{id}`,
/// keyed by lead id. Watched by the Timeline / Notes / Tasks tabs.

@ProviderFor(leadDetail)
final leadDetailProvider = LeadDetailFamily._();

/// Loads a lead's detail bundle (timeline, notes, tasks) from `GET /leads/{id}`,
/// keyed by lead id. Watched by the Timeline / Notes / Tasks tabs.

final class LeadDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<LeadDetailBundle>,
          LeadDetailBundle,
          FutureOr<LeadDetailBundle>
        >
    with $FutureModifier<LeadDetailBundle>, $FutureProvider<LeadDetailBundle> {
  /// Loads a lead's detail bundle (timeline, notes, tasks) from `GET /leads/{id}`,
  /// keyed by lead id. Watched by the Timeline / Notes / Tasks tabs.
  LeadDetailProvider._({
    required LeadDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'leadDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$leadDetailHash();

  @override
  String toString() {
    return r'leadDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LeadDetailBundle> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LeadDetailBundle> create(Ref ref) {
    final argument = this.argument as String;
    return leadDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LeadDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$leadDetailHash() => r'2a3c540147d9ec5c179753f107f9ba7265db6b97';

/// Loads a lead's detail bundle (timeline, notes, tasks) from `GET /leads/{id}`,
/// keyed by lead id. Watched by the Timeline / Notes / Tasks tabs.

final class LeadDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LeadDetailBundle>, String> {
  LeadDetailFamily._()
    : super(
        retry: null,
        name: r'leadDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads a lead's detail bundle (timeline, notes, tasks) from `GET /leads/{id}`,
  /// keyed by lead id. Watched by the Timeline / Notes / Tasks tabs.

  LeadDetailProvider call(String leadId) =>
      LeadDetailProvider._(argument: leadId, from: this);

  @override
  String toString() => r'leadDetailProvider';
}

/// Editable pipeline status / temperature / conversion flag for a single lead,
/// keyed by the lead id so each lead keeps its own state. The initial
/// temperature is seeded from the lead's `priority` via [initialTemperature].

@ProviderFor(LeadDetailController)
final leadDetailControllerProvider = LeadDetailControllerFamily._();

/// Editable pipeline status / temperature / conversion flag for a single lead,
/// keyed by the lead id so each lead keeps its own state. The initial
/// temperature is seeded from the lead's `priority` via [initialTemperature].
final class LeadDetailControllerProvider
    extends $NotifierProvider<LeadDetailController, LeadDetailState> {
  /// Editable pipeline status / temperature / conversion flag for a single lead,
  /// keyed by the lead id so each lead keeps its own state. The initial
  /// temperature is seeded from the lead's `priority` via [initialTemperature].
  LeadDetailControllerProvider._({
    required LeadDetailControllerFamily super.from,
    required (String, {LeadTemperature initialTemperature}) super.argument,
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
        '$argument';
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
    r'76f87055069f5925a22f4997ed62290c37cda282';

/// Editable pipeline status / temperature / conversion flag for a single lead,
/// keyed by the lead id so each lead keeps its own state. The initial
/// temperature is seeded from the lead's `priority` via [initialTemperature].

final class LeadDetailControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          LeadDetailController,
          LeadDetailState,
          LeadDetailState,
          LeadDetailState,
          (String, {LeadTemperature initialTemperature})
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
  /// keyed by the lead id so each lead keeps its own state. The initial
  /// temperature is seeded from the lead's `priority` via [initialTemperature].

  LeadDetailControllerProvider call(
    String leadId, {
    LeadTemperature initialTemperature = LeadTemperature.warm,
  }) => LeadDetailControllerProvider._(
    argument: (leadId, initialTemperature: initialTemperature),
    from: this,
  );

  @override
  String toString() => r'leadDetailControllerProvider';
}

/// Editable pipeline status / temperature / conversion flag for a single lead,
/// keyed by the lead id so each lead keeps its own state. The initial
/// temperature is seeded from the lead's `priority` via [initialTemperature].

abstract class _$LeadDetailController extends $Notifier<LeadDetailState> {
  late final _$args =
      ref.$arg as (String, {LeadTemperature initialTemperature});
  String get leadId => _$args.$1;
  LeadTemperature get initialTemperature => _$args.initialTemperature;

  LeadDetailState build(
    String leadId, {
    LeadTemperature initialTemperature = LeadTemperature.warm,
  });
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
    element.handleCreate(
      ref,
      () => build(_$args.$1, initialTemperature: _$args.initialTemperature),
    );
  }
}
