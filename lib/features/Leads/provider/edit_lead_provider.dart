import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../data/leads_repository.dart';
import '../model/lead_model.dart';

/// The Edit-Lead form's free-text values, collected from the screen's
/// [TextEditingController]s at submit time. Grouped into one object so
/// [EditLeadForm.submit] stays readable instead of taking twenty arguments.
class EditLeadText {
  final String title;
  final String firstName;
  final String lastName;
  final String interestedIn;
  final String description;
  final String phone;
  final String alternatePhone;
  final String email;
  final String company;
  final String designation;
  final String website;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final String utmSource;
  final String utmMedium;
  final String utmCampaign;
  final String integrationRef;

  const EditLeadText({
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.interestedIn,
    required this.description,
    required this.phone,
    required this.alternatePhone,
    required this.email,
    required this.company,
    required this.designation,
    required this.website,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
    required this.utmSource,
    required this.utmMedium,
    required this.utmCampaign,
    required this.integrationRef,
  });
}

/// Reactive state backing the Edit-Lead form. Only the values that drive other
/// widgets live here — the dropdown selections (which also scope the branch
/// list to the chosen territory) and the in-flight save flag. Plain text inputs
/// keep their own controllers.
class EditLeadFormState {
  /// `hot` / `warm` / `cold`, matching the backend's `priority` values.
  final String priority;

  final int? statusId;
  final int? leadSourceId;
  final int? leadTypeId;
  final int? territoryId;
  final int? branchId;

  /// True while `PUT /leads/{id}` is in flight — blocks a second submit.
  final bool isSaving;

  const EditLeadFormState({
    this.priority = 'warm',
    this.statusId,
    this.leadSourceId,
    this.leadTypeId,
    this.territoryId,
    this.branchId,
    this.isSaving = false,
  });

  /// The `clear*` flags exist because a null id argument means "unchanged"
  /// here; they are how the form actually deselects a dropdown.
  EditLeadFormState copyWith({
    String? priority,
    int? statusId,
    bool clearStatus = false,
    int? leadSourceId,
    bool clearLeadSource = false,
    int? leadTypeId,
    bool clearLeadType = false,
    int? territoryId,
    bool clearTerritory = false,
    int? branchId,
    bool clearBranch = false,
    bool? isSaving,
  }) {
    return EditLeadFormState(
      priority: priority ?? this.priority,
      statusId: clearStatus ? null : (statusId ?? this.statusId),
      leadSourceId:
          clearLeadSource ? null : (leadSourceId ?? this.leadSourceId),
      leadTypeId: clearLeadType ? null : (leadTypeId ?? this.leadTypeId),
      territoryId: clearTerritory ? null : (territoryId ?? this.territoryId),
      branchId: clearBranch ? null : (branchId ?? this.branchId),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class EditLeadForm extends Notifier<EditLeadFormState> {
  @override
  EditLeadFormState build() => const EditLeadFormState();

  /// Loads the form with [lead]'s current values. Called once when the screen
  /// opens. An unrecognised priority falls back to `warm`, matching how the
  /// detail screen seeds its temperature.
  void seed(LeadModel lead) {
    final priority = lead.priority?.toLowerCase().trim();
    state = EditLeadFormState(
      priority: const {'hot', 'warm', 'cold'}.contains(priority)
          ? priority!
          : 'warm',
      statusId: lead.statusId ?? lead.status.statusId,
      leadSourceId: lead.leadSourceId,
      leadTypeId: lead.leadTypeId,
      territoryId: lead.territoryId,
      branchId: lead.branchId,
    );
  }

  void setPriority(String p) => state = state.copyWith(priority: p);

  void setStatusId(int? id) => state =
      id == null ? state.copyWith(clearStatus: true) : state.copyWith(statusId: id);

  void setLeadSourceId(int? id) => state = id == null
      ? state.copyWith(clearLeadSource: true)
      : state.copyWith(leadSourceId: id);

  void setLeadTypeId(int? id) => state = id == null
      ? state.copyWith(clearLeadType: true)
      : state.copyWith(leadTypeId: id);

  /// Selecting a territory also clears the branch: the branch list is scoped to
  /// the territory, so the previous pick may not exist in the new one.
  void setTerritoryId(int? id) {
    if (id == state.territoryId) return;
    state = (id == null
            ? state.copyWith(clearTerritory: true)
            : state.copyWith(territoryId: id))
        .copyWith(clearBranch: true);
  }

  void setBranchId(int? id) => state =
      id == null ? state.copyWith(clearBranch: true) : state.copyWith(branchId: id);

  /// Saves the form via `PUT /leads/{id}`, returning the API result so the
  /// screen can surface the backend's validation message on failure.
  Future<ApiResult<LeadModel?>> submit(String leadId, EditLeadText text) async {
    state = state.copyWith(isSaving: true);
    final result = await ref.read(leadsRepositoryProvider).updateLead(
          leadId,
          title: text.title,
          firstName: text.firstName,
          lastName: text.lastName,
          interestedIn: text.interestedIn,
          description: text.description,
          phone: text.phone,
          alternatePhone: text.alternatePhone,
          email: text.email,
          company: text.company,
          designation: text.designation,
          website: text.website,
          address: text.address,
          city: text.city,
          state: text.state,
          pincode: text.pincode,
          country: text.country,
          priority: state.priority,
          statusId: state.statusId,
          leadSourceId: state.leadSourceId,
          leadTypeId: state.leadTypeId,
          territoryId: state.territoryId,
          branchId: state.branchId,
          utmSource: text.utmSource,
          utmMedium: text.utmMedium,
          utmCampaign: text.utmCampaign,
          integrationRef: text.integrationRef,
        );
    state = state.copyWith(isSaving: false);
    return result;
  }
}

final editLeadFormProvider =
    NotifierProvider<EditLeadForm, EditLeadFormState>(EditLeadForm.new);
