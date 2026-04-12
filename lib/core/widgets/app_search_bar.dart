import 'package:flutter/material.dart';
import 'package:cargo/core/theme/light_color.dart';

/// A simple text search field that matches the app's SearchWidget style.
/// Bind [controller] to react to input changes via [addListener].
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search…',
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCFCFCF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9E9E9E), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontSize: 14,
          color: LightColors.textColor,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF555555),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF555555),
            size: 18,
          ),
          filled: true,
          fillColor: const Color(0xFFBDBDBD),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}