import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cargo/models/car_model.dart';

class SearchCarController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Search ───────────────────────────────────────────────────────────
  final TextEditingController searchTextController = TextEditingController();
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // ── Price Range ──────────────────────────────────────────────────────
  static const double minPrice = 0;
  static const double maxPrice = 500;
  RangeValues _priceRange = const RangeValues(50, 300);
  RangeValues get priceRange => _priceRange;

  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();

  // ── Seats Filter ────────────────────────────────────────────────────
  final List<String> seatOptions = ['2', '4', '5', '7+'];
  String? _selectedSeats;
  String? get selectedSeats => _selectedSeats;

  // ── Transmission Filter ─────────────────────────────────────────────
  final List<String> transmissionOptions = ['Automatic', 'Manual'];
  String? _selectedTransmission;
  String? get selectedTransmission => _selectedTransmission;

  // ── Fuel Type Filter ────────────────────────────────────────────────
  final List<String> fuelOptions = ['Gasoline', 'Hybrid', 'Electric'];
  String? _selectedFuel;
  String? get selectedFuel => _selectedFuel;

  // ── Results ──────────────────────────────────────────────────────────
  List<Car> _allCars = [];
  List<Car> _filteredCars = [];
  List<Car> get filteredCars => _filteredCars;
  int get resultCount => _filteredCars.length;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ── Filter panel visibility ──────────────────────────────────────────
  bool _showFilters = false;
  bool get showFilters => _showFilters;

  void toggleFilters() {
    _showFilters = !_showFilters;
    notifyListeners();
  }

  // ────────────────────────────────────────────────────────────────────
  SearchCarController() {
    _syncPriceTextFields();
    minPriceController.addListener(_onMinPriceTyped);
    maxPriceController.addListener(_onMaxPriceTyped);
    fetchCars();
    searchTextController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchTextController.removeListener(_onSearchChanged);
    searchTextController.dispose();
    minPriceController.removeListener(_onMinPriceTyped);
    maxPriceController.removeListener(_onMaxPriceTyped);
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  // ── Price text ↔ slider sync ────────────────────────────────────────
  bool _updatingFromSlider = false;

  void _syncPriceTextFields() {
    minPriceController.text = _priceRange.start.round().toString();
    maxPriceController.text = _priceRange.end.round().toString();
  }

  void _onMinPriceTyped() {
    if (_updatingFromSlider) return;
    final val = double.tryParse(minPriceController.text);
    if (val == null) return;
    final clamped = val.clamp(minPrice, _priceRange.end);
    _priceRange = RangeValues(clamped, _priceRange.end);
    _applyFilters();
    notifyListeners();
  }

  void _onMaxPriceTyped() {
    if (_updatingFromSlider) return;
    final val = double.tryParse(maxPriceController.text);
    if (val == null) return;
    final clamped = val.clamp(_priceRange.start, maxPrice);
    _priceRange = RangeValues(_priceRange.start, clamped);
    _applyFilters();
    notifyListeners();
  }

  void updatePriceRange(RangeValues values) {
    _priceRange = values;
    _updatingFromSlider = true;
    _syncPriceTextFields();
    _updatingFromSlider = false;
    _applyFilters();
    notifyListeners();
  }

  void incrementMinPrice() {
    final newVal = (_priceRange.start + 10).clamp(minPrice, _priceRange.end);
    updatePriceRange(RangeValues(newVal, _priceRange.end));
  }

  void decrementMinPrice() {
    final newVal = (_priceRange.start - 10).clamp(minPrice, _priceRange.end);
    updatePriceRange(RangeValues(newVal, _priceRange.end));
  }

  void incrementMaxPrice() {
    final newVal = (_priceRange.end + 10).clamp(_priceRange.start, maxPrice);
    updatePriceRange(RangeValues(_priceRange.start, newVal));
  }

  void decrementMaxPrice() {
    final newVal = (_priceRange.end - 10).clamp(_priceRange.start, maxPrice);
    updatePriceRange(RangeValues(_priceRange.start, newVal));
  }

  // ── Filter selections ───────────────────────────────────────────────
  void selectSeats(String? seats) {
    _selectedSeats = (_selectedSeats == seats) ? null : seats;
    _applyFilters();
    notifyListeners();
  }

  void selectTransmission(String? transmission) {
    _selectedTransmission =
        (_selectedTransmission == transmission) ? null : transmission;
    _applyFilters();
    notifyListeners();
  }

  void selectFuel(String? fuel) {
    _selectedFuel = (_selectedFuel == fuel) ? null : fuel;
    _applyFilters();
    notifyListeners();
  }

  // ── Firestore fetch ──────────────────────────────────────────────────
  Future<void> fetchCars() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('cars').get();
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      _allCars = snapshot.docs
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────
  void _onSearchChanged() {
    _searchQuery = searchTextController.text.trim();
    _applyFilters();
    notifyListeners();
  }

  // ── Filtering logic (local, after Firestore fetch) ───────────────────
  void _applyFilters() {
    _filteredCars = _allCars.where((car) {
      // Price filter
      if (car.pricePerDay < _priceRange.start ||
          car.pricePerDay > _priceRange.end) {
        return false;
      }

      // Text search – match against brand, model, or location
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final haystack =
            '${car.brand} ${car.model} ${car.location}'.toLowerCase();
        if (!haystack.contains(q)) return false;
      }

      // Seats filter
      if (_selectedSeats != null) {
        if (_selectedSeats == '7+') {
          if (car.seats < 7) return false;
        } else {
          final seatCount = int.tryParse(_selectedSeats!) ?? 0;
          if (car.seats != seatCount) return false;
        }
      }

      // Transmission filter
      if (_selectedTransmission != null) {
        if (car.transmission.toLowerCase() !=
            _selectedTransmission!.toLowerCase()) {
          return false;
        }
      }

      // Fuel type filter
      if (_selectedFuel != null) {
        final fuel = _selectedFuel!.toLowerCase();
        if (fuel == 'electric') {
          if (!car.isElectric) return false;
        } else if (fuel == 'hybrid') {
          final carDesc =
              '${car.overview} ${car.brand} ${car.model}'.toLowerCase();
          if (!carDesc.contains('hybrid')) return false;
        } else {
          // Gasoline = not electric and not hybrid
          if (car.isElectric) return false;
          final carDesc =
              '${car.overview} ${car.brand} ${car.model}'.toLowerCase();
          if (carDesc.contains('hybrid')) return false;
        }
      }

      return true;
    }).toList();
  }

  void clearFilters() {
    _priceRange = const RangeValues(50, 300);
    _syncPriceTextFields();
    _selectedSeats = null;
    _selectedTransmission = null;
    _selectedFuel = null;
    searchTextController.clear();
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }
}
