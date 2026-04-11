import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';
import 'package:cargo/core/dataSource/local_data/preferences_manager.dart';
import 'package:cargo/Features/Main/main_screen.dart';
import 'package:cargo/Features/auth/otp_screen.dart';

enum LoginMethod { email, phone }

class LoginController extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  LoginMethod _method = LoginMethod.email;
  LoginMethod get method => _method;
  bool get isEmail => _method == LoginMethod.email;
  bool get isPhone => _method == LoginMethod.phone;

  String? _verificationId;
  bool get codeSent => _verificationId != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // True after a login attempt is blocked by unverified email.
  // The UI uses this to show the "Resend Verification Email" button.
  bool _showResendButton = false;
  bool get showResendButton => _showResendButton;

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
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    // Simple phone validation (you can tighten as needed)
    if (!RegExp(r'^[0-9+]{8,15}$').hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
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
    _showResendButton = false;
    notifyListeners();

    try {
      final user = await FirebaseService().login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (user == null) {
        _showError(context, 'Login failed');
        return;
      }

      // Reload to get the latest emailVerified state from Firebase.
      await user.reload();
      final fresh = FirebaseAuth.instance.currentUser;

      if (fresh == null || !fresh.emailVerified) {
        // Sign out immediately — unverified users must not enter the app.
        await FirebaseAuth.instance.signOut();
        _showResendButton = true;
        _showError(
          context,
          'Please verify your email before logging in. '
          'Check your inbox and spam folder.',
        );
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
      _showError(context, 'Login failed: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Resend Verification Email ────────────────────────────────────────────
  // Signs in temporarily to obtain a live user object, sends the verification
  // email, then signs out again so the unverified user cannot enter the app.
  Future<void> resendVerificationEmail(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      await cred.user?.sendEmailVerification();
      await FirebaseAuth.instance.signOut();
      _showResendButton = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Verification email sent. Check your inbox and spam folder.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      _showError(context, 'Failed to resend: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Forgot Password ──────────────────────────────────────────────────────
  // Shows a dialog asking for an email address, then sends a Firebase
  // password-reset email. Pre-fills with whatever is already in the email field.
  Future<void> showForgotPasswordDialog(BuildContext context) async {
    final emailCtrl =
        TextEditingController(text: emailController.text.trim());

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email address',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              await _sendPasswordReset(context, email);
            },
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );

    emailCtrl.dispose();
  }

  Future<void> _sendPasswordReset(BuildContext context, String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await FirebaseService().resetPassword(email: email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Check your email to reset your password. '
              'Also check your spam folder.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      _showError(context, 'Failed to send reset email: ${e.toString()}');
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
          await _afterPhoneLogin(context, userCredential.user);
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
      _showError(context, 'Failed to send code: ${e.toString()}');
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
      await _afterPhoneLogin(context, cred.user);
    } catch (e) {
      _showError(context, 'Invalid code: ${e.toString()}');
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
