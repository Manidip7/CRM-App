import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_constants.dart';

/// The CRM server this device is pointed at, chosen on first launch by typing
/// the address or scanning the QR code the admin provides.
///
/// [origin] is the bare scheme + host (`https://demo.peplocrm.in`) — never with
/// a trailing slash or the `/api/v1` suffix, so [apiBaseUrl] can build the same
/// URL every other part of the app already expects.
class ServerConfig {
  final String origin;

  /// Company details as reported by the tenant lookup, shown on the setup and
  /// login screens so the user can see *which* CRM they reached. The logo is
  /// only set when that lookup includes one.
  final String? companyName;
  final String? logoUrl;

  const ServerConfig({required this.origin, this.companyName, this.logoUrl});

  String get apiBaseUrl => '$origin${ApiConstants.apiPrefix}';

  /// The host on its own (`demo.peplocrm.in`), for compact display.
  String get displayHost => Uri.tryParse(origin)?.host ?? origin;

  /// Cleans up whatever the user typed or the QR code carried, and returns the
  /// origin — or null when there is no usable host in it.
  ///
  /// Accepts `demo.peplocrm.in`, `https://demo.peplocrm.in/`,
  /// `https://demo.peplocrm.in/api/v1`, and trims stray spaces, because all
  /// four are things people really paste in.
  static String? normalizeOrigin(String input) {
    var text = input.trim();
    if (text.isEmpty) return null;

    // No scheme typed → assume https rather than silently failing to parse.
    if (!text.contains('://')) text = 'https://$text';

    final uri = Uri.tryParse(text);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;

    // Drop anything past the host: an admin who pastes the API root or a deep
    // link shouldn't end up with `/api/v1/api/v1/leads`.
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  Map<String, dynamic> toJson() => {
    'origin': origin,
    'company_name': companyName,
    'logo_url': logoUrl,
  };

  factory ServerConfig.fromJson(Map<String, dynamic> json) => ServerConfig(
    origin: json['origin'] as String,
    companyName: json['company_name'] as String?,
    logoUrl: json['logo_url'] as String?,
  );
}

/// Persists the chosen [ServerConfig] so the setup screen is a genuine
/// first-launch step: every later start goes straight to login.
///
/// Deliberately survives logout — signing out changes the user, not the server
/// the company runs. Call [load] once before `runApp`, like the session and
/// permission stores.
class ServerConfigStore {
  static const _key = 'server.config';

  /// The last address that passed the check, kept **separately** and on purpose
  /// not wiped by [clear]: signing out or switching servers should still leave
  /// the setup screen able to offer the address this device used last, so a
  /// returning user doesn't have to find the link again.
  static const _lastAddressKey = 'server.last_address';

  final SharedPreferences _prefs;
  ServerConfig? _cached;

  ServerConfigStore._(this._prefs) {
    final raw = _prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        _cached = ServerConfig.fromJson(
          (jsonDecode(raw) as Map).cast<String, dynamic>(),
        );
      } catch (_) {
        // Corrupt/old data — drop it and let the user set the server up again
        // rather than crashing on startup.
        _prefs.remove(_key);
      }
    }
  }

  static Future<ServerConfigStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ServerConfigStore._(prefs);
  }

  /// The saved server, or null on a first launch. Available synchronously once
  /// [load] has completed.
  ServerConfig? get cached => _cached;

  /// The address this device last connected to, whether or not a server is
  /// currently set. Used to pre-fill the setup screen.
  String? get lastAddress =>
      _cached?.displayHost ?? _prefs.getString(_lastAddressKey);

  Future<void> save(ServerConfig config) async {
    _cached = config;
    await _prefs.setString(_key, jsonEncode(config.toJson()));
    await _prefs.setString(_lastAddressKey, config.displayHost);
  }

  /// Forgets the active server but keeps [lastAddress].
  Future<void> clear() async {
    _cached = null;
    await _prefs.remove(_key);
  }
}
