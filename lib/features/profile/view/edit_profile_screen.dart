import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_result.dart';
import '../../../core/utils/AppColors.dart';
import '../data/profile_repository.dart';
import '../provider/edit_profile_provider.dart';

/// Form to edit the current user's profile. Pre-filled from [profileProvider]
/// and submitted as multipart/form-data to `POST /my-profile`.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _city;

  /// Existing avatar URL to show when no new image is picked.
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    _name = TextEditingController(text: profile?.name ?? '');
    _phone = TextEditingController(text: profile?.phone ?? '');
    _address = TextEditingController(text: profile?.address ?? '');
    _city = TextEditingController(text: profile?.city ?? '');
    _currentAvatarUrl = profile?.avatar;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked != null) {
      ref.read(editProfileControllerProvider.notifier).pickAvatar(picked.path);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final result =
        await ref.read(editProfileControllerProvider.notifier).save(
              name: _name.text.trim(),
              phone: _phone.text.trim(),
              address: _address.text.trim(),
              city: _city.text.trim(),
            );

    if (!mounted) return;

    switch (result) {
      case Success():
        _snack('Profile updated successfully.', AppColors.primary);
        Navigator.pop(context);
      case Failure(:final error):
        _snack(error.message, AppColors.red);
    }
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(child: _avatarPicker(state.avatarPath)),
              const SizedBox(height: 28),
              _field(_name, 'Name', Icons.person_outline,
                  validator: _required),
              const SizedBox(height: 16),
              _field(_phone, 'Phone', Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _field(_address, 'Address', Icons.location_on_outlined),
              const SizedBox(height: 16),
              _field(_city, 'City', Icons.location_city_outlined),
              const SizedBox(height: 32),
              _saveButton(state.isSaving),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarPicker(String? avatarPath) {
    final ImageProvider? image = avatarPath != null
        ? FileImage(File(avatarPath))
        : (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty
            ? NetworkImage(_currentAvatarUrl!)
            : null);

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryLight.withOpacity(0.2),
            image: image != null
                ? DecorationImage(image: image, fit: BoxFit.cover)
                : null,
            border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
          ),
          child: image == null
              ? const Icon(Icons.person, color: AppColors.primary, size: 44)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickAvatar,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _saveButton(bool saving) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                'Save Changes',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;
}
