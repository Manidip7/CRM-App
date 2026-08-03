import 'package:crm_app/core/permissions/permissions.dart';
import 'package:flutter_test/flutter_test.dart';

/// A trimmed copy of a real `GET /api/roles` response — the `emp` role, which
/// is allowed everything except roles/settings/masters/integrations.
Map<String, dynamic> _rolesResponse({
  String roleName = 'emp',
  Map<String, bool> overrides = const {},
}) {
  final permissionsMap = <String, bool>{
    'dashboard.view': true,
    'leads.view': true,
    'leads.add': true,
    'leads.edit': true,
    'leads.delete': true,
    'leads.mask_source': true,
    'leads.mask_phone': true,
    'leads.mask_email': true,
    'opportunities.view': true,
    'quotations.view': true,
    'customers.view': true,
    'projects.view': true,
    'tasks.view': true,
    'users.view': true,
    'roles.view': false,
    'roles.add': false,
    'roles.edit': false,
    'roles.delete': false,
    'settings.view': false,
    'settings.edit': false,
    'masters.view': false,
    'integrations.view': false,
    'invoices.view': true,
    ...overrides,
  };

  return {
    'success': true,
    'data': [
      {
        'id': 3,
        'name': roleName,
        'guard_name': 'web',
        'created_at': '2026-08-01T15:18:41.000000Z',
        'updated_at': '2026-08-01T15:18:41.000000Z',
        'permissions_map': permissionsMap,
        'permissions': [
          for (final entry in permissionsMap.entries)
            {
              'id': 1,
              'name': entry.key,
              'guard_name': 'web',
              'access': entry.value,
            },
        ],
      },
    ],
  };
}

List<RoleModel> _decode(Map<String, dynamic> json) => (json['data'] as List)
    .map((e) => RoleModel.fromJson((e as Map).cast<String, dynamic>()))
    .toList();

