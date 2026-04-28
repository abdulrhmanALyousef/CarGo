// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo/models/booking_model.dart';
import 'package:cargo/models/car_model.dart';
import 'package:cargo/services/stripe_service.dart';

// ── Trip Entry ────────────────────────────────────────────────────────────────
// Pairs a Booking with its associated Car (nullable — car may have been removed).
class TripEntry {
  final Booking booking;
  final Car? car;
  TripEntry({required this.booking, this.car});
}

class MyTripsController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StripeService _stripe = StripeService();

  // ── State ─────────────────────────────────────────────────────────────────
  List<TripEntry> _trips = [];
  bool _isLoading = false;
  String? _error;

  // Tracks which booking is currently being acted on (cancel or pay).
  // The UI uses this to show a per-card loading indicator.
  String? _actionBookingId;

  // Set when a booking transitions from 'pending' → 'approved' via real-time
  // stream. The screen reads this and shows a payment popup, then calls
  // consumeApprovedNotification() to clear it.
  TripEntry? _newlyApprovedEntry;

  // Tracks the last-known status for each booking so we can detect transitions.
  final Map<String, String> _previousStatuses = {};

  // Real-time Firestore stream subscription.
  StreamSubscription<QuerySnapshot>? _bookingsSubscription;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<TripEntry> get trips => _trips;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get actionBookingId => _actionBookingId;
  TripEntry? get newlyApprovedEntry => _newlyApprovedEntry;

  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  MyTripsController() {
    _initData();
  }

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    super.dispose();
  }

  // ── Initialisation ────────────────────────────────────────────────────────
  // Fetch trips first, then start the real-time stream so _previousStatuses
  // is populated before the first stream event arrives.
  Future<void> _initData() async {
    await fetchTrips();
    _startStream();
  }

  // ── Real-Time Stream ──────────────────────────────────────────────────────
  // Listens for changes to the user's bookings. On a 'pending' → 'approved'
  // transition, sets _newlyApprovedEntry so the UI can show a payment popup.
  void _startStream() {
    if (!isAuthenticated) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    _bookingsSubscription = _firestore
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen(
          _handleSnapshot,
          onError: (e) => print('[MyTripsController] stream error: $e'),
        );
  }

  void _handleSnapshot(QuerySnapshot snapshot) {
    bool changed = false;

    for (final change in snapshot.docChanges) {
      final data = change.doc.data() as Map<String, dynamic>;
      final bookingId = change.doc.id;
      final newStatus = data['status'] as String? ?? '';

      if (change.type == DocumentChangeType.added) {
        // Seed the known-status map from the initial snapshot.
        _previousStatuses[bookingId] = newStatus;
        continue;
      }

      if (change.type == DocumentChangeType.modified) {
        final prevStatus = _previousStatuses[bookingId] ?? '';

        if (prevStatus == 'pending' && newStatus == 'approved') {
          // Booking was approved while renter is online — trigger popup.
          final idx =
              _trips.indexWhere((e) => e.booking.bookingId == bookingId);
          if (idx != -1) {
            final updatedBooking =
                Booking.fromMap({..._trips[idx].booking.toMap(), 'status': 'approved'});
            final updated =
                TripEntry(booking: updatedBooking, car: _trips[idx].car);
            _trips[idx] = updated;
            _newlyApprovedEntry = updated;
            changed = true;
          }
        } else if (newStatus == 'cancelled') {
          _trips.removeWhere((e) => e.booking.bookingId == bookingId);
          changed = true;
        } else if (newStatus != prevStatus) {
          // Generic status update — reflect in the list.
          final idx =
              _trips.indexWhere((e) => e.booking.bookingId == bookingId);
          if (idx != -1) {
            final updatedBooking =
                Booking.fromMap({..._trips[idx].booking.toMap(), 'status': newStatus});
            _trips[idx] =
                TripEntry(booking: updatedBooking, car: _trips[idx].car);
            changed = true;
          }
        }

        _previousStatuses[bookingId] = newStatus;
      }

      if (change.type == DocumentChangeType.removed) {
        _trips.removeWhere((e) => e.booking.bookingId == bookingId);
        _previousStatuses.remove(bookingId);
        changed = true;
      }
    }

    if (changed) notifyListeners();
  }

  // ── Consume Approved Notification ─────────────────────────────────────────
  // Called by the UI after the payment popup has been shown so the flag is
  // cleared and the popup is not re-shown on the next rebuild.
  void consumeApprovedNotification() {
    _newlyApprovedEntry = null;
    notifyListeners();
  }

  // ── Data Fetch ────────────────────────────────────────────────────────────
  // Loads all non-cancelled bookings for the current user.
  // Cancelled bookings are excluded — they are treated as removed from the list.
  Future<void> fetchTrips() async {
    if (!isAuthenticated) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final bookingsSnap = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .get();

      // Filter out cancelled bookings locally — they are considered removed.
      final bookings = bookingsSnap.docs
          .map((doc) => Booking.fromMap(doc.data()))
          .where((b) => b.status != 'cancelled')
          .toList();

      // Seed the known-status map so the stream can detect future transitions.
      for (final b in bookings) {
        _previousStatuses[b.bookingId] = b.status;
      }

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

  // ── Cancel Booking ────────────────────────────────────────────────────────
  // Sets the booking status to 'cancelled' in Firestore and removes it from
  // the local list immediately so the UI reflects the change without a reload.
  Future<void> cancelBooking(
      String bookingId, BuildContext context) async {
    _actionBookingId = bookingId;
    notifyListeners();

    try {
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update({'status': 'cancelled'});

      _trips.removeWhere((e) => e.booking.bookingId == bookingId);
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } on FirebaseException catch (e) {
      print('[MyTripsController] cancelBooking FirebaseException: $e');
      _showError(context, 'Failed to cancel: ${e.message ?? e.code}');
    } catch (e) {
      print('[MyTripsController] cancelBooking error: $e');
      _showError(context, 'Failed to cancel booking. Please try again.');
    } finally {
      _actionBookingId = null;
      notifyListeners();
    }
  }

  // ── Pay for Booking ───────────────────────────────────────────────────────
  // Called after the owner approves the request (status = 'approved').
  //
  // Execution order:
  //   1. Re-check that no confirmed booking now conflicts with these dates.
  //      (Another renter may have paid for the same car in the meantime.)
  //   2. Launch Stripe payment sheet.
  //   3. On payment success — update Firestore status to 'confirmed'.
  //   4. Update the local list entry so the UI reflects 'confirmed' immediately.
  Future<bool> payForBooking(
      TripEntry entry, BuildContext context) async {
    _actionBookingId = entry.booking.bookingId;
    notifyListeners();

    try {
      // Step 1 — re-check car availability (only confirmed bookings lock dates)
      print('[payForBooking] Checking car confirmed bookings — carId: ${entry.booking.carId}');
      final conflict = await _hasCarConfirmedOverlap(entry.booking);
      if (conflict) {
        _showError(
          context,
          'This car has just been confirmed for another booking on those dates. '
          'Your request can no longer be completed.',
        );
        return false;
      }

      // Step 2 — Stripe payment
      print('[payForBooking] Launching Stripe payment...');
      final paid = await _stripe.verifyCard(context);
      if (!paid) {
        print('[payForBooking] User cancelled payment');
        return false;
      }
      print('[payForBooking] Payment successful');

      // Step 3 — confirm in Firestore
      await _firestore
          .collection('bookings')
          .doc(entry.booking.bookingId)
          .update({'status': 'confirmed'});

      // Step 4 — update local state
      final idx = _trips.indexWhere(
        (e) => e.booking.bookingId == entry.booking.bookingId,
      );
      if (idx != -1) {
        final updatedBooking =
            Booking.fromMap({...entry.booking.toMap(), 'status': 'confirmed'});
        _trips[idx] = TripEntry(booking: updatedBooking, car: entry.car);
      }
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Your booking is now confirmed.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }

      return true;
    } on FirebaseException catch (e) {
      print('[payForBooking] FirebaseException [${e.code}]: ${e.message}');
      _showError(context, 'Firebase error [${e.code}]: ${e.message ?? e.toString()}');
      return false;
    } catch (e) {
      print('[payForBooking] Unexpected error: $e');
      _showError(context, e.toString());
      return false;
    } finally {
      _actionBookingId = null;
      notifyListeners();
    }
  }

  // ── Car Confirmed-Overlap Check ───────────────────────────────────────────
  // Returns true if the car already has a CONFIRMED booking that overlaps
  // with the booking's dates (excluding the booking itself).
  Future<bool> _hasCarConfirmedOverlap(Booking booking) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('carId', isEqualTo: booking.carId)
        .where('status', isEqualTo: 'confirmed')
        .get();

    for (final doc in snapshot.docs) {
      if (doc.id == booking.bookingId) continue; // skip self
      final data = doc.data();
      final start = (data['startDate'] as Timestamp).toDate();
      final end = (data['endDate'] as Timestamp).toDate();
      if (!booking.startDate.isAfter(end) &&
          !booking.endDate.isBefore(start)) {
        return true;
      }
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
