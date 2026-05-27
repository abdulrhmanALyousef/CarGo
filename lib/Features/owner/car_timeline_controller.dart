// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo/models/car_model.dart';
import 'package:cargo/models/booking_model.dart';

class CarTimelineController extends ChangeNotifier {
  final Car car;

  CarTimelineController({required this.car}) {
    _load();
  }

  final _db = FirebaseFirestore.instance;

  List<Booking> _bookings = [];
  final Map<String, String> _renterNames = {};
  bool _isLoading = true;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  String renterName(String userId) => _renterNames[userId] ?? 'Unknown';

  // ── Computed groups ───────────────────────────────────────────────────────

  List<Booking> get activeBookings {
    final now = DateTime.now();
    return _bookings.where((b) {
      if (b.status == 'in_trip') return true;
      if (b.status == 'confirmed' &&
          !now.isBefore(b.startDate) &&
          !now.isAfter(b.endDate)) {
        return true;
      }
      return false;
    }).toList();
  }

  List<Booking> get pendingBookings =>
      _bookings.where((b) => b.status == 'pending').toList();

  List<Booking> get upcomingBookings {
    final now = DateTime.now();
    return _bookings.where((b) {
      if (b.status == 'approved') return true;
      if (b.status == 'confirmed' && b.startDate.isAfter(now)) return true;
      return false;
    }).toList();
  }

  List<Booking> get completedBookings {
    final now = DateTime.now();
    return _bookings.where((b) {
      if (b.status == 'completed') return true;
      if (b.status == 'confirmed' && b.endDate.isBefore(now)) return true;
      return false;
    }).toList();
  }

  List<Booking> get cancelledBookings =>
      _bookings.where((b) => b.status == 'cancelled').toList();

  double get totalEarnings {
    final now = DateTime.now();
    return _bookings
        .where((b) =>
            b.status == 'completed' ||
            (b.status == 'confirmed' && b.endDate.isBefore(now)))
        .fold(0.0, (acc, b) => acc + b.totalPrice * 0.9);
  }

  Future<void> refresh() => _load();

  // ── Data load ─────────────────────────────────────────────────────────────

  Future<void> _load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snap = await _db
          .collection('bookings')
          .where('carId', isEqualTo: car.id)
          .orderBy('startDate')
          .get();

      _bookings = snap.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['bookingId'] ??= doc.id;
        return Booking.fromMap(data);
      }).toList();

      // Resolve renter names (cached per load)
      final renterIds = _bookings.map((b) => b.userId).toSet();
      for (final uid in renterIds) {
        if (_renterNames.containsKey(uid)) continue;
        try {
          final uDoc = await _db.collection('users').doc(uid).get();
          _renterNames[uid] =
              (uDoc.data()?['fullName'] as String?) ?? 'Unknown';
        } catch (_) {
          _renterNames[uid] = 'Unknown';
        }
      }
    } catch (e) {
      print('[CarTimelineController] load error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
