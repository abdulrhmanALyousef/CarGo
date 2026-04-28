import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // ── Filter panel visibility ───────────────────────────────────────────────
  bool _showFilters = false;
  bool get showFilters => _showFilters;

  void toggleFilters() {
    _showFilters = !_showFilters;
    notifyListeners();
  }

  // ── Price range (slider) ──────────────────────────────────────────────────
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
    'Family',
    'Sport',
    'Off-Road',
    'SUV',
    'Luxury',
    'Economic',
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

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchCars() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cars')
          .where('city', isEqualTo: cityName)
          .get();
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      _all = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Car.fromJson(data);
          })
          .where((car) => car.ownerId != currentUid)
          .toList();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Filtering ─────────────────────────────────────────────────────────────
  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();

    _filtered = _all.where((car) {
      // Text filter
      if (query.isNotEmpty) {
        final haystack = '${car.brand} ${car.model}'.toLowerCase();
        if (!haystack.contains(query)) return false;
      }

      // Price range filter
      if (car.pricePerDay < _priceRange.start ||
          car.pricePerDay > _priceRange.end) {
        return false;
      }

      // Car type filter
      if (_selectedTypes.isNotEmpty) {
        final matchesType = _selectedTypes.any((type) {
          final t = type.toLowerCase();
          return car.brand.toLowerCase().contains(t) ||
              car.overview.toLowerCase().contains(t) ||
              car.transmission.toLowerCase().contains(t);
        });
        if (!matchesType) return false;
      }

      // Date availability filter
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
    searchController.removeListener(_applyFilters);
    searchController.dispose();
    super.dispose();
  }
}