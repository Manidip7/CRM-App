import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/opportunity_model.dart';

part 'opportunities_provider.freezed.dart';
part 'opportunities_provider.g.dart';

@freezed
abstract class OpportunitiesState with _$OpportunitiesState {
  const factory OpportunitiesState({
    @Default(<OpportunityModel>[]) List<OpportunityModel> items,
    OpportunityStage? selectedStage,
    @Default('') String searchQuery,
    @Default('Newest first') String sortLabel,
  }) = _OpportunitiesState;
}

/// Kept alive so opportunities converted from leads survive navigation.
@Riverpod(keepAlive: true)
class Opportunities extends _$Opportunities {
  @override
  OpportunitiesState build() => const OpportunitiesState(items: _seed);

  void setStage(OpportunityStage? stage) =>
      state = state.copyWith(selectedStage: stage);

  void setSearch(String q) => state = state.copyWith(searchQuery: q);

  /// Adds a freshly converted opportunity to the top of the list.
  void addOpportunity(OpportunityModel opp) =>
      state = state.copyWith(items: [opp, ...state.items]);

  int countByStage(OpportunityStage s) =>
      state.items.where((o) => o.stage == s).length;

  static const List<OpportunityModel> _seed = [
    OpportunityModel(
      id: '1',
      title: 'Website Opportunity',
      contactName: 'Tanweer Khan',
      value: 76.58,
      probability: 70,
      stage: OpportunityStage.proposal,
      source: SourceType.manual,
      timeAgo: '1w',
      nextFollowUp: 'Jun 2, 10:00 AM',
      phone: '+91 98765 43210',
      avatarInitials: 'TK',
      avatarColor: Color(0xFFE53935),
    ),
    OpportunityModel(
      id: '2',
      title: 'Mindverge Software Deal',
      contactName: 'Rahul Sharma',
      value: 45000,
      probability: 85,
      stage: OpportunityStage.negotiation,
      source: SourceType.facebook,
      timeAgo: '1w',
      nextFollowUp: 'Jun 3, 9:00 AM',
      phone: '+91 98765 43210',
      avatarInitials: 'RS',
      avatarColor: Color(0xFF7B72E9),
    ),
    OpportunityModel(
      id: '3',
      title: 'PeploHr Enterprise Plan',
      contactName: 'Priya Menon',
      value: 28000,
      probability: 60,
      stage: OpportunityStage.qualified,
      source: SourceType.facebook,
      timeAgo: '2w',
      nextFollowUp: 'Jun 4, 2:00 PM',
      phone: '+91 87654 32109',
      avatarInitials: 'PM',
      avatarColor: Color(0xFF2DD4A0),
    ),
    OpportunityModel(
      id: '4',
      title: 'Cloud Migration Project',
      contactName: 'Arjun Patel',
      value: 120000,
      probability: 90,
      stage: OpportunityStage.won,
      source: SourceType.website,
      timeAgo: '3w',
      nextFollowUp: 'Jun 5, 11:00 AM',
      phone: '+91 76543 21098',
      avatarInitials: 'AP',
      avatarColor: Color(0xFFFF7043),
    ),
    OpportunityModel(
      id: '5',
      title: 'Annual Support Contract',
      contactName: 'Neha Singh',
      value: 55000,
      probability: 40,
      stage: OpportunityStage.proposal,
      source: SourceType.referral,
      timeAgo: '3d',
      nextFollowUp: 'Jun 6, 3:30 PM',
      phone: '+91 90123 45678',
      avatarInitials: 'NS',
      avatarColor: Color(0xFF26C6DA),
    ),
    OpportunityModel(
      id: '6',
      title: 'UI/UX Redesign',
      contactName: 'Vikram Iyer',
      value: 18500,
      probability: 55,
      stage: OpportunityStage.negotiation,
      source: SourceType.email,
      timeAgo: '5d',
      nextFollowUp: 'Jun 7, 4:00 PM',
      phone: '+91 81234 56789',
      avatarInitials: 'VI',
      avatarColor: Color(0xFFAB47BC),
    ),
  ];
}

/// Opportunities filtered by the active search query + selected stage.
@riverpod
List<OpportunityModel> filteredOpportunities(Ref ref) {
  final s = ref.watch(opportunitiesProvider);
  final query = s.searchQuery.toLowerCase();
  return s.items.where((o) {
    final matchesSearch = query.isEmpty ||
        o.title.toLowerCase().contains(query) ||
        o.contactName.toLowerCase().contains(query) ||
        o.phone.contains(query);
    final matchesStage =
        s.selectedStage == null || o.stage == s.selectedStage;
    return matchesSearch && matchesStage;
  }).toList();
}
