import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cargo/models/car_model.dart';
import 'package:cargo/Features/details/car_details_screen.dart';
import 'package:cargo/core/theme/light_color.dart';

/// Rich car card used on the Home screen.
/// Shows image, price overlay, category badge, brand+model, and specs row.
class CarCard extends StatelessWidget {
  const CarCard({super.key, required this.model});

  final Car model;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CarDetailsScreen(model: model)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              // ── Background image ────────────────────────────────────────
              Positioned.fill(child: _buildImage()),

              // ── Dark gradient overlay ───────────────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // ── Price badge (top-left) ──────────────────────────────────
              Positioned(
                top: 12,
                left: 14,
                child: _PriceBadge(
                  price: model.pricePerDay,
                ),
              ),

              // ── Favourite icon (top-right) ──────────────────────────────
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_outline,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),

              // ── Category badge ──────────────────────────────────────────
              if (model.category.isNotEmpty)
                Positioned(
                  bottom: 44,
                  left: 14,
                  child: _CategoryBadge(category: model.category),
                ),

              // ── Bottom info row ─────────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${model.brand} ${model.model}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            _SpecsRow(model: model),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Arrow button
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: LightColors.primaryColor,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Colors.white,
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

  Widget _buildImage() {
    if (model.images.isEmpty) {
      return Container(
        color: const Color(0xFFCFCFCF),
        child: const Center(
          child: Icon(Icons.directions_car, size: 48, color: Colors.white54),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: model.images.first,
      fit: BoxFit.cover,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(color: Colors.white),
      ),
      errorWidget: (context, url, error) => Container(
        color: const Color(0xFFCFCFCF),
        child: const Center(
          child:
              Icon(Icons.directions_car, size: 48, color: Colors.white54),
        ),
      ),
    );
  }
}

// ── Price Badge ───────────────────────────────────────────────────────────────

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.price});

  final double price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: LightColors.primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'SAR ${price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const TextSpan(
              text: '/day',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category Badge ─────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Specs Row ──────────────────────────────────────────────────────────────────

class _SpecsRow extends StatelessWidget {
  const _SpecsRow({required this.model});

  final Car model;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SpecItem(
            icon: Icons.event_seat_outlined, label: '${model.seats}'),
        const SizedBox(width: 10),
        _SpecItem(icon: Icons.settings_outlined, label: model.transmission),
        if (model.year > 0) ...[
          const SizedBox(width: 10),
          _SpecItem(
              icon: Icons.calendar_today_outlined,
              label: '${model.year}'),
        ],
      ],
    );
  }
}

class _SpecItem extends StatelessWidget {
  const _SpecItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white70),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
