import 'package:flutter/material.dart';
import 'package:cargo/core/constants/app_size.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assests/images/splash.png',
          fit: BoxFit.cover,
          width: AppSizes.w200,
          height: AppSizes.h90,
        ),
      ),
    );
  }
}
