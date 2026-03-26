import 'package:flutter/material.dart';
import 'package:cargo/core/widgets/search_widget.dart';
import 'package:cargo/core/theme/light_color.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFE0E0E0),
                    child: ClipOval(
                      child: Image.network(
                        'https://i.pravatar.cc/100',
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Search Widget ────────────────────────────────────────
              const SearchWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
