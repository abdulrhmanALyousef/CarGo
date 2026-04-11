// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo/models/car_model.dart';
import 'package:cargo/models/booking_model.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/services/stripe_service.dart';

// ════════════════════════════════════════════════════════════════════════════
// FIRESTORE PERMISSION_DENIED — WHY IT HAPPENS AND HOW THIS CONTROLLER HANDLES IT
// ════════════════════════════════════════════════════════════════════════════
//
// The overlap check queries the `bookings` collection filtered by carId:
//
//   _firestore.collection('bookings').where('carId', isEqualTo: car.id).get()
//
// This query returns booking documents that belong to OTHER users.
// Firestore evaluates its Security Rules PER DOCUMENT against each result.
//
// If the Firestore rules say:
//   allow read: if request.auth.uid == resource.data.userId;
//
// ...then reading a booking that belongs to a different user ALWAYS fails,
// even when the requesting user is fully authenticated. The check
// request.auth.uid == resource.data.userId compares the REQUESTER'S uid
// against the DOCUMENT OWNER'S uid. For other users' bookings these will
// never match — Firestore returns PERMISSION_DENIED.
//
// This is NOT a bug in the Dart code. The code is correct.
// The required Firestore rule for the bookings collection is:
//
//   match /bookings/{bookingId} {
//     allow read:   if request.auth != null;   ← any authenticated user
//     allow write:  if request.auth != null;   ← any authenticated user
//   }
//
// Set this in: Firebase Console → Firestore Database → Rules
// See project_context.dart Section 7 for the full recommended ruleset.
// ════════════════════════════════════════════════════════════════════════════

class BookingController extends ChangeNotifier {
  final Car car;

  BookingController({required this.car});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StripeService _stripe = StripeService();

  // ── State ────────────────────────────────────────────────────────────────
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _pickupTime;
  bool _isLoading = false;
  String? _error;

  // Separate flag set when Firestore returns PERMISSION_DENIED.
  // Used by BookingScreen to show a persistent inline banner explaining
  // that the issue is the Firestore Security Rules, not the user's account.
  bool _firestoreRulesError = false;

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  TimeOfDay? get pickupTime => _pickupTime;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get firestoreRulesError => _firestoreRulesError;

  // ── Authentication Guard ─────────────────────────────────────────────────
  // Checked before every Firestore operation.
  //
  // Returning false here means no request is ever sent to Firestore.
  // Returning true means the user has a local auth session — but the
  // Firestore Security Rules may still deny the request server-side
  // (see the block comment at the top of this file).
  //
  // Mirrors FirebaseService.isUserLoggedIn() used across the project.
  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  // ── Text Helpers ─────────────────────────────────────────────────────────
  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String get startDateText =>
      _startDate != null ? _fmtDate(_startDate!) : 'Select date';

  String get endDateText =>
      _endDate != null ? _fmtDate(_endDate!) : 'Select date';

