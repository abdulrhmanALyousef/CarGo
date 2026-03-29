import 'package:flutter/material.dart';
import 'package:cargo/Features/home/models/car_model.dart';
import 'package:cargo/core/theme/light_color.dart';

class CarDetailsScreen extends StatelessWidget {
  const CarDetailsScreen({super.key, required this.model});

  final Car model;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(model.brand),
        backgroundColor: Colors.white,
        foregroundColor: LightColors.textColor,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Under Development'),
      ),
    );
  }
}
