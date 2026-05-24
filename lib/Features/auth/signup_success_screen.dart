import 'package:cargo/Features/Main/main_screen.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

class SignupSuccessScreen extends StatefulWidget {
  final String fullName;
  final String role;

  const SignupSuccessScreen({
    super.key,
    required this.fullName,
    required this.role,
  });

  @override
  State<SignupSuccessScreen> createState() => _SignupSuccessScreenState();
}

class _SignupSuccessScreenState extends State<SignupSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeIn,
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String get _firstName {
    final parts = widget.fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : widget.fullName;
  }

  String get _roleMessage {
    if (widget.role == 'owner') {
      return "Start listing your cars and\nearn money on your terms.";
    }
    return "Explore thousands of cars and\nbook your perfect ride.";
  }

  String get _ctaLabel {
    return widget.role == 'owner' ? 'List My First Car' : 'Explore Cars';
  }

  void _goToApp() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Success icon with animation
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: LightColors.primaryColor.withValues(alpha: 0.1),
                    border: Border.all(
                      color: LightColors.primaryColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 64,
                    color: LightColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    const Text(
                      'Account Created!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: LightColors.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome, $_firstName! 🎉',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: LightColors.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _roleMessage,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[500],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Role chip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: LightColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.role == 'owner'
                          ? Icons.vpn_key_rounded
                          : Icons.directions_car_rounded,
                      size: 16,
                      color: LightColors.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.role == 'owner'
                          ? 'Registered as Owner'
                          : 'Registered as Renter',
                      style: const TextStyle(
                        color: LightColors.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              AppButton(
                text: _ctaLabel,
                onTap: _goToApp,
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: _goToApp,
                child: Text(
                  'Go to Home',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
