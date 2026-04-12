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
      backgroundColor: LightColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: LightColors.backgroundColor,
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
        children: [
          _SearchBar(ctrl: ctrl),
          _DateChip(ctrl: ctrl),
          _CarCount(ctrl: ctrl),
          Expanded(child: _CarList(ctrl: ctrl)),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.ctrl});

  final CarListController ctrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: ctrl.searchController,
        decoration: InputDecoration(
          hintText: 'Search by brand or model…',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: LightColors.primaryColor),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.ctrl});

  final CarListController ctrl;

  @override
  Widget build(BuildContext context) {
    final hasDate = ctrl.dateRange != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ctrl.pickDates(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: hasDate
                    ? LightColors.primaryColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: hasDate ? Colors.white : LightColors.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ctrl.dateText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: hasDate ? Colors.white : LightColors.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasDate) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: ctrl.clearDates,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14,
                    color: LightColors.textColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CarCount extends StatelessWidget {
  const _CarCount({required this.ctrl});

  final CarListController ctrl;

  @override
  Widget build(BuildContext context) {
    if (ctrl.isLoading || ctrl.error != null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${ctrl.cars.length} car${ctrl.cars.length == 1 ? '' : 's'} available',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

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
            Icon(Icons.directions_car_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No cars found',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search or dates',
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400),
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
