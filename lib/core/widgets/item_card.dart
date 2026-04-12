import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    this.assetPath,
    this.networkUrl,
    required this.label,
    this.sublabel,
    required this.onTap,
  });

  /// Local asset image path — use for cities.
  final String? assetPath;

  /// Remote image URL — use for cars.
  final String? networkUrl;

  /// Primary label shown at the bottom (city name or car brand+model).
  final String label;

  /// Optional secondary label (e.g. "SAR 200/day" for cars).
  final String? sublabel;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.hardEdge,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(context),
              // Gradient overlay + label
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.75),
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sublabel != null)
                        Text(
                          sublabel!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    // Local asset
    if (assetPath != null) {
      return Image.asset(
        assetPath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _Placeholder(isCity: true),
      );
    }
    // Network image
    final theme = Theme.of(context);
    return CachedNetworkImage(
      imageUrl: networkUrl ?? '',
      fit: BoxFit.cover,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: theme.colorScheme.surfaceVariant,
        highlightColor: theme.colorScheme.surface,
        child: Container(color: theme.colorScheme.surface),
      ),
      errorWidget: (context, url, error) => const _Placeholder(isCity: false),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final bool isCity;
  const _Placeholder({required this.isCity});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFCFCFCF),
      child: Center(
        child: Icon(
          isCity ? Icons.location_city : Icons.directions_car,
          size: 48,
          color: Colors.white54,
        ),
      ),
    );
  }
}
