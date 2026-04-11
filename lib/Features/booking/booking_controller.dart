// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo/models/car_model.dart';
import 'package:cargo/models/booking_model.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/services/stripe_service.dart';

// ════════════════════════════════════════════════════════════════════════════
// INLINE CALENDAR STRATEGY
// ════════════════════════════════════════════════════════════════════════════
//
// TableCalendar (table_calendar package) is used as an always-visible
// inline widget. Three layers enforce the date constraints:
//
//  Layer 1 — firstDay / lastDay props
//    The calendar cannot navigate to months outside these bounds.
//    Set to max(today, availableFrom) → availableTo so the user can
//    never even see months outside the window.
//
//  Layer 2 — enabledDayPredicate
//    Within [firstDay, lastDay], any day for which this returns false is
//    greyed out and cannot be tapped. Used to block already-booked days.
//
//  Layer 3 — onRangeSelected validation + _validate()
//    Even though the two endpoints must each pass enabledDayPredicate, a
//    range between them can still span a booked day in the middle (because
//    only the tapped days are checked by the predicate). onRangeSelected
//    scans the full range and rejects it if any day is booked.
//    _validate() repeats this scan before createBooking() so the booking
//    is safe regardless of how the state was set.
// ════════════════════════════════════════════════════════════════════════════

class BookingController extends ChangeNotifier {
  final Car car;

  BookingController({required this.car}) {
    // Initialise the calendar on the first selectable month.
    // If availableFrom is in the future show that month; otherwise today.
    final today = _dateOnly(DateTime.now());
    // Always open on the current month, regardless of availableFrom.
    _focusedDay = today;

    print('[BookingController] availableFrom: ${car.availableFrom}');
    print('[BookingController] availableTo:   ${car.availableTo}');

    loadAvailability(); // fire-and-forget; _isLoadingAvailability = true until done
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StripeService _stripe = StripeService();

  // ── State ────────────────────────────────────────────────────────────────
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _pickupTime;
  bool _isLoading = false;
  String? _error;
  bool _firestoreRulesError = false;

  // Calendar focused day — drives which month the calendar displays.
  late DateTime _focusedDay;

  // Starts true so the first build shows a loader while Firestore is fetched.
  bool _isLoadingAvailability = true;

  // Every individual day that is occupied by an active booking for this car.
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
  // These are passed directly to TableCalendar's firstDay / lastDay so the
  // widget itself enforces the bounds without any extra logic.

  // Earliest NAVIGABLE day — controls how far back the user can scroll.
  // Set one year behind today so the user can browse months before
  // availableFrom (those months are visible but disabled via
  // enabledDayPredicate — navigation bound ≠ selectability bound).
  DateTime get calendarFirstDay {
    final now = DateTime.now();
    return DateTime(now.year - 1, now.month, now.day);
  }

  // Latest selectable day: availableTo or 1 year out as a safe fallback.
  DateTime get calendarLastDay {
    if (car.availableTo != null) return _dateOnly(car.availableTo!);
    return _dateOnly(DateTime.now()).add(const Duration(days: 365));
  }

  // ── Day Predicates ───────────────────────────────────────────────────────

  // Passed to TableCalendar.enabledDayPredicate.
  // Returns false for any day that must not be tappable:
  //   • before availableFrom  (car not yet available)
  //   • after availableTo     (car no longer available)
  //   • inside a booked range (already reserved)
  // Time is ignored — all comparisons use date-only values.
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

  // Returns true when [day] is occupied by an existing booking.
  bool isBooked(DateTime day) => _bookedDates.contains(_dateOnly(day));

  // ── Availability Loader ──────────────────────────────────────────────────
  // Fetches all active bookings for this car and expands each range into
  // individual days stored in _bookedDates. These days are then blocked
  // via enabledDayPredicate so the calendar greys them out automatically.
  Future<void> loadAvailability() async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('carId', isEqualTo: car.id)
          .get();

      final booked = <DateTime>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if ((data['status'] as String? ?? '') == 'cancelled') continue;
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

  // Called by TableCalendar when the user swipes or taps to a new month.
  void onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    // No notifyListeners — focusedDay change alone doesn't need a UI rebuild.
    // TableCalendar manages its own page scroll internally.
  }

