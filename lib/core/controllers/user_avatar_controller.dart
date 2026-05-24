import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Streams the current user's profileImageUrl from Firestore.
/// Provided at the root of the widget tree so every avatar widget
/// (home screen button, profile header, etc.) stays in sync.
class UserAvatarController extends ChangeNotifier {
  String _profileImageUrl = '';

  String get profileImageUrl => _profileImageUrl;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _docSub;

  UserAvatarController() {
    _authSub = FirebaseAuth.instance
        .authStateChanges()
        .listen(_onAuthChanged);
  }

  void _onAuthChanged(User? user) {
    _docSub?.cancel();
    _docSub = null;

    if (user == null) {
      if (_profileImageUrl.isNotEmpty) {
        _profileImageUrl = '';
        notifyListeners();
      }
      return;
    }

    _docSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snap) {
      final url = (snap.data()?['profileImageUrl'] as String?) ?? '';
      if (url != _profileImageUrl) {
        _profileImageUrl = url;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _docSub?.cancel();
    super.dispose();
  }
}
