import 'package:flutter/material.dart';
import 'package:cargo/core/widgets/profile_icon_widget.dart';
import 'package:cargo/core/theme/light_color.dart';

class SearchHeader extends StatelessWidget {
  const SearchHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          ProfileIconWidget(
            size: 44,
            backgroundColor: Colors.grey.shade300,
            iconColor: Colors.white,
          ),
          const Spacer(),
          const Text(
            'Search',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: LightColors.textColor,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44), // balance the avatar
        ],
      ),
    );
  }
}
