import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../dataSource/remote_data/firebase_service.dart';

/// Global favorites state — streams the current user's favorited car IDs
/// from Firestore so every CarCard reflects the correct heart state in real time.
class FavoritesNotifier extends ChangeNotifier {
  Set<String> _ids = {};
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot>? _docSub;

  FavoritesNotifier() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  bool isFavorited(String carId) => _ids.contains(carId);

  Future<void> toggle(String carId) async {
    final wasIn = _ids.contains(carId);
    // Optimistic update
    if (wasIn) {
      _ids.remove(carId);
    } else {
      _ids.add(carId);
    }
    notifyListeners();

    try {
      await FirebaseService().toggleFavorite(carId);
      // Firestore stream confirms the real state
    } catch (e) {
      // Revert on error; the Firestore stream will also revert
      if (wasIn) {
        _ids.add(carId);
      } else {
        _ids.remove(carId);
      }
      notifyListeners();
      debugPrint('[FavoritesNotifier] toggle error: $e');
    }
  }

  void _onAuthChanged(User? user) {
    _docSub?.cancel();
    _docSub = null;

    if (user == null) {
      _ids = {};
      notifyListeners();
      return;
    }

    _docSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snap) {
      _ids = Set<String>.from(snap.data()?['favorites'] ?? []);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _docSub?.cancel();
    super.dispose();
  }
}
