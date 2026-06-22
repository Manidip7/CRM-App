// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EditProfileController)
final editProfileControllerProvider = EditProfileControllerProvider._();

final class EditProfileControllerProvider
    extends $NotifierProvider<EditProfileController, EditProfileState> {
  EditProfileControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'editProfileControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$editProfileControllerHash();

  @$internal
  @override
  EditProfileController create() => EditProfileController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EditProfileState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EditProfileState>(value),
    );
  }
}

String _$editProfileControllerHash() =>
    r'835d0dc376e936d202a4d7a0abac057509271c3f';

abstract class _$EditProfileController extends $Notifier<EditProfileState> {
  EditProfileState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<EditProfileState, EditProfileState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EditProfileState, EditProfileState>,
              EditProfileState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