  String get pickupTimeText {
    if (_pickupTime == null) return 'Select time';
    final hour =
        _pickupTime!.hourOfPeriod == 0 ? 12 : _pickupTime!.hourOfPeriod;
    final minute = _pickupTime!.minute.toString().padLeft(2, '0');
    final period = _pickupTime!.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // ── Price Calculation ────────────────────────────────────────────────────
  int get rentalDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  double get totalPrice => rentalDays * car.pricePerDay;

  // ── Date Picker ──────────────────────────────────────────────────────────
  // constrained to car.availableFrom / car.availableTo so the user cannot
  // pick dates outside the owner-defined availability window.
  Future<void> openDatePicker(BuildContext context) async {
    final DateTime firstDate = car.availableFrom ?? DateTime.now();
    final DateTime lastDate =
        car.availableTo ?? DateTime.now().add(const Duration(days: 365));

    final result = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: LightColors.primaryColor,
            onPrimary: Colors.white,
            surface: Color(0xFFD4D4D4),
          ),
        ),
        child: child!,
      ),
    );

    if (result != null) {
      _startDate = result.start;
      _endDate = result.end;
      _error = null;
      notifyListeners();
    }
  }

  // ── Time Picker ──────────────────────────────────────────────────────────
  Future<void> openTimePicker(BuildContext context) async {
    final result = await showTimePicker(
      context: context,
      initialTime: _pickupTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: LightColors.primaryColor,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (result != null) {
      _pickupTime = result;
      _error = null;
      notifyListeners();
    }
  }

  // ── Local Validation (no network) ────────────────────────────────────────
  String? _validate() {
    if (_startDate == null || _endDate == null) {
      return 'Please select pick-up and drop-off dates';
    }
    if (_pickupTime == null) {
      return 'Please select a pick-up time';
    }
    if (_endDate!.isBefore(_startDate!)) {
      return 'Drop-off date must be after pick-up date';
    }
    if (car.availableFrom != null &&
        _startDate!.isBefore(car.availableFrom!)) {
      return 'Pick-up date must be on or after ${_fmtDate(car.availableFrom!)}';
    }
    if (car.availableTo != null && _endDate!.isAfter(car.availableTo!)) {
      return 'Drop-off date must be on or before ${_fmtDate(car.availableTo!)}';
    }
    return null;
  }

  // ── Overlap Check (Firestore READ) ───────────────────────────────────────
  // Queries ALL bookings for this car — including bookings owned by other users.
  //
  // This is why the Firestore rule CANNOT be:
  //   allow read: if request.auth.uid == resource.data.userId;
  //
  // That rule only allows a user to read their OWN bookings. But to check
  // availability, we need to read bookings from everyone who booked this car.
  //
  // The correct rule is:
  //   allow read: if request.auth != null;
  //
  // This method is only ever called after isAuthenticated == true is confirmed.
  Future<bool> _hasOverlap(DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('carId', isEqualTo: car.id)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? '';

      if (status == 'cancelled') continue;

      final existingStart = (data['startDate'] as Timestamp).toDate();
      final existingEnd = (data['endDate'] as Timestamp).toDate();

      // Overlaps when: newStart <= existingEnd  AND  newEnd >= existingStart
      if (!start.isAfter(existingEnd) && !end.isBefore(existingStart)) {
        return true;
      }
    }

    return false;
  }

  // ── Create Booking ───────────────────────────────────────────────────────
  // Fixed execution order — must not be changed:
  //
  //   Step 1 — isAuthenticated       No Firestore call if not logged in.
  //   Step 2 — _validate()           Local checks only, zero network cost.
  //   Step 3 — _hasOverlap()         Firestore READ. Safe: auth confirmed above.
  //   Step 4 — _firestore.doc.set()  Firestore WRITE. Safe: auth confirmed above.
  //
  // FirebaseException is caught separately from generic Exception.
  // A 'permission-denied' code sets _firestoreRulesError = true so the screen
  // can show a persistent inline banner explaining the Firestore rules issue.
  Future<bool> createBooking(BuildContext context) async {
    // ── Step 1: Auth guard ────────────────────────────────────────────────
    // If the user has no local session, we stop here. No Firestore call is
    // made — the PERMISSION_DENIED error cannot come from the server because
    // we never send a request.
    if (!isAuthenticated) {
      _error = 'You must be logged in to book a car';
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!)),
      );
      return false;
    }

    // ── Step 2: Local validation ──────────────────────────────────────────
    final validationError = _validate();
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return false;
    }

    // ── Steps 3–5: Overlap check → Stripe verification → Firestore write ────
    _isLoading = true;
    _firestoreRulesError = false;
    _error = null;
    notifyListeners();

    try {
      // Step 3: Overlap check — reads all bookings for this car.
      // Runs before Stripe so we don't open the payment sheet for taken dates.
      final overlaps = await _hasOverlap(_startDate!, _endDate!);
      if (overlaps) {
        _error = 'This car is already booked for the selected dates';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error!)),
        );
        return false;
      }

      // Step 4: Stripe card verification via SetupIntent.
      // No charge is made — this only confirms the card is real and valid.
      // Returns false if the user closes the sheet without completing.
      final cardVerified = await _stripe.verifyCard(context);
      if (!cardVerified) {
        // User cancelled — stop silently, no error shown.
        return false;
      }

      // Step 5: Write booking document (card confirmed valid).
      final currentUser = FirebaseAuth.instance.currentUser!;
      final docRef = _firestore.collection('bookings').doc();

      final booking = Booking(
        bookingId: docRef.id,
        userId: currentUser.uid,
        carId: car.id,
        startDate: _startDate!,
        endDate: _endDate!,
        pickupTime: pickupTimeText,
        totalPrice: totalPrice,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await docRef.set(booking.toMap());
      return true;

    } on FirebaseException catch (e) {
      print('BookingController FirebaseException [${e.code}]: ${e.message}');

      if (e.code == 'permission-denied') {
        // The user IS authenticated but Firestore Security Rules denied the
        // request. The most common cause: the rules check
        //   resource.data.userId == request.auth.uid
        // which blocks reading OTHER users' bookings for the same car.
        //
        // Fix in Firebase Console → Firestore → Rules:
        //   match /bookings/{bookingId} {
        //     allow read:  if request.auth != null;
        //     allow write: if request.auth != null;
        //   }
        _firestoreRulesError = true;
        _error =
            'Booking access was denied by the server. The Firestore Security '
            'Rules must allow authenticated users to read all bookings. '
            'Please update the rules in Firebase Console.';
      } else {
        _error = 'Failed to create booking. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!)),
      );
      return false;

    } catch (e) {
      print('BookingController unexpected error: $e');
      _error = 'An unexpected error occurred. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error!)),
      );
      return false;

    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}