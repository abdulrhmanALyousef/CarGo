import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';
import 'package:cargo/core/dataSource/local_data/preferences_manager.dart';
import 'package:cargo/Features/Main/main_screen.dart';

class SignUpController extends ChangeNotifier {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nationalIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

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
    if (value == null || value.trim().isEmpty) return 'Please enter your phone number';
    if (!RegExp(r'^[0-9+]{8,15}$').hasMatch(value.trim())) {
      return 'Please enter a valid phone number';
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
      // ─── Check duplicates ─────────────────────────────────────────────
      final phoneExists = await FirebaseService()
          .isPhoneExists(phoneController.text.trim());
      if (phoneExists) {
        _showError(context, 'This phone number is already registered');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final nationalIdExists = await FirebaseService()
          .isNationalIdExists(nationalIdController.text.trim());
      if (nationalIdExists) {
        _showError(context, 'This national ID is already registered');
        _isLoading = false;
        notifyListeners();
        return;
      }

      // ─── Create Auth account ──────────────────────────────────────────
      final User? user = await FirebaseService().signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        fullName: fullNameController.text.trim(),
        phone: phoneController.text.trim(),
        nationalId: nationalIdController.text.trim(),
      );

      if (user == null) {
        _showError(context, 'Sign up failed');
        _isLoading = false;
        notifyListeners();
        return;
      }

      // ─── Upload driving license ───────────────────────────────────────
      final licenseUrl = await FirebaseService().uploadDrivingLicense(
        uid: user.uid,
        imageFile: _licenseFile!,
      );

      // ─── Update Firestore with license URL ────────────────────────────
      await FirebaseService().updateUserLicenseUrl(
        uid: user.uid,
        licenseUrl: licenseUrl,
      );

      await PreferencesManager().setBool('isLoggedIn', true);
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      _showError(context, 'Sign up failed: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _showError(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    nationalIdController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
