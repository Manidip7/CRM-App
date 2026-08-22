import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';
import '../../Leads/provider/assign_providers.dart';
import '../../customers/model/customer_list_item.dart';
import '../../customers/provider/customers_api_provider.dart';
import '../model/project_model.dart';
import '../provider/projects_provider.dart';

/// Form to create — or, when [project] is given, edit — a project. All state
/// (dropdowns, dates, member chips and tags) is held in [projectDraftProvider]
/// so the screen needs no [setState].
class CreateProjectScreen extends ConsumerStatefulWidget {
  /// The project being edited, or null for a brand-new project.
  final ProjectModel? project;

  const CreateProjectScreen({super.key, this.project});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _name = TextEditingController();
  final _totalRate = TextEditingController();
  final _estimatedHours = TextEditingController();
  final _tag = TextEditingController();
  final _description = TextEditingController();

  bool get _isEdit => widget.project != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final project = widget.project;
      if (project != null) {
        // Edit: prefill the draft and the text controllers from the project.
        ref.read(projectDraftProvider.notifier).seed(project);
        _name.text = project.name;
        _totalRate.text =
            project.totalRate > 0 ? project.totalRate.round().toString() : '';
        _estimatedHours.text = project.estimatedHours > 0
            ? project.estimatedHours.round().toString()
            : '';
        _description.text = project.description;
      } else {
        // New: reset the draft so a previous, abandoned form never leaks in.
        ref.read(projectDraftProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _totalRate.dispose();
    _estimatedHours.dispose();
    _tag.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  _sectionLabel('Project Details'),
                  _nameField(),
                  _customerField(),
                  _billingTypeField(),
                  _statusField(),
                  Row(
                    children: [
                      Expanded(child: _totalRateField()),
                      const SizedBox(width: 12),
                      Expanded(child: _estimatedHoursField()),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _startDateField()),
                      const SizedBox(width: 12),
                      Expanded(child: _deadlineField()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _sectionLabel('Members'),
                  _membersField(),
                  const SizedBox(height: 16),
                  _sectionLabel('Tags'),
                  _tagsField(),
                  const SizedBox(height: 16),
                  _sectionLabel('Description'),
                  _descriptionField(),
                  const SizedBox(height: 20),
                  _actionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ──
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 20, color: AppColors.textPrimary),
            ),
          ),
          Text(
            _isEdit ? 'Edit Project' : 'New Project',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ── Fields ──
  Widget _nameField() {
    return _labeledField(
      'Project Name',
      required: true,
      TextField(
        controller: _name,
        onChanged: (v) => ref.read(projectDraftProvider.notifier).setName(v),
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: _inputDecoration('e.g. CRM Platform Revamp'),
      ),
    );
  }

  Widget _customerField() {
    final customersAsync = ref.watch(customerOptionsProvider);
    final customers = customersAsync.asData?.value ?? const <CustomerListItem>[];
    final selectedId =
        ref.watch(projectDraftProvider.select((d) => d.customerId));
    // Guard the dropdown's value: it must match exactly one item (or be null),
    // so drop a stale selection that isn't in the loaded options.
    final value = customers.any((c) => c.id == selectedId) ? selectedId : null;
    return _labeledField(
      'Customer',
      required: true,
      _dropdownShell(
        DropdownButton<int>(
          value: value,
          isExpanded: true,
          hint: Text(
            customersAsync.isLoading
                ? 'Loading customers…'
                : customersAsync.hasError
                    ? 'Could not load customers'
                    : 'Select customer',
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textLight),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          items: customers
              .map((c) => DropdownMenuItem<int>(
                    value: c.id,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (id) {
            CustomerListItem? picked;
            for (final c in customers) {
              if (c.id == id) {
                picked = c;
                break;
              }
            }
            ref
                .read(projectDraftProvider.notifier)
                .setCustomer(picked?.id, picked?.name);
          },
        ),
      ),
    );
  }

  Widget _billingTypeField() {
    final billing =
        ref.watch(projectDraftProvider.select((d) => d.billingType));
    return _labeledField(
      'Billing Type',
      required: true,
      _dropdownShell(
        DropdownButton<BillingType>(
          value: billing,
          isExpanded: true,
          hint: Text(
            'Select billing type',
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textLight),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          items: BillingType.values
              .map((b) => DropdownMenuItem<BillingType>(
                    value: b,
                    child: Text(b.label),
                  ))
              .toList(),
          onChanged: (b) {
            if (b != null) {
              ref.read(projectDraftProvider.notifier).setBillingType(b);
            }
          },
        ),
      ),
    );
  }

  Widget _statusField() {
    final status = ref.watch(projectDraftProvider.select((d) => d.status));
    return _labeledField(
      'Status',
      _dropdownShell(
        DropdownButton<ProjectStatus>(
          value: status,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          items: ProjectStatus.values
              .map((s) => DropdownMenuItem<ProjectStatus>(
                    value: s,
                    child: Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                              color: s.color, shape: BoxShape.circle),
                        ),
                        Text(s.label),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (s) {
            if (s != null) {
              ref.read(projectDraftProvider.notifier).setStatus(s);
            }
          },
        ),
      ),
    );
  }

  Widget _totalRateField() {
    return _labeledField(
      'Total Rate',
      TextField(
        controller: _totalRate,
        keyboardType: TextInputType.number,
        // Numbers only — digits, no decimal point or other characters.
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) => ref
            .read(projectDraftProvider.notifier)
            .setTotalRate(int.tryParse(v) ?? 0),
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: _inputDecoration('₹ 0'),
      ),
    );
  }

  Widget _estimatedHoursField() {
    return _labeledField(
      'Estimated Hours',
      TextField(
        controller: _estimatedHours,
        keyboardType: TextInputType.number,
        // Whole hours only, matching the API's integer `estimated_hours`.
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (v) => ref
            .read(projectDraftProvider.notifier)
            .setEstimatedHours(int.tryParse(v) ?? 0),
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: _inputDecoration('0'),
      ),
    );
  }

  Widget _startDateField() {
    final date = ref.watch(projectDraftProvider.select((d) => d.startDate));
    return _labeledField(
      'Start Date',
      required: true,
      _dateShell(
        date,
        'Select date',
        () => _pickDate(
          initial: ref.read(projectDraftProvider).startDate,
          onPicked: (d) =>
              ref.read(projectDraftProvider.notifier).setStartDate(d),
        ),
      ),
    );
  }

  Widget _deadlineField() {
    final date = ref.watch(projectDraftProvider.select((d) => d.deadline));
    return _labeledField(
      'Deadline',
      _dateShell(
        date,
        'Select date',
        () => _pickDate(
          initial: ref.read(projectDraftProvider).deadline ??
              DateTime.now().add(const Duration(days: 30)),
          onPicked: (d) =>
              ref.read(projectDraftProvider.notifier).setDeadline(d),
        ),
      ),
    );
  }

  Widget _dateShell(DateTime? date, String hint, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                date == null ? hint : _shortDate(date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color:
                      date == null ? AppColors.textLight : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({
    required DateTime? initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  // ── Members multi-select dropdown (API-backed: GET /users) ──
  Widget _membersField() {
    final usersAsync = ref.watch(assignableUsersProvider);
    return usersAsync.when(
      loading: () => _dropdownLikeBox(
        const Row(
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            SizedBox(width: 10),
            Text('Loading members…',
                style: TextStyle(fontSize: 14, color: AppColors.textLight)),
          ],
        ),
      ),
      error: (e, _) => GestureDetector(
        onTap: () => ref.invalidate(assignableUsersProvider),
        child: _dropdownLikeBox(
          Row(
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Could not load members. Tap to retry.',
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
      data: (users) {
        final selectedIds =
            ref.watch(projectDraftProvider.select((d) => d.memberIds));
        final count = selectedIds.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown-style trigger — opens the checkable members menu.
            GestureDetector(
              onTap: users.isEmpty ? null : () => _openMembersMenu(users),
              child: _dropdownLikeBox(
                Row(
                  children: [
                    const Icon(Icons.group_outlined,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        users.isEmpty
                            ? 'No members available'
                            : count == 0
                                ? 'Select members'
                                : '$count member${count == 1 ? '' : 's'} selected',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: count == 0
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            // Selected members shown as removable chips (name looked up by id).
            if (count > 0) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedIds.map((id) {
                  String name = '#$id';
                  for (final u in users) {
                    if (u.id == id) {
                      name = u.name;
                      break;
                    }
                  }
                  return Container(
                    padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => ref
                              .read(projectDraftProvider.notifier)
                              .toggleMember(id),
                          child: const Icon(Icons.close_rounded,
                              size: 15, color: AppColors.primary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        );
      },
    );
  }

  /// The dropdown-style container shared by the members trigger's states.
  Widget _dropdownLikeBox(Widget child) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }

  /// Opens the multi-select members menu as a bottom sheet. Rows toggle the
  /// draft directly, so the sheet stays open while several members are picked.
  Future<void> _openMembersMenu(List<dynamic> users) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  'Select Members',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Done',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Consumer(
                builder: (ctx, r, __) {
                  final selected =
                      r.watch(projectDraftProvider.select((d) => d.memberIds));
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: users.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (_, i) {
                      final u = users[i];
                      final id = u.id as int;
                      final name = u.name as String;
                      final isSelected = selected.contains(id);
                      final designation = u.designation as String?;
                      return InkWell(
                        onTap: () => r
                            .read(projectDraftProvider.notifier)
                            .toggleMember(id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_box_rounded
                                    : Icons.check_box_outline_blank_rounded,
                                size: 20,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (designation != null &&
                                        designation.trim().isNotEmpty)
                                      Text(
                                        designation,
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
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tags ──
  Widget _tagsField() {
    final tags = ref.watch(projectDraftProvider.select((d) => d.tags));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tag,
                onSubmitted: (_) => _submitTag(),
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textPrimary),
                decoration: _inputDecoration('Add a tag and press +'),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _submitTag,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map((t) => Container(
                      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => ref
                                .read(projectDraftProvider.notifier)
                                .removeTag(t),
                            child: const Icon(Icons.close_rounded,
                                size: 15, color: AppColors.accent),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  void _submitTag() {
    ref.read(projectDraftProvider.notifier).addTag(_tag.text);
    _tag.clear();
  }

  Widget _descriptionField() {
    return TextField(
      controller: _description,
      maxLines: 4,
      onChanged: (v) =>
          ref.read(projectDraftProvider.notifier).setDescription(v),
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: _inputDecoration('Describe the project scope...'),
    );
  }

  // ── Cancel / Save ──
  Widget _actionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.maybePop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 50,
            child: Consumer(
              builder: (context, ref, _) {
                final saving =
                    ref.watch(projectDraftProvider.select((d) => d.saving));
                return ElevatedButton(
                  onPressed: saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: Colors.white),
                        )
                      : Text(
                          _isEdit ? 'Update Project' : 'Save Project',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final notifier = ref.read(projectDraftProvider.notifier);
    final draft = ref.read(projectDraftProvider);
    final name = draft.name.trim();

    // Name, customer, billing type and start date are all mandatory; the first
    // missing one is reported.
    final invalid = draft.validationError;
    if (invalid != null) {
      _toast(invalid);
      return;
    }

    notifier.setSaving(true);
    // Edit → PUT /projects/{id}; new → POST /projects. Either reloads the list.
    final projectsNotifier = ref.read(projectsProvider.notifier);
    final error = _isEdit
        ? await projectsNotifier.updateProject(widget.project!.id, draft)
        : await projectsNotifier.createProject(draft);
    if (!mounted) return;
    notifier.setSaving(false);

    if (error != null) {
      _toast(error);
      return;
    }
    Navigator.maybePop(context);
    _toast(_isEdit ? '$name updated' : '$name created');
  }

  // ── Shared field helpers ──
  /// [required] appends a red asterisk to the label. The four mandatory fields
  /// (name, customer, billing type, start date) are the ones marked; the actual
  /// check lives in [ProjectDraft.validationError] so the form and the toast
  /// can't drift apart.
  Widget _labeledField(String label, Widget child, {bool required = false}) {
    final labelStyle = GoogleFonts.poppins(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text.rich(
              TextSpan(
                text: label,
                style: labelStyle,
                children: required
                    ? [
                        TextSpan(
                          text: ' *',
                          style: labelStyle.copyWith(color: AppColors.red),
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

  Widget _dropdownShell(Widget dropdown) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(child: dropdown),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textLight, fontSize: 13.5),
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: _border(AppColors.divider),
        enabledBorder: _border(AppColors.divider),
        focusedBorder: _border(AppColors.primary),
      );

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontSize: 13, color: Colors.white)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
