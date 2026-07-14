import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/project_model.dart';

/// Search text applied to the project list.
class ProjectFilterNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setSearch(String q) => state = q;
  void clear() => state = '';
}

final projectFilterProvider =
    NotifierProvider<ProjectFilterNotifier, String>(ProjectFilterNotifier.new);

/// Holds the project list. Seeded with sample data so the screen renders
/// immediately; swap [_seed] for a repository call (`GET /projects`) once the
/// endpoint is available. Delete/upsert mutate the list locally.
class ProjectsNotifier extends Notifier<List<ProjectModel>> {
  @override
  List<ProjectModel> build() => _seed();

  void delete(String id) =>
      state = state.where((p) => p.id != id).toList();

  void upsert(ProjectModel updated) {
    final exists = state.any((p) => p.id == updated.id);
    state = exists
        ? [for (final p in state) if (p.id == updated.id) updated else p]
        : [updated, ...state];
  }
}

final projectsProvider =
    NotifierProvider<ProjectsNotifier, List<ProjectModel>>(
        ProjectsNotifier.new);

/// Projects after applying the search text, soonest deadline first.
final filteredProjectsProvider = Provider<List<ProjectModel>>((ref) {
  final all = ref.watch(projectsProvider);
  final q = ref.watch(projectFilterProvider).trim().toLowerCase();

  final result = all.where((p) {
    if (q.isEmpty) return true;
    return p.name.toLowerCase().contains(q) ||
        p.customer.toLowerCase().contains(q) ||
        p.status.label.toLowerCase().contains(q) ||
        p.members.any((m) => m.toLowerCase().contains(q));
  }).toList();

  result.sort((a, b) => a.deadline.compareTo(b.deadline));
  return result;
});

/// Aggregate totals (over the full, unfiltered list) for the summary row.
final projectSummaryProvider = Provider<ProjectSummary>((ref) {
  return ProjectSummary.from(ref.watch(projectsProvider));
});

// ─────────────────────────────────────────────
//  Create-project draft
// ─────────────────────────────────────────────

/// Selectable team members powering the Members multi-select. Swap for a
/// repository call (`GET /users`) once the endpoint exists.
final projectMembersProvider = Provider<List<String>>((ref) => const [
      'Priya Sharma',
      'Rahul Verma',
      'Ankit Gupta',
      'Sneha Iyer',
      'Vikram Rao',
      'Meera Nair',
    ]);

/// Full state of the "New Project" form. Kept in Riverpod (not [setState]) so
/// every field — dropdowns, dates, member chips and tags — drives the UI
/// reactively.
class ProjectDraft {
  final String name;
  final String? customer;
  final BillingType billingType;
  final ProjectStatus status;
  final double totalRate;
  final double estimatedHours;
  final DateTime? startDate;
  final DateTime? deadline;
  final List<String> members;
  final List<String> tags;
  final String description;

  const ProjectDraft({
    this.name = '',
    this.customer,
    this.billingType = BillingType.fixed,
    this.status = ProjectStatus.planning,
    this.totalRate = 0,
    this.estimatedHours = 0,
    this.startDate,
    this.deadline,
    this.members = const [],
    this.tags = const [],
    this.description = '',
  });

  ProjectDraft copyWith({
    String? name,
    String? customer,
    BillingType? billingType,
    ProjectStatus? status,
    double? totalRate,
    double? estimatedHours,
    DateTime? startDate,
    DateTime? deadline,
    List<String>? members,
    List<String>? tags,
    String? description,
  }) {
    return ProjectDraft(
      name: name ?? this.name,
      customer: customer ?? this.customer,
      billingType: billingType ?? this.billingType,
      status: status ?? this.status,
      totalRate: totalRate ?? this.totalRate,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      members: members ?? this.members,
      tags: tags ?? this.tags,
      description: description ?? this.description,
    );
  }
}

class ProjectDraftNotifier extends Notifier<ProjectDraft> {
  @override
  ProjectDraft build() => const ProjectDraft();

