import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';
import 'package:cargo/core/dataSource/local_data/preferences_manager.dart';
import 'package:cargo/Features/Main/main_screen.dart';

class PhoneLoginOtpController extends ChangeNotifier {
  final String phone; // full international format: +966XXXXXXXXX

  PhoneLoginOtpController({required this.phone}) {
    for (final f in focusNodes) {
      f.addListener(notifyListeners);
    }
    _startTimer();
  }

  // ─── 4-digit OTP boxes ────────────────────────────────────────────────────
  final List<TextEditingController> boxControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());

  String get otpCode => boxControllers.map((c) => c.text).join();
  bool get isComplete => otpCode.length == 4;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ─── Timer ────────────────────────────────────────────────────────────────
  static const int _timerSeconds = 60;
  int _secondsLeft = _timerSeconds;
  int get secondsLeft => _secondsLeft;
  bool get canResend => _secondsLeft == 0 && !_isLoading;
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
    if (value.isNotEmpty && index < 3) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
    notifyListeners();
  }

  // ─── Resend ───────────────────────────────────────────────────────────────
  Future<void> resendOtp(BuildContext context) async {
    if (!canResend) return;
    for (final c in boxControllers) { c.clear(); }
    focusNodes[0].requestFocus();
    _isLoading = true;
    notifyListeners();
    try {
      await FirebaseService().sendPhoneLoginOtp(phone);
      _startTimer();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New code sent to your phone.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) _showError(context, _extractError(e));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Verify OTP → custom token sign-in ────────────────────────────────────
  Future<void> verifyOtp(BuildContext context) async {
    if (!isComplete) return;
    _isLoading = true;
    notifyListeners();
    try {
      final token = await FirebaseService().verifyPhoneLogin(
        phone: phone,
        code: otpCode,
      );
      await FirebaseAuth.instance.signInWithCustomToken(token);
      await PreferencesManager().setBool('isLoggedIn', true);
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (context.mounted) _showError(context, _extractError(e));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _extractError(Object e) {
    if (e is FirebaseFunctionsException) return e.message ?? e.code;
    if (e is FirebaseAuthException) return e.message ?? e.code;
    return e.toString();
  }

  void _showError(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in boxControllers) { c.dispose(); }
    for (final f in focusNodes) { f.dispose(); }
    super.dispose();
  }
}
