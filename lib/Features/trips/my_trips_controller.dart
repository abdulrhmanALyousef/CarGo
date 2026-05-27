// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo/models/booking_model.dart';
import 'package:cargo/models/car_model.dart';
import 'package:cargo/services/stripe_service.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';
import 'package:cargo/Features/chats/presentation/chat_screen.dart';

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
            final updatedBooking = _trips[idx].booking.copyWith(status: 'approved');
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
          // Rebuild the booking from the full Firestore doc so new fields
          // (pickupStatus, paymentStatus) are reflected without a re-fetch.
          final idx =
              _trips.indexWhere((e) => e.booking.bookingId == bookingId);
          if (idx != -1) {
            final docData = Map<String, dynamic>.from(data);
            docData['bookingId'] = bookingId;
            final updatedBooking = Booking.fromMap(docData);
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
  // If the cancelled booking was the last confirmed booking for the car,
  // the car is reset to ready_for_rental so it reappears in Explore.
  Future<void> cancelBooking(
      String bookingId, BuildContext context) async {
    _actionBookingId = bookingId;
    notifyListeners();

    try {
      // Find the entry before removing so we have the carId
      final entry = _trips.firstWhere(
        (e) => e.booking.bookingId == bookingId,
        orElse: () => TripEntry(booking: _trips.first.booking),
      );
      final carId = entry.booking.carId;

      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update({'status': 'cancelled'});

      // If no other confirmed/in_trip booking exists for the car, revert its
      // status — but only to ready_for_rental when free dates remain in the
      // availability window.  If every day in [availableFrom, availableTo] is
      // already covered by a completed/confirmed/in_trip booking the car gets
      // availability_ended and stops appearing in Explore.
      try {
        final remaining = await _firestore
            .collection('bookings')
            .where('carId', isEqualTo: carId)
            .where('status', whereIn: ['confirmed', 'in_trip'])
            .get();
        if (remaining.docs.isEmpty) {
          final carDoc = await _firestore.collection('cars').doc(carId).get();
          final carData = carDoc.data();
          DateTime? availableFrom;
          DateTime? availableTo;
          final rawFrom = carData?['availableFrom'];
          final rawTo   = carData?['availableTo'];
          if (rawFrom is Timestamp) {
            availableFrom = rawFrom.toDate();
          } else if (rawFrom is String) {
            availableFrom = DateTime.tryParse(rawFrom);
          }
          if (rawTo is Timestamp) {
            availableTo = rawTo.toDate();
          } else if (rawTo is String) {
            availableTo = DateTime.tryParse(rawTo);
          }

          final newStatus = await _computeNewCarStatus(carId, availableFrom, availableTo);
          await _firestore.collection('cars').doc(carId).update({
            'hubStatus': newStatus,
            'status': newStatus,
            'available': newStatus == 'ready_for_rental',
          });
        }
      } catch (_) {}

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

      // Step 3 — confirm in Firestore + set lifecycle fields
      await _firestore
          .collection('bookings')
          .doc(entry.booking.bookingId)
          .update({
        'status': 'confirmed',
        'pickupStatus': 'awaiting_pickup',
        'paymentStatus': 'paid',
      });

      // Step 3b — mark car as reserved (best-effort; Cloud Function also handles this)
      try {
        await _firestore.collection('cars').doc(entry.booking.carId).update({
          'hubStatus': 'reserved',
          'status': 'reserved',
          'available': false,
        });
      } catch (e) {
        print('[payForBooking] Car status update failed (Cloud Function will handle): $e');
      }

      // Step 4 — update local state
      final idx = _trips.indexWhere(
        (e) => e.booking.bookingId == entry.booking.bookingId,
      );
      if (idx != -1) {
        final updatedBooking = entry.booking.copyWith(
          status: 'confirmed',
          pickupStatus: 'awaiting_pickup',
          paymentStatus: 'paid',
        );
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

  // ── Car Confirmed/InTrip Overlap Check ───────────────────────────────────
  // Returns true if the car already has a CONFIRMED or IN_TRIP booking that
  // overlaps with the booking's dates (excluding the booking itself).
  Future<bool> _hasCarConfirmedOverlap(Booking booking) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('carId', isEqualTo: booking.carId)
        .where('status', whereIn: ['confirmed', 'in_trip'])
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

  // ── Open Chat with Owner ──────────────────────────────────────────────────
  Future<void> openChatWithOwner(TripEntry entry, BuildContext context) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final car = entry.car;
    if (car == null) return;

    final ownerId = car.ownerId;
    final chatId = currentUserId.compareTo(ownerId) < 0
        ? '${currentUserId}_$ownerId'
        : '${ownerId}_$currentUserId';

    String ownerName = 'Owner';
    try {
      final data = await FirebaseService().getUserData(uid: ownerId);
      ownerName = data?['fullName'] as String? ?? 'Owner';
    } catch (_) {}

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            currentUserId: currentUserId,
            otherUserId: ownerId,
            otherUserName: ownerName,
          ),
        ),
      );
    }
  }

  // ── Car Status Computation ────────────────────────────────────────────────
  // Returns 'availability_ended' when every day in [availableFrom, availableTo]
  // is covered by a confirmed, in_trip, or completed booking.
  // Returns 'ready_for_rental' when at least one free day remains.
  // The check is intentionally independent of today's date.
  Future<String> _computeNewCarStatus(
    String carId,
    DateTime? availableFrom,
    DateTime? availableTo,
  ) async {
    if (availableFrom == null || availableTo == null) return 'ready_for_rental';

    final snap = await _firestore
        .collection('bookings')
        .where('carId', isEqualTo: carId)
        .where('status', whereIn: ['confirmed', 'in_trip', 'completed'])
        .get();

    final covered = <DateTime>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final startRaw = data['startDate'];
      final endRaw   = data['endDate'];
      if (startRaw == null || endRaw == null) continue;
      final start = startRaw is Timestamp ? startRaw.toDate() : DateTime.tryParse(startRaw.toString());
      final end   = endRaw   is Timestamp ? endRaw.toDate()   : DateTime.tryParse(endRaw.toString());
      if (start == null || end == null) continue;
      var d = _dateOnly(start);
      final endOnly = _dateOnly(end);
      while (!d.isAfter(endOnly)) {
        covered.add(d);
        d = d.add(const Duration(days: 1));
      }
    }

    var cursor = _dateOnly(availableFrom);
    final endOnly = _dateOnly(availableTo);
    while (!cursor.isAfter(endOnly)) {
      if (!covered.contains(cursor)) return 'ready_for_rental';
      cursor = cursor.add(const Duration(days: 1));
    }
    return 'availability_ended';
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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
