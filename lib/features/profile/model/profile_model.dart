/// The authenticated user's profile, mirroring the `data` object returned by
/// `GET /api/v1/my-profile`:
/// ```json
/// {
///   "id": 2, "name": "Admin Owner", "email": "owner@example.com",
///   "phone": "9088089888", "address": null, "city": null,
///   "avatar": "https://.../avatar.png", "roles": ["Owner"]
/// }
/// ```
/// Plain immutable class with manual `fromJson`, matching the project style.
/// Missing/null fields fall back to safe defaults so one odd field can't crash
/// the parse.
class UserProfile {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? city;
  final String? avatar;
  final List<String> roles;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.city,
    this.avatar,
    this.roles = const [],
  });

  /// The primary role to surface in the UI (e.g. "Owner"), or `null` if none.
  String? get primaryRole => roles.isEmpty ? null : roles.first;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      avatar: json['avatar'] as String?,
      roles: _stringList(json['roles']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((e) => '$e').toList(growable: false);
    }
    return const [];
  }
}
