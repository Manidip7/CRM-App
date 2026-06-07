import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/opportunity_model.dart';

part 'opportunity_detail_provider.freezed.dart';
part 'opportunity_detail_provider.g.dart';

@freezed
abstract class OpportunityDetailState with _$OpportunityDetailState {
  const factory OpportunityDetailState({
    @Default(OpportunityStage.proposal) OpportunityStage stage,
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
    int initialProbability = 50,
  }) =>
      OpportunityDetailState(
        stage: initialStage,
        probability: initialProbability,
        closedWon: initialStage == OpportunityStage.won,
      );

  void setStage(OpportunityStage s) => state = state.copyWith(
        stage: s,
        closedWon: s == OpportunityStage.won,
      );

  void setProbability(int p) => state = state.copyWith(probability: p);

  void markWon() => state = state.copyWith(
        stage: OpportunityStage.won,
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
