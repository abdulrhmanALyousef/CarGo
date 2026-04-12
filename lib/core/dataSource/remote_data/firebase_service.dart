import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() => _instance;

  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  // ── Sign Up ───────────────────────────────────────────────────────────────

  Future<User?> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? nationalId,
    String? licenseUrl,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
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
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print('Sign Up Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Error during Sign Up: $e');
      rethrow;
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print('Login Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected Error during Login: $e');
      rethrow;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Logout Error: $e');
      rethrow;
    }
  }

  // ── Driving License ───────────────────────────────────────────────────────

  Future<String> uploadDrivingLicense({
    required String uid,
    required File imageFile,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('User must be authenticated before uploading files');
    }
    final ref = _storage.ref().child('driving_licenses/$uid/license.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  Future<void> updateUserLicenseUrl({
    required String uid,
    required String licenseUrl,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'licenseUrl': licenseUrl,
    });
  }

  // ── Duplicate checks ──────────────────────────────────────────────────────

  Future<bool> isPhoneExists(String phone) async {
    final query = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<bool> isNationalIdExists(String nationalId) async {
    final query = await _firestore
        .collection('users')
        .where('nationalId', isEqualTo: nationalId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // ── Phone Auth ────────────────────────────────────────────────────────────

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

  // ── Auth state ────────────────────────────────────────────────────────────

  bool isUserLoggedIn() => _auth.currentUser != null;

  // ── Firestore reads ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCars() async {
    final snapshot = await _firestore.collection('cars').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> getReviews(String carId) async {
    final snapshot = await _firestore
        .collection('Reviews')
        .where('carId', isEqualTo: carId)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, dynamic>?> getUserData({required String uid}) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  // ── Sign-up OTP (Cloud Functions) ────────────────────────────────────────

  /// Sends a 6-digit OTP to [email] for sign-up verification.
  /// The Firebase Auth user is NOT created until [verifySignupOtp] succeeds.
  Future<void> sendSignupOtp(String email) async {
    final callable = _functions.httpsCallable('sendSignupOtp');
    await callable.call<dynamic>({'email': email});
  }

  /// Verifies the sign-up OTP and creates the Firebase Auth + Firestore user.
  /// [password] is transmitted over HTTPS and never stored in Firestore.
  Future<void> verifySignupOtp({
    required String email,
    required String code,
    required String password,
    required String fullName,
    String phone = '',
    String nationalId = '',
  }) async {
    final callable = _functions.httpsCallable('verifySignupOtp');
    await callable.call<dynamic>({
      'email': email,
      'code': code,
      'password': password,
      'fullName': fullName,
      'phone': phone,
      'nationalId': nationalId,
    });
  }

  // ── Password-reset OTP (Cloud Functions) ─────────────────────────────────

  Future<void> sendOtp(String email) async {
    final callable = _functions.httpsCallable('sendOtp');
    await callable.call<dynamic>({'email': email});
  }

  Future<void> verifyOtp(String email, String code) async {
    final callable = _functions.httpsCallable('verifyOtp');
    await callable.call<dynamic>({'email': email, 'code': code});
  }

  Future<void> resetPasswordWithOtp(String email, String newPassword) async {
    final callable = _functions.httpsCallable('resetPassword');
    await callable.call<dynamic>({'email': email, 'newPassword': newPassword});
  }
}