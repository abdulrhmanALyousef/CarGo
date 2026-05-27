import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/Features/auth/controllers/two_factor_controller.dart';

class TwoFactorScreen extends StatelessWidget {
  final String uid;
  final String maskedPhone;

  const TwoFactorScreen({
    super.key,
    required this.uid,
    required this.maskedPhone,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TwoFactorController(uid: uid, maskedPhone: maskedPhone),
      child: Builder(
        builder: (context) {
          final ctrl = context.watch<TwoFactorController>();

          return Scaffold(
            backgroundColor: LightColors.backgroundColor,
            appBar: AppBar(
              backgroundColor: LightColors.backgroundColor,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF9E9E9E),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: LightColors.textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              title: const Text(
                'Two-Factor Authentication',
                style: TextStyle(
                  color: LightColors.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    // ─── Icon ────────────────────────────────────────────
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: LightColors.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        size: 36,
                        color: LightColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Title ───────────────────────────────────────────
                    const Text(
                      'Verification Required',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: LightColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ─── Subtitle ────────────────────────────────────────
                    Text(
                      maskedPhone.isEmpty
                          ? 'Enter the 4-digit code sent to your registered phone'
                          : 'We sent a 4-digit code to',
                      style: TextStyle(
                        fontSize: 14,
                        color: LightColors.textColor.withValues(alpha: 0.54),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (maskedPhone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        maskedPhone,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: LightColors.primaryColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 36),

                    // ─── OTP Boxes ───────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        final isFocused = ctrl.focusNodes[i].hasFocus;
                        final isFilled =
                            ctrl.boxControllers[i].text.isNotEmpty;

                        return Container(
                          margin:
                              const EdgeInsets.symmetric(horizontal: 8),
                          width: 60,
                          height: 68,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isFocused
                                  ? LightColors.primaryColor
                                  : isFilled
                                      ? LightColors.primaryColor
                                          .withValues(alpha: 0.5)
                                      : const Color(0xFFDDDDDD),
                              width: isFocused ? 2 : 1.5,
                            ),
                            boxShadow: isFocused
                                ? [
                                    BoxShadow(
                                      color: LightColors.primaryColor
                                          .withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: TextField(
                              controller: ctrl.boxControllers[i],
                              focusNode: ctrl.focusNodes[i],
                              textAlign: TextAlign.center,
                              textAlignVertical: TextAlignVertical.center,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(1),
                              ],
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: LightColors.textColor,
                                height: 1,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (v) => ctrl.onChanged(v, i),
                              onTap: () =>
                                  ctrl.focusNodes[i].requestFocus(),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 32),

                    // ─── Timer / Resend ───────────────────────────────────
                    ctrl.canResend
                        ? GestureDetector(
                            onTap: () => ctrl.resendOtp(context),
                            child: const Text(
                              'Resend Code',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: LightColors.primaryColor,
                              ),
                            ),
                          )
                        : RichText(
                            text: TextSpan(
                              text: 'Resend code in ',
                              style: TextStyle(
                                fontSize: 14,
                                color: LightColors.textColor
                                    .withValues(alpha: 0.54),
                              ),
                              children: [
                                TextSpan(
                                  text: ctrl.timerText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: LightColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                    const Spacer(),

                    // ─── Verify Button ────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: (ctrl.isComplete && !ctrl.isLoading)
                            ? () => ctrl.verifyOtp(context)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LightColors.primaryColor,
                          disabledBackgroundColor:
                              LightColors.primaryColor.withValues(alpha: 0.4),
                          foregroundColor: Colors.white,
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
                                'Verify & Sign In',
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
}
