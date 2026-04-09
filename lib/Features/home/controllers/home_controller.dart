import 'package:flutter/material.dart';
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

  List<Car> _cars = [];
  List<Car> get cars => _cars;

  bool _isLoadingCars = false;
  bool get isLoadingCars => _isLoadingCars;

  String? _carsError;
  String? get carsError => _carsError;

  String get location => _location;
  DateTimeRange? get dateRange => _dateRange;

  String get dateText {
    if (_dateRange == null) return '15.08 – 19.8';
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

  void search(BuildContext context) {
    if (_location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pick up location')),
      );
      return;
    }
    // TODO: navigate to results screen
  }

  Future<void> openLocation(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFFD4D4D4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const LocationSheet(),
    );
    if (result != null) {
      setLocation(result);
    }
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
            surface: const Color(0xFFD4D4D4),
          ),
        ),
        child: child!,
      ),
    );
    if (result != null) {
      setDateRange(result);
    }
  }

  Future<void> fetchCars() async {
    _isLoadingCars = true;
    _carsError = null;
    notifyListeners();

    try {
      final data = await FirebaseService().getCars();
      _cars = data.map((json) => Car.fromJson(json)).toList();
    } catch (e) {
      _carsError = e.toString();
    } finally {
      _isLoadingCars = false;
      notifyListeners();
    }
  }
}
