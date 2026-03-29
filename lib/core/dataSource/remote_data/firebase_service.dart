import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload driving license image to Firebase Storage
  /// Returns the download URL
  Future<String> uploadDrivingLicense({
    required String uid,
    required File imageFile,
  }) async {
    final ref = _storage.ref().child('driving_licenses/$uid/license.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  /// Update licenseUrl field in existing user document
  Future<void> updateUserLicenseUrl({
    required String uid,
    required String licenseUrl,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'licenseUrl': licenseUrl,
    });
  }

  /// Check if phone number already exists in Firestore
  Future<bool> isPhoneExists(String phone) async {
    final query = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  /// Check if national ID already exists in Firestore
  Future<bool> isNationalIdExists(String nationalId) async {
    final query = await _firestore
        .collection('users')
        .where('nationalId', isEqualTo: nationalId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  /// Sign Up with Email and Password
  Future<User?> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? nationalId,
    String? licenseUrl,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user != null) {
        await user.updateDisplayName(fullName);

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': fullName,
          'email': email,
          'phone': phone ?? '',
          'nationalId': nationalId ?? '',
          'licenseUrl': licenseUrl ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('Sign Up Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Error during Sign Up: $e');
      rethrow;
    }
  }

  /// Login with Email and Password
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Login should rely on Firebase Auth only; no Firestore writes here.
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Login Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Error during Login: $e');
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Logout Error: $e');
      rethrow;
    }
  }

  /// Get Current User
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Check if user is logged in
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Get User Stream (for real-time auth state changes)
  Stream<User?> getUserStream() {
    return _auth.authStateChanges();
  }

  /// Reset Password
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('Reset Password Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Error during Reset Password: $e');
      rethrow;
    }
  }

  /// Get User Data from Firestore
  Future<Map<String, dynamic>?> getUserData({required String uid}) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Get User Data Error: $e');
      rethrow;
    }
  }

  /// Fetch all cars from Firestore
  Future<List<Map<String, dynamic>>> getCars() async {
    try {
      final snapshot = await _firestore.collection('cars').get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Get Cars Error: $e');
      rethrow;
    }
  }

  /// Send phone verification code
  Future<void> sendPhoneVerification({
    required String phoneNumber,
    required PhoneVerificationCompleted onCompleted,
    required PhoneVerificationFailed onFailed,
    required PhoneCodeSent onCodeSent,
    required PhoneCodeAutoRetrievalTimeout onTimeout,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: timeout,
      verificationCompleted: onCompleted,
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onTimeout,
    );
  }

  /// Sign in with the SMS verification code
  Future<UserCredential> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }
}
