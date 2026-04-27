import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/core/widgets/search_widget.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/Features/home/controllers/home_controller.dart';
import 'package:cargo/Features/home/widgets/car_card.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';
import 'package:cargo/core/dataSource/local_data/preferences_manager.dart';
import 'package:cargo/Features/auth/login_screen.dart';
import 'package:cargo/Features/Main/main_screen.dart';
import 'package:cargo/Features/trips/my_trips_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeController(),
      child: Builder(
        builder: (context) {
          final ctrl = context.watch<HomeController>();

          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ──────────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'What do you want to',
                                style: TextStyle(fontSize: 14, color: LightColors.textColor),
                              ),
                              Text(
                                'Ride Today',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: LightColors.textColor,
                                ),
                              ),
                            ],
                          ),
                          PopupMenuButton<String>(
                            offset: const Offset(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (value) async {
                              if (value == 'login') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              } else if (value == 'my_trips') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MyTripsScreen(),
                                  ),
                                );
                              } else if (value == 'logout') {
                                await FirebaseService().logout();
                                await PreferencesManager().setBool('isloggedin', false);
                                if (!context.mounted) return;
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MainScreen(),
                                  ),
                                  (_) => false,
                                );
                              }
                            },
                            itemBuilder: (_) {
                              final isLoggedIn = FirebaseService().isUserLoggedIn();
                              return [
                                if (!isLoggedIn)
                                  const PopupMenuItem<String>(
                                    value: 'login',
                                    child: Row(
                                      children: [
                                        Icon(Icons.login, size: 20, color: LightColors.primaryColor),
                                        SizedBox(width: 8),
                                        Text('Log In'),
                                      ],
                                    ),
                                  )
                                else ...[
                                  const PopupMenuItem<String>(
                                    value: 'my_trips',
                                    child: Row(
                                      children: [
                                        Icon(Icons.luggage_outlined, size: 20, color: LightColors.primaryColor),
                                        SizedBox(width: 8),
                                        Text('My Trips'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'logout',
                                    child: Row(
                                      children: [
                                        Icon(Icons.logout, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Log Out'),
                                      ],
                                    ),
                                  ),
                                ],
                              ];
                            },
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/imageicon.png',
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Search Widget ────────────────────────────────────────
                      const SearchWidget(),

                      const SizedBox(height: 24),

                      // ── Available Cars Header ────────────────────────────────
                      const Text(
                        'Available Cars',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: LightColors.textColor,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Cars List ────────────────────────────────────────────
                      if (ctrl.isLoadingCars)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(
                              color: LightColors.primaryColor,
                            ),
                          ),
                        )
                      else if (ctrl.carsError != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 12),
                                Text(
                                  'Failed to load cars',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => ctrl.fetchCars(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: LightColors.primaryColor,
                                  ),
                                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (ctrl.cars.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No cars available',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: ctrl.cars.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return CarCard(model: ctrl.cars[index]);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
