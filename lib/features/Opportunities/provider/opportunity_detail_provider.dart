import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_result.dart';
import '../data/opportunities_repository.dart';
import '../model/opportunity_detail_model.dart';
import '../model/opportunity_model.dart';

part 'opportunity_detail_provider.freezed.dart';
part 'opportunity_detail_provider.g.dart';

/// Loads an opportunity's full detail bundle from `GET /opportunities/{id}`,
/// keyed by opportunity id. Watched by the header, Information, Products,
/// Quotes, Timeline, Notes and Tasks sections of the detail screen.
final opportunityDetailBundleProvider = FutureProvider.autoDispose
    .family<OpportunityDetailBundle, String>((ref, id) async {
  final result =
      await ref.watch(opportunitiesRepositoryProvider).getOpportunityDetail(id);
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});

/// GET /opportunity-stages — the selectable stages for the header dropdown.
/// Session-cached (not autoDispose) so it is fetched once and shared.
final opportunityStagesProvider =
    FutureProvider<List<StageOption>>((ref) async {
  final result = await ref.watch(opportunitiesRepositoryProvider).getStages();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});

/// GET /products — the product catalog for the Add Product picker.
/// Session-cached (not autoDispose) so it is fetched once and shared.
final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final result =
      await ref.watch(opportunitiesRepositoryProvider).getProducts();
  return switch (result) {
    Success(:final data) => data,
    Failure(:final error) => throw error,
  };
});

@freezed
abstract class OpportunityDetailState with _$OpportunityDetailState {
  const factory OpportunityDetailState({
    @Default(OpportunityStage.proposal) OpportunityStage stage,

    /// The raw stage id currently selected in the header dropdown (e.g.
    /// `"Prospecting"`). Null until seeded from the opportunity's `stageRaw`.
    String? stageId,
    @Default(50) int probability,
    @Default(false) bool closedWon,
    @Default(<OpportunityProduct>[]) List<OpportunityProduct> products,
  }) = _OpportunityDetailState;
}

/// Editable stage / probability / won flag for a single opportunity, keyed by
/// the opportunity id so each one keeps its own state.
@riverpod
class OpportunityDetailController extends _$OpportunityDetailController {
  @override
  OpportunityDetailState build(
    String opportunityId, {
    OpportunityStage initialStage = OpportunityStage.proposal,
    String? initialStageId,
    int initialProbability = 50,
  }) =>
      OpportunityDetailState(
        stage: initialStage,
        stageId: initialStageId,
        probability: initialProbability,
        closedWon: initialStage == OpportunityStage.won,
      );

  void setStage(OpportunityStage s) => state = state.copyWith(
        stage: s,
        closedWon: s == OpportunityStage.won,
      );

  /// Selects a stage by its raw id from `GET /opportunity-stages`. Keeps the
  /// [OpportunityStage] enum (used for colors / badges elsewhere) in sync.
  void setStageId(String id) {
    final mapped = opportunityStageFromId(id);
    state = state.copyWith(
      stageId: id,
      stage: mapped,
      closedWon: mapped == OpportunityStage.won,
    );
  }

  void setProbability(int p) => state = state.copyWith(probability: p);

  void markWon() => state = state.copyWith(
        stage: OpportunityStage.won,
        stageId: 'Won',
        probability: 100,
        closedWon: true,
      );

  void addProduct(OpportunityProduct product) =>
      state = state.copyWith(products: [...state.products, product]);

  void removeProduct(int index) => state = state.copyWith(
        products: [
          for (var i = 0; i < state.products.length; i++)
            if (i != index) state.products[i],
        ],
      );
}
