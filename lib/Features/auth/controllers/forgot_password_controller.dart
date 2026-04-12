import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';

enum ForgotPasswordStep { email, verify }

class ForgotPasswordController extends ChangeNotifier {
  // ── Text controllers ──────────────────────────────────────────────────────
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────────────
  ForgotPasswordStep _step = ForgotPasswordStep.email;
  ForgotPasswordStep get step => _step;
  bool get isVerifyStep => _step == ForgotPasswordStep.verify;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ── Step 1: Send OTP ──────────────────────────────────────────────────────
  Future<void> sendOtp(BuildContext context) async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _setError('Please enter your email address.');
      return;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _setError('Please enter a valid email address.');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await FirebaseService().sendOtp(email);
      _step = ForgotPasswordStep.verify;
      _error = null;
    } catch (e) {
      _setError(_extractError(e));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Step 2: Verify OTP + reset password ───────────────────────────────────
  Future<void> resetPassword(BuildContext context) async {
    final otp = otpController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (otp.length != 6) {
      _setError('Please enter the 6-digit code.');
      return;
    }
    if (newPassword.length < 6) {
      _setError('Password must be at least 6 characters.');
      return;
    }
    if (newPassword != confirm) {
      _setError('Passwords do not match.');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final email = emailController.text.trim();
      await FirebaseService().verifyOtp(email, otp);
      await FirebaseService().resetPasswordWithOtp(email, newPassword);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully! Please log in.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context); // back to login
      }
    } catch (e) {
      _setError(_extractError(e));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Go back to email step ─────────────────────────────────────────────────
  void backToEmailStep() {
    _step = ForgotPasswordStep.email;
    _error = null;
    otpController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  String _extractError(Object e) {
    if (e is FirebaseFunctionsException) return e.message ?? e.code;
    return e.toString();
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}