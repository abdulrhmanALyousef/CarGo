import 'package:flutter/material.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';
import 'package:cargo/core/errors/error_handler.dart';
import 'package:cargo/Features/auth/forgot_password_otp_screen.dart';

class ForgotPasswordController extends ChangeNotifier {
  // ─── Text controllers ─────────────────────────────────────────────────────
  final TextEditingController emailController = TextEditingController();

  // ─── State ────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ─── Send OTP ─────────────────────────────────────────────────────────────
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
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ForgotPasswordOtpScreen(email: email),
          ),
        );
      }
    } catch (e) {
      _setError(ErrorHandler.handle(e).userMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
