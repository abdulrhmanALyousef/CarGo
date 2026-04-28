import 'package:flutter/material.dart';

// ── ProfileIconWidget ─────────────────────────────────────────────────────────
//
// Canonical circular profile / avatar icon used throughout the app.
// Extracted from the Home screen — do NOT create separate avatar widgets.
//
// Defaults match the Home screen: size 48, imageicon.png asset.
//
// Parameters:
//   size            — diameter of the circle (default: 48)
//   imagePath       — asset path for the image (default: imageicon.png)
//   backgroundColor — fill colour shown behind the image / as fallback bg
//   iconColor       — colour of the fallback person icon when the image fails
//   color           — optional ring / border colour drawn outside the circle
//
// Usage examples:
//
//   ProfileIconWidget()                                   // home default
//   ProfileIconWidget(size: 36, imagePath: 'assets/images/manicon.png')
//   ProfileIconWidget(size: 44, backgroundColor: Colors.grey.shade300)

class ProfileIconWidget extends StatelessWidget {
  final double size;
  final String imagePath;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? color; // ring / border colour (optional)

  const ProfileIconWidget({
    super.key,
    this.size = 48,
    this.imagePath = 'assets/images/imageicon.png',
    this.backgroundColor,
    this.iconColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Widget circle = ClipOval(
      child: Container(
        width: size,
        height: size,
        color: backgroundColor,
        child: Image.asset(
          imagePath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: backgroundColor ?? Colors.grey.shade300,
            child: Icon(
              Icons.person,
              color: iconColor ?? Colors.white,
              size: size * 0.55,
            ),
          ),
        ),
      ),
    );

    if (color != null) {
      return Container(
        width: size + 4,
        height: size + 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color!, width: 2),
        ),
        child: circle,
      );
    }

    return circle;
  }
}
