import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../auth/data/auth_repository.dart';
import '../data/dashboard_repository.dart';
import '../model/dashboard_overview_model.dart';

/// The Overview tab's data, from `GET /dashboard/overview`.
///
/// One request feeds every card, so the whole tab shares a single loading and
/// error state. Re-fetches when the user logs in or out;
/// `ref.invalidate(dashboardOverviewProvider)` drives pull-to-refresh.
final dashboardOverviewProvider =
    FutureProvider<DashboardOverview>((ref) async {
  // No session → no token → don't even try; the call would 401 and bounce the
  // user to login.
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    throw StateError('Not logged in.');
  }

  final result = await ref.watch(dashboardRepositoryProvider).getOverview();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});
