/// Role-based access control, driven by `GET /api/roles`.
///
/// One import gets you everything the UI needs:
/// ```dart
/// import '../../../core/permissions/permissions.dart';
///
/// // declarative
/// Can(permission: AppPermissions.leadsAdd, child: addButton)
///
/// // imperative
/// if (ref.can(AppPermissions.leadsDelete)) showDeleteAction();
///
/// // whole screen
/// PermissionGate(permission: AppPermissions.projectsView, child: ProjectsScreen())
/// ```
library;

export 'app_permissions.dart';
export 'permission_set.dart';
export 'permission_widgets.dart';
export 'permissions_provider.dart';
export 'permissions_store.dart';
export 'role_model.dart';
export 'roles_repository.dart';
