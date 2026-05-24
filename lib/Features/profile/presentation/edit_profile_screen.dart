import 'package:cached_network_image/cached_network_image.dart';
import 'package:cargo/Features/profile/controllers/profile_controller.dart';
import 'package:cargo/core/constants/app_size.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/core/widgets/app_button.dart';
import 'package:cargo/core/widgets/custom_text_formField.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  static const _phonePrefix = '+966';

  @override
  void initState() {
    super.initState();
    final ctrl = context.read<ProfileController>();
    _nameController = TextEditingController(text: ctrl.fullName);
    _phoneController = TextEditingController(
      text: ctrl.phone.isNotEmpty ? ctrl.phone : _phonePrefix,
    );
    _phoneController.addListener(_guardPhonePrefix);
  }

  void _guardPhonePrefix() {
    if (!_phoneController.text.startsWith(_phonePrefix)) {
      final digits =
          _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final restored = _phonePrefix + digits;
      _phoneController.value = TextEditingValue(
        text: restored,
        selection: TextSelection.collapsed(offset: restored.length),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.removeListener(_guardPhonePrefix);
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ProfileController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.pw16,
          vertical: AppSizes.ph24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar picker
              Center(
                child: GestureDetector(
                  onTap: ctrl.pickProfileImage,
                  child: Stack(
                    children: [
                      _EditAvatar(ctrl: ctrl),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: LightColors.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSizes.ph8),
              Text(
                'Tap to change photo',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: AppSizes.ph30),

              // Full name field
              CustomTextFormField(
                controller: _nameController,
                title: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: const Icon(
                  Icons.person_outline_rounded,
                  color: LightColors.primaryColor,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  if (v.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSizes.ph16),

              // Phone field
              CustomTextFormField(
                controller: _phoneController,
                title: 'Phone Number',
                hintText: '+966 5XXXXXXXX',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(
                  Icons.phone_outlined,
                  color: LightColors.primaryColor,
                ),
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val == _phonePrefix || val.length <= _phonePrefix.length) {
                    return 'Please enter your phone number';
                  }
                  final digits = val.substring(_phonePrefix.length);
                  if (!RegExp(r'^5[0-9]{8}$').hasMatch(digits)) {
                    return 'Enter a valid Saudi number (9 digits starting with 5)';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSizes.ph8),

              // Email (read-only)
              _ReadOnlyField(
                icon: Icons.email_outlined,
                label: 'Email',
                value: ctrl.email,
                note: 'Email cannot be changed',
              ),
              SizedBox(height: AppSizes.ph30),

              // Save button
              AppButton(
                text: 'Save Changes',
                isLoading: ctrl.isSaving,
                onTap: ctrl.isSaving ? null : () => _save(context, ctrl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, ProfileController ctrl) async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ctrl.saveProfile(
      context: context,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    if (success && context.mounted) {
      Navigator.pop(context);
    }
  }
}

// ── Edit Avatar ───────────────────────────────────────────────────────────────

class _EditAvatar extends StatelessWidget {
  const _EditAvatar({required this.ctrl});
  final ProfileController ctrl;

  @override
  Widget build(BuildContext context) {
    const double size = 96;

    Widget? content;
    if (ctrl.pendingProfileImage != null) {
      content = ClipOval(
        child: Image.file(
          ctrl.pendingProfileImage!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else if (ctrl.profileImageUrl.isNotEmpty) {
      content = ClipOval(
        child: CachedNetworkImage(
          imageUrl: ctrl.profileImageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => const Icon(
            Icons.person_rounded,
            size: size * 0.55,
            color: LightColors.primaryColor,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: LightColors.primaryColor.withValues(alpha: 0.1),
        border: Border.all(
          color: LightColors.primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: content ??
          const Icon(
            Icons.person_rounded,
            size: size * 0.55,
            color: LightColors.primaryColor,
          ),
    );
  }
}

// ── Read-Only Field ───────────────────────────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.icon,
    required this.label,
    required this.value,
    this.note,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.pw16,
        vertical: AppSizes.ph16,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          SizedBox(width: AppSizes.pw12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppSizes.sp14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    note!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
