import 'package:flutter/material.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';
import 'package:cargo/core/dataSource/local_data/preferences_manager.dart';
import 'package:cargo/Features/Main/main_screen.dart';
import 'package:cargo/Features/auth/two_factor_screen.dart';
import 'package:cargo/Features/auth/phone_login_otp_screen.dart';

enum LoginMethod { email, phone }

class LoginController extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  LoginMethod _method = LoginMethod.email;
  LoginMethod get method => _method;
  bool get isEmail => _method == LoginMethod.email;
  bool get isPhone => _method == LoginMethod.phone;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String get primaryButtonText => isPhone ? 'Send Code' : 'Login';

  void switchMethod(LoginMethod method) {
    _method = method;
    passwordController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? validatePhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your phone number';
    if (!RegExp(r'^5[0-9]{8}$').hasMatch(v)) {
      return 'Enter a valid Saudi number (9 digits starting with 5)';
    }
    return null;
  }

  Future<void> handleLogin(BuildContext context, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;
    if (isEmail) {
      await _loginWithEmail(context);
    } else {
      await _sendOtp(context);
    }
  }

  Future<void> _loginWithEmail(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await FirebaseService().login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (user == null) {
        if (context.mounted) _showError(context, 'Login failed');
        return;
      }

      // Send login OTP for 2FA; if user has no phone/2FA set up, proceeds directly.
      final result = await FirebaseService().sendLoginOtp(user.uid);
      final twoFactorRequired = result['twoFactorRequired'] as bool? ?? false;

      if (twoFactorRequired) {
        final maskedPhone = result['maskedPhone'] as String? ?? '';
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TwoFactorScreen(
                uid: user.uid,
                maskedPhone: maskedPhone,
              ),
            ),
          );
        }
      } else {
        await PreferencesManager().setBool('isLoggedIn', true);
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      }
    } catch (e) {
      if (context.mounted) _showError(context, 'Login failed: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _sendOtp(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    final phone = '+966${phoneController.text.trim()}';
    try {
      await FirebaseService().sendPhoneLoginOtp(phone);
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PhoneLoginOtpScreen(phone: phone),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) _showError(context, 'Failed to send code: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _showError(BuildContext context, String msg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
