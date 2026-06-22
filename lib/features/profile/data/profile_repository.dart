import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/network_providers.dart';
import '../model/profile_model.dart';

/// Talks to the backend's profile endpoint through [ApiClient]. The bearer
/// token is attached automatically by the auth interceptor, so callers only
/// need to be logged in.
class ProfileRepository {
  final ApiClient _api;

  ProfileRepository(this._api);

  /// GET /my-profile → the current user's [UserProfile].
  Future<ApiResult<UserProfile>> getProfile() {
    return _api.get<UserProfile>(
      ApiConstants.myProfile,
      decoder: _decodeProfile,
    );
  }

  /// POST /my-profile (multipart/form-data) → updates the profile.
  ///
  /// Only non-null fields are sent. [avatarPath] is the local path of a newly
  /// picked image; when provided it is uploaded as the `avatar` file field.
  /// Returns the updated [UserProfile] from the response.
  Future<ApiResult<UserProfile>> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? city,
    String? avatarPath,
  }) async {
    final form = FormData.fromMap({
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (avatarPath != null && avatarPath.isNotEmpty)
        'avatar': await MultipartFile.fromFile(
          avatarPath,
          filename: avatarPath.split(RegExp(r'[/\\]')).last,
        ),
    });

    return _api.post<UserProfile>(
      ApiConstants.myProfile,
      data: form,
      decoder: _decodeProfile,
    );
  }

  /// Unwraps the standard `{ success, message, data: {...} }` envelope.
  static UserProfile _decodeProfile(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();

    if (map['success'] == false) {
      throw ApiException(
        type: ApiErrorType.validation,
        message: map['message'] as String? ?? 'Could not load profile.',
        raw: json,
      );
    }

    final data = (map['data'] as Map?)?.cast<String, dynamic>();
    if (data == null) {
      throw ApiException.unexpected('Profile response had no "data" object.');
    }
    return UserProfile.fromJson(data);
  }
}

/// DI for the repository.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

/// Loads the current user's profile from `GET /my-profile`. Watch this from the
/// UI (e.g. the drawer header) to show the live name, email and avatar.
/// `ref.refresh(profileProvider)` re-fetches it.
final profileProvider = FutureProvider<UserProfile>((ref) async {
  final result = await ref.watch(profileRepositoryProvider).getProfile();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});
