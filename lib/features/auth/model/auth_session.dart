/// Domain models for the authenticated user and their session.
///
/// These mirror the `data` object returned by `POST /api/v1/login`:
/// ```json
/// { "user": {...}, "roles": [...], "permissions": [...], "token": "..." }
/// ```
/// Plain immutable classes with manual `fromJson`, matching the rest of the
/// project's model style. Missing/null fields fall back to safe defaults so a
/// single odd field can't crash the parse.
library;

class AuthUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'avatar': avatar,
      };
}

class AuthSession {
  final AuthUser user;
  final List<String> roles;
  final List<String> permissions;
  final String token;

  const AuthSession({
    required this.user,
    required this.roles,
    required this.permissions,
    required this.token,
  });

  /// `true` if the user holds the given permission string, e.g. `leads.add`.
  bool can(String permission) => permissions.contains(permission);

  /// `true` if the user has the given role, e.g. `Owner`.
  bool hasRole(String role) => roles.contains(role);

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: AuthUser.fromJson(
        (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      roles: _stringList(json['roles']),
      permissions: _stringList(json['permissions']),
      token: json['token'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'roles': roles,
        'permissions': permissions,
        'token': token,
      };

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => '$e').toList(growable: false);
    }
    return const [];
  }
}
