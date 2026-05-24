import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cargo/core/widgets/location_sheet.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';
import 'package:cargo/models/car_model.dart';

class HomeController extends ChangeNotifier {
  HomeController() {
    fetchCars();
  }

  String _location = '';
  DateTimeRange? _dateRange;
  String _searchQuery = '';

  // _cars holds every car fetched from Firestore.
  // _displayedCars is the subset shown after search/filter.
  List<Car> _cars = [];
  List<Car> _displayedCars = [];

  bool _isLoadingCars = false;
  bool get isLoadingCars => _isLoadingCars;

  String? _carsError;
  String? get carsError => _carsError;

  String get location => _location;
  DateTimeRange? get dateRange => _dateRange;
  String get searchQuery => _searchQuery;

  /// True when any active filter is applied.
  bool get hasActiveFilter => _dateRange != null || _searchQuery.isNotEmpty;

  /// The list the UI renders — filtered when the user has searched.
  List<Car> get cars => _displayedCars;

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
    notifyListeners();
  }

  void setSearchQuery(String val) {
    _searchQuery = val.trim();
    _applyFilters();
  }

  void clearFilters() {
    _location = '';
    _dateRange = null;
    _searchQuery = '';
    _displayedCars = List.from(_cars);
    notifyListeners();
  }

  // ── Search ──────────────────────────────────────────────────────────────────
  // Applies all active filters: text query, date range, and location.
  // Location is treated as optional for broader discoverability.
  void search(BuildContext context) {
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<Car>.from(_cars);

    // ── Text search: brand, model, category, city, location ────────────────
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

    // ── Date range: check car availability window ───────────────────────────
    if (_dateRange != null) {
      final start = _dateRange!.start;
      final end = _dateRange!.end;
      filtered = filtered.where((car) {
        if (car.availableFrom != null &&
            start.isBefore(car.availableFrom!)) {
          return false;
        }
        if (car.availableTo != null && end.isAfter(car.availableTo!)) {
          return false;
        }
        return true;
        // TODO: Also cross-check against confirmed bookings for this car
        // to prevent showing cars already booked for the selected dates.
        // Requires a Firestore query per car — implement when booking
        // volume justifies the extra reads.
      }).toList();
    }

    _displayedCars = filtered;
    notifyListeners();
  }

  // ── Pickers ─────────────────────────────────────────────────────────────────

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

  // ── Data ─────────────────────────────────────────────────────────────────────

  Future<void> fetchCars() async {
    _isLoadingCars = true;
    _carsError = null;
    notifyListeners();

    try {
      final data = await FirebaseService().getCars();
      final currentUid = FirebaseAuth.instance.currentUser?.uid;

      // TODO: Replace this query with AI recommendation logic.
      // Future recommendation system should rank cars based on renter history,
      // preferences, past booked categories, location, and interaction behavior.

      // Show all cars that belong to other owners. Hub status filtering is done
      // here to include cars that are ready for rental at the hub while also
      // showing legacy cars (no hubStatus field) for backwards compatibility
      // during development. In production, narrow this to visibleStatuses only.
      const visibleStatuses = {'at_hub', 'available', 'ready_for_rental'};

      var allOtherCars = data
          .map((json) => Car.fromJson(json))
          .where((car) => car.ownerId != currentUid)
          .toList();

      // If filtering by hub status returns results, use filtered list.
      // If not (legacy data without hubStatus), show all other-owner cars.
      final hubFiltered = allOtherCars
          .where((car) => visibleStatuses.contains(car.hubStatus))
          .toList();

      _cars = hubFiltered.isNotEmpty ? hubFiltered : allOtherCars;
      _displayedCars = List.from(_cars); // show all on first load
    } catch (e) {
      _carsError = e.toString();
    } finally {
      _isLoadingCars = false;
      notifyListeners();
    }
  }
}
