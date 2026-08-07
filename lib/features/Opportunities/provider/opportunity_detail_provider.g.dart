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

/// Handles adding a note to an opportunity (`POST /opportunities/{id}/notes`),
/// keyed by opportunity id. The state is the in-flight `saving` flag. On success
/// it refreshes the opportunity's detail bundle so the new note appears.

@ProviderFor(AddOpportunityNote)
final addOpportunityNoteProvider = AddOpportunityNoteFamily._();

/// Handles adding a note to an opportunity (`POST /opportunities/{id}/notes`),
/// keyed by opportunity id. The state is the in-flight `saving` flag. On success
/// it refreshes the opportunity's detail bundle so the new note appears.
final class AddOpportunityNoteProvider
    extends $NotifierProvider<AddOpportunityNote, bool> {
  /// Handles adding a note to an opportunity (`POST /opportunities/{id}/notes`),
  /// keyed by opportunity id. The state is the in-flight `saving` flag. On success
  /// it refreshes the opportunity's detail bundle so the new note appears.
  AddOpportunityNoteProvider._({
    required AddOpportunityNoteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'addOpportunityNoteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$addOpportunityNoteHash();

  @override
  String toString() {
    return r'addOpportunityNoteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AddOpportunityNote create() => AddOpportunityNote();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AddOpportunityNoteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$addOpportunityNoteHash() =>
    r'7470c3576360eecabcd2eab2ff3720feef576ee7';

/// Handles adding a note to an opportunity (`POST /opportunities/{id}/notes`),
/// keyed by opportunity id. The state is the in-flight `saving` flag. On success
/// it refreshes the opportunity's detail bundle so the new note appears.

final class AddOpportunityNoteFamily extends $Family
    with $ClassFamilyOverride<AddOpportunityNote, bool, bool, bool, String> {
  AddOpportunityNoteFamily._()
    : super(
        retry: null,
        name: r'addOpportunityNoteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Handles adding a note to an opportunity (`POST /opportunities/{id}/notes`),
  /// keyed by opportunity id. The state is the in-flight `saving` flag. On success
  /// it refreshes the opportunity's detail bundle so the new note appears.

  AddOpportunityNoteProvider call(String opportunityId) =>
      AddOpportunityNoteProvider._(argument: opportunityId, from: this);

  @override
  String toString() => r'addOpportunityNoteProvider';
}

/// Handles adding a note to an opportunity (`POST /opportunities/{id}/notes`),
/// keyed by opportunity id. The state is the in-flight `saving` flag. On success
/// it refreshes the opportunity's detail bundle so the new note appears.

abstract class _$AddOpportunityNote extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get opportunityId => _$args;

  bool build(String opportunityId);
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

/// Deletes a note from an opportunity (`DELETE /opportunities/{id}/notes/{noteId}`),
/// keyed by opportunity id. The state is the id of the note currently being
/// deleted (`null` when idle), so the notes tab can show a spinner on just that
/// card. On success it refreshes the detail bundle so the note disappears.

@ProviderFor(DeleteOpportunityNote)
final deleteOpportunityNoteProvider = DeleteOpportunityNoteFamily._();

/// Deletes a note from an opportunity (`DELETE /opportunities/{id}/notes/{noteId}`),
/// keyed by opportunity id. The state is the id of the note currently being
/// deleted (`null` when idle), so the notes tab can show a spinner on just that
/// card. On success it refreshes the detail bundle so the note disappears.
final class DeleteOpportunityNoteProvider
    extends $NotifierProvider<DeleteOpportunityNote, int?> {
  /// Deletes a note from an opportunity (`DELETE /opportunities/{id}/notes/{noteId}`),
  /// keyed by opportunity id. The state is the id of the note currently being
  /// deleted (`null` when idle), so the notes tab can show a spinner on just that
  /// card. On success it refreshes the detail bundle so the note disappears.
  DeleteOpportunityNoteProvider._({
    required DeleteOpportunityNoteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'deleteOpportunityNoteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$deleteOpportunityNoteHash();

  @override
  String toString() {
    return r'deleteOpportunityNoteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DeleteOpportunityNote create() => DeleteOpportunityNote();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DeleteOpportunityNoteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$deleteOpportunityNoteHash() =>
    r'6c7e7d42fa5938ee52112d9c22c84534df908db5';

/// Deletes a note from an opportunity (`DELETE /opportunities/{id}/notes/{noteId}`),
/// keyed by opportunity id. The state is the id of the note currently being
/// deleted (`null` when idle), so the notes tab can show a spinner on just that
/// card. On success it refreshes the detail bundle so the note disappears.

final class DeleteOpportunityNoteFamily extends $Family
    with $ClassFamilyOverride<DeleteOpportunityNote, int?, int?, int?, String> {
  DeleteOpportunityNoteFamily._()
    : super(
        retry: null,
        name: r'deleteOpportunityNoteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Deletes a note from an opportunity (`DELETE /opportunities/{id}/notes/{noteId}`),
  /// keyed by opportunity id. The state is the id of the note currently being
  /// deleted (`null` when idle), so the notes tab can show a spinner on just that
  /// card. On success it refreshes the detail bundle so the note disappears.

  DeleteOpportunityNoteProvider call(String opportunityId) =>
      DeleteOpportunityNoteProvider._(argument: opportunityId, from: this);

  @override
  String toString() => r'deleteOpportunityNoteProvider';
}

/// Deletes a note from an opportunity (`DELETE /opportunities/{id}/notes/{noteId}`),
/// keyed by opportunity id. The state is the id of the note currently being
/// deleted (`null` when idle), so the notes tab can show a spinner on just that
/// card. On success it refreshes the detail bundle so the note disappears.

abstract class _$DeleteOpportunityNote extends $Notifier<int?> {
  late final _$args = ref.$arg as String;
  String get opportunityId => _$args;

  int? build(String opportunityId);
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

/// Backs the opportunity's Add / Edit Task sheet, keyed by opportunity id and —
/// when editing — the task id, so each sheet keeps its own form. Auto-disposed,
/// so the form resets every time the sheet opens. [taskId] `null` means
/// "create": submitting posts to `/opportunities/{id}/tasks`; otherwise it puts
/// to `/opportunities/{id}/tasks/{taskId}`. The initial values seed the form
/// from the task being edited. On success it refreshes the detail bundle so the
/// Tasks tab reflects the change.

@ProviderFor(OpportunityTaskForm)
final opportunityTaskFormProvider = OpportunityTaskFormFamily._();

/// Backs the opportunity's Add / Edit Task sheet, keyed by opportunity id and —
/// when editing — the task id, so each sheet keeps its own form. Auto-disposed,
/// so the form resets every time the sheet opens. [taskId] `null` means
/// "create": submitting posts to `/opportunities/{id}/tasks`; otherwise it puts
/// to `/opportunities/{id}/tasks/{taskId}`. The initial values seed the form
/// from the task being edited. On success it refreshes the detail bundle so the
/// Tasks tab reflects the change.
final class OpportunityTaskFormProvider
    extends $NotifierProvider<OpportunityTaskForm, OpportunityTaskFormState> {
  /// Backs the opportunity's Add / Edit Task sheet, keyed by opportunity id and —
  /// when editing — the task id, so each sheet keeps its own form. Auto-disposed,
  /// so the form resets every time the sheet opens. [taskId] `null` means
  /// "create": submitting posts to `/opportunities/{id}/tasks`; otherwise it puts
  /// to `/opportunities/{id}/tasks/{taskId}`. The initial values seed the form
  /// from the task being edited. On success it refreshes the detail bundle so the
  /// Tasks tab reflects the change.
  OpportunityTaskFormProvider._({
    required OpportunityTaskFormFamily super.from,
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
         name: r'opportunityTaskFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$opportunityTaskFormHash();

  @override
  String toString() {
    return r'opportunityTaskFormProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  OpportunityTaskForm create() => OpportunityTaskForm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OpportunityTaskFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OpportunityTaskFormState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OpportunityTaskFormProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$opportunityTaskFormHash() =>
    r'd20fd2436362a2ab5aaac6c51ab06063ff474336';

/// Backs the opportunity's Add / Edit Task sheet, keyed by opportunity id and —
/// when editing — the task id, so each sheet keeps its own form. Auto-disposed,
/// so the form resets every time the sheet opens. [taskId] `null` means
/// "create": submitting posts to `/opportunities/{id}/tasks`; otherwise it puts
/// to `/opportunities/{id}/tasks/{taskId}`. The initial values seed the form
/// from the task being edited. On success it refreshes the detail bundle so the
/// Tasks tab reflects the change.

final class OpportunityTaskFormFamily extends $Family
    with
        $ClassFamilyOverride<
          OpportunityTaskForm,
          OpportunityTaskFormState,
          OpportunityTaskFormState,
          OpportunityTaskFormState,
          (
            String, {
            int? taskId,
            DateTime? initialDueAt,
            String initialPriority,
            String initialStatus,
          })
        > {
  OpportunityTaskFormFamily._()
    : super(
        retry: null,
        name: r'opportunityTaskFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Backs the opportunity's Add / Edit Task sheet, keyed by opportunity id and —
  /// when editing — the task id, so each sheet keeps its own form. Auto-disposed,
  /// so the form resets every time the sheet opens. [taskId] `null` means
  /// "create": submitting posts to `/opportunities/{id}/tasks`; otherwise it puts
  /// to `/opportunities/{id}/tasks/{taskId}`. The initial values seed the form
  /// from the task being edited. On success it refreshes the detail bundle so the
  /// Tasks tab reflects the change.

  OpportunityTaskFormProvider call(
    String opportunityId, {
    int? taskId,
    DateTime? initialDueAt,
    String initialPriority = 'medium',
    String initialStatus = 'open',
  }) => OpportunityTaskFormProvider._(
    argument: (
      opportunityId,
      taskId: taskId,
      initialDueAt: initialDueAt,
      initialPriority: initialPriority,
      initialStatus: initialStatus,
    ),
    from: this,
  );

  @override
  String toString() => r'opportunityTaskFormProvider';
}

/// Backs the opportunity's Add / Edit Task sheet, keyed by opportunity id and —
/// when editing — the task id, so each sheet keeps its own form. Auto-disposed,
/// so the form resets every time the sheet opens. [taskId] `null` means
/// "create": submitting posts to `/opportunities/{id}/tasks`; otherwise it puts
/// to `/opportunities/{id}/tasks/{taskId}`. The initial values seed the form
/// from the task being edited. On success it refreshes the detail bundle so the
/// Tasks tab reflects the change.

abstract class _$OpportunityTaskForm
    extends $Notifier<OpportunityTaskFormState> {
  late final _$args =
      ref.$arg
          as (
            String, {
            int? taskId,
            DateTime? initialDueAt,
            String initialPriority,
            String initialStatus,
          });
  String get opportunityId => _$args.$1;
  int? get taskId => _$args.taskId;
  DateTime? get initialDueAt => _$args.initialDueAt;
  String get initialPriority => _$args.initialPriority;
  String get initialStatus => _$args.initialStatus;

  OpportunityTaskFormState build(
    String opportunityId, {
    int? taskId,
    DateTime? initialDueAt,
    String initialPriority = 'medium',
    String initialStatus = 'open',
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<OpportunityTaskFormState, OpportunityTaskFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OpportunityTaskFormState, OpportunityTaskFormState>,
              OpportunityTaskFormState,
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

/// Deletes a task from an opportunity (`DELETE /opportunities/{id}/tasks/{taskId}`),
/// keyed by opportunity id. The state is the id of the task currently being
/// deleted (`null` when idle), so the Tasks tab can show a spinner on just that
/// card. On success it refreshes the detail bundle so the task disappears.

@ProviderFor(DeleteOpportunityTask)
final deleteOpportunityTaskProvider = DeleteOpportunityTaskFamily._();

/// Deletes a task from an opportunity (`DELETE /opportunities/{id}/tasks/{taskId}`),
/// keyed by opportunity id. The state is the id of the task currently being
/// deleted (`null` when idle), so the Tasks tab can show a spinner on just that
/// card. On success it refreshes the detail bundle so the task disappears.
final class DeleteOpportunityTaskProvider
    extends $NotifierProvider<DeleteOpportunityTask, int?> {
  /// Deletes a task from an opportunity (`DELETE /opportunities/{id}/tasks/{taskId}`),
  /// keyed by opportunity id. The state is the id of the task currently being
  /// deleted (`null` when idle), so the Tasks tab can show a spinner on just that
  /// card. On success it refreshes the detail bundle so the task disappears.
  DeleteOpportunityTaskProvider._({
    required DeleteOpportunityTaskFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'deleteOpportunityTaskProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$deleteOpportunityTaskHash();

  @override
  String toString() {
    return r'deleteOpportunityTaskProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DeleteOpportunityTask create() => DeleteOpportunityTask();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DeleteOpportunityTaskProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$deleteOpportunityTaskHash() =>
    r'9374e5a4bca845270efc681f29ae22713a01c5e3';

/// Deletes a task from an opportunity (`DELETE /opportunities/{id}/tasks/{taskId}`),
/// keyed by opportunity id. The state is the id of the task currently being
/// deleted (`null` when idle), so the Tasks tab can show a spinner on just that
/// card. On success it refreshes the detail bundle so the task disappears.

final class DeleteOpportunityTaskFamily extends $Family
    with $ClassFamilyOverride<DeleteOpportunityTask, int?, int?, int?, String> {
  DeleteOpportunityTaskFamily._()
    : super(
        retry: null,
        name: r'deleteOpportunityTaskProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Deletes a task from an opportunity (`DELETE /opportunities/{id}/tasks/{taskId}`),
  /// keyed by opportunity id. The state is the id of the task currently being
  /// deleted (`null` when idle), so the Tasks tab can show a spinner on just that
  /// card. On success it refreshes the detail bundle so the task disappears.

  DeleteOpportunityTaskProvider call(String opportunityId) =>
      DeleteOpportunityTaskProvider._(argument: opportunityId, from: this);

  @override
  String toString() => r'deleteOpportunityTaskProvider';
}

/// Deletes a task from an opportunity (`DELETE /opportunities/{id}/tasks/{taskId}`),
/// keyed by opportunity id. The state is the id of the task currently being
/// deleted (`null` when idle), so the Tasks tab can show a spinner on just that
/// card. On success it refreshes the detail bundle so the task disappears.

abstract class _$DeleteOpportunityTask extends $Notifier<int?> {
  late final _$args = ref.$arg as String;
  String get opportunityId => _$args;

  int? build(String opportunityId);
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
