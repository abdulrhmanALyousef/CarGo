import 'dart:io';
import 'package:cargo/Features/auth/controllers/onboarding_controller.dart';
import 'package:cargo/Features/auth/email_otp_screen.dart';
import 'package:cargo/Features/auth/signup_widgets.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/core/widgets/app_button.dart';
import 'package:cargo/core/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignupStep2Screen extends StatefulWidget {
  const SignupStep2Screen({super.key});

  @override
  State<SignupStep2Screen> createState() => _SignupStep2ScreenState();
}

class _SignupStep2ScreenState extends State<SignupStep2Screen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<OnboardingController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const StepAppBar(step: 2, total: 2),
      body: SafeArea(
        child: Column(
          children: [
            const StepProgressBar(step: 2, total: 2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RoleBadge(role: ctrl.role),
                      const SizedBox(height: 20),
                      const Text(
                        'Verify Identity',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: LightColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ctrl.isRenter
                            ? 'Required for renting vehicles safely'
                            : 'Required to list your vehicles',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // National ID
                      CustomTextFormField(
                        controller: ctrl.nationalIdController,
                        title: 'National ID Number',
                        hintText: '1122334455',
                        validator: ctrl.validateNationalId,
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          color: LightColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Driving License — required for renters, optional for owners
                      _LicenseUploadSection(ctrl: ctrl),
                      const SizedBox(height: 28),

                      // Terms & Conditions
                      _TermsCheckbox(ctrl: ctrl),
                      const SizedBox(height: 32),

                      // Submit button
                      AppButton(
                        text: 'Create Account',
                        isLoading: ctrl.isLoading,
                        onTap: ctrl.isLoading
                            ? null
                            : () => _submit(context, ctrl),
                        icon: ctrl.isLoading
                            ? null
                            : const Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context, OnboardingController ctrl) {
    ctrl.proceedFromStep2(
      context,
      _formKey,
      () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmailOtpScreen(
              email: ctrl.emailController.text.trim(),
              password: ctrl.passwordController.text.trim(),
              fullName: ctrl.fullNameController.text.trim(),
              phone: ctrl.phoneController.text.trim(),
              nationalId: ctrl.nationalIdController.text.trim(),
              licenseFile: ctrl.licenseFile,
              role: ctrl.role,
            ),
          ),
        );
      },
    );
  }
}

// ── License Upload ────────────────────────────────────────────────────────────

class _LicenseUploadSection extends StatelessWidget {
  const _LicenseUploadSection({required this.ctrl});
  final OnboardingController ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Driving License',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ctrl.isRenter
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                ctrl.isRenter ? 'Required' : 'Optional',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ctrl.isRenter ? Colors.red : Colors.orange,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (ctrl.isOwner) ...[
          Text(
            'You can upload this later before publishing your first car.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
        ],
        GestureDetector(
          onTap: ctrl.pickDrivingLicense,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 130,
            decoration: BoxDecoration(
              color: ctrl.hasDrivingLicense
                  ? Colors.transparent
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ctrl.hasDrivingLicense
                    ? LightColors.primaryColor
                    : const Color(0xFFDDDDDD),
                width: ctrl.hasDrivingLicense ? 2 : 1.5,
              ),
            ),
            child: ctrl.hasDrivingLicense
                ? _LicensePreview(file: ctrl.licenseFile!, onRemove: ctrl.clearDrivingLicense)
                : _LicenseUploadPrompt(),
          ),
        ),
      ],
    );
  }
}

class _LicensePreview extends StatelessWidget {
  const _LicensePreview({required this.file, required this.onRemove});
  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            file,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Tap to change',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LicenseUploadPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 36,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to upload license image',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'JPG or PNG',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}

// ── Terms Checkbox ────────────────────────────────────────────────────────────

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.ctrl});
  final OnboardingController ctrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: ctrl.acceptedTerms,
            onChanged: ctrl.toggleTerms,
            activeColor: LightColors.primaryColor,
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            side: const BorderSide(
                color: LightColors.primaryColor, width: 2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: 'By creating an account, you agree to our ',
              style: TextStyle(
                color: LightColors.textColor.withValues(alpha: 0.65),
                fontSize: 13,
                height: 1.5,
              ),
              children: const [
                TextSpan(
                  text: 'Terms and Conditions',
                  style: TextStyle(
                    color: LightColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: LightColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