  /// Clears the form. Call when the create screen opens.
  void reset() => state = const ProjectDraft();

  void setName(String v) => state = state.copyWith(name: v);
  void setCustomer(String? v) => state = state.copyWith(customer: v);
  void setBillingType(BillingType v) => state = state.copyWith(billingType: v);
  void setStatus(ProjectStatus v) => state = state.copyWith(status: v);
  void setTotalRate(double v) => state = state.copyWith(totalRate: v);
  void setEstimatedHours(double v) => state = state.copyWith(estimatedHours: v);
  void setStartDate(DateTime v) => state = state.copyWith(startDate: v);
  void setDeadline(DateTime v) => state = state.copyWith(deadline: v);
  void setDescription(String v) => state = state.copyWith(description: v);

  void toggleMember(String name) {
    final members = [...state.members];
    members.contains(name) ? members.remove(name) : members.add(name);
    state = state.copyWith(members: members);
  }

  void addTag(String tag) {
    final t = tag.trim();
    if (t.isEmpty || state.tags.contains(t)) return;
    state = state.copyWith(tags: [...state.tags, t]);
  }

  void removeTag(String tag) =>
      state = state.copyWith(tags: state.tags.where((t) => t != tag).toList());
}

final projectDraftProvider =
    NotifierProvider<ProjectDraftNotifier, ProjectDraft>(
        ProjectDraftNotifier.new);

/// Suggests the next project id based on the highest existing sequence for the
/// current year, e.g. `PRJ-2026-0008`.
String suggestProjectId(List<ProjectModel> existing) {
  final year = DateTime.now().year;
  final prefix = 'PRJ-$year-';
  var max = 0;
  for (final p in existing) {
    if (!p.id.startsWith(prefix)) continue;
    final n = int.tryParse(p.id.substring(prefix.length));
    if (n != null && n > max) max = n;
  }
  return '$prefix${(max + 1).toString().padLeft(4, '0')}';
}

/// Sample data. Remove when wiring a real API.
List<ProjectModel> _seed() {
  final now = DateTime.now();
  DateTime d(int days) => now.add(Duration(days: days));
  return [
    ProjectModel(
      id: 'PRJ-2026-0007',
      name: 'CRM Platform Revamp',
      customer: 'Acme Industries',
      status: ProjectStatus.inProgress,
      members: ['Priya Sharma', 'Rahul Verma', 'Ankit Gupta'],
      deadline: d(18),
      pendingTasks: 6,
    ),
    ProjectModel(
      id: 'PRJ-2026-0006',
      name: 'Retail Analytics Dashboard',
      customer: 'Nova Retail Pvt Ltd',
      status: ProjectStatus.planning,
      members: ['Rahul Verma', 'Sneha Iyer'],
      deadline: d(32),
      pendingTasks: 4,
    ),
    ProjectModel(
      id: 'PRJ-2026-0005',
      name: 'Cloud Migration',
      customer: 'BlueSky Solutions',
      status: ProjectStatus.onHold,
      members: ['Ankit Gupta'],
      deadline: d(-3),
      pendingTasks: 9,
    ),
    ProjectModel(
      id: 'PRJ-2026-0004',
      name: 'Mobile App Launch',
      customer: 'Greenfield Traders',
      status: ProjectStatus.inProgress,
      members: ['Priya Sharma', 'Sneha Iyer', 'Rahul Verma', 'Ankit Gupta'],
      deadline: d(9),
      pendingTasks: 3,
    ),
    ProjectModel(
      id: 'PRJ-2026-0003',
      name: 'ERP Integration',
      customer: 'Sterling Corp',
      status: ProjectStatus.completed,
      members: ['Rahul Verma', 'Ankit Gupta'],
      deadline: d(-12),
      pendingTasks: 0,
    ),
    ProjectModel(
      id: 'PRJ-2026-0002',
      name: 'Brand Website Redesign',
      customer: 'Horizon Media',
      status: ProjectStatus.planning,
      members: ['Sneha Iyer'],
      deadline: d(24),
      pendingTasks: 5,
    ),
  ];
}
