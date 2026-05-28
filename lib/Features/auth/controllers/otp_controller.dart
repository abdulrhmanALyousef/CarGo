import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';
import 'package:cargo/core/dataSource/local_data/preferences_manager.dart';
import 'package:cargo/core/errors/error_handler.dart';
import 'package:cargo/core/errors/app_messenger.dart';
import 'package:cargo/Features/Main/main_screen.dart';

class OtpController extends ChangeNotifier {
  final String phoneNumber;
  String verificationId;

  OtpController({
    required this.phoneNumber,
    required this.verificationId,
  }) {
    for (var f in focusNodes) {
      f.addListener(notifyListeners);
    }
    _startTimer();
  }

  // ─── OTP boxes ────────────────────────────────────────────────────────────
  final List<TextEditingController> boxControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  String get otpCode =>
      boxControllers.map((c) => c.text).join();
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

  void onBackspace(int index) {
    if (boxControllers[index].text.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
      boxControllers[index - 1].clear();
    }
    notifyListeners();
  }

  // ─── Resend OTP ───────────────────────────────────────────────────────────
  Future<void> resendOtp(BuildContext context) async {
    if (!canResend) return;

    for (var c in boxControllers) {
      c.clear();
    }
    focusNodes[0].requestFocus();
    notifyListeners();

    await FirebaseService().sendPhoneVerification(
      phoneNumber: phoneNumber,
      onCompleted: (credential) async {
        final cred = await FirebaseAuth.instance.signInWithCredential(credential);
        if (context.mounted) await _afterSuccess(context, cred.user);
      },
      onFailed: (e) {
        AppMessenger.showError(context, ErrorHandler.handle(e).userMessage);
      },
      onCodeSent: (newVerificationId, _) {
        verificationId = newVerificationId;
        _startTimer();
        AppMessenger.showSuccess(context, 'New verification code sent!');
        notifyListeners();
      },
      onTimeout: (id) {
        verificationId = id;
        notifyListeners();
      },
    );
  }

  // ─── Verify OTP ───────────────────────────────────────────────────────────
  Future<void> verifyOtp(BuildContext context) async {
    if (!isComplete) return;

    _isLoading = true;
    notifyListeners();

    try {
      final cred = await FirebaseService().signInWithSmsCode(
        verificationId: verificationId,
        smsCode: otpCode,
      );
      if (context.mounted) await _afterSuccess(context, cred.user);
    } catch (e) {
      if (context.mounted) AppMessenger.showError(context, ErrorHandler.handle(e).userMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _afterSuccess(BuildContext context, User? user) async {
    if (user != null) {
      await PreferencesManager().setBool('isLoggedIn', true);
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (_) => false,
        );
      }
    } else {
      AppMessenger.showError(context, 'Unable to sign in. Please try again.');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in boxControllers) {
      c.dispose();
    }
    for (var f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }
}

