// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo/models/car_model.dart';
import 'package:cargo/core/errors/error_handler.dart';
import 'package:cargo/core/errors/app_messenger.dart';

class ActiveListingsController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  List<Car> _listings = [];
  // carId → count of confirmed/approved bookings (active rentals)
  Map<String, int> _activeBookingCount = {};
  bool _isLoading = false;
  String? _error;
  String? _actionCarId;

  List<Car> get listings => _listings;
  Map<String, int> get activeBookingCount => _activeBookingCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get actionCarId => _actionCarId;
  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  static const _visibleStatuses = {'at_hub', 'available', 'ready_for_rental'};

  ActiveListingsController() {
    fetch();
  }

  Future<void> fetch() async {
    if (!isAuthenticated) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final snap = await _db
          .collection('cars')
          .where('ownerId', isEqualTo: uid)
          .get();

      _listings = snap.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Car.fromJson(data);
          })
          .where((c) => _visibleStatuses.contains(c.hubStatus))
          .toList();

      // For each listing, count active bookings (approved + confirmed)
      _activeBookingCount = {};
      for (final car in _listings) {
        final bSnap = await _db
            .collection('bookings')
            .where('carId', isEqualTo: car.id)
            .where('status', whereIn: ['approved', 'confirmed'])
            .get();
        _activeBookingCount[car.id] = bSnap.docs.length;
      }
    } catch (e) {
      _error = ErrorHandler.handle(e, tag: 'ActiveListingsController').userMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Pause — makes the listing invisible to renters ────────────────────────
  Future<void> pauseListing(Car car, BuildContext context) async {
    _actionCarId = car.id;
    notifyListeners();
    try {
      await _db.collection('cars').doc(car.id).update({
        'hubStatus': 'unavailable',
        'available': false,
      });
      _listings.removeWhere((c) => c.id == car.id);
      notifyListeners();
      AppMessenger.showInfo(context, 'Listing paused — hidden from renters.');
    } catch (e) {
      AppMessenger.showError(context, ErrorHandler.handle(e, tag: 'pauseListing').userMessage);
    } finally {
      _actionCarId = null;
      notifyListeners();
    }
  }

}