void main() {
  group('RoleModel.fromJson', () {
    test('reads permissions_map, keeping true and false apart', () {
      final role = _decode(_rolesResponse()).single;

      expect(role.id, 3);
      expect(role.name, 'emp');
      expect(role.permissionsMap['leads.view'], isTrue);
      expect(role.permissionsMap['roles.view'], isFalse);
      expect(role.permissionsMap['settings.edit'], isFalse);
    });

    test('falls back to the permissions array when no map is sent', () {
      final json = _rolesResponse();
      final role = json['data'][0] as Map<String, dynamic>;
      role.remove('permissions_map');

      final parsed = _decode(json).single;
      expect(parsed.permissionsMap['leads.add'], isTrue);
      expect(parsed.permissionsMap['roles.add'], isFalse);
    });

    test('accepts 1/0 and "true"/"false" as booleans', () {
      final parsed = RoleModel.fromJson({
        'id': 1,
        'name': 'odd',
        'permissions_map': {
          'leads.view': 1,
          'leads.add': '1',
          'leads.edit': 'true',
          'leads.delete': 0,
        },
      });

      expect(parsed.permissionsMap['leads.view'], isTrue);
      expect(parsed.permissionsMap['leads.add'], isTrue);
      expect(parsed.permissionsMap['leads.edit'], isTrue);
      expect(parsed.permissionsMap['leads.delete'], isFalse);
    });
  });

  group('PermissionSet.forRoles', () {
    test('grants what the role allows and denies the rest', () {
      final perms = PermissionSet.forRoles(['emp'], _decode(_rolesResponse()));

      expect(perms.can(AppPermissions.leadsView), isTrue);
      expect(perms.can(AppPermissions.leadsAdd), isTrue);
      expect(perms.can(AppPermissions.rolesView), isFalse);
      expect(perms.can(AppPermissions.settingsEdit), isFalse);
      // A key the backend never sent is denied, not assumed.
      expect(perms.can('something.unknown'), isFalse);
    });

    test('matches the role name case-insensitively', () {
      final roles = _decode(_rolesResponse(roleName: 'Emp'));
      expect(PermissionSet.forRoles(['emp'], roles).can('leads.view'), isTrue);
    });

    test('a role the user does not hold contributes nothing', () {
      final perms =
          PermissionSet.forRoles(['manager'], _decode(_rolesResponse()));
      expect(perms.can(AppPermissions.leadsView), isFalse);
    });

    test('multiple roles union: the most permissive one wins', () {
      final roles = [
        ..._decode(_rolesResponse(roleName: 'emp')),
        ..._decode(_rolesResponse(
          roleName: 'admin',
          overrides: {'roles.view': true, 'settings.view': true},
        )),
      ];

      final perms = PermissionSet.forRoles(['emp', 'admin'], roles);
      expect(perms.can(AppPermissions.rolesView), isTrue);
      expect(perms.can(AppPermissions.settingsView), isTrue);
      // Still denied — neither role grants it.
      expect(perms.can(AppPermissions.mastersView), isFalse);
    });

    test('mask_* true means the role may SEE the field', () {
      // The `emp` role in the real payload has every mask_* key true, which
      // clears it to see the source, phone and email.
      final perms = PermissionSet.forRoles(['emp'], _decode(_rolesResponse()));

      expect(perms.isMasked(AppPermissions.leadsMaskPhone), isFalse);
      expect(perms.isMasked(AppPermissions.leadsMaskEmail), isFalse);
      expect(perms.isMasked(AppPermissions.leadsMaskSource), isFalse);
    });

    test('mask_* false hides the field', () {
      final perms = PermissionSet.forRoles(
        ['emp'],
        _decode(_rolesResponse(overrides: {'leads.mask_phone': false})),
      );

      expect(perms.isMasked(AppPermissions.leadsMaskPhone), isTrue);
      expect(perms.isMasked(AppPermissions.leadsMaskEmail), isFalse);
    });

    test('a key the backend never sent leaves the field visible', () {
      // Guards the fallback window: running on the login payload alone must
      // not blank out contact details.
      final perms = PermissionSet.fromGrantedList(const ['leads.view']);
      expect(perms.isMasked(AppPermissions.leadsMaskPhone), isFalse);
      expect(PermissionSet.empty.isMasked(AppPermissions.leadsMaskPhone),
          isFalse);
    });

    test('masks union like everything else — the most permissive role wins', () {
      final roles = [
        ..._decode(_rolesResponse(
          roleName: 'junior',
          overrides: {'leads.mask_phone': false, 'leads.mask_email': false},
        )),
        ..._decode(_rolesResponse(
          roleName: 'senior',
          overrides: {'leads.mask_phone': true, 'leads.mask_email': false},
        )),
      ];

      final juniorOnly = PermissionSet.forRoles(['junior'], roles);
      expect(juniorOnly.isMasked(AppPermissions.leadsMaskPhone), isTrue);

      final both = PermissionSet.forRoles(['junior', 'senior'], roles);
      // Senior clears the phone, so holding both roles reveals it…
      expect(both.isMasked(AppPermissions.leadsMaskPhone), isFalse);
      // …but neither role clears the email, so that stays hidden.
      expect(both.isMasked(AppPermissions.leadsMaskEmail), isTrue);
    });
  });

  group('PermissionSet helpers', () {
    late PermissionSet perms;

    setUp(() {
      perms = PermissionSet.forRoles(['emp'], _decode(_rolesResponse()));
    });

    test('canAny / canAll', () {
      expect(perms.canAny(['roles.view', 'leads.view']), isTrue);
      expect(perms.canAny(['roles.view', 'settings.view']), isFalse);
      expect(perms.canAll(['leads.view', 'leads.add']), isTrue);
      expect(perms.canAll(['leads.view', 'roles.view']), isFalse);
    });

    test('canModule ignores masking keys', () {
      expect(perms.canModule(AppModules.leads), isTrue);
      expect(perms.canModule(AppModules.roles), isFalse);
      expect(perms.canModule(AppModules.settings), isFalse);

      // A role whose ONLY true leads key is a mask must not count as having
      // access to the leads module — being cleared to see a phone number is
      // not the same as being able to open Leads.
      final maskOnly = PermissionSet.forRoles(
        ['emp'],
        _decode(_rolesResponse(overrides: {
          'leads.view': false,
          'leads.add': false,
          'leads.edit': false,
          'leads.delete': false,
        })),
      );
      expect(maskOnly.isMasked(AppPermissions.leadsMaskPhone), isFalse);
      expect(maskOnly.canModule(AppModules.leads), isFalse);
    });

    test('empty set denies everything', () {
      expect(PermissionSet.empty.can(AppPermissions.leadsView), isFalse);
      expect(PermissionSet.empty.canModule(AppModules.leads), isFalse);
    });

    test('unrestricted set allows everything and masks nothing', () {
      expect(PermissionSet.unrestricted.can('anything.at.all'), isTrue);
      expect(PermissionSet.unrestricted.canModule(AppModules.roles), isTrue);
      expect(
        PermissionSet.unrestricted.isMasked(AppPermissions.leadsMaskPhone),
        isFalse,
      );
    });

    test('value equality, so an identical re-resolve is not a state change', () {
      final again = PermissionSet.forRoles(['emp'], _decode(_rolesResponse()));
      expect(again, equals(perms));
      expect(again.hashCode, equals(perms.hashCode));

      final different = PermissionSet.forRoles(
        ['emp'],
        _decode(_rolesResponse(overrides: {'leads.add': false})),
      );
      expect(different, isNot(equals(perms)));
    });
  });

  group('PermissionSet.resolve', () {
    final api = PermissionSet.forRoles(['emp'], _decode(_rolesResponse()));
    final cache = PermissionSet.fromCache(const {'leads.view': true});
    final session = PermissionSet.fromGrantedList(const ['tasks.view']);

    test('prefers the live API result', () {
      final resolved = PermissionSet.resolve(
        fromApi: api,
        fromCache: cache,
        fromSession: session,
      );
      expect(resolved.source, PermissionSource.api);
      expect(resolved.can(AppPermissions.leadsAdd), isTrue);
    });

    test('falls back to the cache while the API is in flight', () {
      final resolved =
          PermissionSet.resolve(fromCache: cache, fromSession: session);
      expect(resolved.source, PermissionSource.cache);
      expect(resolved.can(AppPermissions.leadsView), isTrue);
      expect(resolved.can(AppPermissions.leadsAdd), isFalse);
    });

    test('falls back to the login payload when there is no cache', () {
      final resolved = PermissionSet.resolve(fromSession: session);
      expect(resolved.source, PermissionSource.session);
      expect(resolved.can(AppPermissions.tasksView), isTrue);
    });

    test('fails open when nothing is known, and can be told to fail closed', () {
      expect(PermissionSet.resolve().isUnrestricted, isTrue);
      expect(
        PermissionSet.resolve(failOpenWhenUnknown: false),
        equals(PermissionSet.empty),
      );
    });

    test('an empty API result does not shadow a usable cache', () {
      final resolved = PermissionSet.resolve(
        fromApi: PermissionSet.empty,
        fromCache: cache,
      );
      expect(resolved.source, PermissionSource.cache);
    });
  });
}
