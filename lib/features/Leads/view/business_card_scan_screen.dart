import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/AppColors.dart';
import '../model/business_card_data.dart';
import '../model/lead_model.dart';
import '../provider/business_card_provider.dart';
import '../provider/leads_provider.dart';

/// Scans a business / visiting card and turns it into a lead.
///
/// The flow is capture → recognise → **review** → create. The review step is
/// deliberate: OCR is very good but never perfect, so every parsed value lands
/// in an editable field with the raw scanned text one tap away. Nothing is
/// written to the CRM until the user has seen it.
///
/// Returns the created [LeadModel] to the caller when a lead is saved.
class BusinessCardScanScreen extends ConsumerStatefulWidget {
  const BusinessCardScanScreen({super.key});

  @override
  ConsumerState<BusinessCardScanScreen> createState() =>
      _BusinessCardScanScreenState();
}

class _BusinessCardScanScreenState
    extends ConsumerState<BusinessCardScanScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _altPhone = TextEditingController();
  final _email = TextEditingController();
  final _company = TextEditingController();
  final _designation = TextEditingController();
  final _website = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _country = TextEditingController();
  final _interestedIn =
      TextEditingController(text: 'Business card enquiry');

  /// The parse result the form is currently showing. Compared by identity so a
  /// rescan re-seeds the fields but an unrelated state change (saving, priority)
  /// never overwrites what the user has typed.
  BusinessCardData? _seededFrom;

  @override
  void initState() {
    super.initState();
    // Start clean: a card scanned earlier in the session must not resurface.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(businessCardScanProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    for (final c in [
      _firstName, _lastName, _phone, _altPhone, _email, _company,
      _designation, _website, _address, _city, _state, _pincode, _country,
      _interestedIn,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Copies a fresh parse result into the form's controllers.
  void _seed(BusinessCardData data) {
    _seededFrom = data;
    _firstName.text = data.firstName;
    _lastName.text = data.lastName;
    _phone.text = data.phone;
    _altPhone.text = data.alternatePhone;
    _email.text = data.email;
    _company.text = data.company;
    _designation.text = data.designation;
    _website.text = data.website;
    _address.text = data.address;
    _city.text = data.city;
    _state.text = data.state;
    _pincode.text = data.pincode;
    _country.text = data.country;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BusinessCardScanState>(businessCardScanProvider, (prev, next) {
      if (next.stage != CardScanStage.review) return;
      if (identical(_seededFrom, next.data)) return;
      _seed(next.data);
    });

    // Preselect the backend's default lead source, exactly as the Add-Lead
    // sheet does, so the scan flow is one tap shorter.
    final sources = ref.watch(leadSourcesProvider);
    final selectedSource =
        ref.watch(businessCardScanProvider.select((s) => s.leadSourceId));
    if (selectedSource == null) {
      final list = sources.value;
      if (list != null && list.isNotEmpty) {
        final fallback =
            list.firstWhere((s) => s.isDefault, orElse: () => list.first);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (ref.read(businessCardScanProvider).leadSourceId != null) return;
          ref
              .read(businessCardScanProvider.notifier)
              .setLeadSourceId(fallback.id);
        });
      }
    }

    final state = ref.watch(businessCardScanProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'Scan Business Card',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: switch (state.stage) {
          CardScanStage.idle => _buildIdle(),
          CardScanStage.working => _buildWorking(state),
          CardScanStage.failed => _buildFailed(state),
          CardScanStage.review => _buildReview(state),
        },
      ),
      bottomNavigationBar:
          state.stage == CardScanStage.review ? _buildSaveBar(state) : null,
    );
  }

  // ─────────────────────────────── idle ────────────────────────────────────

  Widget _buildIdle() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 34),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.badge_outlined,
                      size: 38, color: AppColors.primary),
                ),
                const SizedBox(height: 18),
                Text(
                  'Turn a card into a lead',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    'Photograph the card and the name, phone, email, company '
                    'and address are filled in for you.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _primaryButton(
            icon: Icons.photo_camera_rounded,
            label: 'Take a photo',
            onTap: () => ref
                .read(businessCardScanProvider.notifier)
                .scan(ImageSource.camera),
          ),
          const SizedBox(height: 12),
          _secondaryButton(
            icon: Icons.photo_library_outlined,
            label: 'Choose from gallery',
            onTap: () => ref
                .read(businessCardScanProvider.notifier)
                .scan(ImageSource.gallery),
          ),
          const SizedBox(height: 26),
          _tipsCard(),
        ],
      ),
    );
  }

  Widget _tipsCard() {
    const tips = [
      'Lay the card flat and fill the frame with it.',
      'Keep the card straight — avoid steep angles.',
      'Use even light; avoid glare on glossy cards.',
      'Scan the back too if the address is printed there.',
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined,
                  size: 17, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'For the best result',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 8),
                    child: Icon(Icons.circle,
                        size: 5, color: AppColors.textSecondary),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────────────────── working ───────────────────────────────────

  Widget _buildWorking(BusinessCardScanState state) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.imagePaths.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(state.imagePaths.first),
                width: 220,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 26),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Reading the card…',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Everything happens on your phone.',
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────── failed ───────────────────────────────────

  Widget _buildFailed(BusinessCardScanState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.document_scanner_outlined,
                  size: 34, color: AppColors.red),
            ),
            const SizedBox(height: 18),
            Text(
              "Couldn't read that card",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _primaryButton(
              icon: Icons.photo_camera_rounded,
              label: 'Scan again',
              onTap: () => ref
                  .read(businessCardScanProvider.notifier)
                  .scan(ImageSource.camera),
            ),
            const SizedBox(height: 12),
            _secondaryButton(
              icon: Icons.photo_library_outlined,
              label: 'Choose from gallery',
              onTap: () => ref
                  .read(businessCardScanProvider.notifier)
                  .scan(ImageSource.gallery),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  ref.read(businessCardScanProvider.notifier).reset(),
              child: Text(
                'Back',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────── review ───────────────────────────────────

  Widget _buildReview(BusinessCardScanState state) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _scanSummary(state),
          const SizedBox(height: 16),
          _section(
            icon: Icons.person_outline_rounded,
            title: 'Contact',
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      label: 'First name',
                      controller: _firstName,
                      required: true,
                      capitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      label: 'Last name',
                      controller: _lastName,
                      capitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
              _field(
                label: 'Mobile number',
                controller: _phone,
                required: true,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.isEmpty) return 'Required';
                  if (digits.length < 10) return 'Enter a valid phone number';
                  return null;
                },
              ),
              _field(
                label: 'Alternate number',
                controller: _altPhone,
                keyboardType: TextInputType.phone,
              ),
              _field(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return null;
                  final ok =
                      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
                  return ok ? null : 'Enter a valid email';
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.business_outlined,
            title: 'Business',
            children: [
              _field(
                label: 'Company',
                controller: _company,
                capitalization: TextCapitalization.words,
              ),
              _field(
                label: 'Designation',
                controller: _designation,
                capitalization: TextCapitalization.words,
              ),
              _field(
                label: 'Website',
                controller: _website,
                keyboardType: TextInputType.url,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.location_on_outlined,
            title: 'Address',
            children: [
              _field(
                label: 'Address',
                controller: _address,
                maxLines: 2,
                capitalization: TextCapitalization.words,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      label: 'City',
                      controller: _city,
                      capitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      label: 'State',
                      controller: _state,
                      capitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      label: 'Pincode',
                      controller: _pincode,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      label: 'Country',
                      controller: _country,
                      capitalization: TextCapitalization.words,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _section(
            icon: Icons.flag_outlined,
            title: 'Lead details',
            children: [
              _field(
                label: 'Interested in',
                controller: _interestedIn,
                required: true,
                capitalization: TextCapitalization.sentences,
              ),
              _label('Priority', required: true),
              const SizedBox(height: 8),
              Row(
                children: [
                  _priorityChip('Hot', 'hot', AppColors.red, state.priority),
                  const SizedBox(width: 10),
                  _priorityChip(
                      'Warm', 'warm', const Color(0xFFFFB547), state.priority),
                  const SizedBox(width: 10),
                  _priorityChip(
                      'Cold', 'cold', AppColors.primary, state.priority),
                ],
              ),
              const SizedBox(height: 16),
              _label('Lead source', required: true),
              const SizedBox(height: 8),
              _sourceDropdown(state),
            ],
          ),
          const SizedBox(height: 12),
          _rawTextPanel(state.data),
        ],
      ),
    );
  }

  /// The strip above the form: what was captured, how much was read, and the
  /// controls for rescanning or adding the back of the card.
  Widget _scanSummary(BusinessCardScanState state) {
    final count = state.data.capturedCount;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < state.imagePaths.length; i++) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(state.imagePaths[i]),
                    width: 76,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 76,
                      height: 50,
                      color: AppColors.background,
                      child: const Icon(Icons.image_not_supported_outlined,
                          size: 18, color: AppColors.textLight),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count detail${count == 1 ? '' : 's'} captured',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Check every field before saving.',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _miniAction(
                  icon: Icons.refresh_rounded,
                  label: 'Rescan',
                  onTap: () => ref
                      .read(businessCardScanProvider.notifier)
                      .scan(ImageSource.camera),
                ),
              ),
              Container(width: 1, height: 22, color: AppColors.divider),
              Expanded(
                child: state.hasBackSide
                    ? _miniAction(
                        icon: Icons.layers_clear_outlined,
                        label: 'Remove back',
                        onTap: () => ref
                            .read(businessCardScanProvider.notifier)
                            .removeBackSide(),
                      )
                    : _miniAction(
                        icon: Icons.flip_to_back_rounded,
                        label: 'Scan back side',
                        onTap: () => ref
                            .read(businessCardScanProvider.notifier)
                            .addBackSide(ImageSource.camera),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Everything the camera read, verbatim. The safety net for a card whose
  /// layout defeats the parser — the user can still copy a value out by hand.
  Widget _rawTextPanel(BusinessCardData data) {
    if (data.rawLines.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: const Icon(Icons.text_snippet_outlined,
              size: 18, color: AppColors.textSecondary),
          title: Text(
            'Raw scanned text',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                data.rawText,
                style: GoogleFonts.robotoMono(
                  fontSize: 11.5,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: data.rawText));
                  _toast('Scanned text copied', AppColors.primary);
                },
                icon: const Icon(Icons.copy_rounded,
                    size: 15, color: AppColors.primary),
                label: Text(
                  'Copy',
                  style: GoogleFonts.poppins(
                      fontSize: 12.5, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveBar(BusinessCardScanState state) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).viewPadding.bottom),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: state.isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          icon: state.isSaving
              ? const SizedBox.shrink()
              : const Icon(Icons.person_add_alt_1_rounded,
                  size: 18, color: Colors.white),
          label: state.isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: Colors.white),
                )
              : Text(
                  'Create Lead',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  // ────────────────────────────── submit ───────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final notifier = ref.read(businessCardScanProvider.notifier);
    if (ref.read(businessCardScanProvider).leadSourceId == null) {
      return _toast('Please select a lead source', AppColors.red);
    }

    String text(TextEditingController c) => c.text.trim();

    final result = await notifier.submit(BusinessCardLeadInput(
      firstName: text(_firstName),
      lastName: text(_lastName),
      phone: text(_phone),
      alternatePhone: text(_altPhone),
      email: text(_email),
      interestedIn: text(_interestedIn),
      company: text(_company),
      designation: text(_designation),
      website: text(_website),
      address: text(_address),
      city: text(_city),
      state: text(_state),
      pincode: text(_pincode),
      country: text(_country),
    ));

    if (!mounted) return;
    result.when(
      success: (scanned) {
        // Grab the messenger before popping — after the pop this screen's
        // context is defunct and the confirmation would never appear.
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop<LeadModel>(scanned.lead);
        if (scanned.detailsSaved) {
          _showOn(messenger, 'Lead created from business card',
              AppColors.green);
        } else {
          // The contact is safe; only the card's extra fields didn't stick.
          _showOn(
            messenger,
            'Lead created, but the card details could not be saved: '
            '${scanned.detailsError ?? 'please edit the lead to add them.'}',
            const Color(0xFFFFB547),
          );
        }
      },
      failure: (error) => _toast(error.message, AppColors.red),
    );
  }

  // ─────────────────────────── shared widgets ──────────────────────────────

  Widget _section({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label, required: required),
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textCapitalization: capitalization,
            validator: validator ??
                (required
                    ? (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null
                    : null),
            style:
                GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Not found on the card',
              hintStyle: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textLight),
              filled: true,
              fillColor: AppColors.background,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.divider, width: 0.8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.divider, width: 0.8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.4),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.red, width: 1.4),
              ),
              errorStyle:
                  GoogleFonts.poppins(fontSize: 11.5, color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        children: required
            ? [
                TextSpan(
                  text: ' *',
                  style:
                      GoogleFonts.poppins(fontSize: 12.5, color: AppColors.red),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _priorityChip(
      String label, String value, Color color, String selected) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            ref.read(businessCardScanProvider.notifier).setPriority(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.divider,
              width: isSelected ? 1.5 : 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                value == 'hot'
                    ? Icons.local_fire_department_rounded
                    : value == 'warm'
                        ? Icons.wb_sunny_rounded
                        : Icons.ac_unit_rounded,
                size: 16,
                color: isSelected ? color : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceDropdown(BusinessCardScanState state) {
    final sourcesAsync = ref.watch(leadSourcesProvider);
    return sourcesAsync.when(
      loading: () => _shell(const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      )),
      error: (_, _) => _shell(Row(
        children: [
          Expanded(
            child: Text(
              "Couldn't load sources",
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.red),
            ),
          ),
          GestureDetector(
            onTap: () => ref.invalidate(leadSourcesProvider),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      )),
      data: (sources) => _shell(
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: state.leadSourceId,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary),
            hint: Text(
              'Select source',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: AppColors.textLight),
            ),
            borderRadius: BorderRadius.circular(12),
            style: GoogleFonts.poppins(
                fontSize: 14, color: AppColors.textPrimary),
            items: [
              for (final s in sources)
                DropdownMenuItem(value: s.id, child: Text(s.label)),
            ],
            onChanged: (v) =>
                ref.read(businessCardScanProvider.notifier).setLeadSourceId(v),
          ),
        ),
      ),
    );
  }

  Widget _shell(Widget child) {
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: child,
    );
  }

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, size: 19, color: Colors.white),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppColors.primary, width: 1.2),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, size: 19, color: AppColors.primary),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  void _toast(String message, Color color) {
    if (!mounted) return;
    _showOn(ScaffoldMessenger.of(context), message, color);
  }

  void _showOn(ScaffoldMessengerState messenger, String message, Color color) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
