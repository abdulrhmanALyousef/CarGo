import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cargo/models/car_model.dart';
import 'package:cargo/models/review_model.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';
import 'package:cargo/Features/chats/presentation/chat_screen.dart';

class CarDetailsController extends ChangeNotifier {
  final Car car;

  CarDetailsController({required this.car}) {
    fetchReviews();
    fetchOwnerInfo();
  }

  // ─── Image carousel ───────────────────────────────────────────────────────
  int _currentImageIndex = 0;
  int get currentImageIndex => _currentImageIndex;

  void setImageIndex(int index) {
    _currentImageIndex = index;
    notifyListeners();
  }

  // ─── Owner info ───────────────────────────────────────────────────────────
  String? _ownerName;
  String get ownerName => _ownerName ?? 'Owner';

  String? _ownerPhone;

  Future<void> fetchOwnerInfo() async {
    final ownerId = car.ownerId.trim();
    if (ownerId.isEmpty) return;
    print('[Call] fetchOwnerInfo — ownerId=$ownerId');
    try {
      final userData = await FirebaseService().getUserData(uid: ownerId);
      if (userData != null) {
        _ownerName = userData['fullName'] as String?;
        _ownerPhone = userData['phone'] as String?;
        print('[Call] owner fetched — name=$_ownerName | phone=$_ownerPhone');
        notifyListeners();
      } else {
        print('[Call] no user document found for ownerId=$ownerId');
      }
    } catch (e) {
      print('[Call] ERROR fetching owner info: $e');
    }
  }

  // ─── Call owner ───────────────────────────────────────────────────────────
  Future<void> callOwner(BuildContext context) async {
    final phone = _ownerPhone?.trim() ?? '';
    print('[Call] callOwner — phoneNumber="$phone"');

    if (phone.isEmpty) {
      print('[Call] phone number is empty — showing snackbar');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Owner phone number not available.')),
        );
      }
      return;
    }

    // Uri.parse('tel:…') is more reliable across platforms than Uri(scheme:).
    final uri = Uri.parse('tel:$phone');
    print('[Call] launching $uri');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        print('[Call] canLaunchUrl returned false for $uri');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch the phone app.')),
          );
        }
      }
    } catch (e) {
      print('[Call] ERROR launching dialer: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch the phone app.')),
        );
      }
    }
  }

  // ─── Open chat ────────────────────────────────────────────────────────────
  void openChat(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to start a chat.')),
      );
      return;
    }

    final ownerId = car.ownerId;
    final chatId = currentUserId.compareTo(ownerId) < 0
        ? '${currentUserId}_$ownerId'
        : '${ownerId}_$currentUserId';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          currentUserId: currentUserId,
          otherUserId: ownerId,
          otherUserName: _ownerName ?? 'Owner',
        ),
      ),
    );
  }

  // ─── Reviews ──────────────────────────────────────────────────────────────
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
      final data = await FirebaseService().getReviews(car.id);
      _reviews = data.map((json) => Review.fromJson(json)).toList();

      for (final review in _reviews) {
        if (review.userId.isNotEmpty) {
          try {
            final userData =
                await FirebaseService().getUserData(uid: review.userId);
            if (userData != null) {
              review.userName = userData['fullName'] as String? ?? 'User';
              review.userImage = userData['profileImage'] as String?;
            }
          } catch (_) {}
        }
      }
    } catch (_) {
    } finally {
      _isLoadingReviews = false;
      notifyListeners();
    }
  }
}
