import 'package:flutter/material.dart';

class HomeController extends ChangeNotifier {
  String _location = '';
  DateTimeRange? _dateRange;

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
}

