import 'package:flutter/material.dart';
import 'package:cargo/Features/home/models/car_model.dart';
import 'package:cargo/Features/details/models/review_model.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';

class CarDetailsController extends ChangeNotifier {
  final Car car;

  CarDetailsController({required this.car}) {
    fetchReviews();
  }

  int _currentImageIndex = 0;
  int get currentImageIndex => _currentImageIndex;

  void setImageIndex(int index) {
    _currentImageIndex = index;
    notifyListeners();
  }

  List<Review> _reviews = [];
  List<Review> get reviews => _reviews;

  bool _isLoadingReviews = false;
  bool get isLoadingReviews => _isLoadingReviews;

  double get averageRating {
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.fold<double>(0, (sum, r) => sum + r.rating);
    return total / _reviews.length;
  }

  int get totalReviews => _reviews.length;

  Map<int, double> get ratingDistribution {
    final Map<int, int> counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _reviews) {
      final star = r.rating.round().clamp(1, 5);
      counts[star] = (counts[star] ?? 0) + 1;
    }
    if (_reviews.isEmpty) return {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    return counts.map((star, count) => MapEntry(star, count / _reviews.length));
  }

  Future<void> fetchReviews() async {
    _isLoadingReviews = true;
    notifyListeners();

    try {
      print('DEBUG: Fetching reviews for car.id = "${car.id}"');
      final data = await FirebaseService().getReviews(car.id);
      print('DEBUG: Reviews found = ${data.length}');
      for (final d in data) {
        print('DEBUG: Review data = $d');
      }
      _reviews = data.map((json) => Review.fromJson(json)).toList();

      for (final review in _reviews) {
        if (review.userId.isNotEmpty) {
          try {
            final userData = await FirebaseService().getUserData(uid: review.userId);
            if (userData != null) {
              review.userName = userData['fullName'] as String? ?? 'User';
              review.userImage = userData['profileImage'] as String?;
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      print('Fetch Reviews Error: $e');
    } finally {
      _isLoadingReviews = false;
      notifyListeners();
    }
  }
}
