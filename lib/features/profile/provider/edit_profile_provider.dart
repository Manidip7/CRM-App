import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_result.dart';
import '../data/profile_repository.dart';

part 'edit_profile_provider.freezed.dart';
part 'edit_profile_provider.g.dart';

/// UI state for the edit-profile form: the locally picked avatar path (if the
/// user chose a new image) and whether a save is in progress.
@freezed
abstract class EditProfileState with _$EditProfileState {
  const factory EditProfileState({
    String? avatarPath,
    @Default(false) bool isSaving,
  }) = _EditProfileState;
}

@riverpod
class EditProfileController extends _$EditProfileController {
  @override
  EditProfileState build() => const EditProfileState();

  /// Records the local path of a newly picked avatar image.
  void pickAvatar(String path) => state = state.copyWith(avatarPath: path);

  /// Submits the form. On success, refreshes [profileProvider] so the drawer
  /// and top bar pick up the new data. Returns the [ApiResult] so the UI can
  /// show a success/error message.
  Future<ApiResult<void>> save({
    required String name,
    required String phone,
    required String address,
    required String city,
  }) async {
    state = state.copyWith(isSaving: true);

    final result = await ref.read(profileRepositoryProvider).updateProfile(
          name: name,
          phone: phone,
          address: address,
          city: city,
          avatarPath: state.avatarPath,
        );

    state = state.copyWith(isSaving: false);

    if (result is Success) {
      ref.invalidate(profileProvider);
    }
    return result.map((_) {});
  }
}
