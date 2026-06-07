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
    @Default(<OpportunityModel>[]) List<OpportunityModel> backlogItems,
    OpportunityStage? selectedStage,
    @Default('') String searchQuery,
    @Default('Newest first') String sortLabel,
    @Default(false) bool showBacklog,
  }) = _OpportunitiesState;
}

/// Kept alive so opportunities converted from leads survive navigation.
@Riverpod(keepAlive: true)
class Opportunities extends _$Opportunities {
  @override
  OpportunitiesState build() =>
      const OpportunitiesState(items: _seed, backlogItems: _backlogSeed);

  void setStage(OpportunityStage? stage) =>
      state = state.copyWith(selectedStage: stage);

  void setSearch(String q) => state = state.copyWith(searchQuery: q);

  /// Adds a freshly converted opportunity to the top of the active list.
  void addOpportunity(OpportunityModel opp) =>
      state = state.copyWith(items: [opp, ...state.items]);

  /// Switches between the live pipeline and the backlog, resetting filters.
  void toggleBacklog() => state = state.copyWith(
        showBacklog: !state.showBacklog,
        selectedStage: null,
        searchQuery: '',
      );

  /// Applies stage / probability edits made on the detail screen back onto the
  /// matching opportunity (in whichever list it lives).
  void updateOpportunity(
    String id, {
    OpportunityStage? stage,
    int? probability,
  }) {
    OpportunityModel patch(OpportunityModel o) => o.id == id
        ? o.copyWith(stage: stage, probability: probability)
        : o;
    state = state.copyWith(
      items: [for (final o in state.items) patch(o)],
      backlogItems: [for (final o in state.backlogItems) patch(o)],
    );
  }

  int countByStage(OpportunityStage s) {
    final list = state.showBacklog ? state.backlogItems : state.items;
    return list.where((o) => o.stage == s).length;
  }

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

  // Backlog — stalled / overdue deals that have slipped and need attention.
  static const List<OpportunityModel> _backlogSeed = [
    OpportunityModel(
      id: 'B1',
      title: 'Acme Corp - Stalled Deal',
      contactName: 'Rohan Gupta',
      value: 52000,
      probability: 30,
      stage: OpportunityStage.negotiation,
      source: SourceType.facebook,
      timeAgo: '5w',
      nextFollowUp: 'Overdue by 5d',
      phone: '+91 99887 76655',
      avatarInitials: 'RG',
      avatarColor: Color(0xFFE53935),
    ),
    OpportunityModel(
      id: 'B2',
      title: 'NovaTech - No Response',
      contactName: 'Kavya Nair',
      value: 30000,
      probability: 20,
      stage: OpportunityStage.proposal,
      source: SourceType.website,
      timeAgo: '6w',
      nextFollowUp: 'Overdue by 8d',
      phone: '+91 88776 65544',
      avatarInitials: 'KN',
      avatarColor: Color(0xFF7B72E9),
    ),
    OpportunityModel(
      id: 'B3',
      title: 'Skyline Ventures - Cold',
      contactName: 'Aditya Rao',
      value: 88000,
      probability: 25,
      stage: OpportunityStage.qualified,
      source: SourceType.referral,
      timeAgo: '8w',
      nextFollowUp: 'Overdue by 12d',
      phone: '+91 77665 54433',
      avatarInitials: 'AR',
      avatarColor: Color(0xFF2DD4A0),
    ),
    OpportunityModel(
      id: 'B4',
      title: 'Pixel Labs - Reactivate',
      contactName: 'Meera Joshi',
      value: 21000,
      probability: 15,
      stage: OpportunityStage.proposal,
      source: SourceType.manual,
      timeAgo: '4w',
      nextFollowUp: 'Overdue by 3d',
      phone: '+91 66554 43322',
      avatarInitials: 'MJ',
      avatarColor: Color(0xFF26C6DA),
    ),
    OpportunityModel(
      id: 'B5',
      title: 'Quantum Soft - Dropped',
      contactName: 'Sahil Khan',
      value: 47000,
      probability: 10,
      stage: OpportunityStage.lost,
      source: SourceType.email,
      timeAgo: '9w',
      nextFollowUp: 'Overdue by 20d',
      phone: '+91 55443 32211',
      avatarInitials: 'SK',
      avatarColor: Color(0xFFAB47BC),
    ),
  ];
}

/// Opportunities filtered by the active search query + selected stage.
@riverpod
List<OpportunityModel> filteredOpportunities(Ref ref) {
  final s = ref.watch(opportunitiesProvider);
  final source = s.showBacklog ? s.backlogItems : s.items;
  final query = s.searchQuery.toLowerCase();
  return source.where((o) {
    final matchesSearch = query.isEmpty ||
        o.title.toLowerCase().contains(query) ||
        o.contactName.toLowerCase().contains(query) ||
        o.phone.contains(query);
    final matchesStage =
        s.selectedStage == null || o.stage == s.selectedStage;
    return matchesSearch && matchesStage;
  }).toList();
}
