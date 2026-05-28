import 'package:flutter/material.dart';
import '../../../core/dataSource/remote_data/firebase_service.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/errors/app_messenger.dart';
import '../../../models/car_model.dart';

class FavoritesController extends ChangeNotifier {
  List<Car> _favorites = [];
  bool _isLoading = false;
  String? _error;

  List<Car> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  FavoritesController() {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await FirebaseService().getFavoriteCars();
      _favorites = data.map((json) => Car.fromJson(json)).toList();
    } catch (e) {
      _error = ErrorHandler.handle(e, tag: 'FavoritesController').userMessage;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFavorite(BuildContext context, String carId) async {
    try {
      await FirebaseService().toggleFavorite(carId);
      _favorites.removeWhere((car) => car.id == carId);
      notifyListeners();
    } catch (e) {
      if (context.mounted) {
        AppMessenger.showError(context, 'Failed to remove from favorites. Please try again.');
      }
    }
  }
}
