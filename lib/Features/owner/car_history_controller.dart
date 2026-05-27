// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo/models/booking_model.dart';
import 'package:cargo/Features/owner/owner_models.dart';

class CarHistoryController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  List<BookingDetail> _history = [];
  bool _isLoading = false;
  String? _error;

  List<BookingDetail> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  static bool _isPaidTerminal(String status) =>
      status == 'completed' || status == 'confirmed';

  double get totalEarnings => _history
      .where((d) => _isPaidTerminal(d.booking.status))
      .fold(0.0, (acc, d) => acc + d.booking.totalPrice * 0.9);

  int get completedCount =>
      _history.where((d) => _isPaidTerminal(d.booking.status)).length;

  int get cancelledCount =>
      _history.where((d) => d.booking.status == 'cancelled').length;

  CarHistoryController() {
    fetch();
  }

  Future<void> fetch() async {
    if (!isAuthenticated) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Step 1 — get owner's cars
      final carsSnap = await _db
          .collection('cars')
          .where('ownerId', isEqualTo: uid)
          .get();

      if (carsSnap.docs.isEmpty) {
        _history = [];
        return;
      }

      final carMeta = <String, ({String name, String image})>{};
      for (final doc in carsSnap.docs) {
        final d = doc.data();
        final images = (d['images'] as List?)?.cast<String>() ?? [];
        carMeta[doc.id] = (
          name: '${d['brand'] ?? ''} ${d['model'] ?? ''}'.trim(),
          image: images.isNotEmpty ? images.first : '',
        );
      }

      // Step 2 — query completed/cancelled bookings (chunks of 30)
      final carIds = carMeta.keys.toList();
      final allDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      for (var i = 0; i < carIds.length; i += 30) {
        final chunk = carIds.sublist(
            i, i + 30 > carIds.length ? carIds.length : i + 30);
        final snap = await _db
            .collection('bookings')
            .where('carId', whereIn: chunk)
            .where('status', whereIn: ['completed', 'confirmed', 'cancelled'])
            .get();
        allDocs.addAll(snap.docs);
      }

      // Step 3 — enrich with renter names
      final renterCache = <String, String>{};
      final result = <BookingDetail>[];

      for (final doc in allDocs) {
        final booking = Booking.fromMap(doc.data());
        final meta = carMeta[booking.carId];

        String renterName = renterCache[booking.userId] ?? '';
        if (renterName.isEmpty) {
          try {
            final uDoc =
                await _db.collection('users').doc(booking.userId).get();
            renterName =
                (uDoc.data()?['fullName'] as String?) ?? 'Unknown';
            renterCache[booking.userId] = renterName;
          } catch (_) {
            renterName = 'Unknown';
          }
        }

        result.add(BookingDetail(
          booking: booking,
          carName: meta?.name ?? 'Unknown Car',
          carImage: meta?.image ?? '',
          renterName: renterName,
        ));
      }

      // Newest first
      result.sort(
          (a, b) => b.booking.createdAt.compareTo(a.booking.createdAt));
      _history = result;
    } catch (e) {
      print('[CarHistoryController] fetch error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
