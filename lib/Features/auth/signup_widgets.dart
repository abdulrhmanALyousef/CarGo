import 'package:cargo/core/theme/light_color.dart';
import 'package:flutter/material.dart';

// Shared widgets used across multi-step signup screens.

class StepAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StepAppBar({super.key, required this.step, required this.total});
  final int step;
  final int total;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Step $step of $total',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class StepProgressBar extends StatelessWidget {
  const StepProgressBar({super.key, required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = step / total;
    return Container(
      height: 3,
      color: const Color(0xFFEEEEEE),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: const BoxDecoration(
            color: LightColors.primaryColor,
            borderRadius:
                BorderRadius.horizontal(right: Radius.circular(4)),
          ),
        ),
      ),
    );
  }
}

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final isRenter = role == 'renter';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: LightColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRenter
                ? Icons.directions_car_rounded
                : Icons.vpn_key_rounded,
            size: 14,
            color: LightColors.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            isRenter ? 'RENTER' : 'OWNER',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: LightColors.primaryColor,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
