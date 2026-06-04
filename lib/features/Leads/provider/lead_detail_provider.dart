import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/lead_model.dart';

part 'lead_detail_provider.freezed.dart';
part 'lead_detail_provider.g.dart';

@freezed
abstract class LeadDetailState with _$LeadDetailState {
  const factory LeadDetailState({
    @Default(LeadPipelineStatus.newLead) LeadPipelineStatus pipelineStatus,
    @Default(LeadTemperature.warm) LeadTemperature temperature,
    @Default(false) bool converted,
  }) = _LeadDetailState;
}

/// Editable pipeline status / temperature / conversion flag for a single lead,
/// keyed by the lead id so each lead keeps its own state.
@riverpod
class LeadDetailController extends _$LeadDetailController {
  @override
  LeadDetailState build(String leadId) => const LeadDetailState();

  void setStatus(LeadPipelineStatus s) =>
      state = state.copyWith(pipelineStatus: s);

  void setTemperature(LeadTemperature t) =>
      state = state.copyWith(temperature: t);

  void markConverted() => state = state.copyWith(converted: true);
}
