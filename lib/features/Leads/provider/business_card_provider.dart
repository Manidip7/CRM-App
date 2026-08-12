import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_result.dart';
import '../data/business_card_parser.dart';
import '../data/business_card_scanner.dart';
import '../data/leads_repository.dart';
import '../model/business_card_data.dart';
import '../model/lead_model.dart';

/// Where the scan flow currently is.
enum CardScanStage {
  /// Nothing captured yet — the screen shows the camera / gallery choices.
  idle,

  /// An image is being read and parsed.
  working,

  /// Parsing finished; the review form is showing.
  review,

  /// Capture or recognition failed; the screen shows why, with a retry.
  failed,
}

/// The reactive state of the Business-Card scan screen. The review form's text
/// inputs keep their own controllers (seeded from [data]); everything that other
/// widgets react to lives here.
class BusinessCardScanState {
  final CardScanStage stage;

  /// The captured images, front first. A second entry is the back of the card.
  final List<String> imagePaths;

  /// What the parser made of the captured images.
  final BusinessCardData data;

  /// Message shown in the [CardScanStage.failed] state.
  final String? error;

  /// True while `POST /leads` (and the follow-up detail save) is in flight.
  final bool isSaving;

  /// `hot` / `warm` / `cold` for the lead being created.
  final String priority;

  /// The chosen `lead_source_id`, seeded from the backend's default source.
  final int? leadSourceId;

  const BusinessCardScanState({
    this.stage = CardScanStage.idle,
    this.imagePaths = const [],
    this.data = BusinessCardData.empty,
    this.error,
    this.isSaving = false,
    this.priority = 'warm',
    this.leadSourceId,
  });

  bool get hasBackSide => imagePaths.length > 1;

  BusinessCardScanState copyWith({
    CardScanStage? stage,
    List<String>? imagePaths,
    BusinessCardData? data,
    String? error,
    bool clearError = false,
    bool? isSaving,
    String? priority,
    int? leadSourceId,
  }) {
    return BusinessCardScanState(
      stage: stage ?? this.stage,
      imagePaths: imagePaths ?? this.imagePaths,
      data: data ?? this.data,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
      priority: priority ?? this.priority,
      leadSourceId: leadSourceId ?? this.leadSourceId,
    );
  }
}

/// The review form's values at submit time, collected from its controllers.
/// Grouped into one object so [BusinessCardScanController.submit] stays
/// readable instead of taking fifteen arguments.
class BusinessCardLeadInput {
  final String firstName;
  final String lastName;
  final String phone;
  final String alternatePhone;
  final String email;
  final String interestedIn;
  final String company;
  final String designation;
  final String website;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String country;

  const BusinessCardLeadInput({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.alternatePhone,
    required this.email,
    required this.interestedIn,
    required this.company,
    required this.designation,
    required this.website,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
  });

  /// The fields `POST /leads` does not accept and that therefore need the
  /// follow-up `PUT /leads/{id}`. Empty when the card carried none of them.
  bool get hasCardDetails => [
        alternatePhone,
        company,
        designation,
        website,
        address,
        city,
        state,
        pincode,
        country,
      ].any((v) => v.trim().isNotEmpty);
}

/// The outcome of creating a lead from a scanned card.
class ScannedLeadResult {
  final LeadModel lead;

  /// False when the lead was created but the card's extra details (company,
  /// address, website…) could not be saved — the screen tells the user rather
  /// than silently dropping them.
  final bool detailsSaved;

  /// Why the detail save failed, when it did.
  final String? detailsError;

  const ScannedLeadResult({
    required this.lead,
    this.detailsSaved = true,
    this.detailsError,
  });
}

/// Drives the capture → recognise → parse → create-lead flow.
class BusinessCardScanController extends Notifier<BusinessCardScanState> {
  final ImagePicker _picker = ImagePicker();
  final BusinessCardScanner _scanner = const BusinessCardScanner();

  @override
  BusinessCardScanState build() => const BusinessCardScanState();

  /// Clears everything. Called when the scan screen opens, so reopening it
  /// never shows the previous card.
  void reset() => state = const BusinessCardScanState();

  void setPriority(String value) => state = state.copyWith(priority: value);

  void setLeadSourceId(int? id) => state = state.copyWith(leadSourceId: id);

  /// Captures the front of a card and parses it, replacing anything scanned
  /// before.
  Future<void> scan(ImageSource source) async {
    final path = await _pickImage(source);
    if (path == null) return; // user backed out of the camera / picker
    state = state.copyWith(
      stage: CardScanStage.working,
      imagePaths: [path],
      clearError: true,
    );
    await _recognise();
  }

  /// Adds the back of the card and re-parses both sides together. Many cards
  /// put the address or a second number on the reverse.
  Future<void> addBackSide(ImageSource source) async {
    if (state.imagePaths.isEmpty) return scan(source);
    final path = await _pickImage(source);
    if (path == null) return;
    state = state.copyWith(
      stage: CardScanStage.working,
      imagePaths: [state.imagePaths.first, path],
      clearError: true,
    );
    await _recognise();
  }

  /// Drops the back side and re-parses the front on its own.
  Future<void> removeBackSide() async {
    if (!state.hasBackSide) return;
    state = state.copyWith(
      stage: CardScanStage.working,
      imagePaths: [state.imagePaths.first],
      clearError: true,
    );
    await _recognise();
  }

