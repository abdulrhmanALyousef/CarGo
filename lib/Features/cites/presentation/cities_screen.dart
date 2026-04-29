import 'package:flutter/material.dart';
import 'package:cargo/core/widgets/item_card.dart';
import 'package:cargo/core/widgets/profile_menu_button.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/Features/cars/car_list_screen.dart';

class _City {
  final String name;
  final String assetPath;
  const _City(this.name, this.assetPath);
}

class CitiesScreen extends StatelessWidget {
  const CitiesScreen({super.key});

  static const _cities = [
    _City('Riyadh', 'assets/cityimages/riyadhimage.jpg'),
    _City('Jeddah', 'assets/cityimages/jeddahimage.jpg'),
    _City('Qassim', 'assets/cityimages/qassimimage.jpg'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LightColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: LightColors.backgroundColor,
        elevation: 0,
        title: const Text(
          'Browse by City',
          style: TextStyle(
            color: LightColors.textColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ProfileMenuButton(),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _cities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final city = _cities[index];
          return ItemCard(
            assetPath: city.assetPath,
            label: city.name,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CarListScreen(cityName: city.name),
              ),
            ),
          );
        },
      ),
    );
  }
}
