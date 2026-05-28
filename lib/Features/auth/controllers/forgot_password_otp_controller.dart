import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';
import 'package:cargo/core/errors/error_handler.dart';
import 'package:cargo/core/errors/app_messenger.dart';
import 'package:cargo/Features/auth/reset_password_screen.dart';

class ForgotPasswordOtpController extends ChangeNotifier {
  final String email;

  ForgotPasswordOtpController({required this.email}) {
    for (var f in focusNodes) {
      f.addListener(notifyListeners);
    }
    _startTimer();
  }

  // ─── OTP boxes ────────────────────────────────────────────────────────────
  final List<TextEditingController> boxControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  String get otpCode => boxControllers.map((c) => c.text).join();
  bool get isComplete => otpCode.length == 6;

  // ─── Loading ──────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ─── Timer ────────────────────────────────────────────────────────────────
  static const int _timerSeconds = 48;
  int _secondsLeft = _timerSeconds;
  int get secondsLeft => _secondsLeft;
  bool get canResend => _secondsLeft == 0;
  Timer? _timer;

  String get timerText {
    final mins = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final secs = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = _timerSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft > 0) {
        _secondsLeft--;
        notifyListeners();
      } else {
        t.cancel();
        notifyListeners();
      }
    });
  }

  // ─── Input logic ──────────────────────────────────────────────────────────
  void onChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
    notifyListeners();
  }

  // ─── Resend OTP ───────────────────────────────────────────────────────────
  Future<void> resendOtp(BuildContext context) async {
    if (!canResend) return;

    for (var c in boxControllers) { c.clear(); }
    focusNodes[0].requestFocus();
    notifyListeners();

    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseService().sendOtp(email);
      _startTimer();
      if (context.mounted) {
        AppMessenger.showSuccess(context, 'New code sent! Check your email.');
      }
    } catch (e) {
      if (context.mounted) AppMessenger.showError(context, ErrorHandler.handle(e).userMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Verify OTP ───────────────────────────────────────────────────────────
  Future<void> verifyOtp(BuildContext context) async {
    if (!isComplete) return;

    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseService().verifyOtp(email, otpCode);
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(email: email),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) AppMessenger.showError(context, ErrorHandler.handle(e).userMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in boxControllers) { c.dispose(); }
    for (var f in focusNodes) { f.dispose(); }
    super.dispose();
  }
}