  /// Runs OCR over every captured image and parses the combined result.
  Future<void> _recognise() async {
    final paths = state.imagePaths;
    try {
      final lines = <OcrLine>[];
      for (var page = 0; page < paths.length; page++) {
        lines.addAll(await _scanner.recognise(paths[page], page: page));
      }

      if (lines.isEmpty) {
        state = state.copyWith(
          stage: CardScanStage.failed,
          error: 'No text found on this image. Fill the frame with the card, '
              'hold steady and make sure the light is even.',
        );
        return;
      }

      final data = BusinessCardParser.parse(lines);

      if (data.isEmpty) {
        state = state.copyWith(
          stage: CardScanStage.failed,
          error: 'Text was found but no contact details could be read. '
              'Try a straighter, closer photo of the card.',
        );
        return;
      }

      state = state.copyWith(stage: CardScanStage.review, data: data);
    } on BusinessCardScanException catch (e) {
      state = state.copyWith(stage: CardScanStage.failed, error: e.message);
    } catch (e) {
      state = state.copyWith(
        stage: CardScanStage.failed,
        error: 'Could not scan this card. Please try again.',
      );
    }
  }

  /// Opens the camera or the gallery. Returns null when the user cancels.
  Future<String?> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        // Small text needs resolution: cap the long edge high enough that a
        // 6-point phone number survives, but not so high that ML Kit chews
        // through memory on a low-end device.
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 95,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return null;
      if (!await File(file.path).exists()) return null;
      return file.path;
    } catch (e) {
      state = state.copyWith(
        stage: CardScanStage.failed,
        error: source == ImageSource.camera
            ? 'Could not open the camera. Check the app’s camera permission '
                'in Settings and try again.'
            : 'Could not open that image. Please pick another one.',
      );
      return null;
    }
  }

  /// Creates the lead from the reviewed values.
  ///
  /// `POST /leads` only accepts the core contact fields, so anything else the
  /// card gave us (company, designation, website, full address) is saved in a
  /// second `PUT /leads/{id}` right after. A failure there is reported but does
  /// not undo the lead — the salesperson still has the contact.
  Future<ApiResult<ScannedLeadResult>> submit(
      BusinessCardLeadInput input) async {
    final sourceId = state.leadSourceId;
    if (sourceId == null) {
      return Failure(const ApiException(
        type: ApiErrorType.validation,
        message: 'Please select a lead source.',
      ));
    }

    state = state.copyWith(isSaving: true);
    final repo = ref.read(leadsRepositoryProvider);

    final created = await repo.createLead(
      firstName: input.firstName,
      lastName: input.lastName,
      phone: input.phone,
      email: input.email.isEmpty ? null : input.email,
      interestedIn: input.interestedIn,
      priority: state.priority,
      leadSourceId: sourceId,
    );

    if (created is Failure<LeadModel>) {
      state = state.copyWith(isSaving: false);
      return Failure(created.error);
    }

    final lead = (created as Success<LeadModel>).data;
    if (!input.hasCardDetails) {
      state = state.copyWith(isSaving: false);
      return Success(ScannedLeadResult(lead: lead));
    }

    final detail = await _saveCardDetails(repo, lead, input);
    state = state.copyWith(isSaving: false);
    return Success(detail);
  }

  /// Second pass: writes the card-only fields onto the freshly created lead.
  ///
  /// Every value the create call already set is echoed back from [lead] rather
  /// than sent blank, because `PUT /leads/{id}` replaces the record wholesale.
  Future<ScannedLeadResult> _saveCardDetails(
    LeadsRepository repo,
    LeadModel lead,
    BusinessCardLeadInput input,
  ) async {
    final result = await repo.updateLead(
      lead.id,
      title: lead.title,
      firstName: input.firstName,
      lastName: input.lastName,
      interestedIn: input.interestedIn,
      description: lead.description ?? '',
      phone: input.phone,
      alternatePhone: input.alternatePhone,
      email: input.email,
      company: input.company,
      designation: input.designation,
      website: input.website,
      address: input.address,
      city: input.city,
      state: input.state,
      pincode: input.pincode,
      country: input.country,
      priority: state.priority,
      statusId: lead.statusId ?? lead.status.statusId,
      leadSourceId: state.leadSourceId,
      leadTypeId: lead.leadTypeId,
      territoryId: lead.territoryId,
      branchId: lead.branchId,
      utmSource: lead.utmSource ?? '',
      utmMedium: lead.utmMedium ?? '',
      utmCampaign: lead.utmCampaign ?? '',
      integrationRef: lead.integrationRef ?? '',
    );

    return result.when(
      success: (updated) => ScannedLeadResult(lead: updated ?? lead),
      failure: (error) => ScannedLeadResult(
        lead: lead,
        detailsSaved: false,
        detailsError: error.message,
      ),
    );
  }
}

/// The scan screen's controller. Not auto-disposed — the screen calls
/// [BusinessCardScanController.reset] on open, which keeps the lifecycle
/// explicit and survives the brief detach while the camera app is foregrounded.
final businessCardScanProvider =
    NotifierProvider<BusinessCardScanController, BusinessCardScanState>(
        BusinessCardScanController.new);
