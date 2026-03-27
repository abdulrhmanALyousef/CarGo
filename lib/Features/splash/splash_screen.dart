import 'package:flutter/material.dart';
import 'package:cargo/core/constants/app_size.dart';
import 'package:cargo/core/dataSource/local_data/preferences_manager.dart';
import 'package:cargo/Features/auth/login_screen.dart';
import 'package:cargo/Features/Main/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  void _navigateAfterSplash() async {
    await Future.delayed(const Duration(seconds: 2));

    final bool isLoggedIn = PreferencesManager().getBool('isloggedin') ?? false;

    if (!mounted) {
      return;
    }

    if (!isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) {
            return const LoginScreen();
          },
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) {
            return const MainScreen();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assests/images/splash.png',
          fit: BoxFit.contain,
          width: AppSizes.splashImageWidth,
          height: AppSizes.splashImageHeight,
        ),
      ),
    );
  }
}
