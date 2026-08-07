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

String _$leadViewHash() => r'fff5c8d30923b25d639dd57e596521851acf2ff0';

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

String _$addNoteHash() => r'6782ad370637ae2846c81276b40e4f6a2014033e';

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

/// Deletes a note from a lead (`DELETE /leads/{id}/notes/{noteId}`), keyed by
/// lead id. The state is the id of the note currently being deleted (`null`
/// when idle), so the notes tab can show a spinner on just that card. On
/// success it refreshes the lead's detail bundle so the note disappears.

@ProviderFor(DeleteLeadNote)
final deleteLeadNoteProvider = DeleteLeadNoteFamily._();

/// Deletes a note from a lead (`DELETE /leads/{id}/notes/{noteId}`), keyed by
/// lead id. The state is the id of the note currently being deleted (`null`
/// when idle), so the notes tab can show a spinner on just that card. On
/// success it refreshes the lead's detail bundle so the note disappears.
final class DeleteLeadNoteProvider
    extends $NotifierProvider<DeleteLeadNote, int?> {
  /// Deletes a note from a lead (`DELETE /leads/{id}/notes/{noteId}`), keyed by
  /// lead id. The state is the id of the note currently being deleted (`null`
  /// when idle), so the notes tab can show a spinner on just that card. On
  /// success it refreshes the lead's detail bundle so the note disappears.
  DeleteLeadNoteProvider._({
    required DeleteLeadNoteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'deleteLeadNoteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$deleteLeadNoteHash();

  @override
  String toString() {
    return r'deleteLeadNoteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DeleteLeadNote create() => DeleteLeadNote();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DeleteLeadNoteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$deleteLeadNoteHash() => r'efd61f6e9777e5f814bbf5e6dd0519eb57974e1c';

/// Deletes a note from a lead (`DELETE /leads/{id}/notes/{noteId}`), keyed by
/// lead id. The state is the id of the note currently being deleted (`null`
/// when idle), so the notes tab can show a spinner on just that card. On
/// success it refreshes the lead's detail bundle so the note disappears.

final class DeleteLeadNoteFamily extends $Family
    with $ClassFamilyOverride<DeleteLeadNote, int?, int?, int?, String> {
  DeleteLeadNoteFamily._()
    : super(
        retry: null,
        name: r'deleteLeadNoteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Deletes a note from a lead (`DELETE /leads/{id}/notes/{noteId}`), keyed by
  /// lead id. The state is the id of the note currently being deleted (`null`
  /// when idle), so the notes tab can show a spinner on just that card. On
  /// success it refreshes the lead's detail bundle so the note disappears.

  DeleteLeadNoteProvider call(String leadId) =>
      DeleteLeadNoteProvider._(argument: leadId, from: this);

  @override
  String toString() => r'deleteLeadNoteProvider';
}

/// Deletes a note from a lead (`DELETE /leads/{id}/notes/{noteId}`), keyed by
/// lead id. The state is the id of the note currently being deleted (`null`
/// when idle), so the notes tab can show a spinner on just that card. On
/// success it refreshes the lead's detail bundle so the note disappears.

abstract class _$DeleteLeadNote extends $Notifier<int?> {
  late final _$args = ref.$arg as String;
  String get leadId => _$args;

  int? build(String leadId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
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

/// Backs the lead's Add / Edit Task sheet, keyed by lead id and — when editing —
/// the task id, so each sheet keeps its own form. Auto-disposed, so the form
/// resets every time the sheet opens. [taskId] `null` means "create": submitting
/// posts to `/leads/{id}/tasks`; otherwise it puts to `/leads/{id}/tasks/{taskId}`.
/// The initial values seed the form from the task being edited. On success it
/// refreshes the lead's detail bundle so the tasks tab reflects the change.

@ProviderFor(LeadTaskForm)
final leadTaskFormProvider = LeadTaskFormFamily._();

/// Backs the lead's Add / Edit Task sheet, keyed by lead id and — when editing —
/// the task id, so each sheet keeps its own form. Auto-disposed, so the form
/// resets every time the sheet opens. [taskId] `null` means "create": submitting
/// posts to `/leads/{id}/tasks`; otherwise it puts to `/leads/{id}/tasks/{taskId}`.
/// The initial values seed the form from the task being edited. On success it
/// refreshes the lead's detail bundle so the tasks tab reflects the change.
final class LeadTaskFormProvider
    extends $NotifierProvider<LeadTaskForm, LeadTaskFormState> {
  /// Backs the lead's Add / Edit Task sheet, keyed by lead id and — when editing —
  /// the task id, so each sheet keeps its own form. Auto-disposed, so the form
  /// resets every time the sheet opens. [taskId] `null` means "create": submitting
  /// posts to `/leads/{id}/tasks`; otherwise it puts to `/leads/{id}/tasks/{taskId}`.
  /// The initial values seed the form from the task being edited. On success it
  /// refreshes the lead's detail bundle so the tasks tab reflects the change.
  LeadTaskFormProvider._({
    required LeadTaskFormFamily super.from,
    required (
      String, {
      int? taskId,
      DateTime? initialDueAt,
      String initialPriority,
      String initialStatus,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'leadTaskFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$leadTaskFormHash();

  @override
  String toString() {
    return r'leadTaskFormProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  LeadTaskForm create() => LeadTaskForm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeadTaskFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeadTaskFormState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LeadTaskFormProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$leadTaskFormHash() => r'78394d301c8e49dbd24140956591807c3578a48e';

/// Backs the lead's Add / Edit Task sheet, keyed by lead id and — when editing —
/// the task id, so each sheet keeps its own form. Auto-disposed, so the form
/// resets every time the sheet opens. [taskId] `null` means "create": submitting
/// posts to `/leads/{id}/tasks`; otherwise it puts to `/leads/{id}/tasks/{taskId}`.
/// The initial values seed the form from the task being edited. On success it
/// refreshes the lead's detail bundle so the tasks tab reflects the change.

final class LeadTaskFormFamily extends $Family
    with
        $ClassFamilyOverride<
          LeadTaskForm,
          LeadTaskFormState,
          LeadTaskFormState,
          LeadTaskFormState,
          (
            String, {
            int? taskId,
            DateTime? initialDueAt,
            String initialPriority,
            String initialStatus,
          })
        > {
  LeadTaskFormFamily._()
    : super(
        retry: null,
        name: r'leadTaskFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Backs the lead's Add / Edit Task sheet, keyed by lead id and — when editing —
  /// the task id, so each sheet keeps its own form. Auto-disposed, so the form
  /// resets every time the sheet opens. [taskId] `null` means "create": submitting
  /// posts to `/leads/{id}/tasks`; otherwise it puts to `/leads/{id}/tasks/{taskId}`.
  /// The initial values seed the form from the task being edited. On success it
  /// refreshes the lead's detail bundle so the tasks tab reflects the change.

  LeadTaskFormProvider call(
    String leadId, {
    int? taskId,
    DateTime? initialDueAt,
    String initialPriority = 'medium',
    String initialStatus = 'open',
  }) => LeadTaskFormProvider._(
    argument: (
      leadId,
      taskId: taskId,
      initialDueAt: initialDueAt,
      initialPriority: initialPriority,
      initialStatus: initialStatus,
    ),
    from: this,
  );

  @override
  String toString() => r'leadTaskFormProvider';
}

/// Backs the lead's Add / Edit Task sheet, keyed by lead id and — when editing —
/// the task id, so each sheet keeps its own form. Auto-disposed, so the form
/// resets every time the sheet opens. [taskId] `null` means "create": submitting
/// posts to `/leads/{id}/tasks`; otherwise it puts to `/leads/{id}/tasks/{taskId}`.
/// The initial values seed the form from the task being edited. On success it
/// refreshes the lead's detail bundle so the tasks tab reflects the change.

abstract class _$LeadTaskForm extends $Notifier<LeadTaskFormState> {
  late final _$args =
      ref.$arg
          as (
            String, {
            int? taskId,
            DateTime? initialDueAt,
            String initialPriority,
            String initialStatus,
          });
  String get leadId => _$args.$1;
  int? get taskId => _$args.taskId;
  DateTime? get initialDueAt => _$args.initialDueAt;
  String get initialPriority => _$args.initialPriority;
  String get initialStatus => _$args.initialStatus;

  LeadTaskFormState build(
    String leadId, {
    int? taskId,
    DateTime? initialDueAt,
    String initialPriority = 'medium',
    String initialStatus = 'open',
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<LeadTaskFormState, LeadTaskFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LeadTaskFormState, LeadTaskFormState>,
              LeadTaskFormState,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(
        _$args.$1,
        taskId: _$args.taskId,
        initialDueAt: _$args.initialDueAt,
        initialPriority: _$args.initialPriority,
        initialStatus: _$args.initialStatus,
      ),
    );
  }
}

/// Deletes a task from a lead (`DELETE /leads/{id}/tasks/{taskId}`), keyed by
/// lead id. The state is the id of the task currently being deleted (`null`
/// when idle), so the tasks tab can show a spinner on just that card. On
/// success it refreshes the lead's detail bundle so the task disappears.

@ProviderFor(DeleteLeadTask)
final deleteLeadTaskProvider = DeleteLeadTaskFamily._();

/// Deletes a task from a lead (`DELETE /leads/{id}/tasks/{taskId}`), keyed by
/// lead id. The state is the id of the task currently being deleted (`null`
/// when idle), so the tasks tab can show a spinner on just that card. On
/// success it refreshes the lead's detail bundle so the task disappears.
final class DeleteLeadTaskProvider
    extends $NotifierProvider<DeleteLeadTask, int?> {
  /// Deletes a task from a lead (`DELETE /leads/{id}/tasks/{taskId}`), keyed by
  /// lead id. The state is the id of the task currently being deleted (`null`
  /// when idle), so the tasks tab can show a spinner on just that card. On
  /// success it refreshes the lead's detail bundle so the task disappears.
  DeleteLeadTaskProvider._({
    required DeleteLeadTaskFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'deleteLeadTaskProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$deleteLeadTaskHash();

  @override
  String toString() {
    return r'deleteLeadTaskProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DeleteLeadTask create() => DeleteLeadTask();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DeleteLeadTaskProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$deleteLeadTaskHash() => r'd483dfb4bb4aeb043241decee99d7803e5eb95ab';

/// Deletes a task from a lead (`DELETE /leads/{id}/tasks/{taskId}`), keyed by
/// lead id. The state is the id of the task currently being deleted (`null`
/// when idle), so the tasks tab can show a spinner on just that card. On
/// success it refreshes the lead's detail bundle so the task disappears.

final class DeleteLeadTaskFamily extends $Family
    with $ClassFamilyOverride<DeleteLeadTask, int?, int?, int?, String> {
  DeleteLeadTaskFamily._()
    : super(
        retry: null,
        name: r'deleteLeadTaskProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Deletes a task from a lead (`DELETE /leads/{id}/tasks/{taskId}`), keyed by
  /// lead id. The state is the id of the task currently being deleted (`null`
  /// when idle), so the tasks tab can show a spinner on just that card. On
  /// success it refreshes the lead's detail bundle so the task disappears.

  DeleteLeadTaskProvider call(String leadId) =>
      DeleteLeadTaskProvider._(argument: leadId, from: this);

  @override
  String toString() => r'deleteLeadTaskProvider';
}

/// Deletes a task from a lead (`DELETE /leads/{id}/tasks/{taskId}`), keyed by
/// lead id. The state is the id of the task currently being deleted (`null`
/// when idle), so the tasks tab can show a spinner on just that card. On
/// success it refreshes the lead's detail bundle so the task disappears.

abstract class _$DeleteLeadTask extends $Notifier<int?> {
  late final _$args = ref.$arg as String;
  String get leadId => _$args;

  int? build(String leadId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
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

/// Holds the "Assign Lead" form state, keyed by lead id and auto-disposed so
/// each time the sheet opens it starts fresh. Replaces the sheet's local
/// `setState` so the form is Riverpod-managed too.

@ProviderFor(AssignLeadForm)
final assignLeadFormProvider = AssignLeadFormFamily._();

/// Holds the "Assign Lead" form state, keyed by lead id and auto-disposed so
/// each time the sheet opens it starts fresh. Replaces the sheet's local
/// `setState` so the form is Riverpod-managed too.
final class AssignLeadFormProvider
    extends $NotifierProvider<AssignLeadForm, AssignLeadFormState> {
  /// Holds the "Assign Lead" form state, keyed by lead id and auto-disposed so
  /// each time the sheet opens it starts fresh. Replaces the sheet's local
  /// `setState` so the form is Riverpod-managed too.
  AssignLeadFormProvider._({
    required AssignLeadFormFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'assignLeadFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$assignLeadFormHash();

  @override
  String toString() {
    return r'assignLeadFormProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AssignLeadForm create() => AssignLeadForm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AssignLeadFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AssignLeadFormState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AssignLeadFormProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$assignLeadFormHash() => r'acbc1ac44eb08f361ebd5436847432c797ad37ca';

/// Holds the "Assign Lead" form state, keyed by lead id and auto-disposed so
/// each time the sheet opens it starts fresh. Replaces the sheet's local
/// `setState` so the form is Riverpod-managed too.

final class AssignLeadFormFamily extends $Family
    with
        $ClassFamilyOverride<
          AssignLeadForm,
          AssignLeadFormState,
          AssignLeadFormState,
          AssignLeadFormState,
          String
        > {
  AssignLeadFormFamily._()
    : super(
        retry: null,
        name: r'assignLeadFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Holds the "Assign Lead" form state, keyed by lead id and auto-disposed so
  /// each time the sheet opens it starts fresh. Replaces the sheet's local
  /// `setState` so the form is Riverpod-managed too.

  AssignLeadFormProvider call(String leadId) =>
      AssignLeadFormProvider._(argument: leadId, from: this);

  @override
  String toString() => r'assignLeadFormProvider';
}

/// Holds the "Assign Lead" form state, keyed by lead id and auto-disposed so
/// each time the sheet opens it starts fresh. Replaces the sheet's local
/// `setState` so the form is Riverpod-managed too.

abstract class _$AssignLeadForm extends $Notifier<AssignLeadFormState> {
  late final _$args = ref.$arg as String;
  String get leadId => _$args;

  AssignLeadFormState build(String leadId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AssignLeadFormState, AssignLeadFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AssignLeadFormState, AssignLeadFormState>,
              AssignLeadFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
