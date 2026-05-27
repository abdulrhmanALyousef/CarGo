import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';
import 'package:cargo/core/dataSource/local_data/preferences_manager.dart';
import 'package:cargo/Features/Main/main_screen.dart';
import 'package:cargo/Features/auth/otp_screen.dart';
// ignore_for_file: unused_import

enum LoginMethod { email, phone }

class LoginController extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  static const _phonePrefix = '+966';

  LoginController() {
    phoneController.text = _phonePrefix;
    phoneController.addListener(_guardPhonePrefix);
  }

  void _guardPhonePrefix() {
    if (!phoneController.text.startsWith(_phonePrefix)) {
      final digits = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final restored = _phonePrefix + digits;
      phoneController.value = TextEditingValue(
        text: restored,
        selection: TextSelection.collapsed(offset: restored.length),
      );
    }
  }

  LoginMethod _method = LoginMethod.email;
  LoginMethod get method => _method;
  bool get isEmail => _method == LoginMethod.email;
  bool get isPhone => _method == LoginMethod.phone;

  String? _verificationId;
  bool get codeSent => _verificationId != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String get primaryButtonText {
    if (isPhone) {
      return codeSent ? 'Verify & Login' : 'Send Code';
    }
    return 'Login';
  }

  void switchMethod(LoginMethod method) {
    _method = method;
    _verificationId = null;
    otpController.clear();
    passwordController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    phoneController.removeListener(_guardPhonePrefix);
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validatePhone(String? value) {
    final v = value?.trim() ?? '';
    if (v == _phonePrefix || v.length <= _phonePrefix.length) {
      return 'Please enter your phone number';
    }
    final digits = v.substring(_phonePrefix.length);
    if (!RegExp(r'^5[0-9]{8}$').hasMatch(digits)) {
      return 'Enter a valid Saudi number (9 digits starting with 5)';
    }
    return null;
  }

  String? validateOtp(String? value) {
    if (codeSent && (value == null || value.isEmpty)) {
      return 'Please enter the verification code';
    }
    return null;
  }

  Future<void> handleLogin(BuildContext context, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (isEmail) {
      await _loginWithEmail(context);
    } else {
      if (!codeSent) {
        await _sendOtp(context);
      } else {
        await _verifyOtp(context);
      }
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

      await PreferencesManager().setBool('isLoggedIn', true);
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
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

    final phone = phoneController.text.trim();
    try {
      await FirebaseService().sendPhoneVerification(
        phoneNumber: phone,
        onCompleted: (credential) async {
          // Auto-completion flow
          final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          if (context.mounted) await _afterPhoneLogin(context, userCredential.user);
        },
        onFailed: (e) {
          _showError(context, e.message ?? 'Phone verification failed');
        },
        onCodeSent: (verificationId, _) {
          _verificationId = verificationId;
          _isLoading = false;
          notifyListeners();
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtpScreen(
                  phoneNumber: phone,
                  verificationId: verificationId,
                ),
              ),
            );
          }
        },
        onTimeout: (verificationId) {
          _verificationId = verificationId;
          notifyListeners();
        },
      );
    } catch (e) {
      if (context.mounted) _showError(context, 'Failed to send code: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _verifyOtp(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    final code = otpController.text.trim();
    if (_verificationId == null) {
      _showError(context, 'Please request a code first');
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final cred = await FirebaseService().signInWithSmsCode(
        verificationId: _verificationId!,
        smsCode: code,
      );
      if (context.mounted) await _afterPhoneLogin(context, cred.user);
    } catch (e) {
      if (context.mounted) _showError(context, 'Invalid code: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _afterPhoneLogin(BuildContext context, User? user) async {
    if (user != null) {
      await PreferencesManager().setBool('isLoggedIn', true);
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } else {
      _showError(context, 'Login failed');
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
