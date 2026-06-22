import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/auth_session.dart';

/// Persists the **entire** logged-in [AuthSession] (user, roles, permissions
/// and token) to local storage as JSON, so the data survives an app restart.
///
/// The decoded session is cached in memory, which lets the app read it
/// synchronously on startup (e.g. to seed `authSessionProvider`). Call
/// [SessionStore.load] once before `runApp`.
class SessionStore {
  static const _key = 'auth.session';

  final SharedPreferences _prefs;
  AuthSession? _cached;

  SessionStore._(this._prefs) {
    final raw = _prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        _cached = AuthSession.fromJson(
          (jsonDecode(raw) as Map).cast<String, dynamic>(),
        );
        if (kDebugMode) {
          // developer.log('Restored session from storage: $raw', name: 'AUTH');
        }
      } catch (e) {
        // Corrupt/old data — drop it rather than crashing on startup.
        _prefs.remove(_key);
      }
    }
  }

  /// Loads SharedPreferences and hydrates the cached session from disk.
  static Future<SessionStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SessionStore._(prefs);
  }

  /// The persisted session, or `null` if the user has never logged in / logged
  /// out. Available synchronously once [load] has completed.
  AuthSession? get cached => _cached;

  Future<void> save(AuthSession session) async {
    _cached = session;
    await _prefs.setString(_key, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    _cached = null;
    await _prefs.remove(_key);
  }
}
