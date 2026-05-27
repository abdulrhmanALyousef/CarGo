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
  static const double maxPrice = 2000;
  RangeValues _priceRange = const RangeValues(minPrice, maxPrice);
  RangeValues get priceRange => _priceRange;

  // ── Car Types — must match categories used in AddCarController ──────
  final List<String> carTypes = [
    'Sedan',
    'SUV',
    'Hatchback',
    'Coupe',
    'Pickup',
    'Van',
    'Luxury',
    'Convertible',
  ];
  final Set<String> _selectedTypes = {};
  Set<String> get selectedTypes => _selectedTypes;

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
    fetchCars();
    searchTextController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchTextController.removeListener(_onSearchChanged);
    searchTextController.dispose();
    super.dispose();
  }

  // ── Firestore fetch ──────────────────────────────────────────────────
  Future<void> fetchCars() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('cars').get();
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      // Only show cars that are ready for booking. 'at_hub' means verified but
      // not yet listed — it must not appear in search results.
      const visibleStatuses = {
        'available', 'ready_for_rental', 'reserved',
      };
      _allCars = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Car.fromJson(data);
          })
          .where((car) =>
              car.ownerId != currentUid &&
              visibleStatuses.contains(car.hubStatus))
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

  void updatePriceRange(RangeValues values) {
    _priceRange = values;
    _applyFilters();
    notifyListeners();
  }

  void toggleType(String type) {
    if (_selectedTypes.contains(type)) {
      _selectedTypes.remove(type);
    } else {
      _selectedTypes.add(type);
    }
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

      // Text search — match against brand, model, category, city, hub location
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final haystack =
            '${car.brand} ${car.model} ${car.category} ${car.city} ${car.location} ${car.hubLocation}'
                .toLowerCase();
        if (!haystack.contains(q)) return false;
      }

      // Car type filter — matches against the category field stored in Firestore
      if (_selectedTypes.isNotEmpty &&
          !_selectedTypes.contains(car.category)) {
        return false;
      }

      return true;
    }).toList();
  }

  void clearFilters() {
    _priceRange = const RangeValues(minPrice, maxPrice);
    _selectedTypes.clear();
    searchTextController.clear();
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }
}

