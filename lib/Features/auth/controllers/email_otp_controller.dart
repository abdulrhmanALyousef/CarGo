import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';
import 'package:cargo/core/dataSource/local_data/preferences_manager.dart';
import 'package:cargo/core/errors/error_handler.dart';
import 'package:cargo/core/errors/app_messenger.dart';
import 'package:cargo/Features/auth/signup_success_screen.dart';
import 'package:cargo/core/services/mock_verification_service.dart';

class EmailOtpController extends ChangeNotifier {
  final String email;
  final String password;
  final String fullName;
  final String phone;
  final String nationalId;
  final File? licenseFile;
  final String role;

  EmailOtpController({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.nationalId,
    this.licenseFile,
    this.role = 'renter',
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

    for (final c in boxControllers) { c.clear(); }
    focusNodes[0].requestFocus();
    notifyListeners();

    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseService().sendSignupOtp(email);
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
  //
  // Full sign-up sequence:
  //   1. verifySignupOtp  → Cloud Function creates Firebase Auth user + Firestore doc
  //   2. signInWithEmailAndPassword → client gets authenticated session
  //   3. uploadDrivingLicense (if provided)
  //   4. updateUserLicenseUrl (if license was uploaded)
  //   5. updateUserRoles → writes role array to Firestore doc
  //   6. Navigate to SignupSuccessScreen

  Future<void> verifyOtp(BuildContext context) async {
    if (!isComplete) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Step 1: verify OTP + create user via Cloud Function
      await FirebaseService().verifySignupOtp(
        email: email,
        code: otpCode,
        password: password,
        fullName: fullName,
        phone: phone,
        nationalId: nationalId,
      );

      // Step 2: sign in client-side
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('Sign-in returned null user.');

      // Step 3 & 4: upload driving license (if provided)
      if (licenseFile != null) {
        final licenseUrl = await FirebaseService().uploadDrivingLicense(
          uid: user.uid,
          imageFile: licenseFile!,
        );
        await FirebaseService().updateUserLicenseUrl(
          uid: user.uid,
          licenseUrl: licenseUrl,
        );
      }

      // Step 5: persist role
      await FirebaseService().updateUserRoles(
        uid: user.uid,
        roles: [role],
      );

      // Step 5b: initialise verification status and kick off mock review.
      // TODO: Replace with real Moroor/National ID verification API in production.
      await FirebaseService().updateVerificationStatus(user.uid, 'pending');
      MockVerificationService.triggerMockVerification(user.uid);

      // Step 6: navigate to success screen
      await PreferencesManager().setBool('isLoggedIn', true);
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => SignupSuccessScreen(
              fullName: fullName,
              role: role,
            ),
          ),
          (_) => false,
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
    for (final c in boxControllers) { c.dispose(); }
    for (final f in focusNodes) { f.dispose(); }
    super.dispose();
  }
}
