import 'package:flutter/material.dart';
import 'package:cargo/core/theme/light_color.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Services'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text(
          'Services are under development',
          style: TextStyle(
            fontSize: 16,
            color: LightColors.textColor,
          ),
        ),
      ),
    );
  }
}