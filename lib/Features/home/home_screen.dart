import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cargo/core/widgets/search_widget.dart';
import 'package:cargo/core/widgets/profile_menu_button.dart';
import 'package:cargo/core/widgets/app_button.dart';
import 'package:cargo/core/theme/light_color.dart';
import 'package:cargo/Features/home/controllers/home_controller.dart';
import 'package:cargo/Features/home/widgets/car_card.dart';
import 'package:cargo/Features/notifications/notification_bell_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeController(),
      child: Builder(
        builder: (context) {
          final ctrl = context.watch<HomeController>();

          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: RefreshIndicator(
                color: LightColors.primaryColor,
                onRefresh: () => ctrl.fetchCars(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ─────────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'What do you want to',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: LightColors.textColor),
                              ),
                              Text(
                                'Ride Today',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: LightColors.textColor,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: const [
                              NotificationBellButton(),
                              SizedBox(width: 4),
                              ProfileMenuButton(),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Search Widget ──────────────────────────────────────
                      const SearchWidget(),

                      const SizedBox(height: 24),

                      // ── Section header ─────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // "Explore Cars" — replaced from "Available Cars"
                          // TODO: Replace with "Recommended for You" when the
                          // AI recommendation system ranks cars by renter history,
                          // preferences, past booked categories, and location.
                          const Text(
                            'Explore Cars',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: LightColors.textColor,
                            ),
                          ),
                          if (ctrl.hasActiveFilter)
                            GestureDetector(
                              onTap: () => ctrl.clearFilters(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: LightColors.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Clear filters',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: LightColors.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      // ── Active filter chips ────────────────────────────────
                      if (ctrl.hasActiveFilter) ...[
                        const SizedBox(height: 8),
                        _ActiveFilterChips(ctrl: ctrl),
                      ],

                      const SizedBox(height: 14),

                      // ── Cars List ──────────────────────────────────────────
                      if (ctrl.isLoadingCars)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(
                              color: LightColors.primaryColor,
                            ),
                          ),
                        )
                      else if (ctrl.carsError != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 48, color: Colors.red),
                                const SizedBox(height: 12),
                                Text(
                                  'Failed to load cars',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                AppButton(
                                  text: 'Retry',
                                  onTap: () => ctrl.fetchCars(),
                                  width: 120,
                                  height: 44,
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (ctrl.cars.isEmpty)
                        _EmptyState(isFiltered: ctrl.hasActiveFilter)
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: ctrl.cars.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return CarCard(model: ctrl.cars[index]);
                          },
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Active filter chips ────────────────────────────────────────────────────────

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({required this.ctrl});

  final HomeController ctrl;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (ctrl.searchQuery.isNotEmpty)
          _Chip(label: '"${ctrl.searchQuery}"'),
        if (ctrl.dateRange != null)
          _Chip(label: ctrl.dateText),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: LightColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: LightColors.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: LightColors.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isFiltered});

  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered
                  ? Icons.search_off_rounded
                  : Icons.directions_car_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'No cars match your search.'
                  : 'No cars available yet.',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try different keywords or clear your filters.'
                  : 'Check back soon — new vehicles are being added.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
