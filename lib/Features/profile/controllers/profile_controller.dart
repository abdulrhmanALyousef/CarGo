import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/dataSource/local_data/preferences_manager.dart';
import '../../../core/dataSource/remote_data/firebase_service.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/errors/app_messenger.dart';
import '../../auth/login_screen.dart';

class ProfileController extends ChangeNotifier {
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  bool _isSaving = false;
  File? _pendingProfileImage;

  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  File? get pendingProfileImage => _pendingProfileImage;

  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  String get fullName => _userData?['fullName'] ?? '';
  String get email =>
      _userData?['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
  String get phone => _userData?['phone'] ?? '';
  String get nationalId => _userData?['nationalId'] ?? '';
  String get profileImageUrl => _userData?['profileImageUrl'] ?? '';
  String get licenseUrl => _userData?['licenseUrl'] ?? '';
  String get licenseStatus =>
      _userData?['licenseVerificationStatus'] ?? 'pending';
  String get role => _userData?['role'] ?? 'renter';

  bool get isOwner {
    // Firestore stores roles as an array: ['owner'] or ['renter']
    final roles = _userData?['roles'];
    if (roles is List) return roles.contains('owner');
    // Fallback: legacy 'role' string field
    return role == 'owner';
  }

  String get maskedNationalId {
    if (nationalId.isEmpty) return '—';
    if (nationalId.length <= 4) return nationalId;
    return '${'*' * (nationalId.length - 4)}${nationalId.substring(nationalId.length - 4)}';
  }

  ProfileController() {
    loadUserData();
  }

  Future<void> loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _userData = await FirebaseService().getUserData(uid: uid);
    } catch (e) {
      debugPrint('[ProfileController] loadUserData: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickProfileImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      _pendingProfileImage = File(picked.path);
      notifyListeners();
    }
  }

  Future<void> pickAndUploadLicense(BuildContext context) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _isSaving = true;
    notifyListeners();

    try {
      final url = await FirebaseService().uploadDrivingLicense(
        uid: uid,
        imageFile: File(picked.path),
      );
      await FirebaseService().updateUserLicenseUrl(uid: uid, licenseUrl: url);
      _userData = {
        ..._userData ?? {},
        'licenseUrl': url,
        'licenseVerificationStatus': 'pending',
      };
      AppMessenger.showSuccess(context, 'License uploaded. Pending verification.');
    } catch (e) {
      if (context.mounted) AppMessenger.showError(context, ErrorHandler.handle(e, tag: 'uploadLicense').userMessage);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile({
    required BuildContext context,
    required String fullName,
    required String phone,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    _isSaving = true;
    notifyListeners();

    try {
      String? newImageUrl;
      if (_pendingProfileImage != null) {
        newImageUrl = await FirebaseService().uploadProfileImage(
          uid: uid,
          imageFile: _pendingProfileImage!,
        );
      }

      await FirebaseService().updateUserProfile(
        uid: uid,
        fullName: fullName,
        phone: phone,
        profileImageUrl: newImageUrl,
      );

      _userData = {
        ..._userData ?? {},
        'fullName': fullName,
        'phone': phone,
        if (newImageUrl != null) 'profileImageUrl': newImageUrl,
      };
      _pendingProfileImage = null;

      AppMessenger.showSuccess(context, 'Profile updated successfully.');
      return true;
    } catch (e) {
      if (context.mounted) AppMessenger.showError(context, ErrorHandler.handle(e, tag: 'saveProfile').userMessage);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await FirebaseService().logout();
      await PreferencesManager().clear();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (context.mounted) AppMessenger.showError(context, ErrorHandler.handle(e, tag: 'logout').userMessage);
    }
  }

  Future<void> confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _isLoading = true;
    notifyListeners();

    try {
      await FirebaseService().deleteAccount();
      await PreferencesManager().clear();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (context.mounted) {
        AppMessenger.showError(context, ErrorHandler.handle(e, tag: 'deleteAccount').userMessage);
      }
    }
  }
}
