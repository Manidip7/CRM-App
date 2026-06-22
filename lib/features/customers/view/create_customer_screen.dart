import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/AppColors.dart';
import '../model/customer_model.dart';
import '../provider/customers_provider.dart';

/// Form to create a new customer. The status dropdown is backed by
/// [customerDraftStatusProvider] (Riverpod) so the screen needs no [setState].
class CreateCustomerScreen extends ConsumerStatefulWidget {
  const CreateCustomerScreen({super.key});

  @override
  ConsumerState<CreateCustomerScreen> createState() =>
      _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends ConsumerState<CreateCustomerScreen> {
  final _name = TextEditingController();
  final _company = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postalCode = TextEditingController();
  final _country = TextEditingController(text: 'India');
  final _value = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reset the dropdown to its default each time the form opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerDraftStatusProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _email.dispose();
    _phone.dispose();
    _street.dispose();
    _city.dispose();
    _state.dispose();
    _postalCode.dispose();
    _country.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(customerDraftStatusProvider);
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
                  _sectionLabel('Profile'),
                  _field('Name', _name, hint: 'Full name'),
                  _field('Company', _company, hint: 'Company name'),
                  _field('Email', _email,
                      hint: 'name@company.com',
                      keyboardType: TextInputType.emailAddress),
                  _field('Phone', _phone,
                      hint: '+91 90000 00000',
                      keyboardType: TextInputType.phone),
                  _statusField(status),
                  _field('Total Value', _value,
                      hint: 'e.g. 50000',
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 8),
                  _sectionLabel('Address Details'),
                  _field('Street', _street, hint: 'Street / building'),
                  _field('City', _city, hint: 'City'),
                  _field('State', _state, hint: 'State'),
                  _field('Postal Code', _postalCode,
                      hint: 'PIN code',
                      keyboardType: TextInputType.number),
                  _field('Country', _country, hint: 'Country'),
                  const SizedBox(height: 20),
                  _saveButton(),
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
            'Create Customer',
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

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
  }) {
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
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
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
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  Widget _statusField(CustomerStatus status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Status',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CustomerStatus>(
                value: status,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary),
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textPrimary),
                items: CustomerStatus.values
                    .map((s) => DropdownMenuItem<CustomerStatus>(
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
                    ref.read(customerDraftStatusProvider.notifier).set(s);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
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
          'Create Customer',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _toast('Name is required');
      return;
    }

    final city = _city.text.trim();
    final customer = CustomerModel(
      id: 'CUST-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      company: _company.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      location: city.isNotEmpty ? city : _state.text.trim(),
      status: ref.read(customerDraftStatusProvider),
      totalValue: double.tryParse(_value.text.trim()) ?? 0,
      street: _street.text.trim(),
      city: city,
      state: _state.text.trim(),
      postalCode: _postalCode.text.trim(),
      country: _country.text.trim(),
      createdAt: DateTime.now(),
      createdBy: 'Admin Owner',
    );

    ref.read(customersProvider.notifier).add(customer);
    context.pop();
    _toast('${customer.name} created');
  }

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
}
