import 'package:flutter/material.dart';
import 'package:cargo/core/widgets/profile_icon_widget.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';
import 'package:cargo/core/dataSource/local_data/preferences_manager.dart';
import 'package:cargo/Features/auth/login_screen.dart';
import 'package:cargo/Features/Main/main_screen.dart';
import 'package:cargo/Features/trips/my_trips_screen.dart';
import 'package:cargo/Features/mycars/my_cars_screen.dart';

// ── ProfileMenuButton ─────────────────────────────────────────────────────────
//
// A ProfileIconWidget wrapped in a PopupMenuButton that shows the same
// profile menu on every screen: Log In / My Trips / My Cars / Log Out.
//
// Drop-in replacement for the bare ProfileIconWidget wherever a tappable
// profile menu is needed.
//
// Parameters mirror ProfileIconWidget:
//   size            — circle diameter (default: 48)
//   imagePath       — asset path (default: imageicon.png)
//   backgroundColor — optional fill / fallback bg
//   iconColor       — optional fallback icon colour
//   color           — optional ring colour

class ProfileMenuButton extends StatelessWidget {
  final double size;
  final String imagePath;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? color;

  const ProfileMenuButton({
    super.key,
    this.size = 48,
    this.imagePath = 'assets/images/imageicon.png',
    this.backgroundColor,
    this.iconColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        if (value == 'login') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        } else if (value == 'my_trips') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyTripsScreen()),
          );
        } else if (value == 'my_cars') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyCarsScreen()),
          );
        } else if (value == 'logout') {
          await FirebaseService().logout();
          await PreferencesManager().setBool('isloggedin', false);
          if (!context.mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
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
                  Icon(Icons.luggage_outlined,
                      size: 20, color: LightColors.primaryColor),
                  SizedBox(width: 8),
                  Text('My Trips'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'my_cars',
              child: Row(
                children: [
                  Icon(Icons.car_rental,
                      size: 20, color: LightColors.primaryColor),
                  SizedBox(width: 8),
                  Text('My Cars'),
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
      child: ProfileIconWidget(
        size: size,
        imagePath: imagePath,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
        color: color,
      ),
    );
  }
}
