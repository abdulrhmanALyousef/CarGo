import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/Features/home/home_screen.dart';
import 'package:cargo/Features/search/presentation/search_screen.dart';
import 'package:cargo/Features/cites/presentation/cities_screen.dart';
import 'package:cargo/Features/profile/presentation/profile_screen.dart';
import 'package:cargo/Features/chats/presentation/chats_screen.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/core/controllers/user_avatar_controller.dart';


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserAvatarController(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const CitiesScreen(),
    const ProfileScreen(),
    const ChatsScreen(),
  ];

  List<BottomNavigationBarItem> get _navigationItems => [
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
      icon: Image.asset('assets/images/cityimage.png', width: 24, height: 24),
      activeIcon: Image.asset('assets/images/cityimage.png', width: 24, height: 24, color: LightColors.primaryColor),
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
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: LightColors.primaryColor,
        unselectedItemColor: LightColors.textColor,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: _navigationItems,
      ),
    );
  }
}