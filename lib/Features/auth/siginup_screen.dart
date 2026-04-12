import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/core/widgets/custom_text_formField.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/Features/auth/controllers/signup_controller.dart';
import 'package:cargo/Features/auth/login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Stable key — not recreated on every rebuild
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignUpController(),
      child: Consumer<SignUpController>(
        builder: (context, ctrl, _) => Scaffold(
          backgroundColor: LightColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: LightColors.backgroundColor,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF9E9E9E),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: LightColors.textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            title: Text(
              'Create an Account',
              style: TextStyle(
                color: LightColors.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create an Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: LightColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join us today and unlock endless possibilities.\nIt\'s quick, easy, and just a step away!',
                      style: TextStyle(
                        fontSize: 14,
                        color: LightColors.textColor.withOpacity(0.54),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ─── Full Name ───────────────────────────────────────
                    CustomTextFormField(
                      controller: ctrl.fullNameController,
                      title: 'Full Name',
                      hintText: 'Mohammed Bassam',
                      validator: ctrl.validateFullName,
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 16),

                    // ─── Email ───────────────────────────────────────────
                    CustomTextFormField(
                      controller: ctrl.emailController,
                      title: 'Email',
                      hintText: 'Mo@email.com',
                      validator: ctrl.validateEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // ─── Phone Number (always starts with +966) ──────────
                    _PhoneField(ctrl: ctrl),
                    const SizedBox(height: 16),

                    // ─── National ID ─────────────────────────────────────
                    CustomTextFormField(
                      controller: ctrl.nationalIdController,
                      title: 'National ID Number',
                      hintText: '1122334455',
                      validator: ctrl.validateNationalId,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // ─── Password ────────────────────────────────────────
                    CustomTextFormField(
                      controller: ctrl.passwordController,
                      title: 'Password',
                      hintText: '••••••••••••',
                      validator: ctrl.validatePassword,
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),

                    // ─── Confirm Password ────────────────────────────────
                    CustomTextFormField(
                      controller: ctrl.confirmPasswordController,
                      title: 'Confirm Password',
                      hintText: '••••••••••••',
                      validator: ctrl.validateConfirmPassword,
                      obscureText: true,
                    ),
                    const SizedBox(height: 25),

                    // ─── Driving License Upload ──────────────────────────
                    Text(
                      'Add your Driving License',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: LightColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: ctrl.pickDrivingLicense,
                      child: Container(
                        width: double.infinity,
                        height: 130,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ctrl.hasDrivingLicense
                                ? LightColors.primaryColor
                                : const Color(0xFFBDBDBD),
                            width: ctrl.hasDrivingLicense ? 2 : 1,
                          ),
                        ),
                        child: ctrl.hasDrivingLicense
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(
                                      ctrl.licenseFile!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: GestureDetector(
                                      onTap: ctrl.clearDrivingLicense,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 36,
                                    color:
                                        LightColors.textColor.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to upload',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: LightColors.textColor
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── Terms & Conditions ──────────────────────────────
                    Row(
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
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: BorderSide(
                              color: LightColors.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text:
                                  'By creating an account, you agree to our ',
                              style: TextStyle(
                                color: LightColors.textColor.withOpacity(0.7),
                                fontSize: 13,
                                height: 1.4,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms and Conditions',
                                  style: TextStyle(
                                    color: LightColors.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Notice',
                                  style: TextStyle(
                                    color: LightColors.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // ─── Sign Up Button ──────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: ctrl.isLoading
                            ? null
                            : () => ctrl.handleSignUp(context, _formKey),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LightColors.primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              LightColors.primaryColor.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: ctrl.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: LightColors.textColor.withOpacity(0.54),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            ),
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: LightColors.primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Phone field with locked +966 prefix ───────────────────────────────────────

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.ctrl});

  final SignUpController ctrl;

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
          style: const TextStyle(fontSize: 14, color: Color(0xFF222222)),
          decoration: InputDecoration(
            hintText: '+966 5X XXX XXXX',
            hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF2F2F2),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0xFFDDDDDD), width: 1),
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
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF222222), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}