  // Called by TableCalendar on every range interaction:
  //   • First tap  → start = tapped, end = null
  //   • Second tap → start = first, end = second  (or restart if before first)
  //
  // When end is non-null we scan the full range for booked days.
  // If any are found we reject the end date (clear it) and show an error.
  // The calendar re-renders with rangeEndDay = null, returning to
  // "start-only" state so the user can re-tap a valid end date.
  void onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    _focusedDay = focusedDay;
    _startDate = start != null ? _dateOnly(start) : null;

    if (end == null) {
      // First tap — just set the start.
      _endDate = null;
      _error = null;
      notifyListeners();
      return;
    }

    final endOnly = _dateOnly(end);

    // Scan the range for booked days.
    // enabledDayPredicate blocks tapping a booked endpoint, but a booked day
    // can still sit between a valid start and a valid end.
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
    // Window enforcement — the calendar already blocks these via firstDay /
    // lastDay, but _validate() is the last line of defence before Firestore.
    if (car.availableFrom != null &&
        _startDate!.isBefore(_dateOnly(car.availableFrom!))) {
      return 'Pick-up date must be on or after ${_fmtDate(car.availableFrom!)}';
    }
    if (car.availableTo != null &&
        _endDate!.isAfter(_dateOnly(car.availableTo!))) {
      return 'Drop-off date must be on or before ${_fmtDate(car.availableTo!)}';
    }
    // Full range scan — catches booked days between start and end.
    // onRangeSelected already rejects these, but the state could theoretically
    // be set another way, so this guard stays.
    DateTime cursor = _startDate!;
    while (!cursor.isAfter(_endDate!)) {
      if (isBooked(cursor)) {
        return 'Your selected range includes days that are already booked';
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return null;
  }

  // ── Overlap Check (Firestore READ) ───────────────────────────────────────
  // Queries ALL bookings for this car — including other users' bookings.
  // Requires: allow read: if request.auth != null; in Firestore rules.
  Future<bool> _hasOverlap(DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('carId', isEqualTo: car.id)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if ((data['status'] as String? ?? '') == 'cancelled') continue;
      final existingStart = (data['startDate'] as Timestamp).toDate();
      final existingEnd = (data['endDate'] as Timestamp).toDate();
      if (!start.isAfter(existingEnd) && !end.isBefore(existingStart)) {
        return true;
      }
    }
    return false;
  }

  // ── Create Booking ───────────────────────────────────────────────────────
  // Step 1 — isAuthenticated       stops if not logged in
  // Step 2 — _validate()           local checks, zero network cost
  // Step 3 — _hasOverlap()         Firestore READ (auth confirmed above)
  // Step 4 — _stripe.verifyCard()  card verification
  // Step 5 — _firestore.doc.set()  Firestore WRITE
  Future<bool> createBooking(BuildContext context) async {
    if (!isAuthenticated) {
      _error = 'You must be logged in to book a car';
      notifyListeners();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_error!)));
      return false;
    }

    final validationError = _validate();
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(validationError)));
      return false;
    }

    _isLoading = true;
    _firestoreRulesError = false;
    _error = null;
    notifyListeners();

    try {
      final overlaps = await _hasOverlap(_startDate!, _endDate!);
      if (overlaps) {
        _error = 'This car is already booked for the selected dates';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_error!)));
        return false;
      }

      final cardVerified = await _stripe.verifyCard(context);
      if (!cardVerified) return false;

      final currentUser = FirebaseAuth.instance.currentUser!;
      final docRef = _firestore.collection('bookings').doc();

      await docRef.set(Booking(
        bookingId: docRef.id,
        userId: currentUser.uid,
        carId: car.id,
        startDate: _startDate!,
        endDate: _endDate!,
        pickupTime: pickupTimeText,
        totalPrice: totalPrice,
        status: 'pending',
        createdAt: DateTime.now(),
      ).toMap());

      return true;
    } on FirebaseException catch (e) {
      print('BookingController FirebaseException [${e.code}]: ${e.message}');
      if (e.code == 'permission-denied') {
        _firestoreRulesError = true;
        _error =
            'Booking access was denied by the server. Update Firestore rules: '
            'allow read: if request.auth != null;';
      } else {
        _error = 'Failed to create booking. Please try again.';
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_error!)));
      return false;
    } catch (e) {
      print('BookingController unexpected error: $e');
      _error = 'An unexpected error occurred. Please try again.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_error!)));
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
