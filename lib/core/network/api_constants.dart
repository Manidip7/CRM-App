/// Central place for all network-related constants: base URL, timeouts and
/// endpoint paths. Keep every hard-coded URL string here so the rest of the
/// app never has to know where the backend lives.
class ApiConstants {
  ApiConstants._();

  /// Root of the backend API. Change this for staging / production builds.
  static const String baseUrl = 'https://crm.mindverge.in';

  /// Common prefix appended to [baseUrl] (e.g. `/api/v1`).
  static const String apiPrefix = '/api/v1';

  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  // --- Timeouts -------------------------------------------------------------
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);

  // --- Headers --------------------------------------------------------------
  static const String authHeader = 'Authorization';
  static const String contentType = 'application/json';

  // --- Endpoints ------------------------------------------------------------
  // Auth
  static const String login = '/login';
  static const String logout = '/logout';
  static const String forgotPassword = '/forgot-password';
  static const String refreshToken = '/refresh';
  static const String myProfile = '/my-profile';

  // Leads
  static const String leads = '/leads';
  static String leadDetail(String id) => '/leads/$id';
  static String leadPriority(String id) => '/leads/$id/priority';
  static String leadFollowup(String id) => '/leads/$id/followup';
  static String leadStatus(String id) => '/leads/$id/status';
  static String leadNotes(String id) => '/leads/$id/notes';
  static String leadTasks(String id) => '/leads/$id/tasks';
  static String leadConvert(String id) => '/leads/$id/convert';
  static const String leadSources = '/lead-sources';
  static const String currentUpdates = '/current-updates';
  static const String nextActions = '/next-actions';
  static const String statuses = '/statuses';

  // Opportunities
  static const String opportunities = '/opportunities';
  static String opportunityDetail(String id) => '/opportunities/$id';

  // Tasks
  static const String tasks = '/tasks';

  // Dashboard
  static const String dashboard = '/dashboard';
}
