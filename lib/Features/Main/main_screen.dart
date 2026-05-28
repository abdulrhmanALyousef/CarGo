import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cargo/Features/home/home_screen.dart';
import 'package:cargo/Features/search/presentation/search_screen.dart';
import 'package:cargo/Features/cites/presentation/cities_screen.dart';
import 'package:cargo/Features/profile/presentation/profile_screen.dart';
import 'package:cargo/Features/chats/presentation/chats_screen.dart';
import 'package:cargo/Features/owner/dashboard/owner_dashboard_screen.dart';
import 'package:cargo/Features/mycars/my_cars_screen.dart';
import 'package:cargo/Features/owner/booking_requests_screen.dart';
import 'package:cargo/Features/trips/my_trips_screen.dart';
import 'package:cargo/Features/notifications/notification_service.dart';
import 'package:cargo/Features/notifications/notifications_screen.dart';
import 'package:cargo/core/theme/light_color.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool? _isOwner;

  // Owner tab indices
  static const _ownerBookingsTab = 2;

  @override
  void initState() {
    super.initState();
    _detectRole();
    NotificationService.pendingNavigation.addListener(_handlePendingNavigation);
  }

  @override
  void dispose() {
    NotificationService.pendingNavigation
        .removeListener(_handlePendingNavigation);
    super.dispose();
  }

  void _handlePendingNavigation() {
    final target = NotificationService.pendingNavigation.value;
    if (target == null || target.isEmpty) return;
    NotificationService.pendingNavigation.value = null;
    if (!mounted) return;

    switch (target) {
      case 'booking_requests':
        if (_isOwner == true) {
          setState(() => _currentIndex = _ownerBookingsTab);
        } else {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BookingRequestsScreen()));
        }
        break;
      case 'my_trips':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MyTripsScreen()));
        break;
      case 'notifications':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()));
        break;
      default:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    }
  }

  Future<void> _detectRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isOwner = false);
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!mounted) return;
    final data = doc.data();
    final roles = data?['roles'];
    bool isOwner = false;
    if (roles is List) {
      isOwner = roles.contains('owner');
    } else {
      isOwner = (data?['role'] as String?) == 'owner';
    }
    setState(() => _isOwner = isOwner);
  }

  // ── Owner nav ──────────────────────────────────────────────────────────────

  static const _ownerScreens = [
    OwnerDashboardScreen(),
    MyCarsScreen(),
    BookingRequestsScreen(),
    ChatsScreen(),
    ProfileScreen(),
  ];

  static const _ownerItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard_rounded),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.garage_outlined),
      activeIcon: Icon(Icons.garage_rounded),
      label: 'My Cars',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.pending_actions_outlined),
      activeIcon: Icon(Icons.pending_actions_rounded),
      label: 'Bookings',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat_bubble_outline_rounded),
      activeIcon: Icon(Icons.chat_bubble_rounded),
      label: 'Chats',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline_rounded),
      activeIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  // ── Renter nav ─────────────────────────────────────────────────────────────

  static const _renterScreens = [
    HomeScreen(),
    SearchScreen(),
    CitiesScreen(),
    ProfileScreen(),
    ChatsScreen(),
  ];

  List<BottomNavigationBarItem> get _renterItems => [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search_rounded),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Image.asset('assets/images/cityimage.png',
              width: 24, height: 24),
          activeIcon: Image.asset('assets/images/cityimage.png',
              width: 24, height: 24, color: LightColors.primaryColor),
          label: 'Cities',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          activeIcon: Icon(Icons.chat_bubble_rounded),
          label: 'Chats',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    if (_isOwner == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: LightColors.primaryColor),
        ),
      );
    }

    final screens = _isOwner! ? _ownerScreens : _renterScreens;
    final items = _isOwner! ? _ownerItems : _renterItems;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: LightColors.primaryColor,
        unselectedItemColor: LightColors.textColor,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: items,
      ),
    );
  }
}
