import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cargo/models/car_model.dart';
import 'package:cargo/core/theme/light_color.dart';

class CarListController extends ChangeNotifier {
  final String cityName;

  CarListController({required this.cityName}) {
    searchController.addListener(_applyFilters);
    fetchCars();
  }

  final TextEditingController searchController = TextEditingController();

  DateTimeRange? _dateRange;
  DateTimeRange? get dateRange => _dateRange;

  String get dateText {
    if (_dateRange == null) return 'Select dates';
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
    return '${fmt(_dateRange!.start)} – ${fmt(_dateRange!.end)}';
  }

  List<Car> _all = [];
  List<Car> _filtered = [];
  List<Car> get cars => _filtered;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> fetchCars() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cars')
          .where('city', isEqualTo: cityName)
          .get();
      _all = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Car.fromJson(data);
      }).toList();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Date picker ───────────────────────────────────────────────────────────

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

  // ── Filtering ─────────────────────────────────────────────────────────────
  // Runs every time the text field changes OR dates change.
  // Two independent filters are AND-ed:
  //
  //   1. Text — matches brand or model (case-insensitive substring).
  //   2. Date — the requested rental window [start, end] must fit inside
  //             the car's availability window [availableFrom, availableTo].
  //             Cars with no availability window are always shown.

  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();

    _filtered = _all.where((car) {
      // ── Text filter ──────────────────────────────────────────────────────
      if (query.isNotEmpty) {
        final haystack = '${car.brand} ${car.model}'.toLowerCase();
        if (!haystack.contains(query)) return false;
      }

      // ── Date availability filter ─────────────────────────────────────────
      if (_dateRange != null) {
        final start = _dateRange!.start;
        final end = _dateRange!.end;

        // Rental must start on or after availableFrom
        if (car.availableFrom != null && start.isBefore(car.availableFrom!)) {
          return false;
        }
        // Rental must end on or before availableTo
        if (car.availableTo != null && end.isAfter(car.availableTo!)) {
          return false;
        }
      }

      return true;
    }).toList();

    notifyListeners();
  }

  @override
  void dispose() {
    searchController.removeListener(_applyFilters);
    searchController.dispose();
    super.dispose();
  }
}
