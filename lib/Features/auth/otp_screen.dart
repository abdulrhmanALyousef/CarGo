import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/Features/auth/controllers/otp_controller.dart';

class OtpScreen extends StatelessWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OtpController(
        phoneNumber: phoneNumber,
        verificationId: verificationId,
      ),
      child: Builder(
        builder: (context) {
          final ctrl = context.watch<OtpController>();

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
                'Verify Code',
                style: TextStyle(
                  color: LightColors.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    // ─── Icon ────────────────────────────────────────────
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: LightColors.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 36,
                        color: LightColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Title ───────────────────────────────────────────
                    Text(
                      'Verify Code',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: LightColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ─── Subtitle ────────────────────────────────────────
                    Text(
                      'Please enter the code we just sent to',
                      style: TextStyle(
                        fontSize: 14,
                        color: LightColors.textColor.withOpacity(0.54),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phoneNumber,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: LightColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ─── OTP Boxes ───────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (i) {
                        final isFocused = ctrl.focusNodes[i].hasFocus;
                        final isFilled = ctrl.boxControllers[i].text.isNotEmpty;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: 48,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isFocused
                                  ? LightColors.primaryColor
                                  : isFilled
                                      ? LightColors.primaryColor.withOpacity(0.5)
                                      : const Color(0xFFDDDDDD),
                              width: isFocused ? 2 : 1.5,
                            ),
                            boxShadow: isFocused
                                ? [
                                    BoxShadow(
                                      color: LightColors.primaryColor.withOpacity(0.15),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : [],
                          ),
                          child: TextField(
                            controller: ctrl.boxControllers[i],
                            focusNode: ctrl.focusNodes[i],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(1),
                            ],
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: LightColors.textColor,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              counterText: '',
                            ),
                            onChanged: (v) => ctrl.onChanged(v, i),
                            onTap: () => ctrl.focusNodes[i].requestFocus(),
                            onEditingComplete: () {},
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 32),

                    // ─── Timer / Resend ───────────────────────────────────
                    ctrl.canResend
                        ? GestureDetector(
                            onTap: () => ctrl.resendOtp(context),
                            child: Text(
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
                                color: LightColors.textColor.withOpacity(0.54),
                              ),
                              children: [
                                TextSpan(
                                  text: ctrl.timerText,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: LightColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                    const Spacer(),

                    // ─── Continue Button ──────────────────────────────────
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
                              LightColors.primaryColor.withOpacity(0.4),
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
                                'Continue',
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

