// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_quotation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the "Create Quotation" form state, keyed by opportunity id and
/// auto-disposed so each visit starts fresh. Replaces the screen's local
/// `setState` so the form is Riverpod-managed too.

@ProviderFor(CreateQuotationForm)
final createQuotationFormProvider = CreateQuotationFormFamily._();

/// Holds the "Create Quotation" form state, keyed by opportunity id and
/// auto-disposed so each visit starts fresh. Replaces the screen's local
/// `setState` so the form is Riverpod-managed too.
final class CreateQuotationFormProvider
    extends $NotifierProvider<CreateQuotationForm, CreateQuotationFormState> {
  /// Holds the "Create Quotation" form state, keyed by opportunity id and
  /// auto-disposed so each visit starts fresh. Replaces the screen's local
  /// `setState` so the form is Riverpod-managed too.
  CreateQuotationFormProvider._({
    required CreateQuotationFormFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'createQuotationFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$createQuotationFormHash();

  @override
  String toString() {
    return r'createQuotationFormProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CreateQuotationForm create() => CreateQuotationForm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateQuotationFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateQuotationFormState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CreateQuotationFormProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$createQuotationFormHash() =>
    r'fad35ba5284fd5abf5c9db35258e01ee9ddfbb3d';

/// Holds the "Create Quotation" form state, keyed by opportunity id and
/// auto-disposed so each visit starts fresh. Replaces the screen's local
/// `setState` so the form is Riverpod-managed too.

final class CreateQuotationFormFamily extends $Family
    with
        $ClassFamilyOverride<
          CreateQuotationForm,
          CreateQuotationFormState,
          CreateQuotationFormState,
          CreateQuotationFormState,
          String
        > {
  CreateQuotationFormFamily._()
    : super(
        retry: null,
        name: r'createQuotationFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Holds the "Create Quotation" form state, keyed by opportunity id and
  /// auto-disposed so each visit starts fresh. Replaces the screen's local
  /// `setState` so the form is Riverpod-managed too.

  CreateQuotationFormProvider call(String opportunityId) =>
      CreateQuotationFormProvider._(argument: opportunityId, from: this);

  @override
  String toString() => r'createQuotationFormProvider';
}

/// Holds the "Create Quotation" form state, keyed by opportunity id and
/// auto-disposed so each visit starts fresh. Replaces the screen's local
/// `setState` so the form is Riverpod-managed too.

abstract class _$CreateQuotationForm
    extends $Notifier<CreateQuotationFormState> {
  late final _$args = ref.$arg as String;
  String get opportunityId => _$args;

  CreateQuotationFormState build(String opportunityId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<CreateQuotationFormState, CreateQuotationFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CreateQuotationFormState, CreateQuotationFormState>,
              CreateQuotationFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
