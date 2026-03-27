import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  String? _drivingLicenseFileName;
  String? get drivingLicenseFileName => _drivingLicenseFileName;
  bool get hasDrivingLicense => _drivingLicenseFileName != null;

  void toggleTerms(bool? value) {
    _acceptedTerms = value ?? false;
    notifyListeners();
  }

  void pickDrivingLicense() {
    // TODO: wire real file_picker here
    _drivingLicenseFileName = 'driving_license.png';
    notifyListeners();
  }

  void clearDrivingLicense() {
    _drivingLicenseFileName = null;
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
      final User? user = await FirebaseService().signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        fullName: fullNameController.text.trim(),
        phone: phoneController.text.trim(),
        nationalId: nationalIdController.text.trim(),
      );

      if (user != null) {
        await PreferencesManager().setBool('isLoggedIn', true);
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      } else {
        _showError(context, 'Sign up failed');
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

