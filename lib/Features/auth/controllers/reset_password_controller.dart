import 'package:flutter/material.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';
import 'package:cargo/core/errors/error_handler.dart';
import 'package:cargo/core/errors/app_messenger.dart';

class ResetPasswordController extends ChangeNotifier {
  final String email;

  ResetPasswordController({required this.email});

  // ─── Text controllers ─────────────────────────────────────────────────────
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // ─── State ────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool get obscureNew => _obscureNew;
  bool get obscureConfirm => _obscureConfirm;

  void toggleObscureNew() {
    _obscureNew = !_obscureNew;
    notifyListeners();
  }

  void toggleObscureConfirm() {
    _obscureConfirm = !_obscureConfirm;
    notifyListeners();
  }

  // ─── Reset password ───────────────────────────────────────────────────────
  Future<void> resetPassword(BuildContext context) async {
    final newPassword = newPasswordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

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
      await FirebaseService().resetPasswordWithOtp(email, newPassword);

      if (context.mounted) {
        AppMessenger.showSuccess(context, 'Password reset successfully! Please log in.');
        Navigator.of(context).popUntil((route) => route.isFirst);
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
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
