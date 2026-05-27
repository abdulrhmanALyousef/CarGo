import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cargo/models/wallet_model.dart';

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
      debugPrint('Sign Up Error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected Error during Sign Up: $e');
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
      debugPrint('Login Error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected Error during Login: $e');
      rethrow;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Logout Error: $e');
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

  // ── SMS OTP (Cloud Functions — Authentica) ───────────────────────────────

  /// Sends a 4-digit OTP via SMS to [phone] (+966XXXXXXXXX format).
  Future<void> sendSmsOtp(String phone) async {
    final callable = _functions.httpsCallable('sendSmsOtp');
    await callable.call<dynamic>({'phone': phone});
  }

  /// Verifies SMS OTP. If [uid] is provided, marks the user's phone as verified.
  Future<void> verifySmsOtp({
    required String phone,
    required String code,
    String? uid,
  }) async {
    final callable = _functions.httpsCallable('verifySmsOtp');
    await callable.call<dynamic>({
      'phone': phone,
      'code': code,
      if (uid != null) 'uid': uid,
    });
  }

  /// Sends a 2FA login OTP to the user's registered phone.
  /// Returns `{ twoFactorRequired: bool, maskedPhone: String }`.
  Future<Map<String, dynamic>> sendLoginOtp(String uid) async {
    final callable = _functions.httpsCallable('sendLoginOtp');
    final result = await callable.call<dynamic>({'uid': uid});
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Verifies the 2FA login OTP for [uid].
  Future<void> verifyLoginOtp({
    required String uid,
    required String code,
  }) async {
    final callable = _functions.httpsCallable('verifyLoginOtp');
    await callable.call<dynamic>({'uid': uid, 'code': code});
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

  // ── Profile Image ─────────────────────────────────────────────────────────

  Future<String> uploadProfileImage({
    required String uid,
    required File imageFile,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('User must be authenticated before uploading files');
    }
    final ref = _storage.ref().child('profile_images/$uid/profile.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  // ── Update User Profile ───────────────────────────────────────────────────

  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
    required String phone,
    String? profileImageUrl,
  }) async {
    final updates = <String, dynamic>{
      'fullName': fullName,
      'phone': phone,
    };
    if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
    await _firestore.collection('users').doc(uid).update(updates);
    await _auth.currentUser?.updateDisplayName(fullName);
  }

  // ── Delete Account ────────────────────────────────────────────────────────

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    await _firestore.collection('users').doc(user.uid).delete();
    await user.delete();
  }

  // ── Favorites ─────────────────────────────────────────────────────────────

  Future<void> toggleFavorite(String carId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');
    final docRef = _firestore.collection('users').doc(uid);
    final doc = await docRef.get();
    final favorites = List<String>.from(doc.data()?['favorites'] ?? []);
    if (favorites.contains(carId)) {
      await docRef.update({'favorites': FieldValue.arrayRemove([carId])});
    } else {
      await docRef.update({'favorites': FieldValue.arrayUnion([carId])});
    }
  }

  Future<bool> isFavorite(String carId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final doc = await _firestore.collection('users').doc(uid).get();
    final favorites = List<String>.from(doc.data()?['favorites'] ?? []);
    return favorites.contains(carId);
  }

  // ── Update User Roles ─────────────────────────────────────────────────────

  Future<void> updateUserRoles({
    required String uid,
    required List<String> roles,
  }) async {
    await _firestore.collection('users').doc(uid).update({'roles': roles});
  }

  Future<List<Map<String, dynamic>>> getFavoriteCars() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    final doc = await _firestore.collection('users').doc(uid).get();
    final ids = List<String>.from(doc.data()?['favorites'] ?? []);
    if (ids.isEmpty) return [];
    final result = <Map<String, dynamic>>[];
    for (int i = 0; i < ids.length; i += 10) {
      final batch = ids.sublist(i, (i + 10).clamp(0, ids.length));
      final snap = await _firestore
          .collection('cars')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      result.addAll(snap.docs.map((d) => {'id': d.id, ...d.data()}));
    }
    return result;
  }

  // ── Wallet ────────────────────────────────────────────────────────────────

  Stream<WalletModel> streamWallet(String ownerId) {
    return _firestore
        .collection('wallets')
        .doc(ownerId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return WalletModel.empty(ownerId);
      return WalletModel.fromMap(snap.data()!, ownerId);
    });
  }

  Future<WalletModel> getOrCreateWallet(String ownerId) async {
    final ref = _firestore.collection('wallets').doc(ownerId);
    final snap = await ref.get();
    if (snap.exists) return WalletModel.fromMap(snap.data()!, ownerId);
    final wallet = WalletModel.empty(ownerId);
    await ref.set(wallet.toMap());
    return wallet;
  }

  Future<List<TransactionModel>> getTransactions(String ownerId) async {
    try {
      // Single equality filter — no composite index required.
      // Type filtering and sorting are done in memory to avoid a Firestore
      // composite index that may not be deployed yet.
      final snap = await _firestore
          .collection('transactions')
          .where('ownerId', isEqualTo: ownerId)
          .get();
      final docs = snap.docs
          .where((d) => d.data()['type'] == 'booking_payout')
          .toList()
        ..sort((a, b) {
          final aTs = a.data()['createdAt'];
          final bTs = b.data()['createdAt'];
          final aMs = aTs is Timestamp ? aTs.millisecondsSinceEpoch : 0;
          final bMs = bTs is Timestamp ? bTs.millisecondsSinceEpoch : 0;
          return bMs.compareTo(aMs);
        });
      return docs
          .take(50)
          .map((d) => TransactionModel.fromMap(d.data(), d.id))
          .toList();
    } catch (e) {
      debugPrint('[FirebaseService] getTransactions: $e');
      return [];
    }
  }

  Future<List<WithdrawalModel>> getWithdrawals(String ownerId) async {
    try {
      final snap = await _firestore
          .collection('payouts')
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((d) => WithdrawalModel.fromMap(d.data(), d.id))
          .toList();
    } catch (e) {
      debugPrint('[FirebaseService] getWithdrawals: $e');
      return [];
    }
  }

  /// Atomically deducts [amount] from wallet and records a withdrawal request.
  /// Throws if balance is insufficient.
  Future<void> requestWithdrawal({
    required String ownerId,
    required double amount,
    required String bankName,
    required String iban,
    required String accountHolderName,
  }) async {
    final walletRef = _firestore.collection('wallets').doc(ownerId);

    await _firestore.runTransaction((txn) async {
      final walletSnap = await txn.get(walletRef);
      final currentBalance = walletSnap.exists
          ? (walletSnap.data()?['availableBalance'] as num?)?.toDouble() ?? 0.0
          : 0.0;

      if (currentBalance < amount) throw Exception('Insufficient balance');

      final payoutRef = _firestore.collection('payouts').doc();
      txn.set(payoutRef, {
        'ownerId': ownerId,
        'amount': amount,
        'bankName': bankName,
        'iban': iban,
        'accountHolderName': accountHolderName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (walletSnap.exists) {
        txn.update(walletRef, {
          'availableBalance': FieldValue.increment(-amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        txn.set(walletRef, {
          'ownerId': ownerId,
          'availableBalance': 0.0,
          'pendingBalance': 0.0,
          'totalEarnings': 0.0,
          'thisMonthRevenue': 0.0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      // Withdrawal request is already recorded in the 'payouts' collection above.
      // No separate 'transactions' entry is written here — that collection is
      // reserved for booking payouts only, so the UI never shows a phantom
      // Withdrawal entry in Transaction History.
    });
  }

  /// Called when a booking transitions to 'completed'.
  /// Credits the owner 90% of the booking total and logs a payout transaction.
  /// A [walletSettled] guard on the booking document prevents duplicate credits.
  Future<void> creditOwnerForBooking({
    required String ownerId,
    required String bookingId,
    required double bookingTotal,
  }) async {
    const platformFeeRate = 0.10;
    final ownerShare = bookingTotal * (1 - platformFeeRate);
    final platformFee = bookingTotal * platformFeeRate;
    final walletRef = _firestore.collection('wallets').doc(ownerId);
    final bookingRef = _firestore.collection('bookings').doc(bookingId);

    await _firestore.runTransaction((txn) async {
      final bookingSnap = await txn.get(bookingRef);
      // Idempotency guard — do not credit twice.
      if (bookingSnap.data()?['walletSettled'] == true) return;

      final walletSnap = await txn.get(walletRef);
      if (walletSnap.exists) {
        txn.update(walletRef, {
          'availableBalance': FieldValue.increment(ownerShare),
          'totalEarnings': FieldValue.increment(ownerShare),
          'thisMonthRevenue': FieldValue.increment(ownerShare),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        txn.set(walletRef, {
          'ownerId': ownerId,
          'availableBalance': ownerShare,
          'pendingBalance': 0.0,
          'totalEarnings': ownerShare,
          'thisMonthRevenue': ownerShare,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Mark booking as settled and store the fee breakdown.
      txn.update(bookingRef, {
        'walletSettled': true,
        'settledAt': FieldValue.serverTimestamp(),
        'platformFee': platformFee,
        'ownerEarning': ownerShare,
      });

      final txnRef = _firestore.collection('transactions').doc();
      txn.set(txnRef, {
        'ownerId': ownerId,
        'bookingId': bookingId,
        'amount': ownerShare,
        'platformFee': platformFee,
        'type': 'booking_payout',
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}