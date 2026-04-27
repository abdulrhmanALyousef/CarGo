// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo/models/booking_model.dart';
import 'package:cargo/models/car_model.dart';

// ── Trip Entry ────────────────────────────────────────────────────────────────
// Pairs a Booking with its associated Car (nullable — car may have been removed).
class TripEntry {
  final Booking booking;
  final Car? car;
  TripEntry({required this.booking, this.car});
}

class MyTripsController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── State ─────────────────────────────────────────────────────────────────
  List<TripEntry> _trips = [];
  bool _isLoading = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<TripEntry> get trips => _trips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  MyTripsController() {
    fetchTrips();
  }

  // ── Data Fetch ────────────────────────────────────────────────────────────
  Future<void> fetchTrips() async {
    if (!isAuthenticated) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Fetch all bookings that belong to the current user.
      final bookingsSnap = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .get();

      final bookings = bookingsSnap.docs
          .map((doc) => Booking.fromMap(doc.data()))
          .toList();

      // Resolve car details for each booking.
      final entries = <TripEntry>[];
      for (final booking in bookings) {
        Car? car;
        try {
          final carDoc =
              await _firestore.collection('cars').doc(booking.carId).get();
          if (carDoc.exists) {
            car = Car.fromJson({'id': carDoc.id, ...carDoc.data()!});
          }
        } catch (e) {
          print('[MyTripsController] Could not fetch car ${booking.carId}: $e');
        }
        entries.add(TripEntry(booking: booking, car: car));
      }

      // Newest bookings first.
      entries.sort(
        (a, b) => b.booking.createdAt.compareTo(a.booking.createdAt),
      );

      _trips = entries;
    } catch (e) {
      print('[MyTripsController] fetchTrips error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}