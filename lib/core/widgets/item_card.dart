import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cargo/core/theme/light_color.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    this.assetPath,
    this.networkUrl,
    required this.label,
    this.sublabel,
    required this.onTap,
  });

  /// Local asset image — use for cities.
  final String? assetPath;

  /// Remote image URL — use for cars.
  final String? networkUrl;

  /// Primary label shown at the bottom (city name or car brand+model).
  final String label;

  /// Optional price label, e.g. "SAR 500/day". When provided the card also
  /// shows a favourite icon and splits the text into a large price + "/day".
  final String? sublabel;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSublabel = sublabel != null;

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
            children: [
              // ── Background image ────────────────────────────────────────────
              Positioned.fill(child: _buildImage(context, theme)),

              // ── Price overlay (top-left) — cars only ────────────────────────
              if (hasSublabel)
                Positioned(
                  top: 12,
                  left: 14,
                  child: _PriceOverlay(text: sublabel!),
                ),

              // ── Favourite icon (top-right) — cars only ──────────────────────
              if (hasSublabel)
                const Positioned(
                  top: 12,
                  right: 14,
                  child: Icon(
                    Icons.favorite_outline,
                    size: 24,
                    color: Colors.white,
                  ),
                ),

              // ── Bottom gradient + label + arrow ─────────────────────────────
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
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: onTap,
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
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, ThemeData theme) {
    if (assetPath != null) {
      return Image.asset(
        assetPath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _Placeholder(isCity: true),
      );
    }
    return CachedNetworkImage(
      imageUrl: networkUrl ?? '',
      fit: BoxFit.cover,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: theme.colorScheme.surfaceContainerHighest,
        highlightColor: theme.colorScheme.surface,
        child: Container(color: theme.colorScheme.surface),
      ),
      errorWidget: (context, url, error) => const _Placeholder(isCity: false),
    );
  }
}

// ── Price overlay ─────────────────────────────────────────────────────────────
// Parses "SAR 500/day" → large "SAR 500" + small "/day".
// Falls back to showing the whole string when there is no "/".
class _PriceOverlay extends StatelessWidget {
  const _PriceOverlay({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final slashIndex = text.indexOf('/');
    final hasSplit = slashIndex != -1;
    final main = hasSplit ? text.substring(0, slashIndex) : text;
    final suffix = hasSplit ? '/${text.substring(slashIndex + 1)}' : '';

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: main,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
          ),
          if (hasSplit)
            TextSpan(
              text: suffix,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Placeholder ───────────────────────────────────────────────────────────────
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