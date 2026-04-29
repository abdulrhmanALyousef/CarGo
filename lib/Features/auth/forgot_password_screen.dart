import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/Features/auth/controllers/forgot_password_controller.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ForgotPasswordController(),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatelessWidget {
  const _ForgotPasswordView();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ForgotPasswordController>();

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
          'Forgot Password',
          style: TextStyle(
            color: LightColors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ─── Icon ──────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: LightColors.primaryColor.withOpacity(0.1),
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

              // ─── Title ─────────────────────────────────────────────────
              Center(
                child: Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: LightColors.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ─── Subtitle ──────────────────────────────────────────────
              Center(
                child: Text(
                  'Enter your email and we\'ll send you\na verification code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: LightColors.textColor.withOpacity(0.54),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // ─── Email label ───────────────────────────────────────────
              Text(
                'Email',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LightColors.textColor,
                ),
              ),
              const SizedBox(height: 8),

              // ─── Email field ───────────────────────────────────────────
              TextField(
                controller: ctrl.emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) =>
                    context.read<ForgotPasswordController>().sendOtp(context),
                decoration: InputDecoration(
                  hintText: 'Enter your email address',
                  hintStyle:
                      TextStyle(color: LightColors.textColor.withOpacity(0.4)),
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
                ),
              ),

              // ─── Error ─────────────────────────────────────────────────
              if (ctrl.error != null) ...[
                const SizedBox(height: 10),
                Text(
                  ctrl.error!,
                  style: const TextStyle(fontSize: 13, color: Colors.red),
                ),
              ],

              const SizedBox(height: 32),

              // ─── Send OTP button ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: ctrl.isLoading
                      ? null
                      : () => context
                          .read<ForgotPasswordController>()
                          .sendOtp(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LightColors.primaryColor,
                    disabledBackgroundColor:
                        LightColors.primaryColor.withOpacity(0.4),
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
                          'Send OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
