import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/Features/cars/car_list_controller.dart';
import 'package:cargo/core/widgets/item_card.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/Features/details/car_details_screen.dart';

class CarListScreen extends StatelessWidget {
  const CarListScreen({super.key, required this.cityName});

  final String cityName;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CarListController(cityName: cityName),
      child: _CarListView(cityName: cityName),
    );
  }
}

class _CarListView extends StatelessWidget {
  const _CarListView({required this.cityName});

  final String cityName;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CarListController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          cityName,
          style: const TextStyle(
            color: LightColors.textColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: LightColors.textColor),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchBar(ctrl: ctrl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              '${ctrl.cars.length} result${ctrl.cars.length == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 8),
          _FilterPanel(ctrl: ctrl),
          if (ctrl.showFilters) const SizedBox(height: 12),
          Expanded(child: _CarList(ctrl: ctrl)),
        ],
      ),
    );
  }
}

// ── Search bar — matches SearchBarWidget style ────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.ctrl});

  final CarListController ctrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: ctrl.searchController,
                decoration: InputDecoration(
                  hintText: 'Search cars…',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ctrl.showFilters
                  ? const Color(0xFF004B09).withValues(alpha: 0.15)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: Colors.black54),
              onPressed: ctrl.toggleFilters,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter panel — matches SearchFilterPanel style ────────────────────────────

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({required this.ctrl});

  final CarListController ctrl;

  @override
  Widget build(BuildContext context) {
    if (!ctrl.showFilters) return const SizedBox.shrink();

    final hasDate = ctrl.dateRange != null;

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
                  overlayColor:
                      LightColors.primaryColor.withValues(alpha: 0.15),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                  trackHeight: 4,
                  rangeThumbShape: const RoundRangeSliderThumbShape(
                      enabledThumbRadius: 8),
                ),
                child: RangeSlider(
                  values: ctrl.priceRange,
                  min: CarListController.minPrice,
                  max: CarListController.maxPrice,
                  onChanged: ctrl.updatePriceRange,
                ),
              ),
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

              const SizedBox(height: 16),

              // ── Date picker ───────────────────────────────────────────
              const Text(
                'Pick Up Date:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: LightColors.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ctrl.pickDates(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month,
                                color: Colors.grey.shade500, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              ctrl.dateText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: hasDate
                                    ? LightColors.textColor
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (hasDate) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: ctrl.clearDates,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Icon(Icons.close,
                            size: 16, color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

// ── Car list ──────────────────────────────────────────────────────────────────

class _CarList extends StatelessWidget {
  const _CarList({required this.ctrl});

  final CarListController ctrl;

  @override
  Widget build(BuildContext context) {
    if (ctrl.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: LightColors.primaryColor),
      );
    }

    if (ctrl.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                ctrl.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: ctrl.fetchCars,
                style: ElevatedButton.styleFrom(
                    backgroundColor: LightColors.primaryColor),
                child: const Text('Retry',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (ctrl.cars.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No cars found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: ctrl.clearFilters,
              child: const Text(
                'Clear filters',
                style: TextStyle(color: LightColors.primaryColor),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: ctrl.cars.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final car = ctrl.cars[index];
        return ItemCard(
          networkUrl: car.images.isNotEmpty ? car.images.first : '',
          label: '${car.brand} ${car.model}',
          sublabel: 'SAR ${car.pricePerDay.toStringAsFixed(0)}/day',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CarDetailsScreen(model: car),
            ),
          ),
        );
      },
    );
  }
}