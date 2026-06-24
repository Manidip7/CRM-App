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

/// Loads the full lead record from `GET /leads/{id}` (its own fields, including
/// the follow-up data: current_update, next_action, interest_score, etc.),
/// keyed by lead id. The detail screen uses this to populate the header with
/// server-authoritative values the list endpoint may omit.

@ProviderFor(leadFull)
final leadFullProvider = LeadFullFamily._();

/// Loads the full lead record from `GET /leads/{id}` (its own fields, including
/// the follow-up data: current_update, next_action, interest_score, etc.),
/// keyed by lead id. The detail screen uses this to populate the header with
/// server-authoritative values the list endpoint may omit.

final class LeadFullProvider
    extends
        $FunctionalProvider<
          AsyncValue<LeadModel>,
          LeadModel,
          FutureOr<LeadModel>
        >
    with $FutureModifier<LeadModel>, $FutureProvider<LeadModel> {
  /// Loads the full lead record from `GET /leads/{id}` (its own fields, including
  /// the follow-up data: current_update, next_action, interest_score, etc.),
  /// keyed by lead id. The detail screen uses this to populate the header with
  /// server-authoritative values the list endpoint may omit.
  LeadFullProvider._({
    required LeadFullFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'leadFullProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$leadFullHash();

  @override
  String toString() {
    return r'leadFullProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LeadModel> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<LeadModel> create(Ref ref) {
    final argument = this.argument as String;
    return leadFull(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LeadFullProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$leadFullHash() => r'9233dc194721f828b52bfd5e75cb3fc29dc45114';

/// Loads the full lead record from `GET /leads/{id}` (its own fields, including
/// the follow-up data: current_update, next_action, interest_score, etc.),
/// keyed by lead id. The detail screen uses this to populate the header with
/// server-authoritative values the list endpoint may omit.

final class LeadFullFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LeadModel>, String> {
  LeadFullFamily._()
    : super(
        retry: null,
        name: r'leadFullProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads the full lead record from `GET /leads/{id}` (its own fields, including
  /// the follow-up data: current_update, next_action, interest_score, etc.),
  /// keyed by lead id. The detail screen uses this to populate the header with
  /// server-authoritative values the list endpoint may omit.

  LeadFullProvider call(String leadId) =>
      LeadFullProvider._(argument: leadId, from: this);

  @override
  String toString() => r'leadFullProvider';
}

/// Holds the detail screen's display copy of a lead, keyed by lead id, so
/// follow-up edits (scheduling) and server-loaded values update through Riverpod
/// instead of `setState`. Seeded once from the lead passed via navigation;
/// `null` until seeded (the screen falls back to the navigation lead).

@ProviderFor(LeadView)
final leadViewProvider = LeadViewFamily._();

/// Holds the detail screen's display copy of a lead, keyed by lead id, so
/// follow-up edits (scheduling) and server-loaded values update through Riverpod
/// instead of `setState`. Seeded once from the lead passed via navigation;
/// `null` until seeded (the screen falls back to the navigation lead).
final class LeadViewProvider extends $NotifierProvider<LeadView, LeadModel?> {
  /// Holds the detail screen's display copy of a lead, keyed by lead id, so
  /// follow-up edits (scheduling) and server-loaded values update through Riverpod
  /// instead of `setState`. Seeded once from the lead passed via navigation;
  /// `null` until seeded (the screen falls back to the navigation lead).
  LeadViewProvider._({
    required LeadViewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'leadViewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$leadViewHash();

  @override
  String toString() {
    return r'leadViewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LeadView create() => LeadView();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeadModel? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeadModel?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LeadViewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$leadViewHash() => r'568c69511a4ac7a6726b4f0cdec9472c5b4d4fba';

/// Holds the detail screen's display copy of a lead, keyed by lead id, so
/// follow-up edits (scheduling) and server-loaded values update through Riverpod
/// instead of `setState`. Seeded once from the lead passed via navigation;
/// `null` until seeded (the screen falls back to the navigation lead).

final class LeadViewFamily extends $Family
    with
        $ClassFamilyOverride<
          LeadView,
          LeadModel?,
          LeadModel?,
          LeadModel?,
          String
        > {
  LeadViewFamily._()
    : super(
        retry: null,
        name: r'leadViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Holds the detail screen's display copy of a lead, keyed by lead id, so
  /// follow-up edits (scheduling) and server-loaded values update through Riverpod
  /// instead of `setState`. Seeded once from the lead passed via navigation;
  /// `null` until seeded (the screen falls back to the navigation lead).

  LeadViewProvider call(String leadId) =>
      LeadViewProvider._(argument: leadId, from: this);

  @override
  String toString() => r'leadViewProvider';
}

/// Holds the detail screen's display copy of a lead, keyed by lead id, so
/// follow-up edits (scheduling) and server-loaded values update through Riverpod
/// instead of `setState`. Seeded once from the lead passed via navigation;
/// `null` until seeded (the screen falls back to the navigation lead).

abstract class _$LeadView extends $Notifier<LeadModel?> {
  late final _$args = ref.$arg as String;
  String get leadId => _$args;

  LeadModel? build(String leadId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LeadModel?, LeadModel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LeadModel?, LeadModel?>,
              LeadModel?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
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
    required (
      String, {
      LeadTemperature initialTemperature,
      int? initialStatusId,
    })
    super.argument,
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
    r'6799470ced01365ca76b436d5b493d1c1dadefc1';

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
          (String, {LeadTemperature initialTemperature, int? initialStatusId})
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
    int? initialStatusId,
  }) => LeadDetailControllerProvider._(
    argument: (
      leadId,
      initialTemperature: initialTemperature,
      initialStatusId: initialStatusId,
    ),
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
      ref.$arg
          as (
            String, {
            LeadTemperature initialTemperature,
            int? initialStatusId,
          });
  String get leadId => _$args.$1;
  LeadTemperature get initialTemperature => _$args.initialTemperature;
  int? get initialStatusId => _$args.initialStatusId;

  LeadDetailState build(
    String leadId, {
    LeadTemperature initialTemperature = LeadTemperature.warm,
    int? initialStatusId,
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
      () => build(
        _$args.$1,
        initialTemperature: _$args.initialTemperature,
        initialStatusId: _$args.initialStatusId,
      ),
    );
  }
}

/// Handles adding a note to a lead (`POST /leads/{id}/notes`), keyed by lead id.
/// The state is the in-flight `saving` flag. On success it refreshes the lead's
/// detail bundle so the new note appears.

@ProviderFor(AddNote)
final addNoteProvider = AddNoteFamily._();

/// Handles adding a note to a lead (`POST /leads/{id}/notes`), keyed by lead id.
/// The state is the in-flight `saving` flag. On success it refreshes the lead's
/// detail bundle so the new note appears.
final class AddNoteProvider extends $NotifierProvider<AddNote, bool> {
  /// Handles adding a note to a lead (`POST /leads/{id}/notes`), keyed by lead id.
  /// The state is the in-flight `saving` flag. On success it refreshes the lead's
  /// detail bundle so the new note appears.
  AddNoteProvider._({
    required AddNoteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'addNoteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$addNoteHash();

  @override
  String toString() {
    return r'addNoteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AddNote create() => AddNote();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AddNoteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$addNoteHash() => r'd90cbf11d40c34d957f72c688a33fc35b90dcbc2';

/// Handles adding a note to a lead (`POST /leads/{id}/notes`), keyed by lead id.
/// The state is the in-flight `saving` flag. On success it refreshes the lead's
/// detail bundle so the new note appears.

final class AddNoteFamily extends $Family
    with $ClassFamilyOverride<AddNote, bool, bool, bool, String> {
  AddNoteFamily._()
    : super(
        retry: null,
        name: r'addNoteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Handles adding a note to a lead (`POST /leads/{id}/notes`), keyed by lead id.
  /// The state is the in-flight `saving` flag. On success it refreshes the lead's
  /// detail bundle so the new note appears.

  AddNoteProvider call(String leadId) =>
      AddNoteProvider._(argument: leadId, from: this);

  @override
  String toString() => r'addNoteProvider';
}

/// Handles adding a note to a lead (`POST /leads/{id}/notes`), keyed by lead id.
/// The state is the in-flight `saving` flag. On success it refreshes the lead's
/// detail bundle so the new note appears.

abstract class _$AddNote extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get leadId => _$args;

  bool build(String leadId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Converts a lead to an opportunity (`POST /leads/{id}/convert`), keyed by lead
/// id and auto-disposed so the form resets each time the sheet opens.

@ProviderFor(ConvertLead)
final convertLeadProvider = ConvertLeadFamily._();

/// Converts a lead to an opportunity (`POST /leads/{id}/convert`), keyed by lead
/// id and auto-disposed so the form resets each time the sheet opens.
final class ConvertLeadProvider
    extends $NotifierProvider<ConvertLead, ConvertLeadState> {
  /// Converts a lead to an opportunity (`POST /leads/{id}/convert`), keyed by lead
  /// id and auto-disposed so the form resets each time the sheet opens.
  ConvertLeadProvider._({
    required ConvertLeadFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'convertLeadProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$convertLeadHash();

  @override
  String toString() {
    return r'convertLeadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ConvertLead create() => ConvertLead();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConvertLeadState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConvertLeadState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConvertLeadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$convertLeadHash() => r'e3d5f01643f001d7e08bc9192770edf6ece5d49f';

/// Converts a lead to an opportunity (`POST /leads/{id}/convert`), keyed by lead
/// id and auto-disposed so the form resets each time the sheet opens.

final class ConvertLeadFamily extends $Family
    with
        $ClassFamilyOverride<
          ConvertLead,
          ConvertLeadState,
          ConvertLeadState,
          ConvertLeadState,
          String
        > {
  ConvertLeadFamily._()
    : super(
        retry: null,
        name: r'convertLeadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Converts a lead to an opportunity (`POST /leads/{id}/convert`), keyed by lead
  /// id and auto-disposed so the form resets each time the sheet opens.

  ConvertLeadProvider call(String leadId) =>
      ConvertLeadProvider._(argument: leadId, from: this);

  @override
  String toString() => r'convertLeadProvider';
}

/// Converts a lead to an opportunity (`POST /leads/{id}/convert`), keyed by lead
/// id and auto-disposed so the form resets each time the sheet opens.

abstract class _$ConvertLead extends $Notifier<ConvertLeadState> {
  late final _$args = ref.$arg as String;
  String get leadId => _$args;

  ConvertLeadState build(String leadId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ConvertLeadState, ConvertLeadState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ConvertLeadState, ConvertLeadState>,
              ConvertLeadState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Handles adding a task to a lead (`POST /leads/{id}/tasks`), keyed by lead id
/// and auto-disposed so the form resets each time the sheet opens. On success it
/// refreshes the lead's detail bundle so the new task appears.

@ProviderFor(AddTask)
final addTaskProvider = AddTaskFamily._();

/// Handles adding a task to a lead (`POST /leads/{id}/tasks`), keyed by lead id
/// and auto-disposed so the form resets each time the sheet opens. On success it
/// refreshes the lead's detail bundle so the new task appears.
final class AddTaskProvider extends $NotifierProvider<AddTask, AddTaskState> {
  /// Handles adding a task to a lead (`POST /leads/{id}/tasks`), keyed by lead id
  /// and auto-disposed so the form resets each time the sheet opens. On success it
  /// refreshes the lead's detail bundle so the new task appears.
  AddTaskProvider._({
    required AddTaskFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'addTaskProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$addTaskHash();

  @override
  String toString() {
    return r'addTaskProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AddTask create() => AddTask();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddTaskState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddTaskState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AddTaskProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$addTaskHash() => r'4e688a6d7fb78355c4ce404dc1efcab1ab5311b5';

/// Handles adding a task to a lead (`POST /leads/{id}/tasks`), keyed by lead id
/// and auto-disposed so the form resets each time the sheet opens. On success it
/// refreshes the lead's detail bundle so the new task appears.

final class AddTaskFamily extends $Family
    with
        $ClassFamilyOverride<
          AddTask,
          AddTaskState,
          AddTaskState,
          AddTaskState,
          String
        > {
  AddTaskFamily._()
    : super(
        retry: null,
        name: r'addTaskProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Handles adding a task to a lead (`POST /leads/{id}/tasks`), keyed by lead id
  /// and auto-disposed so the form resets each time the sheet opens. On success it
  /// refreshes the lead's detail bundle so the new task appears.

  AddTaskProvider call(String leadId) =>
      AddTaskProvider._(argument: leadId, from: this);

  @override
  String toString() => r'addTaskProvider';
}

/// Handles adding a task to a lead (`POST /leads/{id}/tasks`), keyed by lead id
/// and auto-disposed so the form resets each time the sheet opens. On success it
/// refreshes the lead's detail bundle so the new task appears.

abstract class _$AddTask extends $Notifier<AddTaskState> {
  late final _$args = ref.$arg as String;
  String get leadId => _$args;

  AddTaskState build(String leadId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AddTaskState, AddTaskState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AddTaskState, AddTaskState>,
              AddTaskState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Holds the "Schedule Follow-up" form state, keyed by lead id and auto-disposed
/// so each time the sheet opens it starts fresh. Replaces the sheet's local
/// `setState` so the form is Riverpod-managed too.

@ProviderFor(FollowUpForm)
final followUpFormProvider = FollowUpFormFamily._();

/// Holds the "Schedule Follow-up" form state, keyed by lead id and auto-disposed
/// so each time the sheet opens it starts fresh. Replaces the sheet's local
/// `setState` so the form is Riverpod-managed too.
final class FollowUpFormProvider
    extends $NotifierProvider<FollowUpForm, FollowUpFormState> {
  /// Holds the "Schedule Follow-up" form state, keyed by lead id and auto-disposed
  /// so each time the sheet opens it starts fresh. Replaces the sheet's local
  /// `setState` so the form is Riverpod-managed too.
  FollowUpFormProvider._({
    required FollowUpFormFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'followUpFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$followUpFormHash();

  @override
  String toString() {
    return r'followUpFormProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FollowUpForm create() => FollowUpForm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FollowUpFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FollowUpFormState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FollowUpFormProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$followUpFormHash() => r'6384e03f6a5ca71d8682f4b24bb86722dbe413a5';

/// Holds the "Schedule Follow-up" form state, keyed by lead id and auto-disposed
/// so each time the sheet opens it starts fresh. Replaces the sheet's local
/// `setState` so the form is Riverpod-managed too.

final class FollowUpFormFamily extends $Family
    with
        $ClassFamilyOverride<
          FollowUpForm,
          FollowUpFormState,
          FollowUpFormState,
          FollowUpFormState,
          String
        > {
  FollowUpFormFamily._()
    : super(
        retry: null,
        name: r'followUpFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Holds the "Schedule Follow-up" form state, keyed by lead id and auto-disposed
  /// so each time the sheet opens it starts fresh. Replaces the sheet's local
  /// `setState` so the form is Riverpod-managed too.

  FollowUpFormProvider call(String leadId) =>
      FollowUpFormProvider._(argument: leadId, from: this);

  @override
  String toString() => r'followUpFormProvider';
}

/// Holds the "Schedule Follow-up" form state, keyed by lead id and auto-disposed
/// so each time the sheet opens it starts fresh. Replaces the sheet's local
/// `setState` so the form is Riverpod-managed too.

abstract class _$FollowUpForm extends $Notifier<FollowUpFormState> {
  late final _$args = ref.$arg as String;
  String get leadId => _$args;

  FollowUpFormState build(String leadId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FollowUpFormState, FollowUpFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FollowUpFormState, FollowUpFormState>,
              FollowUpFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
