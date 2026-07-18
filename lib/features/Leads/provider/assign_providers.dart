import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../data/leads_repository.dart';
import '../model/lead_model.dart';

/// Territory options for the Assign-Lead popup (`GET /territories`).
/// Cached for the session; the popup watches this to fill the dropdown.
final territoriesProvider = FutureProvider<List<NamedLookup>>((ref) async {
  final result = await ref.watch(leadsRepositoryProvider).getTerritories();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});

/// Branch options for the Assign-Lead popup, scoped to the selected territory
/// (`GET /branches?territory_id=N`). Pass `null` to load every branch. Keyed by
/// territory id so switching territory refetches its branches.
final branchesProvider =
    FutureProvider.family<List<NamedLookup>, int?>((ref, territoryId) async {
  final result =
      await ref.watch(leadsRepositoryProvider).getBranches(territoryId: territoryId);
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});

/// Lead type options for the Edit-Lead popup (`GET /lead-types`).
/// Cached for the session.
final leadTypesProvider = FutureProvider<List<NamedLookup>>((ref) async {
  final result = await ref.watch(leadsRepositoryProvider).getLeadTypes();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});

/// The users a lead can be assigned to (`GET /users`), for the Assign-Lead
/// multi-select. Cached for the session.
final assignableUsersProvider = FutureProvider<List<AssignableUser>>((ref) async {
  final result = await ref.watch(leadsRepositoryProvider).getAssignableUsers();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});
