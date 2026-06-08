/// Abstraction over where the auth token lives. The networking layer only
/// depends on this interface, so you can swap the in-memory implementation
/// below for `flutter_secure_storage` / `shared_preferences` later without
/// touching the Dio setup.
abstract interface class TokenStorage {
  String? get accessToken;
  String? get refreshToken;

  Future<void> saveTokens({required String accessToken, String? refreshToken});
  Future<void> clear();
}

/// Simple in-memory implementation. Tokens are lost when the app restarts —
/// fine for development. Replace with a persistent implementation for release.
class InMemoryTokenStorage implements TokenStorage {
  String? _accessToken;
  String? _refreshToken;

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
    _refreshToken = refreshToken ?? _refreshToken;
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
  }
}
