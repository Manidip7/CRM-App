import 'package:shared_preferences/shared_preferences.dart';

import 'token_storage.dart';

/// [TokenStorage] backed by [SharedPreferences] so the bearer token survives
/// an app restart. The token is also mirrored in memory because the rest of
/// the networking layer (e.g. [AuthInterceptor]) reads it synchronously.
///
/// Call [PersistentTokenStorage.load] once at startup before building the
/// Dio client so the cached token is available on the very first request.
class PersistentTokenStorage implements TokenStorage {
  static const _accessKey = 'auth.access_token';
  static const _refreshKey = 'auth.refresh_token';

  final SharedPreferences _prefs;
  String? _accessToken;
  String? _refreshToken;

  PersistentTokenStorage._(this._prefs) {
    _accessToken = _prefs.getString(_accessKey);
    _refreshToken = _prefs.getString(_refreshKey);
  }

  /// Loads SharedPreferences and hydrates the in-memory cache from disk.
  static Future<PersistentTokenStorage> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PersistentTokenStorage._(prefs);
  }

  @override
  String? get accessToken => _accessToken;

  @override
  String? get refreshToken => _refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _accessToken = accessToken;
    await _prefs.setString(_accessKey, accessToken);

    if (refreshToken != null) {
      _refreshToken = refreshToken;
      await _prefs.setString(_refreshKey, refreshToken);
    }
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    await _prefs.remove(_accessKey);
    await _prefs.remove(_refreshKey);
  }
}
