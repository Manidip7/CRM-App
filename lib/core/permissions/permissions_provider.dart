import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_result.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/profile/data/profile_repository.dart';
import 'permission_set.dart';
import 'permissions_store.dart';
import 'role_model.dart';
import 'roles_repository.dart';

/// Raw `GET /api/roles` result — every role the backend knows about.
///
/// Kept separate from [permissionsProvider] so a roles-management screen can
/// list them all, and so the fetch is only wired to auth state in one place.
/// Automatically re-fetches when the user logs in or out.
final rolesProvider = FutureProvider<List<RoleModel>>((ref) async {
  // No session → no token → don't even try; the call would 401 and bounce the
  // user to login.
  final session = ref.watch(authSessionProvider);
  if (session == null) return const <RoleModel>[];

  final result = await ref.watch(rolesRepositoryProvider).getRoles();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});

/// The current user's resolved permissions, fetched from `GET /api/roles` and
/// matched against the roles on their session.
///
/// This is the *authoritative* async view. Most UI should watch the
/// synchronous [permissionsProvider] instead, which falls back to the cached /
/// session-supplied map while this is still in flight.
final userPermissionsProvider = FutureProvider<PermissionSet>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null) return PermissionSet.empty;

  final roles = await ref.watch(rolesProvider.future);
  if (roles.isEmpty) return PermissionSet.empty;

  // Role names normally come from the login payload. Some backends only put
  // them on /my-profile, so fall back to that when the session has none —
  // reading the already-resolved value so we never block on that request.
  final roleNames = session.roles.isNotEmpty
      ? session.roles
      : (ref.watch(profileProvider).value?.roles ?? const <String>[]);

  if (roleNames.isEmpty) {
    if (kDebugMode) {
      developer.log(
        'No role name on the session — cannot match against /api/roles '
        '(${roles.map((r) => r.name).join(', ')}).',
        name: 'PERMISSIONS',
      );
    }
    return PermissionSet.empty;
  }

  final resolved = PermissionSet.forRoles(roleNames, roles);

  if (kDebugMode) {
    final denied = resolved.map.entries
        .where((e) => !e.value)
        .map((e) => e.key)
        .toList();
    developer.log(
      'Roles ${roleNames.join(', ')} → $resolved\n'
      'denied (${denied.length}): ${denied.join(', ')}',
      name: 'PERMISSIONS',
    );
  }

  // Remember it so the next cold start renders correctly on the first frame.
  await ref.read(permissionsStoreProvider).save(resolved.map);

  return resolved;
});

/// **The provider the UI should watch.** Always returns a usable
/// [PermissionSet] — never a loading or error state — by falling back through
/// live API → on-disk cache → login payload → fail-open. See
/// [PermissionSet.resolve] for why the last step allows rather than denies.
final permissionsProvider = Provider<PermissionSet>((ref) {
  final session = ref.watch(authSessionProvider);
  if (session == null) return PermissionSet.empty;

  return PermissionSet.resolve(
    fromApi: ref.watch(userPermissionsProvider).value,
    fromCache: switch (ref.watch(permissionsStoreProvider).cached) {
      final cached? => PermissionSet.fromCache(cached),
      _ => null,
    },
    fromSession: session.permissions.isEmpty
        ? null
        : PermissionSet.fromGrantedList(session.permissions),
  );
});

/// Single-permission check, for when watching the whole set would rebuild a
/// widget more often than necessary:
///
/// ```dart
/// if (ref.watch(canProvider(AppPermissions.leadsAdd))) ...
/// ```
final canProvider = Provider.family<bool, String>((ref, permission) {
  return ref.watch(permissionsProvider).can(permission);
});

/// Convenience accessors so screens read naturally.
extension PermissionRefX on WidgetRef {
  /// The current user's full permission set.
  PermissionSet get permissions => watch(permissionsProvider);

  /// `true` if the user may perform [permission] (e.g. `leads.add`).
  bool can(String permission) => watch(permissionsProvider).can(permission);

  /// `true` if the user has any of [permissions].
  bool canAny(Iterable<String> permissions) =>
      watch(permissionsProvider).canAny(permissions);

  /// `true` if a `leads.mask_*` flag says this field must be hidden.
  bool isMasked(String maskPermission) =>
      watch(permissionsProvider).isMasked(maskPermission);
}

/// Same accessors for `ref` inside providers/notifiers, where `watch` would
/// otherwise re-run the provider on every permission change.
extension PermissionReadX on Ref {
  PermissionSet get permissions => read(permissionsProvider);

  bool can(String permission) => read(permissionsProvider).can(permission);
}
