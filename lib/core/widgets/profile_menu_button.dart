import 'package:cached_network_image/cached_network_image.dart';
import 'package:cargo/core/controllers/user_avatar_controller.dart';
import 'package:cargo/core/dataSource/remote_data/firebase_service.dart';
import 'package:cargo/Features/auth/login_screen.dart';
import 'package:cargo/Features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Avatar button used in the home screen header.
/// Taps navigate to ProfileScreen (logged in) or LoginScreen (not logged in).
/// The avatar image is kept in sync with the user's Firestore profileImageUrl
/// via [UserAvatarController], which is provided at the app root.
class ProfileMenuButton extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const ProfileMenuButton({
    super.key,
    this.size = 48,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = context.watch<UserAvatarController>().profileImageUrl;

    return GestureDetector(
      onTap: () {
        final destination = FirebaseService().isUserLoggedIn()
            ? const ProfileScreen()
            : const LoginScreen();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destination),
        );
      },
      child: _AvatarCircle(
        imageUrl: imageUrl,
        size: size,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.imageUrl,
    required this.size,
    this.backgroundColor,
    this.iconColor,
  });

  final String imageUrl;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Colors.grey.shade300;
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: bg,
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _fallbackIcon(bg),
              )
            : _fallbackIcon(bg),
      ),
    );
  }

  Widget _fallbackIcon(Color bg) => Icon(
        Icons.person,
        color: iconColor ?? Colors.white,
        size: size * 0.55,
      );
}
