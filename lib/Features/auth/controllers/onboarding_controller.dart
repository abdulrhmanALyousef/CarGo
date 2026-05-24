import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/dataSource/remote_data/firebase_service.dart';

class OnboardingController extends ChangeNotifier {
  // ── Role ──────────────────────────────────────────────────────────────────

  String _role = 'renter';
  String get role => _role;
  bool get isRenter => _role == 'renter';
  bool get isOwner => _role == 'owner';

  void setRole(String role) {
    _role = role;
    notifyListeners();
  }

  // ── Step 1 controllers ────────────────────────────────────────────────────

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  static const _phonePrefix = '+966';

  OnboardingController() {
    phoneController.text = _phonePrefix;
    phoneController.addListener(_guardPhonePrefix);
  }

  void _guardPhonePrefix() {
    if (!phoneController.text.startsWith(_phonePrefix)) {
      final digits =
          phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final restored = _phonePrefix + digits;
      phoneController.value = TextEditingValue(
        text: restored,
        selection: TextSelection.collapsed(offset: restored.length),
      );
    }
  }

  // ── Step 2 controllers ────────────────────────────────────────────────────

  final nationalIdController = TextEditingController();

  File? _licenseFile;
  File? get licenseFile => _licenseFile;
  bool get hasDrivingLicense => _licenseFile != null;

  bool _acceptedTerms = false;
  bool get acceptedTerms => _acceptedTerms;

  void toggleTerms(bool? value) {
    _acceptedTerms = value ?? false;
    notifyListeners();
  }

  Future<void> pickDrivingLicense() async {
    final picked = await ImagePicker().pickImage(
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

  // ── Loading ───────────────────────────────────────────────────────────────

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── Step 1 validators ─────────────────────────────────────────────────────

  String? validateFullName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your full name';
    if (v.trim().length < 3) return 'Full name is too short';
    return null;
  }

  String? validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(v.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePhone(String? v) {
    final val = v?.trim() ?? '';
    if (val == _phonePrefix || val.length <= _phonePrefix.length) {
      return 'Please enter your phone number';
    }
    final digits = val.substring(_phonePrefix.length);
    if (!RegExp(r'^5[0-9]{8}$').hasMatch(digits)) {
      return 'Enter a valid Saudi number (9 digits starting with 5)';
    }
    return null;
  }

  String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Please enter your password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != passwordController.text) return 'Passwords do not match';
    return null;
  }

  // ── Step 2 validators ─────────────────────────────────────────────────────

  String? validateNationalId(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter your national ID';
    if (!RegExp(r'^[0-9]{8,20}$').hasMatch(v.trim())) {
      return 'Please enter a valid national ID';
    }
    return null;
  }

  // ── Step 2 submit → send OTP ──────────────────────────────────────────────
  //
  // Validates identity fields, runs duplicate checks, sends OTP email,
  // then navigates to EmailOtpScreen.

  Future<void> proceedFromStep2(
    BuildContext context,
    GlobalKey<FormState> formKey,
    void Function() navigateToOtp,
  ) async {
    if (!formKey.currentState!.validate()) return;

    if (isRenter && !hasDrivingLicense) {
      _showError(context, 'Please upload your driving license');
      return;
    }

    if (!_acceptedTerms) {
      _showError(context, 'Please accept the Terms and Conditions');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final phoneExists =
          await FirebaseService().isPhoneExists(phoneController.text.trim());
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

      await FirebaseService().sendSignupOtp(emailController.text.trim());

      if (context.mounted) navigateToOtp();
    } catch (e) {
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
    passwordController.dispose();
    confirmPasswordController.dispose();
    nationalIdController.dispose();
    super.dispose();
  }
}
