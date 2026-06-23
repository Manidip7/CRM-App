import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_result.dart';
import '../data/leads_repository.dart';
import '../model/lead_model.dart';

part 'lead_detail_provider.freezed.dart';
part 'lead_detail_provider.g.dart';

/// Loads a lead's detail bundle (timeline, notes, tasks) from `GET /leads/{id}`,
/// keyed by lead id. Watched by the Timeline / Notes / Tasks tabs.
@riverpod
Future<LeadDetailBundle> leadDetail(Ref ref, String leadId) async {
  final result = await ref.watch(leadsRepositoryProvider).getLeadDetail(leadId);
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
}

@freezed
abstract class LeadDetailState with _$LeadDetailState {
  const factory LeadDetailState({
    @Default(LeadPipelineStatus.newLead) LeadPipelineStatus pipelineStatus,
    @Default(LeadTemperature.warm) LeadTemperature temperature,
    @Default(false) bool converted,
  }) = _LeadDetailState;
}

/// Editable pipeline status / temperature / conversion flag for a single lead,
/// keyed by the lead id so each lead keeps its own state. The initial
/// temperature is seeded from the lead's `priority` via [initialTemperature].
@riverpod
class LeadDetailController extends _$LeadDetailController {
  @override
  LeadDetailState build(
    String leadId, {
    LeadTemperature initialTemperature = LeadTemperature.warm,
  }) =>
      LeadDetailState(temperature: initialTemperature);

  void setStatus(LeadPipelineStatus s) =>
      state = state.copyWith(pipelineStatus: s);

  void setTemperature(LeadTemperature t) =>
      state = state.copyWith(temperature: t);

  void markConverted() => state = state.copyWith(converted: true);
}
