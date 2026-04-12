import 'package:flutter/material.dart';
import 'package:cargo/core/widgets/item_card.dart';
import 'package:cargo/models/car_model.dart';
import 'package:cargo/Features/details/car_details_screen.dart';

/// Thin wrapper over [ItemCard] for displaying a [Car].
/// Keeps all existing call-sites working without changes.
class CarCard extends StatelessWidget {
  const CarCard({super.key, required this.model});

  final Car model;

  @override
  Widget build(BuildContext context) {
    return ItemCard(
      networkUrl: model.images.isNotEmpty ? model.images.first : '',
      label: '${model.brand} ${model.model}',
      sublabel: 'SAR ${model.pricePerDay.toStringAsFixed(0)}/day',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CarDetailsScreen(model: model)),
      ),
    );
  }
}
