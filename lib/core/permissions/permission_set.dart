import 'package:flutter/foundation.dart';

import 'app_permissions.dart';
import 'role_model.dart';

/// The resolved permissions of the **currently logged-in user** — a flat
/// `permission → granted?` map plus the helpers the UI asks it about.
///
/// A user can hold more than one role, so the set is the union (logical OR) of
/// their roles' `permissions_map`s: if *any* of the user's roles grants
/// `leads.add`, they can add leads.
///
/// Immutable — build a new one rather than mutating.
class PermissionSet {
  final Map<String, bool> map;

  /// Where these permissions came from. Only used for debugging/logging and to
  /// let the UI tell "still loading, using cache" from "this is authoritative".
  final PermissionSource source;

  const PermissionSet(this.map, {this.source = PermissionSource.none});

  /// Nobody is logged in / nothing is known — everything is denied.
  static const PermissionSet empty =
      PermissionSet(<String, bool>{}, source: PermissionSource.none);

  /// Everything allowed. Used as the deliberate fail-open default when the
  /// backend gave us no permission information at all (see
  /// [PermissionSet.resolve]).
  static const PermissionSet unrestricted =
      PermissionSet(<String, bool>{}, source: PermissionSource.unrestricted);

  bool get isUnrestricted => source == PermissionSource.unrestricted;

  /// `true` when the user may perform [permission], e.g. `leads.add`.
  ///
  /// An unknown key (one the backend never sent) is treated as **denied**,
  /// except in the unrestricted fail-open mode.
  bool can(String permission) {
    if (isUnrestricted) return true;
    return map[permission] ?? false;
  }

  bool cannot(String permission) => !can(permission);

  /// `true` if **any** of [permissions] is granted. Handy for a screen that
  /// several different actions can reach.
  bool canAny(Iterable<String> permissions) {
    if (isUnrestricted) return true;
    for (final p in permissions) {
      if (can(p)) return true;
    }
    return false;
  }

  /// `true` only if **every** one of [permissions] is granted.
  bool canAll(Iterable<String> permissions) {
    if (isUnrestricted) return true;
    for (final p in permissions) {
      if (!can(p)) return false;
    }
    return true;
  }

  /// `true` if the user has at least one real permission inside [module]
  /// (the part before the dot, e.g. `leads`). Masking keys are ignored — they
  /// hide data rather than grant access, so they must not make a module look
  /// reachable.
  bool canModule(String module) {
    if (isUnrestricted) return true;
    final prefix = '$module.';
    for (final entry in map.entries) {
      if (!entry.key.startsWith(prefix)) continue;
      if (AppPermissions.maskingKeys.contains(entry.key)) continue;
      if (entry.value) return true;
    }
    return false;
  }

  /// `true` when a `leads.mask_*` field must be **hidden** from this role.
  ///
  /// The `mask_*` keys follow the same convention as every other key —
  /// `true` grants, `false` denies — so `leads.mask_phone: true` means the role
  /// is cleared to see the phone, and `false` is what masks it:
  ///
  /// ```dart
  /// if (!perms.isMasked(AppPermissions.leadsMaskPhone)) Text(lead.phone)
  /// ```
  ///
  /// A key the backend never sent is treated as *not* masked. Hiding contact
  /// details is the destructive outcome here, so an unknown key must not
  /// trigger it — that would blank out the phone whenever the app is running
  /// on the login payload alone, before `GET /api/roles` has answered.
  bool isMasked(String maskPermission) {
    if (isUnrestricted) return false;
    final granted = map[maskPermission];
    if (granted == null) return false;
    return !granted;
  }

  /// Builds the union of the `permissions_map`s of every role in [roleNames].
  ///
  /// Role names are matched case-insensitively against [allRoles] because the
  /// login payload and the roles endpoint don't always agree on casing
  /// (`emp` vs `Emp`).
  factory PermissionSet.forRoles(
    Iterable<String> roleNames,
    List<RoleModel> allRoles, {
    PermissionSource source = PermissionSource.api,
  }) {
    final wanted = roleNames.map((r) => r.toLowerCase().trim()).toSet();
    final merged = <String, bool>{};

    for (final role in allRoles) {
      if (!wanted.contains(role.name.toLowerCase().trim())) continue;
      role.permissionsMap.forEach((key, value) {
        // Everything ORs together — the most permissive role wins. This holds
        // for the `mask_*` keys too, since they grant visibility rather than
        // withdraw it (see [isMasked]).
        merged[key] = (merged[key] ?? false) || value;
      });
    }

    return PermissionSet(Map.unmodifiable(merged), source: source);
  }

  /// Builds a set from the flat `permissions: ["leads.view", ...]` list that
  /// the login response carries. Anything not listed is denied.
  factory PermissionSet.fromGrantedList(
    Iterable<String> granted, {
    PermissionSource source = PermissionSource.session,
  }) {
    return PermissionSet(
      Map.unmodifiable({for (final p in granted) p: true}),
      source: source,
    );
  }

  factory PermissionSet.fromCache(Map<String, bool> cached) =>
      PermissionSet(Map.unmodifiable(cached), source: PermissionSource.cache);

  /// Picks the best permission source available right now, in priority order:
  ///
  ///  1. the live `GET /api/roles` result ([fromApi]),
  ///  2. the map cached on disk from the last successful fetch ([fromCache]),
  ///  3. the flat list the login response returned ([fromSession]),
  ///  4. nothing at all → **fail open**.
  ///
  /// Step 4 is a deliberate product decision: if the backend has never told
  /// this build anything about permissions (older API, a user with no role, a
  /// first launch that couldn't reach the network) it is better to show the
  /// full app than to hand the user an empty shell they can't use. The server
  /// still enforces every action, so this only affects what the UI *offers*.
  /// Flip [failOpenWhenUnknown] to `false` to deny instead.
  static PermissionSet resolve({
    PermissionSet? fromApi,
    PermissionSet? fromCache,
    PermissionSet? fromSession,
    bool failOpenWhenUnknown = true,
  }) {
    if (fromApi != null && fromApi.map.isNotEmpty) return fromApi;
    if (fromCache != null && fromCache.map.isNotEmpty) return fromCache;
    if (fromSession != null && fromSession.map.isNotEmpty) return fromSession;
    return failOpenWhenUnknown ? unrestricted : empty;
  }

  /// Value equality matters here: [permissionsProvider] recomputes whenever the
  /// roles request settles, and without `==` Riverpod would treat an identical
  /// re-resolved set as a change and rebuild (and reset) permission-derived
  /// state such as the selected dashboard tab.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermissionSet &&
          other.source == source &&
          mapEquals(other.map, map);

  @override
  int get hashCode => Object.hash(
        source,
        Object.hashAllUnordered(
          map.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      );

  @override
  String toString() {
    if (isUnrestricted) return 'PermissionSet(unrestricted)';
    final allowed = map.entries.where((e) => e.value).length;
    return 'PermissionSet(${source.name}: $allowed/${map.length} granted)';
  }
}

/// Where a [PermissionSet]'s data came from.
enum PermissionSource {
  /// No information — deny everything.
  none,

  /// Live `GET /api/roles` response matched to the user's roles.
  api,

  /// Last successful API result, restored from local storage.
  cache,

  /// The flat `permissions` list in the login response.
  session,

  /// No permission data exists anywhere — allow everything (fail open).
  unrestricted,
}
