import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../data/projects_repository.dart';
import '../model/project_model.dart';

/// The filters applied to the project list. Both are sent to the server
/// (`GET /projects?search=&status=`) rather than applied on the loaded page,
/// so they search across every project and not just the ones fetched so far.
class ProjectFilter {
  final String search;

  /// Null means "any status".
  final ProjectStatus? status;

  const ProjectFilter({this.search = '', this.status});

  ProjectFilter copyWith({
    String? search,
    ProjectStatus? status,
    bool clearStatus = false,
  }) {
    return ProjectFilter(
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

class ProjectFilterNotifier extends Notifier<ProjectFilter> {
  @override
  ProjectFilter build() => const ProjectFilter();

  void setSearch(String q) => state = state.copyWith(search: q);

  void clearSearch() => state = state.copyWith(search: '');

  /// Selecting the active status again clears it (chips toggle).
  void toggleStatus(ProjectStatus s) => state = state.status == s
      ? state.copyWith(clearStatus: true)
      : state.copyWith(status: s);

  void clear() => state = const ProjectFilter();
}

final projectFilterProvider =
    NotifierProvider<ProjectFilterNotifier, ProjectFilter>(
        ProjectFilterNotifier.new);

/// The server-side query bits as a record. Record equality means [ProjectsNotifier]
/// only refetches when the search text or status actually changes, not on every
/// rebuild of the filter object.
final projectsQueryProvider = Provider<({String search, String? status})>((ref) {
  final f = ref.watch(projectFilterProvider);
  return (search: f.search.trim(), status: f.status?.label);
});

/// Paginator metadata for the project list.
class ProjectsPagination {
  final int currentPage;
  final int lastPage;
  final int total;
  final bool isLoadingMore;

  const ProjectsPagination({
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.isLoadingMore = false,
  });

  bool get hasMore => currentPage < lastPage;

  ProjectsPagination copyWith({
    int? currentPage,
    int? lastPage,
    int? total,
    bool? isLoadingMore,
  }) {
    return ProjectsPagination(
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class ProjectsPaginationNotifier extends Notifier<ProjectsPagination> {
  @override
  ProjectsPagination build() => const ProjectsPagination();

  void setFromPage(ProjectsPage page) => state = state.copyWith(
        currentPage: page.currentPage,
        lastPage: page.lastPage,
        total: page.total,
      );

  void setLoadingMore(bool value) =>
      state = state.copyWith(isLoadingMore: value);
}

final projectsPaginationProvider =
    NotifierProvider<ProjectsPaginationNotifier, ProjectsPagination>(
        ProjectsPaginationNotifier.new);

/// Totals for the summary row, taken from the response's `meta` block. They
/// cover every project, so they are set by the fetch rather than derived from
/// the loaded page.
class ProjectSummaryNotifier extends Notifier<ProjectSummary> {
  @override
  ProjectSummary build() => ProjectSummary.empty;

  void set(ProjectSummary summary) => state = summary;
}

final projectSummaryProvider =
    NotifierProvider<ProjectSummaryNotifier, ProjectSummary>(
        ProjectSummaryNotifier.new);

/// The project list from `GET /projects`, refetched from page 1 whenever a
/// filter changes and extended by [loadMore] as the user scrolls.
///
/// [delete] and [upsert] only mutate the loaded list — there is no projects
/// write endpoint wired up yet.
class ProjectsNotifier extends AsyncNotifier<List<ProjectModel>> {
  // Active query, captured on each build so loadMore reuses it.
  String? _search;
  String? _status;

  @override
  Future<List<ProjectModel>> build() async {
    final query = ref.watch(projectsQueryProvider);
    _search = query.search.isEmpty ? null : query.search;
    _status = query.status;

    final page = await _fetch(1);
    _applyMeta(page);
    return page.projects;
  }

  Future<ProjectsPage> _fetch(int page) async {
    final result = await ref.read(projectsRepositoryProvider).getProjects(
          page: page,
          search: _search,
          status: _status,
        );
    return switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw error,
    };
  }

  void _applyMeta(ProjectsPage page) {
    ref.read(projectsPaginationProvider.notifier).setFromPage(page);
    ref.read(projectSummaryProvider.notifier).set(page.summary);
  }

  /// Fetches the next page and appends it. No-op while a load is already
  /// running or when the last page has been reached.
  Future<void> loadMore() async {
    final meta = ref.read(projectsPaginationProvider);
    if (meta.isLoadingMore || !meta.hasMore) return;

    final current = state.value ?? const <ProjectModel>[];
    final pagination = ref.read(projectsPaginationProvider.notifier);
    pagination.setLoadingMore(true);
    try {
      final next = await _fetch(meta.currentPage + 1);
      _applyMeta(next);
      state = AsyncData([...current, ...next.projects]);
    } catch (_) {
      // Keep the already-loaded projects; the next scroll will retry.
    } finally {
      pagination.setLoadingMore(false);
    }
  }

  /// Reloads from page 1.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final page = await _fetch(1);
      _applyMeta(page);
      return page.projects;
    });
  }

  /// Deletes via `DELETE /projects/{id}`. Returns null on success, or the
  /// message to show on failure.
  ///
  /// On success the row is dropped immediately so the list reacts at once, then
  /// the page is refetched quietly to resync the `meta` totals behind the
  /// summary row — [refresh] would blank the screen to a spinner instead.
  Future<String?> deleteProject(String id) async {
    final result =
        await ref.read(projectsRepositoryProvider).deleteProject(id);

    switch (result) {
      case Failure(:final error):
        return error.message;
      case Success():
        final current = state.value;
        if (current != null) {
          state = AsyncData(current.where((p) => p.id != id).toList());
        }
        try {
          final page = await _fetch(1);
          _applyMeta(page);
          state = AsyncData(page.projects);
        } catch (_) {
          // Keep the removal; pull-to-refresh will resync the totals.
        }
        return null;
    }
  }

  void upsert(ProjectModel updated) {
    final current = state.value ?? const <ProjectModel>[];
    final exists = current.any((p) => p.id == updated.id);
    state = AsyncData(exists
        ? [for (final p in current) if (p.id == updated.id) updated else p]
        : [updated, ...current]);
  }
}

final projectsProvider =
    AsyncNotifierProvider<ProjectsNotifier, List<ProjectModel>>(
        ProjectsNotifier.new);

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
