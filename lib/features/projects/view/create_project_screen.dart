import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';
import '../../customers/provider/customers_provider.dart';
import '../model/project_model.dart';
import '../provider/projects_provider.dart';

/// Form to create a new project. All state (dropdowns, dates, member chips and
/// tags) is held in [projectDraftProvider] so the screen needs no [setState].
class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    // Reset the draft so a previous, abandoned form never leaks in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectDraftProvider.notifier).reset();
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
            'New Project',
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
      TextField(
        controller: _name,
        onChanged: (v) => ref.read(projectDraftProvider.notifier).setName(v),
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: _inputDecoration('e.g. CRM Platform Revamp'),
      ),
    );
  }

  Widget _customerField() {
    final customers = ref.watch(customersProvider);
    final selected =
        ref.watch(projectDraftProvider.select((d) => d.customer));
    return _labeledField(
      'Customer',
      _dropdownShell(
        DropdownButton<String>(
          value: selected,
          isExpanded: true,
          hint: Text('Select customer',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: AppColors.textLight)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          items: customers
              .map((c) => DropdownMenuItem<String>(
                    value: c.name,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) =>
              ref.read(projectDraftProvider.notifier).setCustomer(v),
        ),
      ),
    );
  }

  Widget _billingTypeField() {
    final billing =
        ref.watch(projectDraftProvider.select((d) => d.billingType));
    return _labeledField(
      'Billing Type',
      _dropdownShell(
        DropdownButton<BillingType>(
          value: billing,
          isExpanded: true,
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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [_decimalFormatter],
        onChanged: (v) => ref
            .read(projectDraftProvider.notifier)
            .setTotalRate(double.tryParse(v) ?? 0),
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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [_decimalFormatter],
        onChanged: (v) => ref
            .read(projectDraftProvider.notifier)
            .setEstimatedHours(double.tryParse(v) ?? 0),
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: _inputDecoration('0'),
      ),
    );
  }

  Widget _startDateField() {
    final date = ref.watch(projectDraftProvider.select((d) => d.startDate));
    return _labeledField(
      'Start Date',
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

  // ── Members multi-select ──
  Widget _membersField() {
    final all = ref.watch(projectMembersProvider);
    final selected = ref.watch(projectDraftProvider.select((d) => d.members));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: all.map((m) {
        final isSelected = selected.contains(m);
        return GestureDetector(
          onTap: () => ref.read(projectDraftProvider.notifier).toggleMember(m),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.12)
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.person_outline_rounded,
                  size: 15,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  m,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'Save Project',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _save() {
    final draft = ref.read(projectDraftProvider);
    final name = draft.name.trim();

    if (name.isEmpty) {
      _toast('Project name is required');
      return;
    }
    if (draft.customer == null || draft.customer!.trim().isEmpty) {
      _toast('Please select a customer');
      return;
    }

    final now = DateTime.now();
    final project = ProjectModel(
      id: suggestProjectId(ref.read(projectsProvider)),
      name: name,
      customer: draft.customer!.trim(),
      status: draft.status,
      members: draft.members,
      deadline: draft.deadline ?? now.add(const Duration(days: 30)),
      billingType: draft.billingType,
      totalRate: draft.totalRate,
      estimatedHours: draft.estimatedHours,
      startDate: draft.startDate,
      tags: draft.tags,
      description: draft.description.trim(),
    );

    ref.read(projectsProvider.notifier).upsert(project);
    Navigator.maybePop(context);
    _toast('${project.name} created');
  }

  // ── Shared field helpers ──
  Widget _labeledField(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
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

/// Only digits and a single decimal point.
final _decimalFormatter =
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'));
