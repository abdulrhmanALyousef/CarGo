import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cargo/models/car_model.dart';
import 'package:cargo/core/theme/light_color.dart';

class CarListController extends ChangeNotifier {
  final String cityName;

  CarListController({required this.cityName}) {
    searchController.addListener(_applyFilters);
    _startCarsStream();
  }

  final TextEditingController searchController = TextEditingController();

  // ── Filter panel ──────────────────────────────────────────────────────────
  bool _showFilters = false;
  bool get showFilters => _showFilters;

  void toggleFilters() {
    _showFilters = !_showFilters;
    notifyListeners();
  }

  // ── Price range ───────────────────────────────────────────────────────────
  static const double minPrice = 0;
  static const double maxPrice = 500;
  RangeValues _priceRange = const RangeValues(0, 500);
  RangeValues get priceRange => _priceRange;

  void updatePriceRange(RangeValues values) {
    _priceRange = values;
    _applyFilters();
    notifyListeners();
  }

  // ── Car types ─────────────────────────────────────────────────────────────
  final List<String> carTypes = [
    'Sedan', 'SUV', 'Hatchback', 'Coupe', 'Pickup', 'Van', 'Luxury', 'Convertible',
  ];
  final Set<String> _selectedTypes = {};
  Set<String> get selectedTypes => _selectedTypes;

  void toggleType(String type) {
    if (_selectedTypes.contains(type)) {
      _selectedTypes.remove(type);
    } else {
      _selectedTypes.add(type);
    }
    _applyFilters();
    notifyListeners();
  }

  // ── Date range ────────────────────────────────────────────────────────────
  DateTimeRange? _dateRange;
  DateTimeRange? get dateRange => _dateRange;

  String get dateText {
    if (_dateRange == null) return 'Pick Up date';
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
    return '${fmt(_dateRange!.start)} – ${fmt(_dateRange!.end)}';
  }

  Future<void> pickDates(BuildContext context) async {
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
          ),
        ),
        child: child!,
      ),
    );
    if (result != null) {
      _dateRange = result;
      _applyFilters();
    }
  }

  void clearDates() {
    _dateRange = null;
    _applyFilters();
  }

  // ── Data ──────────────────────────────────────────────────────────────────
  List<Car> _all = [];
  List<Car> _filtered = [];
  List<Car> get cars => _filtered;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  StreamSubscription<QuerySnapshot>? _carsSubscription;

  // ── Real-Time Stream ──────────────────────────────────────────────────────
  void _startCarsStream() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    _carsSubscription = FirebaseFirestore.instance
        .collection('cars')
        .where('city', isEqualTo: cityName)
        .snapshots()
        .listen(
      (snap) {
        _all = snap.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          return Car.fromJson(data);
        }).where((car) {
          if (car.ownerId == currentUid) return false;
          // Only show cars ready for rental — excludes reserved, in_trip, etc.
          return car.hubStatus == 'ready_for_rental';
        }).toList();

        _isLoading = false;
        _error = null;
        _applyFilters();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Kept for pull-to-refresh compatibility.
  Future<void> fetchCars() async {
    _carsSubscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();
    _startCarsStream();
  }

  // ── Filtering ─────────────────────────────────────────────────────────────
  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();

    _filtered = _all.where((car) {
      if (query.isNotEmpty) {
        final haystack = '${car.brand} ${car.model}'.toLowerCase();
        if (!haystack.contains(query)) return false;
      }

      if (car.pricePerDay < _priceRange.start ||
          car.pricePerDay > _priceRange.end) {
        return false;
      }

      if (_selectedTypes.isNotEmpty &&
          !_selectedTypes.contains(car.category)) {
        return false;
      }

      if (_dateRange != null) {
        final start = _dateRange!.start;
        final end = _dateRange!.end;
        if (car.availableFrom != null && start.isBefore(car.availableFrom!)) {
          return false;
        }
        if (car.availableTo != null && end.isAfter(car.availableTo!)) {
          return false;
        }
      }

      return true;
    }).toList();

    notifyListeners();
  }

  void clearFilters() {
    _priceRange = const RangeValues(0, 500);
    _selectedTypes.clear();
    _dateRange = null;
    searchController.clear();
    _applyFilters();
    notifyListeners();
  }

  @override
  void dispose() {
    _carsSubscription?.cancel();
    searchController.removeListener(_applyFilters);
    searchController.dispose();
    super.dispose();
  }
}
