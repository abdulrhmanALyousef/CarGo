import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/Features/auth/controllers/reset_password_controller.dart';

class ResetPasswordScreen extends StatelessWidget {
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ResetPasswordController(email: email),
      child: Builder(
        builder: (context) {
          final ctrl = context.watch<ResetPasswordController>();

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
                    icon: const Icon(Icons.arrow_back, color: LightColors.textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              title: const Text(
                'Reset Password',
                style: TextStyle(
                  color: LightColors.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ─── Icon ─────────────────────────────────────────────
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: LightColors.primaryColor.withValues(alpha:0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          size: 36,
                          color: LightColors.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Title ────────────────────────────────────────────
                    const Center(
                      child: Text(
                        'Create New Password',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: LightColors.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ─── Subtitle ─────────────────────────────────────────
                    Center(
                      child: Text(
                        'Your new password must be different\nfrom your previous password.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: LightColors.textColor.withValues(alpha:0.54),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ─── New password ─────────────────────────────────────
                    _buildLabel('New Password'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ctrl.newPasswordController,
                      obscureText: ctrl.obscureNew,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(
                        'Enter new password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            ctrl.obscureNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: LightColors.textColor.withValues(alpha:0.4),
                          ),
                          onPressed: () =>
                              context.read<ResetPasswordController>().toggleObscureNew(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── Confirm password ─────────────────────────────────
                    _buildLabel('Confirm Password'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ctrl.confirmPasswordController,
                      obscureText: ctrl.obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) =>
                          context.read<ResetPasswordController>().resetPassword(context),
                      decoration: _inputDecoration(
                        'Re-enter new password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            ctrl.obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: LightColors.textColor.withValues(alpha:0.4),
                          ),
                          onPressed: () =>
                              context.read<ResetPasswordController>().toggleObscureConfirm(),
                        ),
                      ),
                    ),

                    // ─── Error ────────────────────────────────────────────
                    if (ctrl.error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        ctrl.error!,
                        style:
                            const TextStyle(fontSize: 13, color: Colors.red),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // ─── Reset button ─────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: ctrl.isLoading
                            ? null
                            : () => context
                                .read<ResetPasswordController>()
                                .resetPassword(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LightColors.primaryColor,
                          disabledBackgroundColor:
                              LightColors.primaryColor.withValues(alpha:0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: ctrl.isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Reset Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: LightColors.textColor,
        ),
      );

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: LightColors.textColor.withValues(alpha:0.4)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF2F2F2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: LightColors.primaryColor,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      );
}
