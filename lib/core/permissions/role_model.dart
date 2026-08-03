/// Models for `GET /api/roles`.
///
/// ```json
/// {
///   "success": true,
///   "data": [
///     {
///       "id": 3,
///       "name": "emp",
///       "guard_name": "web",
///       "permissions_map": { "dashboard.view": true, "roles.view": false, ... },
///       "permissions": [
///         { "id": 1, "name": "dashboard.view", "access": true, ... }, ...
///       ]
///     }
///   ]
/// }
/// ```
///
/// Plain immutable classes with manual `fromJson`, matching the rest of the
/// project's model style. Missing/odd fields fall back to safe defaults so one
/// bad entry can't crash the parse.
library;

class RolePermission {
  final int id;
  final String name;
  final String guardName;

  /// `true` = the role is allowed to do this, `false` = denied.
  final bool access;

  const RolePermission({
    required this.id,
    required this.name,
    required this.guardName,
    required this.access,
  });

  factory RolePermission.fromJson(Map<String, dynamic> json) {
    return RolePermission(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      guardName: json['guard_name'] as String? ?? '',
      access: _asBool(json['access']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'guard_name': guardName,
        'access': access,
      };
}

class RoleModel {
  final int id;

  /// Role name as stored by the backend, e.g. `emp`, `Owner`.
  final String name;
  final String guardName;

  /// Flat `permission name → granted?` map. This is what the app actually
  /// gates on. Built from `permissions_map` when present, otherwise folded
  /// from the `permissions` array.
  final Map<String, bool> permissionsMap;

  const RoleModel({
    required this.id,
    required this.name,
    required this.guardName,
    required this.permissionsMap,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    final map = <String, bool>{};

    // Preferred source: the ready-made `permissions_map` object.
    final rawMap = json['permissions_map'];
    if (rawMap is Map) {
      rawMap.forEach((key, value) {
        map['$key'] = _asBool(value);
      });
    }

    // Fallback / top-up: the detailed `permissions` array. Only fills keys the
    // map didn't already provide, so `permissions_map` stays authoritative.
    final rawList = json['permissions'];
    if (rawList is List) {
      for (final entry in rawList) {
        if (entry is! Map) continue;
        final perm = RolePermission.fromJson(entry.cast<String, dynamic>());
        if (perm.name.isEmpty) continue;
        map.putIfAbsent(perm.name, () => perm.access);
      }
    }

    return RoleModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      guardName: json['guard_name'] as String? ?? '',
      permissionsMap: Map.unmodifiable(map),
    );
  }
}

/// Accepts the several shapes a backend may use for a boolean: `true`, `1`,
/// `"1"`, `"true"`. Anything else (including `null`) is `false`.
bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.toLowerCase().trim();
    return v == '1' || v == 'true' || v == 'yes';
  }
  return false;
}
