import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/core/widgets/custom_text_formField.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/Features/auth/controllers/signup_controller.dart';
import 'package:cargo/Features/auth/login_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignUpController(),
      child: Builder(
        builder: (context) {
          final ctrl = context.watch<SignUpController>();
          final formKey = GlobalKey<FormState>();

          return Scaffold(
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
                'Sign Up',
                style: TextStyle(
                  color: LightColors.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: LightColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fill your details to continue',
                        style: TextStyle(
                          fontSize: 14,
                          color: LightColors.textColor.withOpacity(0.54),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ─── Full Name ─────────────────────────────────────
                      CustomTextFormField(
                        controller: ctrl.fullNameController,
                        title: 'Full Name',
                        hintText: 'Enter your full name',
                        validator: ctrl.validateFullName,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 16),

                      // ─── Email ─────────────────────────────────────────
                      CustomTextFormField(
                        controller: ctrl.emailController,
                        title: 'Email',
                        hintText: 'Enter your email',
                        validator: ctrl.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // ─── Phone Number ──────────────────────────────────
                      CustomTextFormField(
                        controller: ctrl.phoneController,
                        title: 'Phone Number',
                        hintText: 'Enter your phone number',
                        validator: ctrl.validatePhone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // ─── National ID ───────────────────────────────────
                      CustomTextFormField(
                        controller: ctrl.nationalIdController,
                        title: 'National ID Number',
                        hintText: 'Enter your national ID number',
                        validator: ctrl.validateNationalId,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // ─── Password ──────────────────────────────────────
                      CustomTextFormField(
                        controller: ctrl.passwordController,
                        title: 'Password',
                        hintText: 'Enter your password',
                        validator: ctrl.validatePassword,
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),

                      // ─── Confirm Password ──────────────────────────────
                      CustomTextFormField(
                        controller: ctrl.confirmPasswordController,
                        title: 'Confirm Password',
                        hintText: 'Re-enter your password',
                        validator: ctrl.validateConfirmPassword,
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),

                      // ─── Driving License Upload ────────────────────────
                      Text(
                        'Driving License',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: LightColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: ctrl.hasDrivingLicense ? null : ctrl.pickDrivingLicense,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDDDDDD)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                ctrl.hasDrivingLicense
                                    ? Icons.check_circle_outline
                                    : Icons.add_circle_outline,
                                color: ctrl.hasDrivingLicense
                                    ? LightColors.primaryColor
                                    : LightColors.textColor.withOpacity(0.54),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  ctrl.hasDrivingLicense
                                      ? ctrl.drivingLicenseFileName!
                                      : 'Upload driving license',
                                  style: TextStyle(
                                    color: ctrl.hasDrivingLicense
                                        ? LightColors.textColor
                                        : LightColors.textColor.withOpacity(0.54),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (ctrl.hasDrivingLicense)
                                GestureDetector(
                                  onTap: ctrl.clearDrivingLicense,
                                  child: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: LightColors.textColor.withOpacity(0.54),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ─── Terms & Conditions ────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: ctrl.acceptedTerms,
                            onChanged: ctrl.toggleTerms,
                            activeColor: LightColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: 'I agree to the ',
                                style: TextStyle(
                                  color: LightColors.textColor.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Terms and Conditions',
                                    style: TextStyle(
                                      color: LightColors.primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ─── Sign Up Button ────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: ctrl.isLoading
                              ? null
                              : () => ctrl.handleSignUp(context, formKey),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LightColors.primaryColor,
                            foregroundColor: Colors.white,
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
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ─── Already have an account ───────────────────────
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
          );
        },
      ),
    );
  }
}

