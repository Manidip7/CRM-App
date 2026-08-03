import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/permissions/permissions.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/model/auth_session.dart';
import '../features/auth/view/LoginScreen.dart';
import '../features/dashbord/view/dashboard_screen.dart';
import '../features/Leads/model/lead_model.dart';
import '../features/Leads/view/edit_lead_screen.dart';
import '../features/Leads/view/lead_detail_screen.dart';
import '../features/Opportunities/model/opportunity_model.dart';
import '../features/Opportunities/view/OpportunitiesScreen.dart';
import '../features/Opportunities/view/opportunity_detail_screen.dart';
import '../features/customers/model/customer_model.dart';
import '../features/customers/view/create_customer_screen.dart';
import '../features/customers/view/customer_detail_screen.dart';
import '../features/invoices/view/create_invoice_screen.dart';
import '../features/projects/model/project_model.dart';
import '../features/projects/view/create_project_screen.dart';
import '../features/projects/view/project_detail_screen.dart';
import '../features/profile/view/edit_profile_screen.dart';
import '../features/quotations/model/quotation_model.dart';
import '../features/quotations/view/edit_quotation_screen.dart';
import '../features/splash/view/splash_screen.dart';
import '../features/task/view/task_list_screen.dart';

/// Centralised route paths and names for the app.
///
/// The dashboard's main sections (Overview, Leads, Tasks, Opportunities,
/// Follow-ups, Quotations, Customers) are switched in-place inside
/// [DashboardScreen] via `dashboardNavProvider`, so they are NOT routes.
/// These routes cover the distinct screens pushed on top of the dashboard.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String opportunities = '/opportunities';
  static const String leadDetail = '/lead-detail';
  static const String editLead = '/edit-lead';
  static const String opportunityDetail = '/opportunity-detail';
  static const String customerDetail = '/customer-detail';
  static const String createCustomer = '/create-customer';
  static const String createInvoice = '/create-invoice';
  static const String createProject = '/create-project';
  static const String projectDetail = '/project-detail';
  static const String taskList = '/task-list';
  static const String editQuotation = '/edit-quotation';
  static const String editProfile = '/edit-profile';

  /// Permission required to open each guarded route. Routes left out of this
  /// map are open to any logged-in user (splash, login, dashboard shell, and
  /// the profile screen — everyone may edit their own profile).
  ///
  /// Hiding the button that pushes a route is the first line of defence; this
  /// is the second, and it's the one that survives a deep link, a stale
  /// back-stack entry, or a `context.push` someone forgets to wrap.
  static const Map<String, String> routePermissions = {
    leadDetail: AppPermissions.leadsView,
    editLead: AppPermissions.leadsEdit,
    opportunities: AppPermissions.opportunitiesView,
    opportunityDetail: AppPermissions.opportunitiesView,
    customerDetail: AppPermissions.customersView,
    createCustomer: AppPermissions.customersAdd,
    createInvoice: AppPermissions.invoicesAdd,
    createProject: AppPermissions.projectsAdd,
    projectDetail: AppPermissions.projectsView,
    taskList: AppPermissions.tasksView,
    editQuotation: AppPermissions.quotationsEdit,
  };
}

/// Global router configuration. Complex arguments (models) are passed through
/// GoRouter's `extra` field since they are not URL-encodable.
///
/// Exposed as a provider so it can read [authSessionProvider] and redirect:
/// a logged-in user is sent straight to the dashboard (skipping the login
/// screen on relaunch), and a logged-out user is bounced back to login.
final routerProvider = Provider<GoRouter>((ref) {
  // Bridge the session state to a [Listenable] so GoRouter re-evaluates its
  // redirect whenever the user logs in or out.
  final refresh = ValueNotifier<AuthSession?>(ref.read(authSessionProvider));
  ref.onDispose(refresh.dispose);
  ref.listen<AuthSession?>(
    authSessionProvider,
    (_, next) => refresh.value = next,
  );

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(authSessionProvider) != null;
      final atLogin = state.matchedLocation == AppRoutes.login;
      final atSplash = state.matchedLocation == AppRoutes.splash;

      // The splash screen handles its own navigation (after requesting
      // permissions), so leave it alone.
      if (atSplash) return null;
      // Already logged in but sitting on the login screen → go to dashboard.
      if (loggedIn && atLogin) return AppRoutes.dashboard;
      // Not logged in and trying to reach a protected screen → back to login.
      if (!loggedIn && !atLogin) return AppRoutes.login;

      // Logged in, but does this role have the permission this route needs?
      final required = AppRoutes.routePermissions[state.matchedLocation];
      if (required != null &&
          !ref.read(permissionsProvider).can(required)) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.opportunities,
      name: 'opportunities',
      builder: (context, state) => const OpportunitiesScreen(),
    ),
    GoRoute(
      path: AppRoutes.leadDetail,
      name: 'leadDetail',
      builder: (context, state) =>
          LeadDetailScreen(lead: state.extra as LeadModel),
    ),
    GoRoute(
      path: AppRoutes.editLead,
      name: 'editLead',
      builder: (context, state) =>
          EditLeadScreen(lead: state.extra as LeadModel),
    ),
    GoRoute(
      path: AppRoutes.opportunityDetail,
      name: 'opportunityDetail',
      builder: (context, state) =>
          OpportunityDetailScreen(opportunity: state.extra as OpportunityModel),
    ),
    GoRoute(
      path: AppRoutes.customerDetail,
      name: 'customerDetail',
      builder: (context, state) =>
          CustomerDetailScreen(customer: state.extra as CustomerModel),
    ),
    GoRoute(
      path: AppRoutes.createCustomer,
      name: 'createCustomer',
      builder: (context, state) => const CreateCustomerScreen(),
    ),
    GoRoute(
      path: AppRoutes.createInvoice,
      name: 'createInvoice',
      builder: (context, state) => const CreateInvoiceScreen(),
    ),
    GoRoute(
      path: AppRoutes.createProject,
      name: 'createProject',
      // `extra` carries the project to edit; null for a brand-new project.
      builder: (context, state) =>
          CreateProjectScreen(project: state.extra as ProjectModel?),
    ),
    GoRoute(
      path: AppRoutes.projectDetail,
      name: 'projectDetail',
      builder: (context, state) =>
          ProjectDetailScreen(project: state.extra as ProjectModel),
    ),
    GoRoute(
      path: AppRoutes.taskList,
      name: 'taskList',
      builder: (context, state) => const TaskListScreen(),
    ),
    GoRoute(
      path: AppRoutes.editQuotation,
      name: 'editQuotation',
      builder: (context, state) => EditQuotationScreen(
        quotation: state.extra as QuotationModel,
        isCreate: state.uri.queryParameters['create'] == '1',
      ),
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      name: 'editProfile',
      builder: (context, state) => const EditProfileScreen(),
    ),
  ],
  );
});
