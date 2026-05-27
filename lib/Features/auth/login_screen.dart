import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/core/widgets/custom_text_form_field.dart';
import 'package:cargo/Features/auth/controllers/login_controller.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/Features/auth/welcome_screen.dart';
import 'package:cargo/Features/auth/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Stable key — not recreated on every rebuild
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginController(),
      child: Consumer<LoginController>(
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
                  icon: const Icon(Icons.arrow_back, color: LightColors.textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            title: const Text(
              'Login',
              style: TextStyle(
                color: LightColors.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: LightColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your registered account to sign in',
                    style: TextStyle(
                      fontSize: 14,
                      color: LightColors.textColor.withValues(alpha:0.54),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ─── Method toggle ───────────────────────────────────
                  _MethodToggle(ctrl: ctrl),
                  const SizedBox(height: 25),

                  // ─── Email fields ────────────────────────────────────
                  if (ctrl.isEmail) ...[
                    CustomTextFormField(
                      controller: ctrl.emailController,
                      title: 'Email',
                      hintText: 'Enter your email address',
                      validator: ctrl.validateEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    CustomTextFormField(
                      controller: ctrl.passwordController,
                      title: 'Password',
                      hintText: '••••••••••••',
                      validator: ctrl.validatePassword,
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: LightColors.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ─── Phone field ─────────────────────────────────────
                  if (ctrl.isPhone) ...[
                    _PhoneLoginField(ctrl: ctrl),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 16),

                  // ─── Login / Send Code button ────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: ctrl.isLoading
                          ? null
                          : () => ctrl.handleLogin(context, _formKey),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LightColors.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            LightColors.primaryColor.withValues(alpha:0.5),
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
                          : Text(
                              ctrl.primaryButtonText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: LightColors.textColor.withValues(alpha:0.54),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const WelcomeScreen()),
                          ),
                          child: const Text(
                            'Sign Up',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Method toggle (Email / Phone Number) ─────────────────────────────────────

class _MethodToggle extends StatelessWidget {
  const _MethodToggle({required this.ctrl});

  final LoginController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Email',
            isSelected: ctrl.isEmail,
            onTap: () => ctrl.switchMethod(LoginMethod.email),
          ),
          _Tab(
            label: 'Phone Number',
            isSelected: ctrl.isPhone,
            onTap: () => ctrl.switchMethod(LoginMethod.phone),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? LightColors.textColor
                    : LightColors.textColor.withValues(alpha:0.55),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Phone field with locked +966 prefix ──────────────────────────────────────

class _PhoneLoginField extends StatelessWidget {
  const _PhoneLoginField({required this.ctrl});

  final LoginController ctrl;

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