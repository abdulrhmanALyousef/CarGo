// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo/models/booking_model.dart';
import 'package:cargo/models/car_model.dart';

// ── Booking Request Entry ──────────────────────────────────────────────────────
// Pairs a Booking with the customer's display name.
class BookingRequestEntry {
  final Booking booking;
  final String customerName;

  BookingRequestEntry({
    required this.booking,
    required this.customerName,
  });
}

class MyCarsController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── State ─────────────────────────────────────────────────────────────────
  List<Car> _cars = [];
  // carId → list of pending / approved requests for that car
  Map<String, List<BookingRequestEntry>> _requestsMap = {};
  bool _isLoading = false;
  String? _error;
  // bookingId being processed (accept / reject); drives per-row spinner
  String? _actionId;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<Car> get cars => _cars;
  Map<String, List<BookingRequestEntry>> get requestsMap => _requestsMap;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get actionId => _actionId;
  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  MyCarsController() {
    fetchMyCars();
  }

  // ── Data Fetch ────────────────────────────────────────────────────────────
  // Loads all cars owned by the current user, then for each car loads
  // its pending and approved booking requests with customer display names.
  Future<void> fetchMyCars() async {
    if (!isAuthenticated) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // ── Owner's cars ─────────────────────────────────────────────────────
      final carsSnap = await _firestore
          .collection('cars')
          .where('ownerId', isEqualTo: uid)
          .get();

      _cars = carsSnap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Car.fromJson(data);
      }).toList();

      // ── Requests per car ─────────────────────────────────────────────────
      _requestsMap = {};
      for (final car in _cars) {
        final reqSnap = await _firestore
            .collection('bookings')
            .where('carId', isEqualTo: car.id)
            .where('status', whereIn: ['pending', 'approved'])
            .get();

        final requests = <BookingRequestEntry>[];
        for (final doc in reqSnap.docs) {
          final booking = Booking.fromMap(doc.data());
          String customerName = 'Unknown';
          try {
            final userDoc =
                await _firestore.collection('users').doc(booking.userId).get();
            if (userDoc.exists) {
              customerName =
                  (userDoc.data()?['fullName'] as String?) ?? 'Unknown';
            }
          } catch (e) {
            print('[MyCarsController] Could not fetch user ${booking.userId}: $e');
          }
          requests.add(BookingRequestEntry(
            booking: booking,
            customerName: customerName,
          ));
        }

        // Newest request first
        requests.sort(
          (a, b) => b.booking.createdAt.compareTo(a.booking.createdAt),
        );
        _requestsMap[car.id] = requests;
      }
    } catch (e) {
      print('[MyCarsController] fetchMyCars error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Accept Request ────────────────────────────────────────────────────────
  // Execution order:
  //   1. Check that no other booking for this car is already approved or
  //      confirmed for the same date range (one-renter-per-range rule).
  //   2. Update status to 'approved' in Firestore.
  //   3. Reflect the change in the local list immediately.
  Future<void> acceptRequest(
    BookingRequestEntry entry,
    String carId,
    BuildContext context,
  ) async {
    _actionId = entry.booking.bookingId;
    notifyListeners();

    try {
      // Step 1 — one-renter-per-range check
      final hasOverlap = await _hasAcceptedOverlap(
        carId,
        entry.booking.startDate,
        entry.booking.endDate,
        entry.booking.bookingId,
      );

      if (hasOverlap) {
        _showError(
          context,
          'Another renter has already been accepted for these dates. '
          'Only one acceptance is allowed per date range.',
        );
        return;
      }

      // Step 2 — approve in Firestore
      await _firestore
          .collection('bookings')
          .doc(entry.booking.bookingId)
          .update({'status': 'approved'});

      // Step 3 — update local state
      final requests = List<BookingRequestEntry>.from(
          _requestsMap[carId] ?? []);
      final idx =
          requests.indexWhere((r) => r.booking.bookingId == entry.booking.bookingId);
      if (idx != -1) {
        final updatedBooking =
            Booking.fromMap({...entry.booking.toMap(), 'status': 'approved'});
        requests[idx] =
            BookingRequestEntry(booking: updatedBooking, customerName: entry.customerName);
        _requestsMap[carId] = requests;
      }
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Request accepted. ${entry.customerName} will be notified to complete payment.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on FirebaseException catch (e) {
      print('[MyCarsController] acceptRequest FirebaseException: $e');
      _showError(context, 'Firebase error [${e.code}]: ${e.message ?? e.toString()}');
    } catch (e) {
      print('[MyCarsController] acceptRequest error: $e');
      _showError(context, e.toString());
    } finally {
      _actionId = null;
      notifyListeners();
    }
  }

  // ── Reject Request ────────────────────────────────────────────────────────
  // Sets the booking status to 'cancelled' and removes it from the local list.
  Future<void> rejectRequest(
    BookingRequestEntry entry,
    String carId,
    BuildContext context,
  ) async {
    _actionId = entry.booking.bookingId;
    notifyListeners();

    try {
      await _firestore
          .collection('bookings')
          .doc(entry.booking.bookingId)
          .update({'status': 'cancelled'});

      // Remove from local state
      final requests = List<BookingRequestEntry>.from(
          _requestsMap[carId] ?? []);
      requests.removeWhere(
          (r) => r.booking.bookingId == entry.booking.bookingId);
      _requestsMap[carId] = requests;
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request from ${entry.customerName} rejected.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on FirebaseException catch (e) {
      print('[MyCarsController] rejectRequest FirebaseException: $e');
      _showError(context, 'Firebase error [${e.code}]: ${e.message ?? e.toString()}');
    } catch (e) {
      print('[MyCarsController] rejectRequest error: $e');
      _showError(context, e.toString());
    } finally {
      _actionId = null;
      notifyListeners();
    }
  }

  // ── Overlap Check (accept guard) ──────────────────────────────────────────
  // Returns true if the car already has an approved or confirmed booking that
  // overlaps [start]–[end], excluding [excludeBookingId] (the request itself).
  Future<bool> _hasAcceptedOverlap(
    String carId,
    DateTime start,
    DateTime end,
    String excludeBookingId,
  ) async {
    final snap = await _firestore
        .collection('bookings')
        .where('carId', isEqualTo: carId)
        .where('status', whereIn: ['approved', 'confirmed'])
        .get();

    for (final doc in snap.docs) {
      if (doc.id == excludeBookingId) continue;
      final data = doc.data();
      final eStart = (data['startDate'] as Timestamp).toDate();
      final eEnd = (data['endDate'] as Timestamp).toDate();
      if (!start.isAfter(eEnd) && !end.isBefore(eStart)) return true;
    }
    return false;
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
