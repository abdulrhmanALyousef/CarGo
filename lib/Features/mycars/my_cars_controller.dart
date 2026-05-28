// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo/models/car_model.dart';
import 'package:cargo/core/errors/error_handler.dart';
import 'package:cargo/core/errors/app_messenger.dart';

class MyCarsController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Car> _cars = [];
  bool _isLoading = true;
  String? _error;

  List<Car> get cars => _cars;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  StreamSubscription<QuerySnapshot>? _carsSubscription;

  MyCarsController() {
    _startStream();
  }

  @override
  void dispose() {
    _carsSubscription?.cancel();
    super.dispose();
  }

  // ── Real-Time Stream ──────────────────────────────────────────────────────
  // Owner sees ALL their cars regardless of status, updated in real-time.
  // When a renter pays and the car moves to 'reserved', the owner's screen
  // immediately shows the updated status without needing to pull-to-refresh.
  void _startStream() {
    if (!isAuthenticated) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    final uid = FirebaseAuth.instance.currentUser!.uid;

    _carsSubscription = _firestore
        .collection('cars')
        .where('ownerId', isEqualTo: uid)
        .snapshots()
        .listen(
      (snap) {
        _cars = snap.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          return Car.fromJson(data);
        }).toList();
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = ErrorHandler.handle(e, tag: 'MyCarsController').userMessage;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Kept for explicit pull-to-refresh.
  Future<void> fetchMyCars() async {
    _carsSubscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();
    _startStream();
  }

  Future<void> resumeListing(Car car, BuildContext context) async {
    try {
      await _firestore.collection('cars').doc(car.id).update({
        'hubStatus': 'ready_for_rental',
        'status': 'ready_for_rental',
        'available': true,
      });

      AppMessenger.showInfo(context, 'Listing resumed — visible to renters again.');
    } catch (e) {
      AppMessenger.showError(context, ErrorHandler.handle(e, tag: 'resumeListing').userMessage);
    }
  }

  Future<void> confirmDelivery(Car car, BuildContext context) async {
    try {
      await _firestore.collection('cars').doc(car.id).update({
        'hubStatus': 'awaiting_employee_verification',
        'status': 'awaiting_employee_verification',
        'available': false,
        'deliveryRequestedAt': FieldValue.serverTimestamp(),
        'isVerifiedAtHub': false,
        'verifiedByEmployeeId': null,
        'verifiedAt': null,
        'rejectionReason': null,
      });

      AppMessenger.showInfo(
        context,
        'Delivery request submitted. A CarGo employee will verify your vehicle shortly.',
        color: const Color(0xFFE65100),
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      AppMessenger.showError(context, ErrorHandler.handle(e, tag: 'confirmDelivery').userMessage);
    }
  }

  Future<void> acknowledgeRejection(Car car, BuildContext context) async {
    try {
      await _firestore.collection('cars').doc(car.id).update({
        'hubStatus': 'awaiting_dropoff',
        'status': 'awaiting_owner_dropoff',
        'available': false,
        'rejectionReason': null,
      });

      AppMessenger.showInfo(
        context,
        'Status reset. Please re-deliver your vehicle to the hub.',
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      AppMessenger.showError(context, ErrorHandler.handle(e, tag: 'acknowledgeRejection').userMessage);
    }
  }

  Future<void> setHubStatus(
    Car car,
    String newStatus,
    BuildContext context,
  ) async {
    try {
      final update = <String, dynamic>{'hubStatus': newStatus, 'status': newStatus};
      if (newStatus == 'ready_for_rental' || newStatus == 'at_hub') {
        update['available'] = true;
      } else {
        update['available'] = false;
      }
      await _firestore.collection('cars').doc(car.id).update(update);
    } catch (e) {
      AppMessenger.showError(context, ErrorHandler.handle(e, tag: 'setHubStatus').userMessage);
    }
  }
}
