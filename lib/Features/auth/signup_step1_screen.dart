import 'package:cargo/Features/auth/controllers/onboarding_controller.dart';
import 'package:cargo/Features/auth/signup_step2_screen.dart';
import 'package:cargo/Features/auth/signup_widgets.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/core/widgets/app_button.dart';
import 'package:cargo/core/widgets/custom_text_formField.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SignupStep1Screen extends StatefulWidget {
  const SignupStep1Screen({super.key});

  @override
  State<SignupStep1Screen> createState() => _SignupStep1ScreenState();
}

class _SignupStep1ScreenState extends State<SignupStep1Screen> {
  final _formKey = GlobalKey<FormState>();

  void _continue(OnboardingController ctrl) {
    if (!_formKey.currentState!.validate()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: ctrl,
          child: const SignupStep2Screen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<OnboardingController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: StepAppBar(step: 1, total: 2),
      body: SafeArea(
        child: Column(
          children: [
            StepProgressBar(step: 1, total: 2),
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
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: LightColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tell us a little about yourself',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Full Name
                      CustomTextFormField(
                        controller: ctrl.fullNameController,
                        title: 'Full Name',
                        hintText: 'Mohammed Al-Rashidi',
                        validator: ctrl.validateFullName,
                        keyboardType: TextInputType.name,
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: LightColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email
                      CustomTextFormField(
                        controller: ctrl.emailController,
                        title: 'Email',
                        hintText: 'name@example.com',
                        validator: ctrl.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: LightColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      _PhoneField(ctrl: ctrl),
                      const SizedBox(height: 16),

                      // Password
                      CustomTextFormField(
                        controller: ctrl.passwordController,
                        title: 'Password',
                        hintText: '••••••••••••',
                        validator: ctrl.validatePassword,
                        obscureText: true,
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: LightColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      CustomTextFormField(
                        controller: ctrl.confirmPasswordController,
                        title: 'Confirm Password',
                        hintText: '••••••••••••',
                        validator: ctrl.validateConfirmPassword,
                        obscureText: true,
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: LightColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 32),

                      AppButton(
                        text: 'Continue',
                        onTap: () => _continue(ctrl),
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
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
}

// ── Phone field ───────────────────────────────────────────────────────────────

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.ctrl});
  final OnboardingController ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl.phoneController,
          keyboardType: TextInputType.phone,
          validator: ctrl.validatePhone,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[+0-9]'))],
          style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
          decoration: InputDecoration(
            hintText: '+966 5X XXX XXXX',
            hintStyle:
                const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF2F2F2),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                border: Border(
                  right:
                      BorderSide(color: Color(0xFFDDDDDD), width: 1),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🇸🇦', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 6),
                  Text(
                    '+966',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF222222),
                    ),
                  ),
                ],
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: LightColors.primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

