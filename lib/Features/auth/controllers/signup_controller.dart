import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';
import 'package:cargo/Features/auth/email_otp_screen.dart';

class SignUpController extends ChangeNotifier {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nationalIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  SignUpController() {
    phoneController.text = '+966';
    phoneController.addListener(_guardPhonePrefix);
  }

  static const _phonePrefix = '+966';

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

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _acceptedTerms = false;
  bool get acceptedTerms => _acceptedTerms;

  // ─── Driving License ─────────────────────────────────────────────────────
  File? _licenseFile;
  File? get licenseFile => _licenseFile;
  bool get hasDrivingLicense => _licenseFile != null;

  void toggleTerms(bool? value) {
    _acceptedTerms = value ?? false;
    notifyListeners();
  }

  Future<void> pickDrivingLicense() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      _licenseFile = File(picked.path);
      notifyListeners();
    }
  }

  void clearDrivingLicense() {
    _licenseFile = null;
    notifyListeners();
  }

  // ─── Validators ──────────────────────────────────────────────────────────

  String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your full name';
    if (value.trim().length < 3) return 'Full name is too short';
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(value.trim())) {
      return 'Please enter a valid email';
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

  String? validateNationalId(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your national ID';
    if (!RegExp(r'^[0-9]{8,20}$').hasMatch(value.trim())) {
      return 'Please enter a valid national ID';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != passwordController.text) return 'Passwords do not match';
    return null;
  }

  // ─── Handle Sign Up ───────────────────────────────────────────────────────
  //
  // Flow:
  //   1. Validate form + terms + driving license
  //   2. Check phone / national-ID duplicates (fast Firestore reads)
  //   3. Call sendSignupOtp Cloud Function → OTP email is sent via Resend
  //   4. Navigate to EmailOtpScreen
  //
  // The Firebase Auth user is created ONLY after the user verifies the OTP
  // on the next screen (handled by EmailOtpController).

  Future<void> handleSignUp(
      BuildContext context, GlobalKey<FormState> formKey) async {
    if (!formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      _showError(context, 'Please accept Terms and Conditions');
      return;
    }

    if (!hasDrivingLicense) {
      _showError(context, 'Please upload your driving license');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // ─── Duplicate checks (fail fast before sending OTP) ──────────────
      final phoneExists = await FirebaseService()
          .isPhoneExists(phoneController.text.trim());
      if (phoneExists) {
        _showError(context, 'This phone number is already registered');
        return;
      }

      final nationalIdExists = await FirebaseService()
          .isNationalIdExists(nationalIdController.text.trim());
      if (nationalIdExists) {
        _showError(context, 'This national ID is already registered');
        return;
      }

      // ─── Send OTP via Cloud Function (Resend) ─────────────────────────
      print('[SignUpController] sending signup OTP to ${emailController.text.trim()}');
      await FirebaseService().sendSignupOtp(emailController.text.trim());
      print('[SignUpController] OTP sent, navigating to EmailOtpScreen');

      // ─── Navigate to OTP verification screen ─────────────────────────
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmailOtpScreen(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
              fullName: fullNameController.text.trim(),
              phone: phoneController.text.trim(),
              nationalId: nationalIdController.text.trim(),
              licenseFile: _licenseFile!,
            ),
          ),
        );
      }
    } catch (e) {
      print('[SignUpController] handleSignUp error: $e');
      _showError(context, _extractError(e));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _extractError(Object e) {
    if (e is FirebaseFunctionsException) return e.message ?? e.code;
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
    phoneController.removeListener(_guardPhonePrefix);
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    nationalIdController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}