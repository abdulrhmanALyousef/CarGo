import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/core/widgets/custom_text_formField.dart';
import 'package:cargo/Features/auth/controllers/login_controller.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/Features/auth/siginup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginController(),
      child: Builder(
        builder: (context) {
          final ctrl = context.watch<LoginController>();
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
                'Login',
                style: TextStyle(
                  color: LightColors.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
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
                          color: LightColors.textColor.withOpacity(0.54),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFBDBDBD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => ctrl.switchMethod(LoginMethod.email),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: ctrl.isEmail ? LightColors.primaryColor.withOpacity(0.18) : const Color(0xFFBDBDBD),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Email',
                                      style: TextStyle(
                                        color: LightColors.textColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => ctrl.switchMethod(LoginMethod.phone),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: ctrl.isPhone ? LightColors.primaryColor.withOpacity(0.18) : const Color(0xFFBDBDBD),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Phone Number',
                                      style: TextStyle(
                                        color: LightColors.textColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      if (ctrl.isEmail) ...[
                        CustomTextFormField(
                          controller: ctrl.emailController,
                          title: 'Email',
                          hintText: 'Enter your email address..',
                          validator: ctrl.validateEmail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          controller: ctrl.passwordController,
                          title: 'Password',
                          hintText: 'Enter your password..',
                          validator: ctrl.validatePassword,
                          obscureText: true,
                        ),
                        const SizedBox(height: 15),
                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: LightColors.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (ctrl.isPhone) ...[
                        CustomTextFormField(
                          controller: ctrl.phoneController,
                          title: 'Phone Number',
                          hintText: 'Enter your phone number..',
                          validator: ctrl.validatePhone,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),
                      ],
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: ctrl.isLoading ? null : () => ctrl.handleLogin(context, formKey),
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
                                color: LightColors.textColor.withOpacity(0.54),
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SignUpScreen()),
                              ),
                              child: Text(
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
          );
        },
      ),
    );
  }
}

