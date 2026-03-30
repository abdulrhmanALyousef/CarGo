import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/Features/search/controller/search_controller.dart';
import 'package:cargo/core/theme/light_color.dart';

class SearchFilterPanel extends StatelessWidget {
  const SearchFilterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SearchCarController>();
    if (!ctrl.showFilters) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Price Range ───────────────────────────────────────────
              const Text(
                'Price Range:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: LightColors.textColor,
                ),
              ),
              const SizedBox(height: 4),

              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: LightColors.primaryColor,
                  inactiveTrackColor: Colors.grey.shade200,
                  thumbColor: LightColors.primaryColor,
                  overlayColor: LightColors.primaryColor.withValues(alpha: 0.15),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                  trackHeight: 4,
                  rangeThumbShape: const RoundRangeSliderThumbShape(
                      enabledThumbRadius: 8),
                ),
                child: RangeSlider(
                  values: ctrl.priceRange,
                  min: SearchCarController.minPrice,
                  max: SearchCarController.maxPrice,
                  onChanged: (values) => ctrl.updatePriceRange(values),
                ),
              ),

              // ── Price labels ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _PriceChip('${ctrl.priceRange.start.round()} SAR'),
                  _PriceChip('${ctrl.priceRange.end.round()} SAR'),
                ],
              ),

              const SizedBox(height: 16),

              // ── Car Type Grid ─────────────────────────────────────────
              GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: ctrl.carTypes.map((type) {
                  final isSelected = ctrl.selectedTypes.contains(type);
                  return GestureDetector(
                    onTap: () => ctrl.toggleType(type),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? LightColors.primaryColor
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                            color: isSelected
                                ? LightColors.primaryColor
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 12, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? LightColors.primaryColor
                                  : LightColors.textColor,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small green price chip
class _PriceChip extends StatelessWidget {
  final String label;
  const _PriceChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: LightColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: LightColors.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


