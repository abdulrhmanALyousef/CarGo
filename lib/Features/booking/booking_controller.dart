// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo/models/car_model.dart';
import 'package:cargo/models/booking_model.dart';
import 'package:cargo/core/theme/light_color.dart';

// ════════════════════════════════════════════════════════════════════════════
// INLINE CALENDAR STRATEGY
// ════════════════════════════════════════════════════════════════════════════
//
// TableCalendar (table_calendar package) is used as an always-visible
// inline widget. Three layers enforce the date constraints:
//
//  Layer 1 — firstDay / lastDay props
//    The calendar cannot navigate to months outside these bounds.
//
//  Layer 2 — enabledDayPredicate
//    Within [firstDay, lastDay], any day for which this returns false is
//    greyed out and cannot be tapped. Used to block already-confirmed days.
//
//  Layer 3 — onRangeSelected validation + _validate()
//    Even though the two endpoints must each pass enabledDayPredicate, a
//    range between them can still span a confirmed day in the middle.
//    onRangeSelected scans the full range and rejects it if any day is
//    confirmed-booked.  _validate() repeats this scan before createBooking().
// ════════════════════════════════════════════════════════════════════════════

class BookingController extends ChangeNotifier {
  final Car car;

  BookingController({required this.car}) {
    final today = _dateOnly(DateTime.now());
    _focusedDay = today;

    print('[BookingController] availableFrom: ${car.availableFrom}');
    print('[BookingController] availableTo:   ${car.availableTo}');

    loadAvailability();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── State ────────────────────────────────────────────────────────────────
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _pickupTime;
  bool _isLoading = false;
  String? _error;
  bool _firestoreRulesError = false;

  late DateTime _focusedDay;

  // Starts true so the first build shows a loader while Firestore is fetched.
  bool _isLoadingAvailability = true;

  // Days that are locked because a CONFIRMED booking covers them.
  // Pending/approved bookings do NOT appear here — they don't lock dates.
  Set<DateTime> _bookedDates = {};

  // ── Getters ──────────────────────────────────────────────────────────────
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  TimeOfDay? get pickupTime => _pickupTime;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get firestoreRulesError => _firestoreRulesError;
  bool get isLoadingAvailability => _isLoadingAvailability;
  DateTime get focusedDay => _focusedDay;

  // ── Authentication Guard ─────────────────────────────────────────────────
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

  // ── Date Helpers ─────────────────────────────────────────────────────────
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // ── Calendar Boundary Props ──────────────────────────────────────────────
  DateTime get calendarFirstDay {
    final now = DateTime.now();
    return DateTime(now.year - 1, now.month, now.day);
  }

  DateTime get calendarLastDay {
    if (car.availableTo != null) return _dateOnly(car.availableTo!);
    return _dateOnly(DateTime.now()).add(const Duration(days: 365));
  }

  // ── Day Predicates ───────────────────────────────────────────────────────

  bool isDayEnabled(DateTime day) {
    final d = _dateOnly(day);
    if (car.availableFrom != null && d.isBefore(_dateOnly(car.availableFrom!))) {
      return false;
    }
    if (car.availableTo != null && d.isAfter(_dateOnly(car.availableTo!))) {
      return false;
    }
    return !isBooked(d);
  }

  // Returns true only for days locked by a CONFIRMED booking.
  bool isBooked(DateTime day) => _bookedDates.contains(_dateOnly(day));

  // ── Availability Loader ──────────────────────────────────────────────────
  // Only CONFIRMED bookings lock the calendar.
  // Pending and approved requests are visible to multiple renters
  // simultaneously and do not block date selection until payment is made.
  Future<void> loadAvailability() async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('carId', isEqualTo: car.id)
          .where('status', isEqualTo: 'confirmed')
          .get();

      final booked = <DateTime>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final start = (data['startDate'] as Timestamp).toDate();
        final end = (data['endDate'] as Timestamp).toDate();
        DateTime cursor = _dateOnly(start);
        final endOnly = _dateOnly(end);
        while (!cursor.isAfter(endOnly)) {
          booked.add(cursor);
          cursor = cursor.add(const Duration(days: 1));
        }
      }
      _bookedDates = booked;
    } catch (e) {
      print('BookingController.loadAvailability error: $e');
      _bookedDates = {};
    } finally {
      _isLoadingAvailability = false;
      notifyListeners();
    }
  }

  // ── Calendar Callbacks ───────────────────────────────────────────────────

  void onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
  }

  void onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    _focusedDay = focusedDay;
    _startDate = start != null ? _dateOnly(start) : null;

    if (end == null) {
      _endDate = null;
      _error = null;
      notifyListeners();
      return;
    }

    final endOnly = _dateOnly(end);

    DateTime cursor = _startDate!;
    while (!cursor.isAfter(endOnly)) {
      if (isBooked(cursor)) {
        _endDate = null;
        _error =
            'Your selected range includes days that are already booked. '
            'Please choose dates that do not overlap with existing bookings.';
        notifyListeners();
        return;
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    _endDate = endOnly;
    _error = null;
    notifyListeners();
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
      return 'Please select pick-up and drop-off dates on the calendar';
    }
    if (_pickupTime == null) {
      return 'Please select a pick-up time';
    }
    if (!_endDate!.isAfter(_startDate!)) {
      return 'Drop-off date must be after pick-up date';
    }
    if (car.availableFrom != null &&
        _startDate!.isBefore(_dateOnly(car.availableFrom!))) {
      return 'Pick-up date must be on or after ${_fmtDate(car.availableFrom!)}';
    }
    if (car.availableTo != null &&
        _endDate!.isAfter(_dateOnly(car.availableTo!))) {
      return 'Drop-off date must be on or before ${_fmtDate(car.availableTo!)}';
    }
    DateTime cursor = _startDate!;
    while (!cursor.isAfter(_endDate!)) {
      if (isBooked(cursor)) {
        return 'Your selected range includes days that are already booked';
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return null;
  }

  // ── Renter Double-Booking Guard (Firestore READ) ─────────────────────────
  // Checks whether the current user already has a pending, approved, or
  // confirmed booking for ANY car that overlaps with [start]–[end].
  // Cancelled bookings are skipped — they no longer count.
  Future<bool> _hasRenterOverlap(DateTime start, DateTime end) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await _firestore
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? '';
      if (status == 'cancelled') continue;
      final existingStart = (data['startDate'] as Timestamp).toDate();
      final existingEnd = (data['endDate'] as Timestamp).toDate();
      if (!start.isAfter(existingEnd) && !end.isBefore(existingStart)) {
        return true;
      }
    }
    return false;
  }

  // ── Car Confirmed-Booking Overlap Check (Firestore READ) ─────────────────
  // Only CONFIRMED bookings lock dates for a car. Pending and approved
  // requests from other renters do not prevent a new request from being
  // submitted — the owner decides who to accept.
  Future<bool> _hasCarConfirmedOverlap(DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('carId', isEqualTo: car.id)
        .where('status', isEqualTo: 'confirmed')
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final existingStart = (data['startDate'] as Timestamp).toDate();
      final existingEnd = (data['endDate'] as Timestamp).toDate();
      if (!start.isAfter(existingEnd) && !end.isBefore(existingStart)) {
        return true;
      }
    }
    return false;
  }

  // ── Create Booking ───────────────────────────────────────────────────────
  // Step 1 — isAuthenticated               stops if not logged in
  // Step 2 — _validate()                   local checks, zero network cost
  // Step 3 — _hasRenterOverlap()           Firestore READ — prevents double booking
  // Step 4 — _hasCarConfirmedOverlap()     Firestore READ — car already confirmed?
  // Step 5 — _firestore.doc.set()          Firestore WRITE — status: 'pending'
  //
  // NO payment at this stage. Payment happens after the owner approves the
  // request. The renter pays from My Trips once the status becomes 'approved'.
  Future<bool> createBooking(BuildContext context) async {
    if (!isAuthenticated) {
      _error = 'You must be logged in to book a car';
      notifyListeners();
      _showError(context, _error!);
      return false;
    }

    final validationError = _validate();
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      _showError(context, validationError);
      return false;
    }

    _isLoading = true;
    _firestoreRulesError = false;
    _error = null;
    notifyListeners();

    try {
      // Step 3 — prevent renter from booking two cars at the same time
      print('[createBooking] Checking renter availability — userId: ${FirebaseAuth.instance.currentUser!.uid}');
      final renterBusy = await _hasRenterOverlap(_startDate!, _endDate!);
      if (renterBusy) {
        _error =
            'You already have an active booking that overlaps these dates. '
            'Cancel or complete that trip before booking another.';
        _showError(context, _error!);
        return false;
      }

      // Step 4 — check if car has a confirmed booking for these dates
      print('[createBooking] Checking car confirmed bookings — carId: ${car.id}');
      final carTaken = await _hasCarConfirmedOverlap(_startDate!, _endDate!);
      if (carTaken) {
        _error = 'This car is already booked for the selected dates';
        _showError(context, _error!);
        return false;
      }

      // Step 5 — write the pending booking request (no payment)
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

      print('[createBooking] Writing pending booking request:');
      print('  bookingId:  ${booking.bookingId}');
      print('  userId:     ${booking.userId}');
      print('  carId:      ${booking.carId}');
      print('  startDate:  ${booking.startDate}');
      print('  endDate:    ${booking.endDate}');
      print('  pickupTime: ${booking.pickupTime}');
      print('  totalPrice: ${booking.totalPrice}');

      await docRef.set(booking.toMap());
      print('[createBooking] Booking request created: ${docRef.id}');

      return true;
    } on FirebaseException catch (e) {
      print('[createBooking] FirebaseException [${e.code}]: ${e.message}');
      if (e.code == 'permission-denied') {
        _firestoreRulesError = true;
        _error =
            'Access denied [permission-denied]. Fix Firestore rules:\n'
            'allow read, write: if request.auth != null;';
      } else {
        _error = 'Firebase error [${e.code}]: ${e.message ?? e.toString()}';
      }
      _showError(context, _error!);
      return false;
    } catch (e) {
      print('[createBooking] Unexpected error: $e');
      _error = e.toString();
      _showError(context, _error!);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
