/// Every permission key the backend can return from `GET /api/roles`
/// (`data[].permissions_map`), as compile-time constants.
///
/// Always gate UI with these instead of raw strings — a typo in
/// `'leads.dlete'` silently evaluates to "no access" and the button just
/// disappears, which is very hard to spot. With constants the compiler catches
/// it.
library;

class AppPermissions {
  AppPermissions._();

  // --- Dashboard ------------------------------------------------------------
  static const String dashboardView = 'dashboard.view';

  // --- Leads ----------------------------------------------------------------
  static const String leadsView = 'leads.view';
  static const String leadsAdd = 'leads.add';
  static const String leadsEdit = 'leads.edit';
  static const String leadsDelete = 'leads.delete';
  static const String leadsChangeStatus = 'leads.change_status';
  static const String leadsImport = 'leads.import';
  static const String leadsExport = 'leads.export';
  static const String leadsFollowUp = 'leads.follow_up';
  static const String leadsBulkAction = 'leads.bulk_action';
  static const String leadsLostLead = 'leads.lost_lead';
  static const String leadsChangePriority = 'leads.change_priority';
  static const String leadsAssign = 'leads.assign';
  static const String leadsTransfer = 'leads.transfer';
  static const String leadsConvert = 'leads.convert';
  static const String leadsAddNotes = 'leads.add_notes';
  static const String leadsAddCallLog = 'leads.add_calllog';
  static const String leadsAddTask = 'leads.add_task';
  static const String leadsTimeline = 'leads.timeline';

  /// NOTE: the three `mask_*` keys read like every other key — `true` grants,
  /// `false` denies — so `true` means this role IS cleared to see the field and
  /// `false` is what masks it. Gate them through [PermissionSet.isMasked],
  /// which flips the sense for you and leaves an unknown key unmasked.
  static const String leadsMaskSource = 'leads.mask_source';
  static const String leadsMaskPhone = 'leads.mask_phone';
  static const String leadsMaskEmail = 'leads.mask_email';

  // --- Backlog leads --------------------------------------------------------
  static const String backlogLeadsView = 'backlog_leads.view';
  static const String backlogLeadsFollowUp = 'backlog_leads.follow_up';
  static const String backlogLeadsChangeStatus = 'backlog_leads.change_status';
  static const String backlogLeadsTimeline = 'backlog_leads.timeline';

  // --- Opportunities --------------------------------------------------------
  static const String opportunitiesView = 'opportunities.view';
  static const String opportunitiesEdit = 'opportunities.edit';
  static const String opportunitiesDelete = 'opportunities.delete';
  static const String opportunitiesExport = 'opportunities.export';
  static const String opportunitiesChangeStatus = 'opportunities.change_status';
  static const String opportunitiesFollowUp = 'opportunities.follow_up';
  static const String opportunitiesQuotation = 'opportunities.quotation';
  static const String opportunitiesTimeline = 'opportunities.timeline';
  static const String opportunitiesAddNotes = 'opportunities.add_notes';
  static const String opportunitiesAddCallLog = 'opportunities.add_calllog';
  static const String opportunitiesAddTask = 'opportunities.add_task';
  static const String opportunitiesSendEmail = 'opportunities.send_email';

  // --- Backlog opportunities ------------------------------------------------
  static const String backlogOpportunitiesView = 'backlog_opportunities.view';
  static const String backlogOpportunitiesChangeStatus =
      'backlog_opportunities.change_status';
  static const String backlogOpportunitiesRescheduleReactivate =
      'backlog_opportunities.reschedule_reactivate';
  static const String backlogOpportunitiesTimeline =
      'backlog_opportunities.timeline';

  // --- Quotations -----------------------------------------------------------
  static const String quotationsView = 'quotations.view';
  static const String quotationsAdd = 'quotations.add';
  static const String quotationsEdit = 'quotations.edit';
  static const String quotationsDelete = 'quotations.delete';
  static const String quotationsDownload = 'quotations.download';
  static const String quotationsSendEmail = 'quotations.send_email';

  // --- Customers ------------------------------------------------------------
  static const String customersView = 'customers.view';
  static const String customersAdd = 'customers.add';
  static const String customersEdit = 'customers.edit';
  static const String customersDelete = 'customers.delete';
  static const String customersAddContact = 'customers.add_contact';

  // --- Contacts -------------------------------------------------------------
  static const String contactsView = 'contacts.view';
  static const String contactsAdd = 'contacts.add';

  // --- Projects -------------------------------------------------------------
  static const String projectsView = 'projects.view';
  static const String projectsAdd = 'projects.add';
  static const String projectsEdit = 'projects.edit';
  static const String projectsDelete = 'projects.delete';
  static const String projectsTask = 'projects.task';
  static const String projectsFiles = 'projects.files';
  static const String projectsNotes = 'projects.notes';
  static const String projectsActivity = 'projects.activity';

  // --- Tasks ----------------------------------------------------------------
  static const String tasksView = 'tasks.view';
  static const String tasksAdd = 'tasks.add';
  static const String tasksEdit = 'tasks.edit';
  static const String tasksDelete = 'tasks.delete';
  static const String tasksChangeStatus = 'tasks.change_status';

  // --- Users ----------------------------------------------------------------
  static const String usersView = 'users.view';
  static const String usersAdd = 'users.add';
  static const String usersEdit = 'users.edit';
  static const String usersDelete = 'users.delete';
  static const String usersTableView = 'users.table_view';
  static const String usersTreeView = 'users.tree_view';

  // --- Roles ----------------------------------------------------------------
  static const String rolesView = 'roles.view';
  static const String rolesAdd = 'roles.add';
  static const String rolesEdit = 'roles.edit';
  static const String rolesDelete = 'roles.delete';

  // --- Settings / masters / integrations ------------------------------------
  static const String settingsView = 'settings.view';
  static const String settingsEdit = 'settings.edit';
  static const String mastersView = 'masters.view';
  static const String mastersAdd = 'masters.add';
  static const String mastersEdit = 'masters.edit';
  static const String mastersDelete = 'masters.delete';
  static const String integrationsView = 'integrations.view';
  static const String integrationsEdit = 'integrations.edit';

  // --- Invoices -------------------------------------------------------------
  static const String invoicesView = 'invoices.view';
  static const String invoicesAdd = 'invoices.add';
  static const String invoicesEdit = 'invoices.edit';
  static const String invoicesDelete = 'invoices.delete';

  /// The `mask_*` keys. They gate *field visibility* rather than an action, so
  /// `canModule('leads')` skips them — being cleared to see a phone number is
  /// not the same as having access to the leads module.
  static const Set<String> maskingKeys = {
    leadsMaskSource,
    leadsMaskPhone,
    leadsMaskEmail,
  };
}

/// Module prefixes (the part before the dot). Useful for "does this user have
/// *any* access to leads at all" style checks.
class AppModules {
  AppModules._();

  static const String dashboard = 'dashboard';
  static const String leads = 'leads';
  static const String backlogLeads = 'backlog_leads';
  static const String opportunities = 'opportunities';
  static const String backlogOpportunities = 'backlog_opportunities';
  static const String quotations = 'quotations';
  static const String customers = 'customers';
  static const String contacts = 'contacts';
  static const String projects = 'projects';
  static const String tasks = 'tasks';
  static const String users = 'users';
  static const String roles = 'roles';
  static const String settings = 'settings';
  static const String masters = 'masters';
  static const String integrations = 'integrations';
  static const String invoices = 'invoices';
}
