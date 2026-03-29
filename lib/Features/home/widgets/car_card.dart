import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cargo/Features/home/models/car_model.dart';
import 'package:cargo/Features/details/car_details_screen.dart' show CarDetailsScreen;
import 'package:cargo/core/theme/light_color.dart';

class CarCard extends StatelessWidget {
  const CarCard({super.key, required this.model});

  final Car model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CarDetailsScreen(model: model),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),

        ),
        clipBehavior: Clip.hardEdge,
        child: _buildImageSection(context),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: CachedNetworkImage(
            imageUrl: model.images.isNotEmpty ? model.images.first : '',
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: theme.colorScheme.surfaceVariant,
              highlightColor: theme.colorScheme.surface,
              child: Container(color: theme.colorScheme.surface),
            ),
            errorWidget: (context, url, error) => Container(
              color: theme.colorScheme.surfaceVariant,
              child: Icon(
                Icons.directions_car,
                color: theme.iconTheme.color,
                size: 48,
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 14,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'SAR ${model.pricePerDay.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: LightColors.textColor,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const TextSpan(
                  text: '/day',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const Positioned(
          top: 12,
          right: 14,
          child: Icon(
            Icons.favorite_outline,
            size: 24,
            color: Colors.white,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${model.brand} ${model.model}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CarDetailsScreen(model: model),
                      ),
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF2D5016),
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: LightColors.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}