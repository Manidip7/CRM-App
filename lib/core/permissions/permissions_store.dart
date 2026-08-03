import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Caches the last successfully resolved `permission → granted?` map on disk.
///
/// Why bother when the map is one API call away: without a cache, every cold
/// start renders the app *before* `GET /api/roles` answers, so drawer entries
/// and buttons would pop in and out a second after launch. Seeding from the
/// cache makes the first frame already correct, and the API response only
/// corrects it if the role changed server-side.
///
/// Mirrors [SessionStore]: decoded once in the constructor and kept in memory
/// so it can be read synchronously. Call [PermissionsStore.load] before
/// `runApp`.
class PermissionsStore {
  static const _key = 'auth.permissions_map';

  final SharedPreferences _prefs;
  Map<String, bool>? _cached;

  PermissionsStore._(this._prefs) {
    final raw = _prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = (jsonDecode(raw) as Map).cast<String, dynamic>();
        _cached = {
          for (final entry in decoded.entries) entry.key: entry.value == true,
        };
      } catch (_) {
        // Corrupt/old data — drop it rather than crashing on startup.
        _prefs.remove(_key);
      }
    }
  }

  static Future<PermissionsStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PermissionsStore._(prefs);
  }

  /// The last cached map, or `null` if we've never fetched one.
  Map<String, bool>? get cached => _cached;

  Future<void> save(Map<String, bool> map) async {
    // Nothing useful to remember, and writing `{}` would make the next launch
    // think it has real (empty = deny-all) data.
    if (map.isEmpty) return;
    if (_mapEquals(_cached, map)) return;
    _cached = Map.unmodifiable(map);
    await _prefs.setString(_key, jsonEncode(map));
  }

  Future<void> clear() async {
    _cached = null;
    await _prefs.remove(_key);
  }

  static bool _mapEquals(Map<String, bool>? a, Map<String, bool> b) {
    if (a == null || a.length != b.length) return false;
    for (final entry in b.entries) {
      if (a[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Holds the [PermissionsStore]. Overridden in `main()` with the instance
/// loaded from disk before the app starts.
///
/// Declared here — rather than next to the other permission providers — so the
/// auth layer can clear the cache on logout without importing anything that
/// imports it back.
final permissionsStoreProvider = Provider<PermissionsStore>((ref) {
  throw UnimplementedError(
    'permissionsStoreProvider must be overridden in main()',
  );
});
