import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_result.dart';
import '../../../core/utils/AppColors.dart';
import '../model/lead_model.dart';
import '../provider/assign_providers.dart';
import '../provider/edit_lead_provider.dart';
import '../provider/lead_detail_provider.dart';
import '../provider/leads_provider.dart';

/// A lookup option normalised to `(id, name)` so the five id-backed dropdowns
/// (status, source, type, territory, branch) can share one builder, despite
/// their providers returning three different option classes.
typedef _Option = ({int id, String name});

/// Full-screen form to edit an existing [LeadModel], saved via
/// `PUT /leads/{id}`.
///
/// The dropdown selections live in [editLeadFormProvider] (the territory pick
/// also scopes the branch list); the plain text inputs, which drive nothing
/// else, keep their own controllers.
class EditLeadScreen extends ConsumerStatefulWidget {
  final LeadModel lead;

  const EditLeadScreen({super.key, required this.lead});

  @override
  ConsumerState<EditLeadScreen> createState() => _EditLeadScreenState();
}

class _EditLeadScreenState extends ConsumerState<EditLeadScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Information
  late final TextEditingController _titleController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _interestedInController;
  late final TextEditingController _descriptionController;

  // Contact & Professional Details
  late final TextEditingController _phoneController;
  late final TextEditingController _altPhoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _companyController;
  late final TextEditingController _designationController;
  late final TextEditingController _websiteController;

  // Location Details
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _countryController;

  // Marketing & Tracking
  late final TextEditingController _utmSourceController;
  late final TextEditingController _utmMediumController;
  late final TextEditingController _utmCampaignController;
  late final TextEditingController _integrationRefController;

  @override
  void initState() {
    super.initState();
    final lead = widget.lead;

    // The list endpoint composes `contact_name` from the two name parts and may
    // not send them back, so fall back to splitting it on the first space.
    final parts = lead.contactName.trim().split(RegExp(r'\s+'));
    final firstName = lead.firstName ?? (parts.isEmpty ? '' : parts.first);
    final lastName =
        lead.lastName ?? (parts.length > 1 ? parts.sublist(1).join(' ') : '');

    _titleController = TextEditingController(text: lead.title);
    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _interestedInController = TextEditingController(text: lead.interestedIn ?? '');
    _descriptionController = TextEditingController(text: lead.description ?? '');
    _phoneController = TextEditingController(text: lead.phone ?? '');
    _altPhoneController = TextEditingController(text: lead.alternatePhone ?? '');
    _emailController = TextEditingController(text: lead.email ?? '');
    _companyController = TextEditingController(text: lead.companyName ?? '');
    _designationController = TextEditingController(text: lead.designation ?? '');
    _websiteController = TextEditingController(text: lead.website ?? '');
    _addressController = TextEditingController(text: lead.address ?? '');
    _cityController = TextEditingController(text: lead.city ?? '');
    _stateController = TextEditingController(text: lead.stateName ?? '');
    _pincodeController = TextEditingController(text: lead.pincode ?? '');
    _countryController = TextEditingController(text: lead.country ?? '');
    _utmSourceController = TextEditingController(text: lead.utmSource ?? '');
    _utmMediumController = TextEditingController(text: lead.utmMedium ?? '');
    _utmCampaignController = TextEditingController(text: lead.utmCampaign ?? '');
    _integrationRefController =
        TextEditingController(text: lead.integrationRef ?? '');

    // Seed the reactive dropdown state after the first frame — modifying a
    // provider during initState/build throws in Riverpod.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(editLeadFormProvider.notifier).seed(lead);
    });
  }

  @override
  void dispose() {
    for (final c in [
      _titleController,
      _firstNameController,
      _lastNameController,
      _interestedInController,
      _descriptionController,
      _phoneController,
      _altPhoneController,
      _emailController,
      _companyController,
      _designationController,
      _websiteController,
      _addressController,
      _cityController,
      _stateController,
      _pincodeController,
      _countryController,
      _utmSourceController,
      _utmMediumController,
      _utmCampaignController,
      _integrationRefController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  EditLeadForm get _form => ref.read(editLeadFormProvider.notifier);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    _buildBasicInformation(),
                    const SizedBox(height: 14),
                    _buildContactDetails(),
                    const SizedBox(height: 14),
                    _buildLocationDetails(),
                    const SizedBox(height: 14),
                    _buildClassification(),
                    const SizedBox(height: 14),
                    _buildMarketing(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionBar(),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 17, color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Lead',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  widget.lead.leadNo ?? widget.lead.contactName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Basic Information ────────────────────────────────────────────────────────
  Widget _buildBasicInformation() {
    return _section(
      icon: Icons.info_outline_rounded,
      title: 'Basic Information',
      children: [
        _textField(
          controller: _titleController,
          label: 'Lead Title / Opportunity Name',
          hint: 'e.g. Mindverge Software - Facebook Lead',
          required: true,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _textField(
                controller: _firstNameController,
                label: 'First Name',
                hint: 'First name',
                required: true,
                capitalizeWords: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _textField(
                controller: _lastNameController,
                label: 'Last Name',
                hint: 'Last name',
                capitalizeWords: true,
              ),
            ),
          ],
        ),
        _textField(
          controller: _interestedInController,
          label: 'Interested In',
          hint: 'Product or service of interest',
        ),
        _textField(
          controller: _descriptionController,
          label: 'Description',
          hint: 'Notes about this lead',
          maxLines: 4,
        ),
      ],
    );
  }

  // ── Contact & Professional Details ───────────────────────────────────────────
  Widget _buildContactDetails() {
    return _section(
      icon: Icons.contact_phone_outlined,
      title: 'Contact & Professional Details',
      children: [
        _textField(
          controller: _phoneController,
          label: 'Phone',
          hint: '+91 98765 43210',
          required: true,
          keyboardType: TextInputType.phone,
        ),
        _textField(
          controller: _altPhoneController,
          label: 'Alternative Phone',
          hint: 'Secondary number',
          keyboardType: TextInputType.phone,
        ),
        _textField(
          controller: _emailController,
          label: 'Email',
          hint: 'name@company.com',
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            final text = v?.trim() ?? '';
            if (text.isEmpty) return null;
            final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
            return valid ? null : 'Enter a valid email address';
          },
        ),
        _textField(
          controller: _companyController,
          label: 'Company',
          hint: 'Organisation name',
          capitalizeWords: true,
        ),
        _textField(
          controller: _designationController,
          label: 'Designation',
          hint: 'e.g. Procurement Head',
          capitalizeWords: true,
        ),
        _textField(
          controller: _websiteController,
          label: 'Website',
          hint: 'company.com',
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  // ── Location Details ─────────────────────────────────────────────────────────
  Widget _buildLocationDetails() {
    return _section(
      icon: Icons.location_on_outlined,
      title: 'Location Details',
      children: [
        _textField(
          controller: _addressController,
          label: 'Address',
          hint: 'Street address',
          maxLines: 2,
          capitalizeWords: true,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _textField(
                controller: _cityController,
                label: 'City',
                hint: 'City',
                capitalizeWords: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _textField(
                controller: _stateController,
                label: 'State',
                hint: 'State',
                capitalizeWords: true,
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _textField(
                controller: _pincodeController,
                label: 'Pincode',
                hint: '700001',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _textField(
                controller: _countryController,
                label: 'Country',
                hint: 'Country',
                capitalizeWords: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Classification ───────────────────────────────────────────────────────────
  Widget _buildClassification() {
    final form = ref.watch(editLeadFormProvider);

    return _section(
      icon: Icons.sell_outlined,
      title: 'Classification',
      children: [
        _buildPriorityDropdown(form.priority),
        _idDropdown(
          label: 'Status',
          options: ref.watch(leadStatusesProvider).whenData(
                (list) => [for (final s in list) (id: s.id, name: s.name)],
              ),
          selected: form.statusId,
          fallbackLabel: null,
          onChanged: _form.setStatusId,
        ),
        _idDropdown(
          label: 'Lead Source',
          options: ref.watch(leadSourcesProvider).whenData(
                (list) => [for (final s in list) (id: s.id, name: s.label)],
              ),
          selected: form.leadSourceId,
          fallbackLabel: widget.lead.sourceKnown
              ? widget.lead.source.name.toUpperCase()
              : null,
          onChanged: _form.setLeadSourceId,
        ),
        _idDropdown(
          label: 'Lead Type',
          options: ref.watch(leadTypesProvider).whenData(
                (list) => [for (final t in list) (id: t.id, name: t.name)],
              ),
          selected: form.leadTypeId,
          fallbackLabel: widget.lead.leadTypeName,
          onChanged: _form.setLeadTypeId,
        ),
        _idDropdown(
          label: 'Territory',
          options: ref.watch(territoriesProvider).whenData(
                (list) => [for (final t in list) (id: t.id, name: t.name)],
              ),
          selected: form.territoryId,
          fallbackLabel: widget.lead.territoryName,
          onChanged: _form.setTerritoryId,
        ),
        _idDropdown(
          label: 'Branch',
          // Scoped to the picked territory; passing null loads every branch.
          options: ref.watch(branchesProvider(form.territoryId)).whenData(
                (list) => [for (final b in list) (id: b.id, name: b.name)],
              ),
          selected: form.branchId,
          fallbackLabel: widget.lead.branchName,
          onChanged: _form.setBranchId,
        ),
      ],
    );
  }

  /// Priority is a fixed `hot` / `warm` / `cold` set (no lookup endpoint), so it
  /// gets its own dropdown rather than going through [_idDropdown].
  Widget _buildPriorityDropdown(String selected) {
    const priorities = ['hot', 'warm', 'cold'];
    return _fieldWrapper(
      label: 'Priority',
      child: DropdownButtonFormField<String>(
        initialValue: priorities.contains(selected) ? selected : 'warm',
        isExpanded: true,
        decoration: _inputDecoration(hint: 'Select priority'),
        style: _valueStyle,
        dropdownColor: AppColors.cardBackground,
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary),
        items: [
          for (final p in priorities)
            DropdownMenuItem<String>(
              value: p,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _priorityColor(p),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${p[0].toUpperCase()}${p.substring(1)} Lead',
                      style: _valueStyle),
                ],
              ),
            ),
        ],
        onChanged: (v) {
          if (v != null) _form.setPriority(v);
        },
      ),
    );
  }

  Color _priorityColor(String p) => switch (p) {
        'hot' => AppColors.red,
        'cold' => const Color(0xFF42A5F5),
        _ => const Color(0xFFFFB547),
      };

  // ── Marketing & Tracking ─────────────────────────────────────────────────────
  Widget _buildMarketing() {
    return _section(
      icon: Icons.campaign_outlined,
      title: 'Marketing & Tracking',
      children: [
        _textField(
          controller: _utmSourceController,
          label: 'UTM Source',
          hint: 'e.g. facebook',
        ),
        _textField(
          controller: _utmMediumController,
          label: 'UTM Medium',
          hint: 'e.g. cpc',
        ),
        _textField(
          controller: _utmCampaignController,
          label: 'UTM Campaign',
          hint: 'e.g. summer_launch',
        ),
        _textField(
          controller: _integrationRefController,
          label: 'Integration Ref',
          hint: 'External reference id',
        ),
      ],
    );
  }

  // ── Cancel / Save bar ────────────────────────────────────────────────────────
  Widget _buildActionBar() {
    final isSaving = ref.watch(editLeadFormProvider.select((s) => s.isSaving));
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.8)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: isSaving ? null : () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Save Changes',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Save ─────────────────────────────────────────────────────────────────────

  /// Validates, saves via `PUT /leads/{id}`, then reflects the change on the
  /// detail screen and in the leads list before popping.
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      // The invalid field may be scrolled out of view, so say what happened.
      _showSnack('Please fix the highlighted fields', isError: true);
      return;
    }

    String text(TextEditingController c) => c.text.trim();

    final result = await _form.submit(
      widget.lead.id,
      EditLeadText(
        title: text(_titleController),
        firstName: text(_firstNameController),
        lastName: text(_lastNameController),
        interestedIn: text(_interestedInController),
        description: text(_descriptionController),
        phone: text(_phoneController),
        alternatePhone: text(_altPhoneController),
        email: text(_emailController),
        company: text(_companyController),
        designation: text(_designationController),
        website: text(_websiteController),
        address: text(_addressController),
        city: text(_cityController),
        state: text(_stateController),
        pincode: text(_pincodeController),
        country: text(_countryController),
        utmSource: text(_utmSourceController),
        utmMedium: text(_utmMediumController),
        utmCampaign: text(_utmCampaignController),
        integrationRef: text(_integrationRefController),
      ),
    );
    if (!mounted) return;

    switch (result) {
      case Failure(:final error):
        _showSnack(error.message, isError: true);
      case Success():
        _applyLocally();
        // Pull the server-authoritative record and a fresh timeline (the save
        // adds an `updated` activity).
        ref.invalidate(leadFullProvider(widget.lead.id));
        ref.invalidate(leadDetailProvider(widget.lead.id));
        context.pop(true);
    }
  }

  /// Rebuilds the lead from the form and pushes it into the detail screen's
  /// held copy and the leads list, so both show the edit immediately rather
  /// than waiting on a refetch.
  void _applyLocally() {
    final form = ref.read(editLeadFormProvider);
    String? orNull(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    // Resolve the picked ids back to their labels from the loaded option lists,
    // falling back to the lead's existing label when a list has not loaded.
    final statuses = ref.read(leadStatusesProvider).asData?.value ?? const [];
    final sources = ref.read(leadSourcesProvider).asData?.value ?? const [];
    final types = ref.read(leadTypesProvider).asData?.value ?? const [];
    final territories = ref.read(territoriesProvider).asData?.value ?? const [];
    final branches =
        ref.read(branchesProvider(form.territoryId)).asData?.value ?? const [];

    final updated = widget.lead.copyWithEdit(
      title: _titleController.text.trim(),
      firstName: orNull(_firstNameController),
      lastName: orNull(_lastNameController),
      interestedIn: orNull(_interestedInController),
      description: orNull(_descriptionController),
      phone: orNull(_phoneController),
      alternatePhone: orNull(_altPhoneController),
      email: orNull(_emailController),
      companyName: orNull(_companyController),
      designation: orNull(_designationController),
      website: orNull(_websiteController),
      address: orNull(_addressController),
      city: orNull(_cityController),
      stateName: orNull(_stateController),
      pincode: orNull(_pincodeController),
      country: orNull(_countryController),
      priority: form.priority,
      statusName: _nameIn(
          [for (final s in statuses) (id: s.id, name: s.name)], form.statusId),
      statusId: form.statusId,
      leadSourceName: _nameIn(
          [for (final s in sources) (id: s.id, name: s.label)],
          form.leadSourceId),
      leadSourceId: form.leadSourceId,
      leadTypeId: form.leadTypeId,
      leadTypeName: _nameIn(
              [for (final t in types) (id: t.id, name: t.name)],
              form.leadTypeId) ??
          widget.lead.leadTypeName,
      territoryId: form.territoryId,
      territoryName: _nameIn(
              [for (final t in territories) (id: t.id, name: t.name)],
              form.territoryId) ??
          widget.lead.territoryName,
      branchId: form.branchId,
      branchName: _nameIn(
              [for (final b in branches) (id: b.id, name: b.name)],
              form.branchId) ??
          widget.lead.branchName,
      utmSource: orNull(_utmSourceController),
      utmMedium: orNull(_utmMediumController),
      utmCampaign: orNull(_utmCampaignController),
      integrationRef: orNull(_integrationRefController),
    );

    ref.read(leadViewProvider(widget.lead.id).notifier).applyEdit(updated);
    ref.read(leadsListProvider.notifier).replaceLead(updated);
  }

  /// The display name of the option matching [id], or null when nothing is
  /// selected or the list holds no such option.
  String? _nameIn(List<_Option> options, int? id) {
    if (id == null) return null;
    for (final o in options) {
      if (o.id == id) return o.name;
    }
    return null;
  }

  // ── Shared field builders ────────────────────────────────────────────────────

  TextStyle get _valueStyle => GoogleFonts.poppins(
        fontSize: 13.5,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      );

  InputDecoration _inputDecoration({String? hint}) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
      filled: true,
      fillColor: AppColors.background,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: border(AppColors.divider, 0.8),
      border: border(AppColors.divider, 0.8),
      focusedBorder: border(AppColors.primary, 1.4),
      errorBorder: border(AppColors.red, 0.8),
      focusedErrorBorder: border(AppColors.red, 1.4),
      errorStyle: GoogleFonts.poppins(fontSize: 11, color: AppColors.red),
    );
  }

  /// A labelled slot in a section. [required] adds the red asterisk.
  Widget _fieldWrapper({
    required String label,
    required Widget child,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: RichText(
              text: TextSpan(
                text: label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                children: required
                    ? [
                        TextSpan(
                          text: ' *',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.red,
                          ),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
    bool capitalizeWords = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return _fieldWrapper(
      label: label,
      required: required,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType ??
            (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
        textInputAction:
            maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
        textCapitalization: capitalizeWords
            ? TextCapitalization.words
            : TextCapitalization.none,
        inputFormatters: inputFormatters,
        style: _valueStyle,
        cursorColor: AppColors.primary,
        decoration: _inputDecoration(hint: hint),
        validator: validator ??
            (required
                ? (v) => (v?.trim().isEmpty ?? true)
                    ? '$label is required'
                    : null
                : null),
      ),
    );
  }

  /// A dropdown backed by an id-based lookup list. Shows a disabled placeholder
  /// while the options load or if they fail, and keeps a stand-in item for a
  /// value that is not in the list — `DropdownButtonFormField` asserts unless
  /// exactly one item matches the current value.
  Widget _idDropdown({
    required String label,
    required AsyncValue<List<_Option>> options,
    required int? selected,
    required String? fallbackLabel,
    required ValueChanged<int?> onChanged,
  }) {
    return _fieldWrapper(
      label: label,
      child: options.when(
        loading: () => _dropdownPlaceholder('Loading…'),
        error: (_, _) => _dropdownPlaceholder('Could not load $label'),
        data: (list) {
          final ids = <int>{};
          final items = <DropdownMenuItem<int?>>[
            DropdownMenuItem<int?>(
              value: null,
              child: Text('Not set',
                  style: GoogleFonts.poppins(
                      fontSize: 13.5, color: AppColors.textLight)),
            ),
            for (final o in list)
              if (ids.add(o.id))
                DropdownMenuItem<int?>(
                  value: o.id,
                  child: Text(o.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _valueStyle),
                ),
          ];
          // The lead may reference an option the list does not contain (e.g. an
          // inactive one, which the repository filters out).
          if (selected != null && !ids.contains(selected)) {
            items.add(DropdownMenuItem<int?>(
              value: selected,
              child: Text(fallbackLabel ?? '$label #$selected',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _valueStyle),
            ));
          }
          return DropdownButtonFormField<int?>(
            initialValue: selected,
            isExpanded: true,
            decoration: _inputDecoration(hint: 'Select ${label.toLowerCase()}'),
            style: _valueStyle,
            dropdownColor: AppColors.cardBackground,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary),
            items: items,
            onChanged: onChanged,
          );
        },
      ),
    );
  }

  Widget _dropdownPlaceholder(String message) {
    return Container(
      height: 45,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Text(
        message,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
      ),
    );
  }

  /// A titled card grouping one set of fields.
  Widget _section({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 2),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
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

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: isError ? AppColors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
