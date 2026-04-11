import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';
import 'package:cargo/core/dataSource/local_data/preferences_manager.dart';
import 'package:cargo/Features/Main/main_screen.dart';

class EmailOtpController extends ChangeNotifier {
  final String email;
  final String password;
  final String fullName;
  final String phone;
  final String nationalId;
  final File licenseFile;

  EmailOtpController({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.nationalId,
    required this.licenseFile,
  }) {
    for (final f in focusNodes) {
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
    if (value.length == 1 && index < 5) {
      focusNodes[index + 1].requestFocus();
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

    for (final c in boxControllers) c.clear();
    focusNodes[0].requestFocus();
    notifyListeners();

    _isLoading = true;
    notifyListeners();

    try {
      print('[EmailOtpController] resending OTP to $email');
      await FirebaseService().sendSignupOtp(email);
      _startTimer();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New code sent! Check your email.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[EmailOtpController] resendOtp error: $e');
      _showError(context, _extractError(e));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Verify OTP ───────────────────────────────────────────────────────────
  //
  // Full sign-up sequence after OTP is confirmed:
  //   1. verifySignupOtp  → Cloud Function creates Firebase Auth user + Firestore doc
  //   2. signInWithEmailAndPassword → client gets an authenticated session
  //   3. uploadDrivingLicense       → now authenticated, upload is allowed
  //   4. updateUserLicenseUrl       → write URL back to Firestore
  //   5. Navigate to MainScreen

  Future<void> verifyOtp(BuildContext context) async {
    if (!isComplete) return;

    _isLoading = true;
    notifyListeners();

    try {
      // ── Step 1: verify OTP + create user ─────────────────────────────
      print('[EmailOtpController] step 1 — verifySignupOtp');
      await FirebaseService().verifySignupOtp(
        email: email,
        code: otpCode,
        password: password,
        fullName: fullName,
        phone: phone,
        nationalId: nationalId,
      );

      // ── Step 2: sign in client-side ───────────────────────────────────
      print('[EmailOtpController] step 2 — signInWithEmailAndPassword');
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('Sign-in returned null user.');

      // ── Step 3 & 4: upload driving license ────────────────────────────
      print('[EmailOtpController] step 3 — uploadDrivingLicense uid=${user.uid}');
      final licenseUrl = await FirebaseService().uploadDrivingLicense(
        uid: user.uid,
        imageFile: licenseFile,
      );
      print('[EmailOtpController] step 4 — updateUserLicenseUrl');
      await FirebaseService().updateUserLicenseUrl(
        uid: user.uid,
        licenseUrl: licenseUrl,
      );

      // ── Step 5: navigate ──────────────────────────────────────────────
      print('[EmailOtpController] step 5 — sign-up complete, navigating');
      await PreferencesManager().setBool('isLoggedIn', true);
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      print('[EmailOtpController] verifyOtp error: $e');
      _showError(context, _extractError(e));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Returns the real error message so it's visible during debugging.
  // FirebaseFunctionsException carries the exact message thrown on the server.
  String _extractError(Object e) {
    if (e is FirebaseFunctionsException) {
      return e.message ?? e.code;
    }
    if (e is FirebaseAuthException) {
      return e.message ?? e.code;
    }
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
    for (final c in boxControllers) c.dispose();
    for (final f in focusNodes) f.dispose();
    super.dispose();
  }
}