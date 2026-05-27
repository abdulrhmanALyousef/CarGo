// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo/models/car_model.dart';

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
        print('[MyCarsController] stream error: $e');
        _error = e.toString();
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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing resumed — visible to renters again.'),
            backgroundColor: Color(0xFF1565C0),
          ),
        );
      }
    } on FirebaseException catch (e) {
      _showError(context,
          'Firebase error [${e.code}]: ${e.message ?? e.toString()}');
    } catch (e) {
      _showError(context, e.toString());
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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Delivery request submitted. A CarGo employee will verify your vehicle shortly.',
            ),
            backgroundColor: Color(0xFFE65100),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } on FirebaseException catch (e) {
      _showError(context,
          'Firebase error [${e.code}]: ${e.message ?? e.toString()}');
    } catch (e) {
      _showError(context, e.toString());
    }
  }

  /// Called when owner acknowledges a rejection and wants to re-deliver.
  Future<void> acknowledgeRejection(Car car, BuildContext context) async {
    try {
      await _firestore.collection('cars').doc(car.id).update({
        'hubStatus': 'awaiting_dropoff',
        'status': 'awaiting_owner_dropoff',
        'available': false,
        'rejectionReason': null,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Status reset. Please re-deliver your vehicle to the hub.'),
            backgroundColor: Color(0xFF1565C0),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on FirebaseException catch (e) {
      _showError(context,
          'Firebase error [${e.code}]: ${e.message ?? e.toString()}');
    } catch (e) {
      _showError(context, e.toString());
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
    } on FirebaseException catch (e) {
      _showError(context,
          'Firebase error [${e.code}]: ${e.message ?? e.toString()}');
    }
  }

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
