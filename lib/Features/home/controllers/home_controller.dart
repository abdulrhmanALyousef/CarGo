import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo/core/widgets/location_sheet.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/models/car_model.dart';

class HomeController extends ChangeNotifier {
  HomeController() {
    _startCarsStream();
  }

  String _location = '';
  DateTimeRange? _dateRange;
  String _searchQuery = '';

  List<Car> _cars = [];
  List<Car> _displayedCars = [];

  bool _isLoadingCars = true;
  bool get isLoadingCars => _isLoadingCars;

  // True while the async booking-conflict check is running after dates are selected.
  bool _isCheckingBookings = false;
  bool get isCheckingBookings => _isCheckingBookings;

  // Car IDs excluded because they have a confirmed/in_trip booking that overlaps
  // the currently selected date range. Cleared when dates are cleared.
  Set<String> _bookingConflictedIds = {};

  String? _carsError;
  String? get carsError => _carsError;

  String get location => _location;
  DateTimeRange? get dateRange => _dateRange;
  String get searchQuery => _searchQuery;

  bool get hasActiveFilter => _dateRange != null || _searchQuery.isNotEmpty;

  List<Car> get cars => _displayedCars;

  StreamSubscription<QuerySnapshot>? _carsSubscription;

  // Incremented each time setDateRange is called so stale async checks are ignored.
  int _conflictCheckVersion = 0;

  String get dateText {
    if (_dateRange == null) return 'Select dates';
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
    return '${fmt(_dateRange!.start)} – ${fmt(_dateRange!.end)}';
  }

  void setLocation(String val) {
    _location = val;
    notifyListeners();
  }

  void setDateRange(DateTimeRange val) {
    _dateRange = val;
    _conflictCheckVersion++;
    _applyFilters();
    _refreshBookingConflicts(_conflictCheckVersion);
  }

  void setSearchQuery(String val) {
    _searchQuery = val.trim();
    _applyFilters();
  }

  void clearFilters() {
    _location = '';
    _dateRange = null;
    _searchQuery = '';
    _bookingConflictedIds = {};
    _isCheckingBookings = false;
    _displayedCars = List.from(_cars);
    notifyListeners();
  }

  void search(BuildContext context) {
    _applyFilters();
  }

  // ── Real-Time Stream ───────────────────────────────────────────────────────
  // Listens to the full cars collection. Filters client-side to:
  //   1. Exclude the current user's own cars
  //   2. Show ready_for_rental AND reserved (has a future confirmed booking but
  //      may still have available date slots). in_trip / maintenance / awaiting_*
  //      are hidden because the car is not available.
  // When dates are selected, _refreshBookingConflicts() runs async to remove
  // cars whose confirmed/in_trip bookings overlap the requested range.
  void _startCarsStream() {
    _carsSubscription = FirebaseFirestore.instance
        .collection('cars')
        .snapshots()
        .listen(
      (snap) {
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        _cars = snap.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          return Car.fromJson(data);
        }).where((car) {
          if (car.ownerId == currentUid) return false;
          return car.hubStatus == 'ready_for_rental' ||
                 car.hubStatus == 'available' ||
                 car.hubStatus == 'reserved';
        }).toList();

        _isLoadingCars = false;
        _carsError = null;
        _applyFilters();
        // Re-run booking conflict check if dates are already selected
        if (_dateRange != null) {
          _conflictCheckVersion++;
          _refreshBookingConflicts(_conflictCheckVersion);
        }
      },
      onError: (e) {
        _carsError = e.toString();
        _isLoadingCars = false;
        notifyListeners();
      },
    );
  }

  // Kept for pull-to-refresh compatibility — re-attaches the stream.
  Future<void> fetchCars() async {
    _carsSubscription?.cancel();
    _isLoadingCars = true;
    _carsError = null;
    notifyListeners();
    _startCarsStream();
  }

  void _applyFilters() {
    var filtered = List<Car>.from(_cars);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((car) {
        return car.brand.toLowerCase().contains(q) ||
            car.model.toLowerCase().contains(q) ||
            car.category.toLowerCase().contains(q) ||
            car.city.toLowerCase().contains(q) ||
            car.location.toLowerCase().contains(q) ||
            car.hubLocation.toLowerCase().contains(q);
      }).toList();
    }

    if (_dateRange != null) {
      final start = _dateRange!.start;
      final end = _dateRange!.end;
      // Filter 1: car availability window (fast, no network).
      filtered = filtered.where((car) {
        if (car.availableFrom != null && start.isBefore(car.availableFrom!)) {
          return false;
        }
        if (car.availableTo != null && end.isAfter(car.availableTo!)) {
          return false;
        }
        return true;
      }).toList();
      // Filter 2: exclude cars whose confirmed/in_trip bookings overlap the
      // selected range. This is populated by _refreshBookingConflicts() which
      // runs asynchronously after dates are chosen.
      if (_bookingConflictedIds.isNotEmpty) {
        filtered =
            filtered.where((c) => !_bookingConflictedIds.contains(c.id)).toList();
      }
    } else {
      // No dates selected: hide reserved cars — only ready_for_rental / available
      // are truly bookable without knowing the desired dates. Reserved cars
      // reappear once dates are chosen and pass the booking-conflict check.
      filtered = filtered.where((car) =>
          car.hubStatus == 'ready_for_rental' ||
          car.hubStatus == 'available').toList();
    }

    _displayedCars = filtered;
    notifyListeners();
  }

  // ── Async Booking-Conflict Check ──────────────────────────────────────────
  // Queries Firestore for confirmed/in_trip bookings that overlap the selected
  // date range for all currently visible cars (in chunks of 30).
  // Uses [version] to discard results from stale calls when dates change rapidly.
  Future<void> _refreshBookingConflicts(int version) async {
    if (_dateRange == null) return;
    _isCheckingBookings = true;
    notifyListeners();

    final start = _dateRange!.start;
    final end   = _dateRange!.end;
    final carIds = _cars.map((c) => c.id).toList();
    final conflicted = <String>{};

    try {
      for (var i = 0; i < carIds.length; i += 30) {
        if (_conflictCheckVersion != version) return; // stale — abandon
        final chunk = carIds.sublist(i, (i + 30).clamp(0, carIds.length));
        final snap = await FirebaseFirestore.instance
            .collection('bookings')
            .where('carId', whereIn: chunk)
            .where('status', whereIn: ['confirmed', 'in_trip'])
            .get();

        for (final doc in snap.docs) {
          final data = doc.data();
          final existStart =
              (data['startDate'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final existEnd =
              (data['endDate'] as Timestamp?)?.toDate() ?? DateTime(2000);
          // Standard overlap: requestedStart < existingEnd AND requestedEnd > existingStart
          if (start.isBefore(existEnd) && end.isAfter(existStart)) {
            conflicted.add(data['carId'] as String? ?? '');
          }
        }
      }
    } catch (_) {
      // On error, keep current conflict set — the booking screen calendar
      // will still block reserved days when the user taps through.
    }

    if (_conflictCheckVersion != version) return; // stale — another check started

    _bookingConflictedIds = conflicted;
    _isCheckingBookings = false;
    _applyFilters(); // re-apply to reflect the newly populated conflict set
  }

  // ── Pickers ────────────────────────────────────────────────────────────────

  Future<void> openLocation(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFFD4D4D4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const LocationSheet(),
    );
    if (result != null) setLocation(result);
  }

  Future<void> openDate(BuildContext context) async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
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
    if (result != null) setDateRange(result);
  }

  @override
  void dispose() {
    _carsSubscription?.cancel();
    super.dispose();
  }
}
