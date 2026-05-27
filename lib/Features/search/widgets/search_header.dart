import 'package:flutter/material.dart';
import 'package:cargo/core/widgets/profile_menu_button.dart';
import 'package:cargo/core/theme/light_color.dart';

class SearchHeader extends StatelessWidget {
  const SearchHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Search',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: LightColors.textColor,
            ),
          ),
          ProfileMenuButton(),
        ],
      ),
    );
  }
}
