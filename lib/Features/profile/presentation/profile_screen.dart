import 'package:cargo/Features/auth/login_screen.dart';
import 'package:cargo/Features/profile/controllers/profile_controller.dart';
import 'package:cargo/Features/profile/presentation/owner_profile_view.dart';
import 'package:cargo/Features/profile/presentation/renter_profile_view.dart';
import 'package:cargo/core/constants/app_size.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileController(),
      child: const _ProfileBody(),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ProfileController>();

    if (!ctrl.isLoggedIn) return const _NotLoggedInView();

    if (ctrl.isLoading && ctrl.userData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(
          child: CircularProgressIndicator(color: LightColors.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: ctrl.loadUserData,
        color: LightColors.primaryColor,
        child: ctrl.isOwner
            ? OwnerProfileView(ctrl: ctrl)
            : RenterProfileView(ctrl: ctrl),
      ),
    );
  }
}

// ── Not Logged In ─────────────────────────────────────────────────────────────

class _NotLoggedInView extends StatelessWidget {
  const _NotLoggedInView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 56,
                  color: Colors.grey[400],
                ),
              ),
              SizedBox(height: AppSizes.ph24),
              Text(
                'Sign in to view your profile',
                style: TextStyle(
                  fontSize: AppSizes.sp18,
                  fontWeight: FontWeight.bold,
                  color: LightColors.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSizes.ph8),
              Text(
                'Access your trips, favorites, and settings',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSizes.ph30),
              AppButton(
                text: 'Sign In',
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
